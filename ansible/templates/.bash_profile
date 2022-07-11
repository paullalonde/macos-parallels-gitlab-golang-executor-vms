
# golang
export PATH="${PATH}:${HOME}/bin:${HOME}/go/bin"

export APPLE_APPLICATION_CERTIFICATE_HASH={{ keychain_certificates[0].hash | quote }}
export APPLE_INSTALLER_CERTIFICATE_HASH={{ keychain_certificates[1].hash | quote }}
