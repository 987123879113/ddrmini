import os
import sys

input_filename = sys.argv[1]
output_folder = sys.argv[2]
chunk_size = int(sys.argv[3], 16)

os.makedirs("parts", exist_ok=True)

with open(input_filename, "rb") as infile:
	infile.seek(0, 2)
	filelen = infile.tell()
	infile.seek(0, 0)

	for i in range(0, filelen, chunk_size):
		output_filename = os.path.join(output_folder, "part%d.bin" % (i // chunk_size))
		print("Dumping", output_filename)

		chunk = infile.read(chunk_size)

		if len(chunk) < chunk_size:
			padsize = chunk_size - len(chunk)
			print("Short %d bytes" %  padsize)
			chunk += bytearray(b"\0" * padsize)

		open(output_filename, "wb").write(chunk)
