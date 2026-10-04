#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.gemini/antigravity-cli"
SETTINGS_FILE="${TARGET_DIR}/settings.json"
TARGET_SCRIPT="${TARGET_DIR}/statusline.sh"

echo "=== Antigravity Statusline Installer ==="
echo "Target directory: ${TARGET_DIR}"

mkdir -p "${TARGET_DIR}"

# 1. Detect fastest python3 executable
echo "[1/4] Detecting Python runtime..."
PY_BIN=""
if [ -x "/opt/homebrew/bin/python3" ]; then
  PY_BIN="/opt/homebrew/bin/python3"
elif [ -x "/usr/local/bin/python3" ]; then
  PY_BIN="/usr/local/bin/python3"
elif [ -x "/usr/bin/python3" ]; then
  PY_BIN="/usr/bin/python3"
else
  PY_BIN="$(command -v python3 || true)"
fi

if [ -z "${PY_BIN}" ]; then
  echo "Error: python3 not found. Please install Python 3.8+."
  exit 1
fi
echo "Using Python runtime: ${PY_BIN}"

# 2. Install global engineering guide (GEMINI.md)
echo "[2/5] Installing global engineering guide (GEMINI.md)..."
mkdir -p "${HOME}/.gemini/config"
cp "${SCRIPT_DIR}/GEMINI.md" "${HOME}/.gemini/config/GEMINI.md"
cp "${SCRIPT_DIR}/GEMINI.md" "${HOME}/.gemini/config/AGENTS.md"
cp "${SCRIPT_DIR}/GEMINI.md" "${TARGET_DIR}/AGENTS.md"

# 3. Backup existing statusline.sh if present
echo "[3/5] Installing statusline script..."
if [ -f "${TARGET_SCRIPT}" ]; then
  cp "${TARGET_SCRIPT}" "${TARGET_SCRIPT}.bak"
  echo "Backed up existing script to ${TARGET_SCRIPT}.bak"
fi

# Copy script and adapt shebang
cp "${SCRIPT_DIR}/statusline.sh" "${TARGET_SCRIPT}"
sed -i '' "1s|^#!.*|#!${PY_BIN}|" "${TARGET_SCRIPT}" 2>/dev/null || sed -i "1s|^#!.*|#!${PY_BIN}|" "${TARGET_SCRIPT}"
chmod +x "${TARGET_SCRIPT}"

# 4. Configure settings.json
echo "[4/5] Updating ${SETTINGS_FILE}..."
"${PY_BIN}" - <<EOF
import json
import os

settings_path = "${SETTINGS_FILE}"
target_script = "${TARGET_SCRIPT}"

settings = {}
if os.path.isfile(settings_path):
    try:
        with open(settings_path, "r", encoding="utf-8") as f:
            settings = json.load(f)
    except Exception:
        settings = {}

if not isinstance(settings, dict):
    settings = {}

settings["statusLine"] = {
    "type": "command",
    "command": target_script,
    "enabled": True,
    "stack_with_default": True
}

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("Successfully configured statusLine in settings.json.")
EOF

# 5. Smoke test
echo "[5/5] Verifying statusline execution..."
TEST_PAYLOAD='{"cwd":"'${HOME}'","context_window":{"remaining_percentage":95,"total_input_tokens":50000,"size":1000000},"tasks":1}'
echo "${TEST_PAYLOAD}" | "${TARGET_SCRIPT}"

echo ""
echo "=== Installation Completed Successfully! ==="
echo "Statusline is active at: ${TARGET_SCRIPT}"
