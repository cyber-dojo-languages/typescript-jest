#!/bin/bash -Eeu

# Added beside the compiler the base image put in /etc/ts, rather than into a
# prefix of their own, because a start-point symlinks that one directory in as
# its node_modules and node finds a package only by looking there.
#
# typescript is deliberately absent: it comes from the base image. Naming it
# here would let this image drift to a different compiler from its siblings,
# which is the thing having a base image is for.
#
# Two of these carry a version. They are the versions this image has always
# installed, kept rather than floated because nothing here has established that
# a newer major still works with the rest.
npm install --prefix /etc/ts \
  jest \
  ts-jest \
  @types/jest \
  ts-lib \
  strip-ansi-cli \
  eslint \
  prettier \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser \
  'eslint-config-prettier@^6.10.1' \
  'eslint-plugin-prettier@^3.1.2'

# The base image set this for what it installed; these packages are new, and a
# kata runs as sandbox.
chown -R sandbox /etc/ts
