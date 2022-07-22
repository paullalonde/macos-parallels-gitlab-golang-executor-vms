#!/bin/bash

set -eux

export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/go/bin:/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/bin:${HOME}/go/bin"

TEMP_DIR="/Users/{{ executor_user }}/.setup-keychain-temp"
mkdir -p "${TEMP_DIR}"
trap "{ rm -rf ${TEMP_DIR}; }" EXIT

echo "Creating keychain ..."
security create-keychain -p "{{ keychain_password | trim }}" "{{ keychain_name }}"

echo "Set keychain settings to defaults (no auto-lock timeout, and no lock on sleep) ..."
security set-keychain-settings "{{ keychain_name }}"
{% for item in apple_certificates %}

echo "Importing certificate {{ item.filename }} ..."
security import ~/certs/"{{ item.filename }}" \
  -f pkcs12 -x \
  -k "{{ keychain_name }}" \
  -T /usr/bin/codesign \
  -T /usr/bin/pkgbuild \
  -T /usr/bin/productbuild \
  -T /usr/bin/productsign \
  -T /usr/bin/security \
  -P "{{ item.password | trim }}" \
  >/dev/null
{% endfor %}

echo "Allowing Apple tools to access signing keys ..."
security set-key-partition-list \
  -S "apple-tool:,apple:,codesign:" \
  -s \
  -k "{{ keychain_password | trim }}" \
  "{{ keychain_name }}" \
  >/dev/null

{% for item in apple_developer_program_credentials %}
echo "Importing altool credentials for {{ item.username }} ..."
xcrun altool --store-password-in-keychain-item "{{ adp_keychain_service_altool }}" \
  -u "{{ item.username }}" \
  -p "{{ item.password | trim }}"  \
  --keychain "{{ keychain_name }}"

{% if has_notarytool %}
# TODO: Finish this
echo "Importing notarytool credentials for {{ item.username }} ..."
xcrun notarytool store-credentials "{{ adp_keychain_service_notarytool }}" \
  --apple-id "{{ item.username }}" \
  --password "{{ item.password | trim }}"  \
  --team-id "{{ item.team_id }}" \
  --keychain "{{ keychain_name }}"
{% endif %}
{% endfor %}

# Add keychain to search list
security list-keychains -d user -s "{{ keychain_name }}"

# Signal to Ansible that we succeeded.
touch "{{ per_user_keychain_sentinel }}"
