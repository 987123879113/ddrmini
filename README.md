# DDR mini classic hacking guide

**WARNING**: This CAN brick your device if you're unlucky or not careful. Modify at your own risk.

What this guide covers: how to dump and write to the eMMC connected to an Allwinner A527 chip, how to make custom updates that work with the existing update system, and how to modify the system to use a USB drive to play game data instead of writing changes to the eMMC.

What this guide does NOT cover: How to decrypt the game data.

## Tools

- [SyterKit](https://github.com/YuzukiHD/SyterKit)
- [sunxi-tools](https://github.com/linux-sunxi/sunxi-tools)
- [swupdate](https://github.com/sbabic/swupdate/)
- cpio

You must also apply my patches for SyterKit and sunxi-tools found in the [patches](patches) folder.

## SD card
It's possible to get the SD card to work but it requires SMD soldering skills. It's recommended if you are able to solder the parts required to get it to work as it will save you from potentially bricking your device. You can find information on that [here](https://honeylab.hatenablog.jp/entry/2024/09/18/101605) (Japanese). The SD card has boot priority over the eMMC.

## eMMC

### Entering FEL mode
FEL mode is required to run any of the `sunxi-fel` commands that give us the ability to read/write memory and run programs on the A527 CPU. To enable FEL mode you must disassmble your unit to access the PCB. There will be a small button behind one of the USB ports. Switch the power switch to the OFF position (required step) then hold the button while inserting the USB-C power cable. If done successfully you should be able to run `sunxi-fel version` to get information about the connected CPU.

### Dumping eMMC
The tools used to dump the eMMC to the host PC can be found in the [dumper](dumper) folder.

For building I just swapped out the code in `board/avaota-a1/smhc2_test/main.c` of SyterKit.

It will take a very long time for the full eMMC to be dumped. Occasionally it will break so you also have to monitor the output file and check if the file starts to output nothing but Ws. If you open the output file in a hex editor and see nothing but Ws at the end of the file, go back to the first block that is not all Ws and redump from that position and combine the files after. You will need to restart the PCB for it to start dumping correctly again.

The eMMC is a GPT disk so you can mount the image or extract it (7-Zip can open it) to extract the individual partitions inside the image.

## Writing to eMMC

The tools used to dump the eMMC to the host PC can be found in the [uploader](uploader) folder.

The chunk_file.py script is to be used to split a large file into the required chunk size for the uploader script. `python3 chunk_file.py input_file.bin parts 0x8000` will dump 0x8000 chunks into a folder named `parts`.

Similar to dumping, writing also occasionally breaks. You will notice when it breaks if it hangs abnormally long when writing a certain file. You must reboot the PCB and restart the script if that happens.

The writer tool has a few options that can be controlled using the `#define`s in the program. `VERIFIED_WRITES` will read the existing data at the specified block and skip it if it matches the data that is to be written, and will also verify that the data written to the eMMC can be read back and matches what was to be written to the eMMC. This flag is slower but it's useful if you want to be sure the data is writing correctly. The other flag available is `EXTENDED_BUFFER` which uses a combination of the internal buffer + SRAM to hold twice as much data to be written.

## Updates
You will possibly need to build your own copy of swupdate to handle updates. The Ubuntu version of swupdate, for example, is not built to signed updates using the private/public key method. Follow the build instructions in the swupdate README. You must enable verification of signed images using RSA PKCS#1.5 in your build.

## Extracting updates
This device uses swupdate to handle updates. You can extract updates using the following command:
```
cpio -idmv --no-absolute-filenames < filename.img
```

## Creating updates
To make the actual update using swupdate, you must first create a new set of public and private keys to be used to to sign your update files.
```
openssl genrsa -aes256 -out priv.pem
openssl rsa -in priv.pem -out pubkey.pem -outform PEM -pubout
```

Once you have your keys made you are ready to start making your own updates. You can use [this script](updates/build_update.sh) as a template for building your own updates. Modify the `IMAGES` variable to include the specific partitions you want to include in your update.


You can verify your update is signed correctly using the following command:
```
swupdate -v -l 6 -k pubkey.pem -e "stable,upgrade_kernel" -c -i ddrmini-diff-v1.0.2.bin
```

### Note about update naming
The `UPDATE_METHOD` variable is mostly symbolic and will not change how the update is actually processed once the update is started. The options are:
`bootloader`, `diff`, `core`, `recovery`, and `all`. Additionally, the timing at which you hold the P1 start and P2 start buttons during boot changes which updater you will run. If you hold P1 start + P2 start from a cold boot then you will be launching the updater from the recovery partition which allows you to install all update types. If you time your button presses correctly you can also make it boot into the rootfs's bootloader, which is only able to update using the `recovery` method.

So far only `core` has been seen in official updates. The `core` update method will replace the entire partition on the eMMC with what is contained in the update.

### `recovery` update type
Never use this update type unless you have no other options somehow. Using a recovery update will write the `recovery` flag to the `misc` partition. The machine won't be able to boot properly until you write the `user` flag back into the `misc` partition.

### `core` update type
```
software =
{
    version = "1.0.1";
    description = "Update file";

    stable = {
        upgrade_kernel = {
            images: (
                {
                    filename = "rootfs"
                    sha256 = "<sha256 of rootfs>";
                    device = "/dev/disk/by-label/rootfs";
                    installed-directly = true;
                }
            );
        };
    };
 }
```

### `diff` update type
```
software =
{
    version = "1.0.2";
    description = "Custom update";

    stable = {
        upgrade_kernel = {
            files: (
                {
                    filename = "file.sh";
                    path = "/path/to/file.sh";
                    device = "/dev/mmcblk0p4";
                    filesystem = "ext4";
                    sha256 = "<sha256 of file.sh>";
                    properties = {create-destination = "true"};
                }
            );
        };
    };
 }
```

## Making the device accept custom updates
**WARNING**: Doing this step means you will not be able to use official updates going forward unless you restore your original recovery partition. If you wish to use official updates then you will need to extract the update and resign it using your own keys.

### Extracting initrd from recovery partition
The compressed initrd file is embedded in the executable in the recovery partition. You will need to extract recovery.img from your eMMC dump for this step.

Open recovery.img in a hex editor and search for `1F 8B 08 00 00 00 00 00` to find the start of the gzipped data. The compressed initrd data is the second result. Copy all data from that `1F 8B 08 00 00 00 00 00` header until the end of the compressed data into a file named initrd.gz and then use gzip to decompress it: `gzip -d initrd.gz`. As of writing this guide, the exact offset for the compressed initrd data is at 0xabe60c and the filesize is 38156221 bytes.

The initrd file that's extracted is in the same cpio format that's used for normal updates use, so you can follow the same steps to extract the contents of the initrd if you wish.

### Creating modified initrd

Once you have the initrd data extracted you will find the device's pubkey.pem in `/etc/swupdate/pubkey.pem`. Open the decompressed initrd in a hex editor, search for the contents of the pubkey.pem in the uncompressed initrd (it should be the only hit for the string `-----BEGIN PUBLIC KEY-----` if you want to find it that way), and overwrite it with your own pubkey.pem. The filesize of your pubkey.pem should be exactly the same as the original so nothing else needs to be done in the initrd file.

Once you have the modified file saved, you can re-compress it using the following command:
`gzip -9 > initrd-mod.gz < initrd-mod.img`

Then you can use [this script](recovery/insert_recovery_initrd.py) to insert your modified initrd.gz into the recovery partition properly. The tool will read your unmodified `recovery.img` and `initrd-mod.gz` files and output `recovery-output.img` (the full recovery partition with the modded initrd.gz) which can be written back to the eMMC to overwrite the existing recovery partition.

For a quick test if it's working, you can insert a USB with an official update on it and if it gives an error saying that the update is invalid then it should be working.

## Redirecting game data to USB drive
Included in [updates/usb_init](updates/usb_init) is a custom modification I made that patches the default initialization script to search for any available USB drives connected to the machine, mount it, and search for a file named `DDRmenu`. If the `DDRmenu` file is found then the USB drive becomes the boot target, otherwise it will use the standard internal game folder like normal.

This mod allows you to safely make modification as you wish without modifying the eMMC any more than required.
