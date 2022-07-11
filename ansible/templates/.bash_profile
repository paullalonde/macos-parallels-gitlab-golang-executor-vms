
# golang
export PATH="${PATH}:${HOME}/go/bin"

export APPLE_APPLICATION_CERTIFICATE_HASH={{ keychain_certificates[0].hash | quote }}
export APPLE_INSTALLER_CERTIFICATE_HASH={{ keychain_certificates[1].hash | quote }}

# For some reason, codesign fails if the keychain holding the Apple certificates is locked.
security unlock-keychain -p {{ keychain_password | trim }} executor
