#!/bin/bash
set -e

PASS_PHRASE=$1
EMAIL_ADDRESS=$2
REAL_NAME=$3

cat > ppa-key <<EOF
     %echo Generating a basic OpenPGP key
     Key-Type: 1
     Key-Length: 2048
     Subkey-Type: 1
     Subkey-Length: 2048
     Name-Real: $REAL_NAME
     Name-Email: $EMAIL_ADDRESS
     Expire-Date: 0
     Passphrase: $PASS_PHRASE
     # Do a commit here, so that we can later print "done" :-)
     %commit
     %echo done
EOF

gpg --batch --generate-key ppa-key
rm -rf ppa-key
echo "$PASS_PHRASE" | gpg --batch --quiet --yes --passphrase-fd 0 --pinentry-mode loopback --export-secret-keys --armor "$EMAIL_ADDRESS" > ppa-private-key.asc
gpg --export --armor "$EMAIL_ADDRESS" > KEY.gpg
