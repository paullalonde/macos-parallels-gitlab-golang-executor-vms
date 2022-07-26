#!/bin/bash

set -eux

export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/go/bin:/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/bin:${HOME}/go/bin"

TEMP_DIR="/Users/{{ executor_user }}/.setup-keychain-temp"
mkdir -p "${TEMP_DIR}"
trap "{ rm -rf ${TEMP_DIR}; }" EXIT

KEYCHAIN="{{ keychain_path }}"
KEYCHAIN_PASSWORD="{{ keychain_password | trim }}"

echo "Creating keychain ..."
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN}"

echo "Unlocking keychain ..."
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN}"

echo "Set keychain settings to defaults (no auto-lock timeout, and no lock on sleep) ..."
security set-keychain-settings "${KEYCHAIN}"

echo "Set default keychain"
security default-keychain -s "{{ keychain_path }}"
{% for item in apple_certificates %}

echo "Importing certificate {{ item.filename }} ..."
security import ~/certs/"{{ item.filename }}" \
  -f pkcs12 -x \
  -T /usr/bin/codesign \
  -T /usr/bin/pkgbuild \
  -T /usr/bin/productbuild \
  -T /usr/bin/productsign \
  -T /usr/bin/security \
  -k "${KEYCHAIN}" \
  -P "{{ item.password | trim }}" \
  >/dev/null
{% endfor %}

echo "Setting key partition list ..."
security set-key-partition-list \
  -S "apple-tool:,apple:,codesign:" \
  -s \
  -k "${KEYCHAIN_PASSWORD}" \
  "${KEYCHAIN}" \
  >/dev/null
{% for item in apple_developer_program_credentials %}

{# WARNING: altool has a tendency to FAIL SILENTLY #}
{% if altool_supports_keychain_option %}
echo "Importing altool credentials for {{ item.username }} ..."
xcrun altool --store-password-in-keychain-item "{{ altool_keychain_item }}  ({{ item.username }})" \
  -u "{{ item.username }}" \
  -p "{{ item.password | trim }}" \
  --keychain "${KEYCHAIN}"
{% else %}
{# I can't get 'altool --store-password-in-keychain-item' to work on Catalina; fallback to 'security add-generic-password' #}
echo "Importing generic altool credentials for {{ item.username }} ..."
security add-generic-password \
  -s "{{ altool_keychain_item }} ({{ item.username }})" \
  -l "{{ altool_keychain_item }} ({{ item.username }})" \
  -a "{{ item.username }}" \
  -p "{{ item.password | trim }}" \
  -T $(xcrun --find altool) \
  -T /usr/bin/security \
  "${KEYCHAIN}"
security set-generic-password-partition-list \
  -S "apple-tool:,apple:" \
  -s "{{ altool_keychain_item }} ({{ item.username }})" \
  -a "{{ item.username }}" \
  -k "${KEYCHAIN_PASSWORD}" \
  "${KEYCHAIN}" \
  >/dev/null
{% endif %}
{% if has_notarytool %}

echo "Importing notarytool credentials for {{ item.username }} ..."
xcrun notarytool store-credentials "{{ notarytool_profile }} ({{ item.username }})" \
  --apple-id "{{ item.username }}" \
  --password "{{ item.password | trim }}"  \
  --team-id "{{ item.team_id }}" \
  --keychain "${KEYCHAIN}"
{% endif %}
{% endfor %}
{% if fetch_files %}

echo "Dumping keychain ..."
security dump-keychain -a "${KEYCHAIN}" >"{{ per_user_keychain_dump }}"
{% endif %}

echo "Locking keychain ..."
security lock-keychain "${KEYCHAIN}"

# Signal to Ansible that we succeeded.
touch "{{ per_user_keychain_sentinel }}"
