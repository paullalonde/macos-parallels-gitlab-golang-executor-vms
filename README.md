# MacOS Parallels Gitlab Golang Executor VMs

Creates Parallels Desktop virtual machines containing a Gitlab CI
[executor](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-executors)
capable of building [golang](https://go.dev) projects on macOS.
It starts with a *base* VM (see below), and performs the following actions:

- Installs golang 1.16 and related tools.
- Creates a `gitlab-executor` account with a known password.
  The user is not privileged (i.e. it's not an Adminstrator).
  This is the user under which Gitlab CI jobs will run.
- Creates a custom keychain for the `gitlab-executor` account.
- Installs some golang packages in the context of the `gitlab-executor` user.

This executor cannot run Gitlab jobs directly;
it needs to be hosted by a [Gitlab runner](https://docs.gitlab.com/runner/configuration/) first.

#### Why?

Admittedly, this is an odd executor VM.
Although some CI offerings support macOS VMs, these are geared toward typical macOS/iOS development.
My needs are a bit different.
I write quite a few golang-based utilities.
For the macOS versions of these utilities, I like to codesign them in order to avoid having to work around Gatekeeper.
I also give them a proper installer.
So I need a build enviroment that has both macOS build tools (Xcode etc) and golang.
I don't use Xcode to manage the build process, though.
Golang has its own suite of tools.

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
- Homebrew is installed.
- Xcode is installed.

[This repository](https://github.com/paullalonde/macos-parallels-build-vms) can generate a suitable base VM.

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

#### Ansible Vault password

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

#### Executor password

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

#### Executor keychain password

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

#### Apple Developer Program (ADP) credentials

TODO

#### Apple certificates

TODO

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
