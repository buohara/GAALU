set -euo pipefail

DOT_KIND="${DOT_KIND:-hestenes}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
GEN_PY="$SCRIPT_DIR/svgen/generateGP.py"
OUT_DIR="$SCRIPT_DIR/svgen"

if [[ ! -f "$GEN_PY" ]]; then
  echo "Generator not found: $GEN_PY" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "[1/2] Generating FULL SV ops (dot-kind=$DOT_KIND)"
python3 "$GEN_PY" \
  -sv-mul   "$OUT_DIR/gp_full_mul.sv" \
  -sv-wedge "$OUT_DIR/gp_full_wedge.sv" \
  -sv-dot   "$OUT_DIR/gp_full_dot.sv" \
  -sv-norm  "$OUT_DIR/gp_full_norm.sv" \
  --dot-kind "$DOT_KIND"

echo "[2/2] Generating EVEN SV ops (dot-kind=$DOT_KIND)"
python3 "$GEN_PY" -even \
  -sv-mul   "$OUT_DIR/gp_even_mul.sv" \
  -sv-wedge "$OUT_DIR/gp_even_wedge.sv" \
  -sv-dot   "$OUT_DIR/gp_even_dot.sv" \
  -sv-norm  "$OUT_DIR/gp_even_norm.sv" \
  --dot-kind "$DOT_KIND"

echo "Done. Outputs in $OUT_DIR"