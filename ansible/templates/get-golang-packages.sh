#!/bin/bash

set -eu

export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/go/bin:/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/bin:${HOME}/go/bin"
export GOPATH="${HOME}/go"

go get github.com/onsi/ginkgo/ginkgo@v{{ ginkgo_version }}
go get github.com/onsi/gomega/...@v{{ gomega_version }}
go get github.com/jstemmer/go-junit-report@v{{ go_junit_report_version }}
