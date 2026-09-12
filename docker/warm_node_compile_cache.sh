#!/bin/bash -Eeu

# Run as sandbox when the image is built, never as root.
#
# The base image warms the compiler into NODE_COMPILE_CACHE; this warms what
# this image adds, which is jest and the TypeScript transform it runs tests
# through. Node keeps one entry per file, so both end up in the same directory.
#
# Node partitions that directory by user id. A cache warmed as root is one the
# sandbox user cannot read, so a kata would recompile everything and then write
# a second full copy, which measured slower than having no cache at all. That
# is why this runs as sandbox, and why the first check below exists.

readonly WARM=/tmp/warm-jest
mkdir -p "${WARM}"
cd "${WARM}"

cat > hiker.ts <<'EOF'
export function answer(): number {
  return 6 * 7;
}
EOF

cat > hiker.test.ts <<'EOF'
import { answer } from './hiker';

describe('answer', () => {
  it('to life the universe and everything', () => {
    expect(answer()).toEqual(42);
  });
});
EOF

# The same shape as the kata's, so the modules loaded here are the modules a
# kata loads.
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "strict": true,
    "skipLibCheck": true,
    "target": "es2022",
    "lib": ["es2022"],
    "types": ["jest", "node"]
  }
}
EOF

cat > jest.config.js <<'EOF'
module.exports = {
  transform: { "^.+\\.tsx?$": ["ts-jest", { isolatedModules: true }] },
  testEnvironment: "node",
  testRegex: ".*test\\.(t|j)sx?$",
  moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json", "node"]
};
EOF

ln -s /etc/ts/node_modules "${WARM}/node_modules"

milliseconds()
{
  local -r start="$(date +%s%N)"
  "$@" > /dev/null 2>&1
  local -r finish="$(date +%s%N)"
  echo "$(( (finish - start) / 1000000 ))"
}

readonly COLD="$(milliseconds node_modules/.bin/jest --runInBand)"
readonly WARMED="$(milliseconds node_modules/.bin/jest --runInBand)"

echo "jest cold ${COLD}ms, warmed ${WARMED}ms"
ls "${NODE_COMPILE_CACHE}"

# Named for the uid that wrote it. Anything else means this ran as the wrong
# user and a kata will not read a byte of what was just written.
if [ -z "$(ls "${NODE_COMPILE_CACHE}" | grep -- "-$(id -u)\$")" ]; then
  echo "compile cache was not written by uid $(id -u)"
  exit 42
fi

# A cache that is not read is a cache that costs image size and gives nothing
# back. The second run has to beat the first.
if [ "${WARMED}" -ge "${COLD}" ]; then
  echo "warmed run (${WARMED}ms) did not beat the cold one (${COLD}ms)"
  exit 42
fi
