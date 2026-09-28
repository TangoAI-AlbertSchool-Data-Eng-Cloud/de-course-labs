#!/usr/bin/env bash
# Time the same question against both layouts, three runs each.
set -uo pipefail

export PATH="/c/Users/charl/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin:$PATH"
export CLOUDSDK_PYTHON="C:/Users/charl/miniconda3/python.exe"
P=education-tangoai

run() {
  local label="$1" sql="$2"
  local best=99999 t
  for i in 1 2 3; do
    local start end
    start=$(date +%s%N)
    bq --project_id=$P query --use_legacy_sql=false --format=none --nouse_cache "$sql" >/dev/null 2>&1
    end=$(date +%s%N)
    t=$(( (end - start) / 1000000 ))
    printf '    run %d: %5d ms\n' "$i" "$t"
    [ "$t" -lt "$best" ] && best=$t
  done
  printf '  %-46s best %5d ms\n' "$label" "$best"
}

echo "=== Q1: whole month, sum of units ==="
run "by_day (31 objects)" \
  "SELECT SUM(qty) FROM \`education-tangoai.l02_exp.by_day\`"
run "by_day_product (8,649 objects)" \
  "SELECT SUM(qty) FROM \`education-tangoai.l02_exp.by_day_product\`"

echo
echo "=== Q2: one week, partition filter on dt ==="
run "by_day (31 objects)" \
  "SELECT SUM(qty) FROM \`education-tangoai.l02_exp.by_day\` WHERE dt BETWEEN '2026-08-01' AND '2026-08-07'"
run "by_day_product (8,649 objects)" \
  "SELECT SUM(qty) FROM \`education-tangoai.l02_exp.by_day_product\` WHERE dt BETWEEN '2026-08-01' AND '2026-08-07'"
