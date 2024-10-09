#!/bin/bash

OUTPUT_FILENAME=emmc_dump.bin

# Comment out if you wish to keep the same file between runs (like if you are dumping the full eMMC and need to restart the script)
rm $OUTPUT_FILENAME > /dev/null

rm emmc-temp.bin > /dev/null

# Must match the size used by dumper.elf
CHUNK_SIZE=0xc000

# 1 block = 512 bytes, so for example a block offset of 0x44a000 corresponds to a raw offset of 0x89400000
block_offset=0


while true;
do
	echo Reading block offset $(printf "0x%x" "$block_offset"

    ./sunxi-fel writel 0x44a50 $(printf "0x%x" "$block_offset")
	# Set flag to force tool to recognize that the address has been initialized already
	./sunxi-fel writel 0x44a54 0x57357357

	./sunxi-fel spl dumper.elf
	./sunxi-fel read 0x45404 $CHUNK_SIZE emmc-temp.bin
	cat emmc-temp.bin >> $OUTPUT_FILENAME

    let "block_offset=block_offset+(CHUNK_SIZE/0x200)"
done
