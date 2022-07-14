
# golang
export PATH="${PATH}:${HOME}/bin:${HOME}/go/bin"

export APPLE_DEVELOPER_ID_APPLICATION_CERTIFICATE_HASH={{ keychain_certificates[0].hash }}
export APPLE_DEVELOPER_ID_INSTALLER_CERTIFICATE_HASH={{ keychain_certificates[1].hash }}
export APPLE_DEVELOPER_PROGRAM_USER={{ apple_developer_program_credentials.user }}
