import sys

data = bytearray(open(sys.argv[1], "rb").read())
idx = data.index(b"WWWWWWWWWWWWWWWW")
print(idx)
