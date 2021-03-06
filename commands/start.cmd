#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

## ensure warden install has been run
assert_installed

pushd "${WARDEN_DIR}" >/dev/null
docker-compose -p warden -f docker/docker-compose.yml start "${WARDEN_PARAMS[@]}" "$@"
