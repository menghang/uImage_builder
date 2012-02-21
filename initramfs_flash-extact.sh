#!/bin/bash

UIMAGE=$1

tail -c +65 ${UIMAGE} | lzma -dc | tail -c +$((pos+1)) | cpio -i --no-absolute-filenames

#tail -c +129 ${UIMAGE} | lzma -dc | tail -c +$((pos+1)) | cpio -i --no-absolute-filenames
