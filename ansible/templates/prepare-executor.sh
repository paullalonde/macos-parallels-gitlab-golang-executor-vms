#!/bin/bash

set -eu

# For some reason, codesign fails if the keychain holding the Apple certificates is locked.
security unlock-keychain -p {{ keychain_password | trim }} executor
