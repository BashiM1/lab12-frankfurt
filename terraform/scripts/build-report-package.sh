#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/report-generator"
SOURCE_DIR="$ROOT_DIR/src/report-generator"
OUTPUT_ZIP="$ROOT_DIR/report-generator-with-dependencies.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

python3 -m pip install \
  --requirement "$SOURCE_DIR/requirements.txt" \
  --target "$BUILD_DIR" \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all:

cp "$SOURCE_DIR/lambda_function.py" "$BUILD_DIR/lambda_function.py"

(
  cd "$BUILD_DIR"
  zip -qr "$OUTPUT_ZIP" .
)

python3 - "$OUTPUT_ZIP" <<'PY'
import sys
import zipfile

path = sys.argv[1]
with zipfile.ZipFile(path) as archive:
    names = set(archive.namelist())
    if "lambda_function.py" not in names:
        raise SystemExit("lambda_function.py is missing from ZIP root")
    if not any(name.startswith("reportlab/") for name in names):
        raise SystemExit("reportlab package is missing from ZIP")
print(path)
PY
