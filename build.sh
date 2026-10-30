#!/usr/bin/env bash
set -euo pipefail

# Thin OGC/DPS build for VEDA Black Marble (in-repo).
# Installs uv + maap-py, then `uv sync`s this repository.

basedir=$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)
export PATH="${HOME}/.local/bin:${PATH}"

echo "Ensuring uv is available"
if ! command -v uv >/dev/null 2>&1; then
  # maap_base may not have curl; prefer pip/python installers
  if command -v pip >/dev/null 2>&1; then
    pip install --quiet --no-cache-dir uv
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install --quiet --no-cache-dir uv
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --quiet --no-cache-dir uv
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://astral.sh/uv/install.sh | sh
  elif command -v curl >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    echo "ERROR: cannot install uv (need pip, wget, or curl)" >&2
    exit 1
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
fi
command -v uv >/dev/null 2>&1 || {
  echo "ERROR: uv not found after install" >&2
  exit 1
}
echo "uv=$(command -v uv)"

echo "Ensuring maap-py is available (MAAP Secrets)"
if command -v pip >/dev/null 2>&1; then
  pip install --quiet --no-cache-dir 'maap-py'
elif command -v pip3 >/dev/null 2>&1; then
  pip3 install --quiet --no-cache-dir 'maap-py'
else
  python3 -m pip install --quiet --no-cache-dir 'maap-py'
fi

echo "Syncing dependencies with uv"
(
  cd "${basedir}"
  uv sync --no-dev
  uv run blackmarble --help >/dev/null
)

chmod +x "${basedir}/run.sh" "${basedir}/build.sh" "${basedir}/resolve_earthdata_token.py"
echo "Build complete → ${basedir}"
