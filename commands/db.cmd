#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

if (( ${#WARDEN_PARAMS[@]} == 0 )); then
    echo -e "\033[33mThis command has required params, please use --help for details."
    exit 1
fi

## load connection information for the mysql service
eval "$(grep "^MYSQL_" "${WARDEN_ENV_PATH}/.env")"
if [[ -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.base.yml" ]]; then
  eval "$(grep -E '^\W+- MYSQL_.*=\$\{.*\}' "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.base.yml" | sed -E 's/.*- //g')"
else
  eval "$(grep -E '^\W+- MYSQL_.*=\$\{.*\}' "${WARDEN_DIR}/custom_environments/${WARDEN_ENV_TYPE}.yml" | sed -E 's/.*- //g')"
fi

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.yml" ]]; then
    eval "$(grep -E '^\W+- MYSQL_.*=\$\{.*\}' "${WARDEN_ENV_PATH}/.warden/warden-env.yml" | sed -E 's/.*- //g')"
fi

if [[ -f "${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml" ]]; then
    eval "$(grep -E '^\W+- MYSQL_.*=\$\{.*\}' "${WARDEN_ENV_PATH}/.warden/warden-env.${WARDEN_ENV_SUBT}.yml" | sed -E 's/.*- //g')"
fi

## sub-command execution
case "${WARDEN_PARAMS[0]}" in
    connect)
        "${WARDEN_DIR}/bin/warden" env exec db \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" "$@"
        ;;
    import)
        LC_ALL=C sed -E 's/DEFINER[ ]*=[ ]*`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' \
            | "${WARDEN_DIR}/bin/warden" env exec -T db \
            mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}"
        ;;
    *)
        echo -e "\033[33mThe command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        exit 1
        ;;
esac
