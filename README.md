# MacOS Parallels Gitlab Golang Executor VMs

Creates Parallels Desktop virtual machines containing a Gitlab CI
[executor](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-executors)
capable of building golang projects on macOS.
It starts with a *base* VM (see below), and performs the following actions:

- Installs golang 1.16 and related tools.
- Creates a `gitlab-executor` user with a known password.
  The user is not privileged (i.e. it's not an Adminstrator).
  This is the user under which Gitlab CI jobs will run.
- Installs some golang packages in the context of the `gitlab-executor` user.

This executor cannot run Gitlab jobs directly;
it needs to be hosted by a [Gitlab runner](https://docs.gitlab.com/runner/configuration/) first.

#### Why?

Admitedely, this is an odd executor VM.
Although some CI offerings support macOS VMs, these are typically geared toward usual macOS/iOS development.
My needs are a bit different.
I write quite a few golang-based utilities.
For the macOS versions of these utilities, I like to codesign them in order to avoid having to work around Gatekeeper.
I also give them a proper installer.
So I need a build enviroment that has both macOS build tools (Xcode etc) and golang.
I don't use Xcode to manage the build process, though.
Golang has its own suite of tools.

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
1. Packer will perform the following steps:
   1. Create the new VM as a copy of the base VM.
   1. Run the Ansible playbook, which in turn installs Homebrew and Xcode.
   1. Save the VM under the `vms` directory.
   1. Tar & gzip the VM, producing a `.tgz` file.
   1. Compute the tgz file's SHA256 checksum and save it to a file.
   1. Both files (the tgz and the checksum) are placed in the `output` diretory.
