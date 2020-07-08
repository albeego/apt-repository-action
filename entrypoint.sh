#!/bin/bash
set -e

download_files() {
  swift --os-auth-url "$INPUT_OPEN_STACK_AUTHORISATION_URL" --auth-version 3 \
    --os-project-id "$INPUT_OPEN_STACK_PROJECT_ID" \
    --os-username "$INPUT_SWIFT_CLIENT_USERNAME" \
    --os-password "$INPUT_SWIFT_CLIENT_PASSWORD" \
    --os-region-name "$INPUT_SWIFT_REGION_NAME" \
    download "$INPUT_SWIFT_CONTAINER_NAME" \
    --prefix debian/pool/main/
}

upload() {
  swift --os-auth-url "$INPUT_OPEN_STACK_AUTHORISATION_URL" --auth-version 3 \
    --os-project-id "$INPUT_OPEN_STACK_PROJECT_ID" \
    --os-username "$INPUT_SWIFT_CLIENT_USERNAME" \
    --os-password "$INPUT_SWIFT_CLIENT_PASSWORD" \
    --os-region-name "$INPUT_SWIFT_REGION_NAME" \
    upload "$INPUT_SWIFT_CONTAINER_NAME" "$1"
}

write_key_to_file() {

  KEY="${3//-----BEGIN PGP $1 KEY BLOCK-----/}"
  KEY="${KEY//-----END PGP $1 KEY BLOCK-----/}"

  echo "-----BEGIN PGP $1 KEY BLOCK-----" >"$2"
  printf "%s\n" "$KEY" >>"$2"
  echo "-----END PGP $1 KEY BLOCK-----" >>"$2"
}

write_private_key_to_file() {
  write_key_to_file "PRIVATE" private.key "$INPUT_PRIVATE_KEY"
}

write_public_key_to_file() {
  write_key_to_file "PUBLIC" KEY.gpg "$INPUT_PUBLIC_KEY"
}

cd "$INPUT_EXECUTION_PATH"

rm "$INPUT_LIST_FILE_NAME" || true

write_private_key_to_file
gpg --import private.key
rm private.key

mkdir -p debian/dists/bionic/main/binary-amd64
mkdir -p debian/dists/bionic/main/binary-arm64
mkdir -p debian/pool/main
cp -r *.deb debian/pool/main
download_files
mkdir cache || true
apt-ftparchive generate apt-ftparchive.conf
apt-ftparchive -c bionic.conf release debian/dists/bionic >>debian/dists/bionic/Release
echo "$INPUT_PRIVATE_KEY_PASSPHRASE" | gpg -u "${INPUT_PRIVATE_KEY_EMAIL}" --batch --quiet --yes --passphrase-fd 0 --pinentry-mode loopback -abs -o - debian/dists/bionic/Release >debian/dists/bionic/Release.gpg
echo "$INPUT_PRIVATE_KEY_PASSPHRASE" | gpg -u "${INPUT_PRIVATE_KEY_EMAIL}" --batch --quiet --yes --passphrase-fd 0 --pinentry-mode loopback --clearsign -o - debian/dists/bionic/Release >debian/dists/bionic/InRelease
upload debian
upload cache

wget "$INPUT_STORAGE_CONTAINER_URL"/"$INPUT_LIST_FILE_NAME" || echo "deb $INPUT_STORAGE_CONTAINER_URL/debian bionic main" >"$INPUT_LIST_FILE_NAME"
upload "$INPUT_LIST_FILE_NAME"

wget "$INPUT_STORAGE_CONTAINER_URL"/"$INPUT_PUBLIC_KEY" || upload "$INPUT_PUBLIC_KEY"

rm KEY.gpg
rm debian -rf
rm cache -rf