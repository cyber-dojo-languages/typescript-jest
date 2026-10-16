#!/bin/bash -Eeu

# Appends one test framework to the test_frameworks list the base image
# wrote in /versions.json, keeping any entry an earlier image added. Stops
# the build if the list is not found, rather than record nothing.
add_test_framework()
{
  local -r name="${1}"
  local -r version="${2}"
  local -r entry="{\"name\": \"${name}\", \"version\": \"${version}\"}"
  if grep -q '"test_frameworks": \[\]' /versions.json; then
    sed -i "s|\"test_frameworks\": \[\]|\"test_frameworks\": [${entry}]|" /versions.json
  else
    sed -i "/\"test_frameworks\": \[/s|}\]|}, ${entry}]|" /versions.json
  fi
  if ! grep -q -F "${entry}" /versions.json; then
    echo "Could not add ${name} to /versions.json" >&2
    cat /versions.json >&2
    exit 1
  fi
}

# Added beside the compiler the base image put in /etc/ts, rather than into a
# prefix of their own, because a start-point symlinks that one directory in as
# its node_modules and node finds a package only by looking there.
#
# typescript is deliberately absent: it comes from the base image. Naming it
# here would let this image drift to a different compiler from its siblings,
# which is the thing having a base image is for. None carries a version, so a
# rebuild installs the newest of each.
#
# The base image sets NODE_COMPILE_CACHE, and npm runs here as root. Node names
# the cache directory after the uid that wrote it, so anything root puts there
# is a directory no kata can ever read: image size paid for nothing. Unsetting
# it for this one command keeps that weight out, and the warming step that
# follows, which runs as sandbox, writes the cache a kata does read.
env --unset=NODE_COMPILE_CACHE npm install --prefix /etc/ts \
  jest \
  ts-jest \
  @types/jest \
  ts-lib \
  strip-ansi-cli \
  eslint \
  prettier \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser \
  eslint-config-prettier \
  eslint-plugin-prettier

# The base image set this for what it installed; these packages are new, and a
# kata runs as sandbox.
chown -R sandbox /etc/ts

# Read from the installed package, so the record is the jest a kata runs.
add_test_framework Jest "$(node -p "require('/etc/ts/node_modules/jest/package.json').version")"
cat /versions.json
