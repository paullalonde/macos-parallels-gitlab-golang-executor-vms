# Ticksmith macOS Gitlab Executor

Creates a Parallels Desktop virtual machine containing a Gitlab executor tailored for Ticksmith's needs.
It starts with a *base* VM (see below), and performs the following actions:

- ...

#### Base VM

The base VM must have the following characteristics:

- It runs one of the supported versions of macOS (Catalina, Big Sur, or Monterey).
- There's an administrator account called `packer` with a known password.
- Remote Login (i.e. SSH) must be turned on, and enabled for the `packer` account.
- The Command Line Developer Tools are installed.
- Homebrew is installed.
- Xcode is installed.

[This repository](https://github.com/paullalonde/macos-parallels-build-vms) can generate a suitable base VM.

## Requirements

- Packer 1.8
- Parallels Desktop 17
- Parallels Virtualization SDK 17.1.4
- A base VM
- jq

## Setup

1. Create a Packer variables file for the version of macOS you are interested in, at `packer/conf/<os>.pkrvars.hcl`.
   Add the following contents:
   ```
   source_vm    = "<REPLACE-ME>"
   ssh_password = "<REPLACE-ME>"
   ```
   Replace the `source_vm`'s value with the path to the base VM.
   Obviously, the base VM has to actually run the correct version of macOS.
   Replace the `ssh_password`'s value with the password of the `packer` account in the VM.

## Procedure

1. Run the script:
   ```bash
   ./bin/provision.sh --os <name>
   ```
   where *name* is one of:
   - `catalina`
   - `bigsur`
   - `monterey`
1. Packer will create the new VM as a copy of the base VM.
1. Packer will then run the Ansible playbook, which in turn installs Homebrew and Xcode.
1. Packer then saves the VM under the `vms` directory.
