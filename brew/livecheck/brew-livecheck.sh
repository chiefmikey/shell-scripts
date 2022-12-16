#!/bin/sh

echo "+ brew livecheck"
cd ${HOME}

FLAG_LIST="balskdt"
while getopts 'balskdt:' OPTION; do
  case ${OPTION} in
    b)
      LC_BUMP="-b"
      FLAG_REDUCER="${FLAG_REDUCER} -b "
      ;;
    a)
      LC_ALL="y"
      FLAG_REDUCER="${FLAG_REDUCER} -a "
      ;;
    l)
      LC_LOCAL="y"
      ;;
    s)
      LC_STATUS="y"
      ;;
    k)
      LC_KILL="y"
      ;;
    d)
      LC_SCREEN="screen -S livecheck -dm"
      echo + "Detached: livecheck"
      ;;
    t)
      LC_DELAY="-t ${OPTARG}"
      ;;
    *)
      BAD_FLAGS=
      for flag in ${@}; do
        [ -n "${FLAG_LIST##*${flag##*-}*}" ] && BAD_FLAGS="${BAD_FLAGS} ${flag}"
      done
      echo "Invalid flags:${BAD_FLAGS}"
      exit 1
      ;;
  esac
done
shift "$((OPTIND-1))"

flag_limit_zero () {
  local COUNT=0
  local INVALID_FLAGS=
  for flag in ${@}; do
    local COUNT=$((COUNT + 1))
    INVALID_FLAGS="${INVALID_FLAGS} ${flag} "
  done
  [ ${COUNT} -gt 0 ] && echo "Invalid flags:${INVALID_FLAGS}" && exit 1
}

flag_limit_one () {
  local COUNT=0
  for flag in ${@}; do
    local COUNT=$((COUNT + 1))
  done
  [ ${COUNT} -gt 1 ] && echo "Invalid flags:${INVALID_FLAGS}" && exit 1
}

[ "${LC_KILL}" = "y" ] && flag_limit_zero ${LC_BUMP} ${LC_DELAY}
[ "${LC_STATUS}" = "y" ] && flag_limit_zero ${LC_BUMP} ${LC_DELAY}
flag_limit_one ${LC_ALL} ${LC_LOCAL} ${LC_STATUS} ${LC_KILL}

[ "${LC_KILL}" != "y" ] && [ "${LC_STATUS}" != "y" ] && LC_RUNNING=$(screen -ls | grep livecheck | awk '{print $1}')

brew_livecheck () {
  [ "${LC_ALL}" = "y" ] && ${LC_SCREEN} ${SCRIPT_DIR}/brew-livecheck/brew-livecheck-all.sh ${LC_BUMP} ${LC_DELAY}
  [ "${LC_LOCAL}" = "y" ] && ${LC_SCREEN} ${SCRIPT_DIR}/brew-livecheck/brew-livecheck-local.sh ${LC_BUMP} ${LC_DELAY}
  [ "${LC_STATUS}" = "y" ] && ${SCRIPT_DIR}/brew-livecheck/brew-livecheck-status.sh
  [ "${LC_KILL}" = "y" ] && ${SCRIPT_DIR}/brew-livecheck/brew-livecheck-kill.sh
}

if [ -n "${LC_RUNNING}" ]; then
  echo "Livecheck is already running"
  echo "Kill livecheck: (y/n)"
  read LC_REPLACE
  if [ "${LC_REPLACE}" = "y" ] || [ "${LC_REPLACE}" = "yes" ]; then
    ${SCRIPT_DIR}/brew-livecheck/brew-livecheck-kill.sh
    brew_livecheck
  fi
  if [ "${LC_REPLACE}" = "n" ] || [ "${LC_REPLACE}" = "no" ]; then
    exit 1
  fi
else
  brew_livecheck
fi