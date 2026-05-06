#!/bin/sh
# my_name < email@example.com >
#
# DESCRIPTION:
# USAGE:
# LICENSE: ___

set -eu

usage() {
    echo "Usage: $(basename "$0") [options]"
    exit 1
}

main() {
    echo "Hello"
}

main "$@"
