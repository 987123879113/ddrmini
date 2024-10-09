#!/bin/bash

UPDATE_TYPE="diff"
PRODUCT_NAME="ddrmini"
CONTAINER_VER="1.0.2"
IMAGES="file.bin"
FILES="sw-description sw-description.sig $IMAGES"

openssl dgst -sha256 -sign priv.pem sw-description > sw-description.sig

for i in $FILES;do
        echo $i;done | cpio -ov -H crc >  ${PRODUCT_NAME}-${UPDATE_TYPE}-v${CONTAINER_VER}.bin
