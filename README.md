# GitHub Action for deploying packages to a Signed APT repository

Action provides an environment with all the packages necessary for synchronising a signed APT repository and uploading to an OpenStack compatible Object Storage instance.
The action will download all the current deb files, add your new .deb file, rebuild the PPA and upload the changes. The deb file must be located in the root of your workspace to be picked up.
It is not recommended to check .deb files in to source control, however preceding build steps can produce a .deb file from your source code.

## Inputs

### `storage-container-url`
**Required** URL of OpenStack compatible Object Storage container
### `open-stack-authorisation-url`
**Required** URL of OpenStack authorisation end point
### `open-stack-project-id`
**Required** OpenStack project ID with which the target Object Storage container is associated
### `swift-client-username`
**Required** OpenStack / Swift client username for uploads
### `swift-client-password`
**Required** OpenStack / Swift client password for uploads
### `swift-region-name`
**Required** OpenStack / Swift client region name for target Object Storage container
### `swift-container-name`
**Required** OpenStack / Swift client name for target Object Storage container
### `private-key`
**Required** GPG Private key in ascii armor format for signing packages
### `private-key-email`
**Required** GPG Private key email address
### `private-key-passphrase`
**Required** GPG Private key passphrase
### `public-key`
**Required** GPG Public key in ascii armor for verifying signing packages
### `list-file-name`
**Required** Name of the .list file users will download and add to their local machines when consuming your PPA

## Consuming packages

The PPA can be added to your installation using the following command
```shell script
curl -s --compressed `storage-container-url`/KEY.gpg | sudo apt-key add -
sudo curl -s --compressed -o /etc/apt/sources.list.d/`list-file-name` `storage-container-url`/`list-file-name`
sudo apt update
```
## Seeding the GPG Keys

Initial setup requires the GPG signatory to be setup for the publishing repositories, the included `gpg-key-generator.sh` script can be used for this purpose:
```shell script
gpg-key-generator.sh <PASSWORD_GOES_HERE> <EMAIL_ADDRESS_GOES_HERE> <REAL_NAME_GOES_HERE>
``` 
This will produce a `ppa-private-key.asc` (private key) and a `KEY.gpg` (public key) file. The private key and passphrase must be stored securely, for example using last pass, as with the current setup

## Usage

To compile a rust binary/library with x86_64-unknown-linux-musl target:

```yaml
name: PPA deployment

on: [push]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      
    - name: Deploy to PPA
      uses:  albeego/apt-repository-action@master
      with:
        storage_container_url: https://storage.uk.cloud.ovh.net/v1/AUTH_12345/object-storage-1
        open_stack_authorisation_url: https://auth.cloud.ovh.net/v3
        open_stack_project_id: 12345
        swift_client_username: username
        swift_client_password: ${{ secrets.SWIFT_PASSWORD }}
        swift_region_name: UK
        swift_container_name: object-storage-1
        private_key: ${{ secrets.PPA_PRIVATE_KEY }}
        private_key_email: info@me.com
        private_key_passphrase: ${{ secrets.PPA_PRIVATE_KEY_PASSPHRASE }}
        public_key: ${{ secrets.PPA_PUBLIC_KEY }}
        list_file_name: my_respository.list
```

## License

The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE-MIT.txt).

