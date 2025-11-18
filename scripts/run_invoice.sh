#!/usr/bin/env bash
set -euo pipefail

INVOICE_ID=${1:-1}
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$PROJECT_ROOT/build"
SRC_FILE="$PROJECT_ROOT/src/invoice_generator.cob"
BINARY="$BUILD_DIR/invoice_generator"

mkdir -p "$BUILD_DIR"

if ! command -v cobc >/dev/null 2>&1; then
  echo "cobc (GNUCobol) is required but not found in PATH" >&2
  exit 1
fi

cobc -x -free -std=cobol85 -Wall -I"$PROJECT_ROOT" -o "$BINARY" "$SRC_FILE" -lecpg

echo "Built $BINARY"
PGDATABASE=${PGDATABASE:-cobol_invoice}
export PGDATABASE
PGUSER=${PGUSER:-cobol_dev}
export PGUSER
PGPASSWORD=${PGPASSWORD:-secret}
export PGPASSWORD
PGHOST=${PGHOST:-localhost}
export PGHOST
PGPORT=${PGPORT:-5432}
export PGPORT

"$BINARY" "$INVOICE_ID"
