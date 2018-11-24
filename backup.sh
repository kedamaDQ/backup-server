#
# collect backup files from remote hosts.
#
# this script SHOULD run as root because there are some unwritable files even if
# owner. eg, because permission of files under the /etc/ca-certificates are 444,
# non-root users cannot overwrite or remove such backuped files even if owner.
# root privilege is neccessary to remove such files.
#
BACKUP_BASE=$(cd $(dirname $0); pwd)

source "${BACKUP_BASE}/.env"
source "${BACKUP_BASE}/utils.sh"

LIST_DIR="${BACKUP_BASE}/backup.d"
LIST_EXT='.list'

# check arguments
HOST=${1:?"usage: ${0} <host> [<port>]"}
PORT=${2:-22}

# check list file
LIST="${LIST_DIR}/${HOST}${LIST_EXT}"

if [[ ! -f "${LIST}" || ! -r "${LIST}" ]]; then
  error "file not found or not readable: ${LIST}"
  exit 2
fi


# check rsync
if [[ -z "${RSYNC_CMD}" ]]; then
  RSYNC_CMD=$(which rsync)
fi

if [[ -z "${RSYNC_CMD}" || ! -f "${RSYNC_CMD}" || ! -x "${RSYNC_CMD}" ]]; then
  error "rsync command not available"
  exit 3
fi

# check mkdir
if [[ -z "${MKDIR_CMD}" ]]; then
  MKDIR_CMD=$(which mkdir)
fi

if [[ -z "${MKDIR_CMD}" || ! -f "${MKDIR_CMD}" || ! -x "${MKDIR_CMD}" ]]; then
  error "mkdir command not available"
  exit 3
fi

# log setting
if [[ -z "${LOG_DIR}" ]]; then
  LOG='/dev/null'
else
  if [[ ! -d "${LOG_DIR}" || ! -w "${LOG_DIR}" ]]; then
    error "cannot access log directory: ${LOG_DIR}"
    exit 4
  fi
  LOG="$(stripslash ${LOG_DIR})/${HOST}.$(date +%Y-%m-%d-%H.%M.%S).log"
fi

# start
info "start backup ${HOST}."
info "rsync log: ${LOG}"

RETURN=0

while read DIR OPTS; do
  RESULT=0

  # skip blank or comment
  if [[ "${DIR}" =~ ^\s*$ || "${DIR}" =~ ^\s*\# ]]; then
    continue
  fi

  if [[ "${DIR}" =~ ^[^/] ]]; then
    error "target path should be absolute path: ${DIR}"
    error "skip: ${DIR}"
    RETURN=$(( ${RETURN} + 1 ))
    continue
  fi

  if [[ "${DIR}" =~ [^/]$ ]]; then
    warn "target path shuld be ends with '/': ${DIR}"
    RESULT=$(( ${RESULT} + 1 ))
    DIR="${DIR}/"
  fi

  SRC="${HOST}:${DIR}"
  DST="${DST_DIR}/${HOST}${DIR}"

  # create directory
  ${MKDIR_CMD} -p ${DST}
  if [[ ${?} -ne 0 ]]; then
    error "cannot create destination directory: ${DST}"
    RETURN=$(( ${RETURN} + 1 ))
    continue
  fi

  # do rsync
  info "start rsync from '${SRC}' to '${DST}'"

  ${RSYNC_CMD} ${RSYNC_COMOPTS} ${OPTS} \
    --rsh "ssh -l ${SSH_USER} -i ${SSH_PRIVKEY} -p ${PORT} -o strictHostKeyChecking=no" \
    --rsync-path='sudo rsync' \
    ${SRC} ${DST} >> ${LOG} 2>&1

  # check return
  if [[ ${?} -ne 0 ]]; then
    warn "rsync returns code that is none zero: ${!}"
    RESULT=$(( ${RESULT} + 2 ))
  fi

  # output result of backup every target directory
  if [[ ${RESULT} -eq 0 ]]; then
    info "succeeded to backup from ${SRC} to ${DST}"
  else
    warn "some warnings occurred to backup from ${SRC} to ${DST}: ${RESULT}"
  fi
done < ${LIST}

if [[ ${RETURN} -eq 0 ]]; then
  info "succeeded to backup ${HOST}"
else
  error "some errors occurred to backup ${HOST}"
fi

exit ${RETURN}
