"""Measure what Parquet actually does to Albert's Marketplace data.

Answers two questions for the lecture:
  1. what do row-group statistics look like, concretely?
  2. how much smaller is Parquet than CSV, for numeric and for text-heavy data?
"""

import pathlib

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

HERE = pathlib.Path(__file__).parent
CSV = HERE / "legacy_csv"
OUT = HERE / "pq"
OUT.mkdir(exist_ok=True)


def roundtrip(name, df, compression):
    csv_path = OUT / f"{name}.csv"
    pq_path = OUT / f"{name}.{compression}.parquet"
    df.to_csv(csv_path, index=False)
    pq.write_table(pa.Table.from_pandas(df, preserve_index=False), pq_path,
                   compression=compression)
    return csv_path.stat().st_size, pq_path.stat().st_size


print("=" * 72)
print("1. COMPRESSION: same rows, CSV versus Parquet")
print("=" * 72)

items = pd.read_csv(CSV / "order_items.csv")
orders = pd.read_csv(CSV / "orders.csv")[["order_id", "order_date"]]
orders["order_date"] = pd.to_datetime(orders["order_date"])
items = items.merge(orders, on="order_id")

review = pd.read_csv(CSV / "review.csv")
text_col = [c for c in review.columns if "text" in c.lower() or "body" in c.lower()]
print(f"review columns: {list(review.columns)}")

for label, df in [("order_items (numeric)", items), ("review (text-heavy)", review)]:
    for comp in ("snappy", "zstd"):
        c, p = roundtrip(label.split()[0] + "." + comp, df, comp)
        print(f"{label:24s} {comp:7s}  CSV {c:>12,}  Parquet {p:>12,}  "
              f"{c / p:5.1f}x smaller")

print()
print("=" * 72)
print("2. ROW-GROUP STATISTICS: what is actually in the footer")
print("=" * 72)

# one month, as the lesson uses it, written with small row groups so there is
# more than one to show
month = items[(items.order_date >= "2026-08-01") & (items.order_date <= "2026-08-31")]
sample = OUT / "one-month.parquet"
pq.write_table(
    pa.Table.from_pandas(
        month[["order_id", "p_id", "qty", "price_at_purchase"]], preserve_index=False),
    sample, compression="snappy", row_group_size=2500)

md = pq.ParquetFile(sample).metadata
print(f"file           : {sample.name}")
print(f"rows           : {md.num_rows:,}")
print(f"row groups     : {md.num_row_groups}")
print(f"file size      : {sample.stat().st_size:,} bytes")
print(f"created by     : {md.created_by}")
print()

for g in range(md.num_row_groups):
    rg = md.row_group(g)
    print(f"--- row group {g}: {rg.num_rows:,} rows, "
          f"{rg.total_byte_size:,} bytes ---")
    for c in range(rg.num_columns):
        col = rg.column(c)
        st = col.statistics
        if st is None:
            continue
        print(f"  {col.path_in_schema:20s} min={str(st.min)[:22]:24s} "
              f"max={str(st.max)[:22]:24s} nulls={st.null_count}")
    print()
