#!/bin/bash

set -eu

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

echo "Importing certificate {{ cert.filename }} ..."
security import ~/certs/"{{ cert.filename }}" \
  -f pkcs12 -x \
  -k "${KEYCHAIN}" \
{% for path in xcrun_tool_paths %}
  -T "{{ path | trim }}" \
{% endfor %}
  -P "{{ cert.password | trim }}" \
  >/dev/null
{% endfor %}

echo "Allowing Apple tools to access signing keys ..."
security set-key-partition-list \
  -S "apple-tool:,apple:,codesign:" \
  -s \
  -k "${KEYCHAIN_PASSWORD}" \
  "${KEYCHAIN}" \
  >/dev/null
{% for item in apple_developer_program_credentials %}

{# WARNING: altool has a tendency to FAIL SILENTLY #}
echo "Importing altool credentials for {{ item.username }} ..."
xcrun altool --store-password-in-keychain-item "{{ altool_keychain_item }} ({{ item.username }})" \
{% if altool_supports_keychain_option %}
  --keychain "${KEYCHAIN}" \
{% endif %}
  -u "{{ item.username }}" \
  -p "{{ item.password | trim }}"
{% if has_notarytool %}

echo "Importing notarytool credentials for {{ item.username }} ..."
xcrun notarytool store-credentials "{{ notarytool_profile }} ({{ item.username }})" \
  --apple-id "{{ item.username }}" \
  --password "{{ item.password | trim }}"  \
  --team-id "{{ item.team_id }}" \
  --keychain "${KEYCHAIN}"
{% endif %}
{% endfor %}

echo "Locking keychain ..."
security lock-keychain "${KEYCHAIN}"

# Signal to Ansible that we succeeded.
touch "{{ per_user_keychain_sentinel }}"
