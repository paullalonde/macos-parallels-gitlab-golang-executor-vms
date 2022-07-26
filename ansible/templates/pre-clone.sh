#!/bin/bash
#
# This script is meant to be called from the Gitlab runner's pre-clone script.
# It requires the following environment variables:
#
#   KEYCHAIN_PASSWORD   The password of our custom keychain.

set -eu

security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "{{ keychain_path }}"
security list-keychains -s "{{ keychain_path }}" "/Library/Keychains/System.keychain"
