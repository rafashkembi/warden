#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

function locateEnvPath () {
    local WARDEN_ENV_PATH="$(pwd)"
    while [[ "${WARDEN_ENV_PATH}" != "/" ]]; do
        if [[ -f "${WARDEN_ENV_PATH}/.env" ]] \
            && grep "^WARDEN_ENV_NAME" "${WARDEN_ENV_PATH}/.env" >/dev/null \
            && grep "^WARDEN_ENV_TYPE" "${WARDEN_ENV_PATH}/.env" >/dev/null
        then
            break
        fi
        WARDEN_ENV_PATH="$(dirname "${WARDEN_ENV_PATH}")"
    done

    if [[ "${WARDEN_ENV_PATH}" = "/" ]]; then
        >&2 echo -e "\033[31mEnvironment config could not be found. Please run \"warden env-init\" and try again!\033[0m"
        return 1
    fi

    ## Resolve .env symlink should it exist in project sub-directory allowing sub-stacks to use relative link to parent
    WARDEN_ENV_PATH="$(
        cd "$(
            dirname "$(
                (readlink "${WARDEN_ENV_PATH}/.env" || echo "${WARDEN_ENV_PATH}/.env")
            )"
        )" >/dev/null \
        && pwd
    )"

    echo "${WARDEN_ENV_PATH}"
}

function loadEnvConfig () {
    local WARDEN_ENV_PATH="${1}"
    eval "$(grep "^WARDEN_" "${WARDEN_ENV_PATH}/.env")"

    WARDEN_ENV_NAME="${WARDEN_ENV_NAME:-}"
    WARDEN_ENV_TYPE="${WARDEN_ENV_TYPE:-}"

    WARDEN_ENV_SUBT="${OSTYPE:-undefined}"
    if [[ ${WARDEN_ENV_SUBT} =~ ^darwin ]]; then
        WARDEN_ENV_SUBT=darwin
    fi

    if [[ ! -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.base.yml" ]] && [[ ! -f "${WARDEN_DIR}/custom_environments/${WARDEN_ENV_TYPE}.yml" ]]; then
        >&2 echo -e "\033[31mInvalid environment type \"${WARDEN_ENV_TYPE}\" specified.\033[0m"
        return 1
    fi
}
