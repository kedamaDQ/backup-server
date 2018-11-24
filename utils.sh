# logging utils
function log {
  echo "$(date +%Y-%m-%d-%H.%M.%S) ${1}"
}

function info {
  log "[II] ${1}"
}

function warn {
  log "[WW] ${1}" >&2
}

function error {
  log "[EE] ${1}" >&2
}

function stripslash {
  t=${1}
  if [[ ${t} =~ ^(.+)/$ ]]; then
    t=${BASH_REMATCH[1]}
  fi
  echo ${t}
}
