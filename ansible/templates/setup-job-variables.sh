# This file is meant to be source'd, typically from the Gitlab runner's pre_build_script.

# Hashes of Apple certificates
{% for item in apple_certificates %}
export {{ item.job_variables.hash }}="{{ certificate_hashes[loop.index-1] }}"
{% endfor %}

# Keychain items
{% for item in apple_developer_program_credentials %}
export {{ item.job_variables.username }}="{{ item.username }}"
export {{ item.job_variables.team_id }}="{{ item.team_id }}"
export {{ item.job_variables.asc_provider }}="{{ item.asc_provider }}"
export {{ item.job_variables.altool.keychain_item }}="{{ adp_keychain_service_altool }}"
{% if has_notarytool %}
export {{ item.job_variables.notarytool.keychain_item }}="{{ adp_keychain_service_notarytool }}"
{% endif %}
{% endfor %}
