#!/bin/bash
set -e

# -------------------------
# config
# -------------------------
EXTENSIONS=(sh py)
MODE="${1:-}"   # apply | dry-run | empty -> show usage

# -------------------------
# build find expression
# -------------------------
FIND_EXPR=()
for ext in "${EXTENSIONS[@]}"; do
    FIND_EXPR+=(-name "*.$ext" -o)
done
unset 'FIND_EXPR[${#FIND_EXPR[@]}-1]'

# -------------------------
# find targets
# -------------------------
mapfile -t FILES < <(find . -type f \( "${FIND_EXPR[@]}" \))

if [ "${#FILES[@]}" -eq 0 ]; then
    echo "✅ No target files found."
    exit 0
fi

case "$MODE" in

  dry-run)
    echo "==== DRY RUN MODE ===="
    echo "The following files will be chmod +x:"
    printf '  %s\n' "${FILES[@]}"
    echo "==== END ====="
    ;;

  apply)
    echo "==== APPLY MODE ===="
    for f in "${FILES[@]}"; do
        chmod +x "$f"
        echo "chmod +x: $f"
    done
    echo "✅ Done."
    ;;

  *)
    cat <<EOF
Usage:
  $(basename "$0") [apply | dry-run]

Examples:
  $(basename "$0") dry-run     # Show what will change
  $(basename "$0") apply       # Actually chmod

EOF
    exit 1
    ;;

esac
