"""Build the two partition layouts for L02's over-partitioning experiment.

Layout A: bronze/order_items_by_day/dt=YYYY-MM-DD/part-0.parquet
Layout B: bronze/order_items_by_day_product/dt=YYYY-MM-DD/p_id=<sku>/part-0.parquet

Both hold exactly the same rows: one calendar month of order_items.
"""

import pathlib
import shutil
import sys

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

HERE = pathlib.Path(__file__).parent
CSV = HERE / "legacy_csv"
OUT = HERE / "out"

MONTH_START = pd.Timestamp("2026-08-01")
MONTH_END = pd.Timestamp("2026-08-31")

items = pd.read_csv(CSV / "order_items.csv")
orders = pd.read_csv(CSV / "orders.csv")
orders = orders[["order_id", "order_date"]]
orders["order_date"] = pd.to_datetime(orders["order_date"])

df = items.merge(orders, on="order_id", how="inner")
month = df[(df.order_date >= MONTH_START) & (df.order_date <= MONTH_END)].copy()
month["dt"] = month.order_date.dt.strftime("%Y-%m-%d")

print(f"order_items rows total        : {len(items):,}")
print(f"rows in {MONTH_START:%Y-%m}              : {len(month):,}")
print(f"distinct days                 : {month.dt.nunique()}")
print(f"distinct (day, product) pairs : {month.groupby(['dt', 'p_id']).ngroups:,}")
print(f"distinct products             : {month.p_id.nunique():,}")

cols = ["order_id", "p_id", "qty", "price_at_purchase"]
schema = pa.schema([
    ("order_id", pa.int64()),
    ("p_id", pa.string()),
    ("qty", pa.int64()),
    ("price_at_purchase", pa.float64()),
])


def write(table_dir, keys):
    """One parquet file per group, Hive-style, as a writer would lay it out."""
    root = OUT / table_dir
    if root.exists():
        shutil.rmtree(root)
    n = 0
    for key, group in month.groupby(keys, sort=True):
        key = (key,) if not isinstance(key, tuple) else key
        prefix = root.joinpath(*[f"{k}={v}" for k, v in zip(keys, key)])
        prefix.mkdir(parents=True, exist_ok=True)
        pq.write_table(
            pa.Table.from_pandas(group[cols], schema=schema, preserve_index=False),
            prefix / "part-0.parquet",
            compression="snappy",
        )
        n += 1
    files = list(root.rglob("*.parquet"))
    size = sum(f.stat().st_size for f in files)
    print(f"\n{table_dir}")
    print(f"  objects    : {len(files):,}")
    print(f"  total bytes: {size:,} ({size / 1024 / 1024:.2f} MiB)")
    print(f"  mean bytes : {size / len(files):,.0f}")
    return len(files), size


a = write("order_items_by_day", ["dt"])
b = write("order_items_by_day_product", ["dt", "p_id"])

print()
print(f"objects  B/A : {b[0] / a[0]:.0f}x")
print(f"bytes    B/A : {b[1] / a[1]:.2f}x")
