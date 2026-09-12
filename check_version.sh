#!/usr/bin/env bash
set -Eeu

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat ${MY_DIR}/docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# Confirms the version of one tool inside the image. docker/install.sh asks npm
# for most of them without naming a version, so a rebuild picking up a new
# release stops here and names it, rather than changing what the image offers
# without saying so.
check_version()
{
  local -r name="${1}"
  local -r expected="${2}"
  local -r version_command="${3}"
  local -r actual=$(docker run --rm -i ${IMAGE_NAME} sh -c "${version_command}")

  if echo "${actual}" | grep -q "${expected}"; then
    echo "${name} VERSION CONFIRMED as ${expected}"
  else
    echo "${name} VERSION EXPECTED: ${expected}"
    echo "${name} VERSION   ACTUAL: ${actual}"
    exit 42
  fi
}

# The compiler is checked as well as the test framework, even though it comes
# from the base image. ts-jest declares a peer range on it, so the pairing is
# what has to hold here: a base image that moved to a compiler ts-jest refuses
# would break this image and nothing else would say so.
check_version jest       30.5      '/etc/ts/node_modules/.bin/jest --version'
check_version typescript 'Version 6.0' '/etc/ts/node_modules/.bin/tsc --version'
