#!/bin/bash

fileidx=0
fileoffsetbase=0

ELF_FILENAME=uploader.elf

OFFSET=$(python3 find_buffer.py $ELF_FILENAME)

# Chunk size must match the chunk size used in uploader.elf
CHUNK_SIZE=0x8000

END_OFFSET=$OFFSET+$CHUNK_SIZE
let "OFFSET=OFFSET/0x10"
let "END_OFFSET=END_OFFSET/0x10"

# Offsets for individual partitions can be found below, if you need to write something specific
# gpt
#fileoffsetbase=0
# rootfs
#fileoffsetbase=0x4A000
# udisk
#fileoffsetbase=0x46C800
# env
#fileoffsetbase=0x22000
# boot
#fileoffsetbase=0x2A000
# recovery
#fileoffsetbase=0x44C000
# riscv
#fileoffsetbase=0x44A000
# boot-resources
#fileoffsetbase=0x12000
# misc
#fileoffsetbase=0x46C400
# pri_key
#fileoffsetbase=0x46C000

while true
do
	let fileoffset="fileoffsetbase+((fileidx*CHUNK_SIZE)/0x200)"

	echo Writing to block offset $(printf "0x%x" "$fileoffset")

	./sunxi-fel writel 0x44a50 $(printf "0x%x" "$fileoffset")
	# Set flag to force tool to recognize that the address has been initialized already
	./sunxi-fel writel 0x44a54 0x57357351

	file=parts/part$fileidx.bin
	echo $fileidx $file

	if [ ! -f "$file" ]; then
        # Will show if you've reached the end of the available files or if there's a missing file in the parts folder
		echo "File not found: " $file
		exit
	fi

	let "fileidx=fileidx+1"

    # Only needed if uploader tool was compiled with EXTENDED_BUFFER
    # file=parts/part$fileidx.bin
	# if [ -f "$file" ]; then
	# 	./sunxi-fel write 0x45404 $file
	# 	let "fileidx=fileidx+1"
	# fi

	dd if=uploader.elf of=uploader_payload.elf bs=16 count=$(printf "%d" "$OFFSET")
	cat $file >> uploader_payload.elf
	dd if=uploader.elf bs=16 skip=$(printf "%d" "$END_OFFSET") >> uploader_payload.elf

	time ./sunxi-fel spl uploader_payload.elf

	echo ""
done
