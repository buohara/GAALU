set -euo pipefail

NUM_RANDOM=1000
SEED=1
EVEN=0

usage() {
  echo "Usage: $0 [-n NUM_RANDOM] [--seed SEED] [-even]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n) NUM_RANDOM="$2"; shift 2 ;;
    --seed) SEED="$2"; shift 2 ;;
    -even) EVEN=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/../.."
GEN_PY="$SCRIPT_DIR/gen_test_vecs.py"
OUT_DIR="$REPO_ROOT/tests/vectors"

if [[ ! -f "$GEN_PY" ]]; then
  echo "Missing generator: $GEN_PY" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "Generating test vectors:"
echo "  NUM_RANDOM = $NUM_RANDOM"
echo "  SEED       = $SEED"
echo "  EVEN       = $EVEN"
echo "  OUT_DIR    = $OUT_DIR"

CMD=(python3 "$GEN_PY" -n "$NUM_RANDOM" -o "$OUT_DIR" --seed "$SEED")
if [[ $EVEN -eq 1 ]]; then
  CMD+=(-even)
fi

"${CMD[@]}"

echo "Done."