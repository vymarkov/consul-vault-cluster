#! /bin/bash

MACHINE_STORAGE_PATH="${MACHINE_STORAGE_PATH:-"$HOME/.docker/machine/certs"}"

archive_name="certs.zip"
zip -rj "$archive_name" "$MACHINE_STORAGE_PATH" > /dev/null

echo "Exported certs to $archive_name"