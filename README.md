# GitHub Action for deploying packages to a Signed APT repository

Action provides an environment with all the packages necessary for synchronising a signed APT repository and uploading to an OpenStack compatible Object Storage instance.
The action will download all the current deb files, add your new .deb file, rebuild the PPA and upload the changes. The deb file must be located in the root of your workspace to be picked up.
It is not recommended to check .deb files in to source control, however preceding build steps can produce a .deb file from your source code.

## Inputs

### `storage_container_url`
**Required** URL of OpenStack compatible Object Storage container
### `open_stack_authorisation_url`
**Required** URL of OpenStack authorisation end point
### `open_stack_project_id`
**Required** OpenStack project ID with which the target Object Storage container is associated
### `swift_client_username`
**Required** OpenStack / Swift client username for uploads
### `swift_client_password`
**Required** OpenStack / Swift client password for uploads
### `swift_region_name`
**Required** OpenStack / Swift client region name for target Object Storage container
### `swift_container_name`
**Required** OpenStack / Swift client name for target Object Storage container
### `private_key`
**Required** GPG Private key in ascii armor format for signing packages
### `private_key_email`
**Required** GPG Private key email address
### `private_key_passphrase`
**Required** GPG Private key passphrase
### `public_key`
**Required** GPG Public key file name, stored in ascii armor for verifying signing packages - This may well exceed the size limit for secrets!!!
### `list_file_name`
**Required** Name of the .list file users will download and add to their local machines when consuming your PPA
### `execution_path`:
**Required** Sub directory in which to execute the action defaults to the repository root

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

To deploy a .deb file to your PPA, you will need some configuration files and the public key in the execution directory:

### apt-ftparchive.conf

This configuration file is used to specify the structure of your PPA, where are things stored, what compressions to use, supported version and what architectures are available.

```shell script
Dir {
    ArchiveDir "./debian";
    CacheDir "./cache";
};
Default {
    Packages::Compress ". gzip bzip2";
    Sources::Compress ". gzip";
    Contents::Compress ". gzip";
};
TreeDefault {
    BinCacheDB "packages-$(SECTION)-$(ARCH).db";
    Directory "pool/$(SECTION)";
    Packages "$(DIST)/$(SECTION)/binary-$(ARCH)/Packages";
    SrcDirectory "pool/$(SECTION)";
    Contents "$(DIST)/Contents-$(ARCH)";
};
Tree "dists/bionic" {
    Sections "main";
    Architectures "amd64";
};
```
This configuration will support ubuntu 18.04 and 20.04 for 64 bit x86 systems only

### bionic.conf

```shell script
APT::FTPArchive::Release::Codename "bionic";
APT::FTPArchive::Release::Origin "My repository";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Label "Packages hosted by me!!!";
APT::FTPArchive::Release::Architectures "amd64";
APT::FTPArchive::Release::Suite "bionic";
```
 Currently there is only support for bionic, there will be more support added soon

```yaml
name: PPA deployment

on: [push]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - name: Copy PPA files to working directory
      run: |
        cd sumbodule
        cp KEY.gpg build-directory/
        cp apt-ftparchive.conf build-directory/
        cp bionic.conf build-directory/
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
        public_key: KEY.gpg
        list_file_name: my_respository.list
        execution_path: sumbodule/build-directory
```

## License

The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE-MIT.txt).

