#!/bin/bash -e

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# Preinstall pip, setuptools and wheel.
pip_whl=$(rlocation io_pypa_pip_whl/file/pip-20.2.3-py2.py3-none-any.whl)
setuptools_whl=$(rlocation io_pypa_setuptools_whl/file/setuptools-50.3.2-py3-none-any.whl)
wheel_whl=$(rlocation io_pypa_wheel_whl/file/wheel-0.33.6-py2.py3-none-any.whl)

tmpdir="$(mktemp -d)"
trap "rm -rf $tmpdir" EXIT
env - \
  PYTHONPATH="$pip_whl" \
  PYTHONNOUSERSITE="1" \
"$(rlocation __main__/rules/pip/python_runtime)" \
  -m pip install -q --no-deps --no-index --no-cache-dir --target "$tmpdir" \
  "$pip_whl" "$setuptools_whl" "$wheel_whl"

for var in $(export -p | grep -Po "(?<=declare -x )([^=]*)(?==)"); do
    if [[ "${!var}" =~ \$ROOT/ ]]; then
        declare $var="$(echo ${!var} | sed 's#\$ROOT/#'$(pwd)/'#g')"
    fi
done

env \
  PYTHONPATH="$tmpdir${PYTHONPATH:+:}${PYTHONPATH-}" \
"$(rlocation __main__/rules/pip/python_runtime)" -m pip "$@"
