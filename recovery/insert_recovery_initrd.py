PARTITION_START_OFFSET = 0x89800000

CHUNK_SIZE = 0x8000

INITRD_OFFSET = 0xabe60c
INITRD_SIZE_OFFSET = 0x2f21dd0
INITRD_MAX_SIZE = INITRD_SIZE_OFFSET - INITRD_OFFSET - 1

data = bytearray(open("recovery.img", "rb").read())

new_data = bytearray(open("initrd-mod.gz", "rb").read())
new_data = new_data[:4] + bytearray(b"\0\0\0\0") + new_data[8:]
new_data_size = len(new_data)

print("%08x bytes vs %08x bytes" % (len(new_data), INITRD_MAX_SIZE))
assert(len(new_data) <= INITRD_MAX_SIZE)

if len(new_data) < INITRD_MAX_SIZE:
    new_data += b"\0" * (INITRD_MAX_SIZE - len(new_data))

new_recovery = data[:INITRD_OFFSET] + new_data + b"\0" + int.to_bytes(new_data_size, 4, 'little') + data[INITRD_SIZE_OFFSET+4:]

open("recovery-output.img", "wb").write(new_recovery)

# output diff file
offset = None
last_offset = None
for i in range(INITRD_OFFSET, INITRD_SIZE_OFFSET + 4):
    if new_recovery[i] != data[i]:
        if offset is None:
            offset = i
        else:
            last_offset = i

if offset is None:
    print("No changes!")
    exit(1)

offset = (offset // CHUNK_SIZE) * CHUNK_SIZE

last_offset = ((last_offset // CHUNK_SIZE) + 1) * CHUNK_SIZE
while ((last_offset // CHUNK_SIZE) % 2) != 0:
    last_offset = ((last_offset // CHUNK_SIZE) + 1) * CHUNK_SIZE

print("offset: %08x (block: %08x)" % (PARTITION_START_OFFSET + offset, (PARTITION_START_OFFSET + offset) // 0x200))
open("recovery-diff.img", "wb").write(new_recovery[offset:last_offset])
open("recovery-undiff.img", "wb").write(data[offset:last_offset])
