#!/bin/bash
set -e

STORAGE_CONTAINER_URL=$1
OPEN_STACK_AUTHORISATION_URL=$2
OPEN_STACK_PROJECT_ID=$3
SWIFT_CLIENT_USERNAME=$4
SWIFT_CLIENT_PASSWORD=$5
SWIFT_REGION_NAME=$6
SWIFT_CONTAINER_NAME=$7
PRIVATE_KEY=$8
PRIVATE_KEY_EMAIL=$9
PRIVATE_KEY_PASSPHRASE=${10}
PUBLIC_KEY=${11}
LIST_FILE_NAME=${12}

download_files() {
  swift --os-auth-url "$OPEN_STACK_AUTHORISATION_URL" --auth-version 3 \
    --os-project-id "$OPEN_STACK_PROJECT_ID" \
    --os-username "$SWIFT_CLIENT_USERNAME" \
    --os-password "$SWIFT_CLIENT_PASSWORD" \
    --os-region-name "$SWIFT_REGION_NAME" \
    download "$SWIFT_CONTAINER_NAME" \
    --prefix debian/pool/main/
}

upload() {
  swift --os-auth-url "$OPEN_STACK_AUTHORISATION_URL" --auth-version 3 \
    --os-project-id "$OPEN_STACK_PROJECT_ID" \
    --os-username "$SWIFT_CLIENT_USERNAME" \
    --os-password "$SWIFT_CLIENT_PASSWORD" \
    --os-region-name "$SWIFT_REGION_NAME" \
    upload "$SWIFT_CONTAINER_NAME" "$1"
}

write_key_to_file() {

  KEY="${3//-----BEGIN PGP $1 KEY BLOCK-----/}"
  KEY="${KEY//-----END PGP $1 KEY BLOCK-----/}"

  echo "-----BEGIN PGP $1 KEY BLOCK-----" >"$2"
  printf "%s\n" "$KEY" >>"$2"
  echo "-----END PGP $1 KEY BLOCK-----" >>"$2"
}

write_private_key_to_file() {
  write_key_to_file "PRIVATE" private.key "$PRIVATE_KEY"
}

write_public_key_to_file() {
  write_key_to_file "PUBLIC" KEY.gpg "$PUBLIC_KEY"
}

rm "$LIST_FILE_NAME" || true

write_private_key_to_file
gpg --import private.key
rm private.key

mkdir -p debian/dists/bionic/main/binary-amd64
mkdir -p debian/pool/main
cp -r *.deb debian/pool/main
download_files
mkdir cache
apt-ftparchive generate apt-ftparchive.conf
apt-ftparchive -c bionic.conf release debian/dists/bionic >>debian/dists/bionic/Release
echo "$PRIVATE_KEY_PASSPHRASE" | gpg -u "${PRIVATE_KEY_EMAIL}" --batch --quiet --yes --passphrase-fd 0 --pinentry-mode loopback -abs -o - debian/dists/bionic/Release >debian/dists/bionic/Release.gpg
echo "$PRIVATE_KEY_PASSPHRASE" | gpg -u "${PRIVATE_KEY_EMAIL}" --batch --quiet --yes --passphrase-fd 0 --pinentry-mode loopback --clearsign -o - debian/dists/bionic/Release >debian/dists/bionic/InRelease
upload debian
upload cache

wget "$STORAGE_CONTAINER_URL"/"$LIST_FILE_NAME" || echo "deb $STORAGE_CONTAINER_URL bionic main" >"$LIST_FILE_NAME"
upload "$LIST_FILE_NAME"

wget "$STORAGE_CONTAINER_URL"/KEY.gpg || write_public_key_to_file
upload KEY.gpg

rm KEY.gpg
rm debian
rm cache