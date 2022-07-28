# MacOS Parallels Gitlab Golang Executor VMs

Creates Parallels Desktop virtual machines containing a Gitlab CI
[executor](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-executors)
capable of building [golang](https://go.dev) projects on macOS.
It starts with a *base* VM (see below), and performs the following actions:

- Installs golang 1.16 and related tools.
- Creates a `gitlab-executor` account with a known password.
  The user is not privileged (i.e. it's not an Adminstrator).
  This is the user under which Gitlab CI jobs will run.
- Creates a custom keychain for the `gitlab-executor` account,
  which is populated with Apple-specific secrets such as credentials and signing certificates.
- Installs some golang packages in the context of the `gitlab-executor` user.

This executor cannot run Gitlab jobs directly;
it needs to be hosted by a [Gitlab runner](https://docs.gitlab.com/runner/configuration/) first.

#### Why?

Admittedly, this is an odd executor VM.
Although some CI offerings support macOS VMs, these are geared toward typical macOS/iOS development.
My needs are a bit different.
I write quite a few golang-based utilities.
For the macOS versions of these utilities, I like to codesign them in order to avoid having to work around Gatekeeper.
I also give them a proper installer, which I then notarize.
So I need a build enviroment that has both macOS build tools (Xcode etc) and golang.
I don't use Xcode to manage the build process, though.
Golang has its own suite of tools.

#### In-VM Secrets

The VM produced herein contains secrets within a custom keychain.
The keychain is protected by a password that is shared between this Gitlab executor and the Gitlab runner that invokes it.
The secrets fall into two categories:

- Apple signing identities; these are used for code signing.
  Recall that in keychain parlance, an identity is a certificate paired with its matching private key.
- Apple Developer Program credentials; these are used for notarization.

Obviously, having the keychain baked into the Gitlab executor VM means that a change to the secrets requires
rebuilding the VM.
So it's not very convenient.
The tradeoff is that the secrets are less exposed to users of individual Gitlab repositories than if they were
provided as normal Gitlab environment variables.

## Requirements

- Packer 1.8
- Parallels Desktop 17 (Pro or Business edition)
- Parallels Virtualization SDK 17.1.4
- Ansible
- A base VM

#### Base VM

The base VM must have the following characteristics:

- It runs one of the supported versions of macOS (Catalina, Big Sur, or Monterey).
- There's an administrator account called `packer` with a known password.
- Remote Login (i.e. SSH) must be turned on, and enabled for the `packer` account.
- The Command Line Developer Tools are installed.
- Homebrew, jq and Xcode are installed.

[This repository](https://github.com/paullalonde/macos-parallels-build-vms) can generate a suitable base VM.

## Gitlab Runner Integration

Some coordination is required between this Gitlab executor and the Gitlab runner that invokes it.

1. The VM produced herein needs to be available to the runner.
1. The runner's pre-clone script needs to :
   1. Create a `KEYCHAIN_PASSWORD` environment variable containing the custom keychain's password.
   1. Call the script at `~/bin/pre-clone.sh`.
      This will unlock the keychain.
1. The runner's pre-build script needs to:
   1. Source the script at `~/bin/pre-build.sh`.
      This will populate the Gitlab job with executor-specific environment variables.

## Setup

#### General

1. Create a Packer variables file for the version of macOS you are interested in, at `packer/conf/<os>.pkrvars.hcl`.
   **DO NOT COMMIT THIS FILE TO SOURCE CONTROL**.
   Add the following variables:
  - `base_vm_checksum` The SHA256 checksum of the base VM.
  - `base_vm_name` The name of the base VM, without any extension.
    Obviously, the base VM has to actually run the correct version of macOS.
  - `base_vm_url` The base URL for downloading the base VM.
  - `ssh_password` The password of the packer account in the VM.

#### Ansible Vault Password

The [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) password
is used to encrypt other secrets in Ansible files that get committed to source control.

1. Decide on an Ansible Vault password.
1. Create a file containing the password, to be read later by Ansible Vault.
   We will call this file `vaultpw` in the examples below.
   **DO NOT COMMIT THIS FILE TO SOURCE CONTROL**.
1. Create a `.env` file containing the password, to be read later by the script that builds the VM.
   **DO NOT COMMIT THIS FILE TO SOURCE CONTROL**.
   ```bash
   export VAULT_PASSWORD=...
   ```

#### Executor Password

The `gitlab-executor` account, under which Gitlab jobs will run, needs a password.

1. Decide on the password for the `gitlab-executor` account.
1. Encrypt the `gitlab-executor` account's password with the vault password:
   ```bash
   ansible-vault encrypt_string --vault-password-file vaultpw >cipher.txt
   ```
   Paste the password into the terminal, then type Ctrl-D.
   The encrypted password will be written to `cipher.txt`.
1. Edit the Ansible group variables file for the version of macOS, i.e. `ansible/conf/${os_name}.yaml`.
   Replace the value of the `executor_password` property with the contents of the `cipher.txt` file.

#### Executor Keychain Password

The `gitlab-executor` account needs a password for its custom keychain.

1. Decide on the password for the `gitlab-executor` account's keychain.
1. Encrypt the `gitlab-executor` account's keychain password with the vault password:
   ```bash
   ansible-vault encrypt_string --vault-password-file vaultpw >cipher.txt
   ```
   Paste the password into the terminal, then type Ctrl-D.
   The encrypted password will be written to `cipher.txt`.
1. Edit the Ansible group variables file for the version of macOS, eg `ansible/conf/${os_name}.yaml`.
   Replace the value of the `keychain_password` property with the contents of the `cipher.txt` file.

#### Apple Certificates

1. Delete all of the files under `ansible/files/certificates`.
1. In the `ansible/group_vars/all.yaml` file, delete all array elements under the `apple_certificates` property.
1. For each signing certificate you have:
   1. Export the certificate from your local keychain. Use a secure password to protect it.
      This will produce a PKCS#12 file with a `.p12` extension.
   1. Place the `.p12` file under `ansible/files/certificates`.
   1. Edit the `ansible/group_vars/all.yaml` file.
      Add an array element under the `apple_certificates` property with the following contents.
      - `filename` is the certificate file's name, with its `.p12` extension.
      - `password` is the `.p12` file's password,
        encrypted with `ansible-vault` similarly to the executor account's password.
      - `job_variables` is a collection of key/value pairs, where each value is an environment variable name.
        The variable will be made available to Gitlab jobs running in this executor.
        - `hash` is the name of the environment variable that will hold the SHA1 hash of the certificate;
          this is used by `codesign` *et al* to identify the certificate to use when signing.
          For example, if the variable is defined like so:
          ```yaml
          hash: MY_CERT_HASH
          ```
          then a Gitlab job running in this executor can issue this call:
          ```bash
          codesign --sign "${MY_CERT_HASH}" ...
          ```

#### Apple Developer Program (ADP) Credentials

1. In the `ansible/group_vars/all.yaml` file, delete all array elements under the `apple_developer_program_credentials` property.
1. For each credential you have:
   1. Edit the `ansible/group_vars/all.yaml`.
      Add an array element under the `apple_developer_program_credentials` property with the following contents.
      - `username` is the name of the Apple Developer account.
      - `password` is an app-specific password belonging to the Apple Developer account;
        it needs to be encrypted with `ansible-vault` similarly to the executor account's password.
      - `team_id` is an ADP Team ID of which the Apple Developer account is a member.
      - `asc_provider` is an App Store Connect Provider of which the Apple Developer account is a member.
      - `job_variables` is a collection of key/value pairs, where each value is an environment variable name.
        The variable will be made available to Gitlab jobs running in this executor.
        - `username` is the name of the environment variable that will hold the name of the Apple Developer account.
        - `team_id` is the name of the environment variable that will hold the ADP Team ID.
        - `asc_provider` is the name of the environment variable that will hold the App Store Connect Provider.
        - `altool` is a collection of variables for use by `altool`.
          - `keychain_item` is the name of the keychain item that will hold ADP credentials for use by `altool`.
        - `notarytool` is a collection of variables for use by `notarytool`.
          - `profile` is the name of the profile (aka keychain item) that will hold ADP credentials for use by `notarytool`.

Here's an example.
Given these ADP credentials:

```yaml
apple_developer_program_credentials:
  - username: my-user@gmail.com
    password: ...
    team_id: ...
    asc_provider: ...
    job_variables:
      username: MY_ADP_USERNAME
      team_id: MY_ADP_TEAM_ID
      asc_provider: MY_ASC_PROVIDER
      altool:
        keychain_item: MY_ALTOOL_ITEM
      notarytool:
        profile: MY_NOTARYTOOL_PROFILE
```

then a Gitlab job running in this executor can issue these calls:

```bash
xcrun altool --notarize-app ... -u "${MY_ADP_USERNAME}" -p "@keychain:${MY_ALTOOL_ITEM}" --asc-provider  "${MY_ASC_PROVIDER}"

xcrun notarytool submit ... --keychain-profile "${MY_NOTARYTOOL_PROFILE}" --keychain "${KEYCHAIN}"
```

## Procedure

1. Run the script:
   ```bash
   ./make-executor-vm.sh --os <name>
   ```
   where *name* is one of:
   - `catalina`
   - `bigsur`
   - `monterey`

1. Packer will perform the following steps:
   1. Create the new VM as a copy of the base VM.
   1. Run the Ansible playbook, which in turn creates the `gitlab-executor` account and
      installs golang and related tools.
   1. Save the VM.
   1. Tar & gzip the VM, producing a `.tgz` file.
   1. Compute the tgz file's checksum and save it to a file.

1. The final outputs will be:
   - `output/macos-${var.os_name}-golang-executor.pvm.tgz`, the tar'd and gzip'd VM.
   - `output/macos-${var.os_name}-golang-executor.pvm.tgz.sha256`, the checksum.

## Related Repositories

- [Bootable ISO images for macOS](https://github.com/paullalonde/macos-bootable-iso-images).
- [Base VMs for macOS](https://github.com/paullalonde/macos-parallels-base-vms).
- [Build VMs for macOS](https://github.com/paullalonde/macos-parallels-build-vms).
