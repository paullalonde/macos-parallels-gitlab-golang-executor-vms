# This file is meant to be source'd, typically from the Gitlab runner's pre_build_script.

# Hashes of Apple certificates
{% for item in apple_certificates %}
export {{ item.job_variables.hash }}="{{ certificate_hashes[loop.index-1] }}"
{% endfor %}

# Keychain items
{% for item in apple_developer_program_credentials %}
export {{ item.job_variables.generic.keychain_item }}="{{ adp_keychain_service }}"
export {{ item.job_variables.generic.username }}="{{ item.username }}"
export {{ item.job_variables.altool.keychain_item }}="{{ adp_keychain_service_altool }}"
export {{ item.job_variables.altool.username }}="{{ item.username }}"
{% if has_notarytool %}
export {{ item.job_variables.notarytool.keychain_item }}="{{ adp_keychain_service_notarytool }}"
export {{ item.job_variables.notarytool.username }}="{{ item.username }}"
{% endif %}
{% endfor %}
