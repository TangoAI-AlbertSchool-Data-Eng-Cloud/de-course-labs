"""Sanity-check that the generated bill actually has the five shapes in it.

    python make_bill.py > bill.ndjson
    python check_shapes.py

Prints a day-by-day series per SKU so you can see the spike, the slope, the
step and the flat line before trusting the file.
"""

import collections
import json

rows = [json.loads(line) for line in open("bill.ndjson", encoding="utf-8")]


ALL_DAYS = sorted({r["usage_start_time"][:10] for r in rows})


def series(match):
    """Cost per day, ZERO-FILLED.

    The export omits rows for days with no usage, so a plain group-by returns a
    shorter list and every index after the gap means the wrong day. Zero-filling
    against every day in the bill is what makes "day 30" mean day 30.
    """
    by_day = collections.defaultdict(float)
    for r in rows:
        if match in r["sku"]["description"]:
            by_day[r["usage_start_time"][:10]] += r["cost"]
    return [round(by_day.get(day, 0.0), 1) for day in ALL_DAYS]


print("rows:", len(rows), "total: EUR", round(sum(r["cost"] for r in rows), 2))
print()

for name, key, shape in [
    ("analysis", "Analysis", "expect a SPIKE around day 41"),
    ("storage", "Standard Storage", "expect a SLOPE, always rising"),
    ("class A ops", "Class A", "expect a high PLATEAU"),
    ("vm", "N2 Instance", "expect FLAT"),
    ("egress", "Download", "expect ZERO then a STEP at day 30"),
]:
    s = series(key)
    print(f"{name:12} {shape}")
    print(f"             days 0-4   {s[:5]}")
    print(f"             days 28-32 {s[28:33]}")
    print(f"             days 39-43 {s[39:44]}")
    print(f"             last 3     {s[-3:]}")
    print()

unlabelled = sum(r["cost"] for r in rows if not r["labels"])
total = sum(r["cost"] for r in rows)
print(f"unlabelled: EUR {unlabelled:.2f} ({100 * unlabelled / total:.0f}% of the bill)")
