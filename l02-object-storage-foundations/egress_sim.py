"""Cost of moving 500 TiB from a US bucket to a European one.

Prices read from https://cloud.google.com/storage/pricing on 2026-09-21.
  within Google Cloud, N. America -> Europe : $0.05 / GiB
  within Google Cloud, same location        : free
  out of Google Cloud (worldwide, tiered)   : $0.12 / $0.11 / $0.08 per GiB
  inbound                                   : free
  Standard storage, europe-west1            : $0.020 / GiB-month
  Class A (write) / Class B (read)          : $0.005 / $0.0004 per 1,000
"""

GIB = 1024
TIB = 1024 * GIB

DATA_TIB = 500
data_gib = DATA_TIB * GIB

print(f"Dataset: {DATA_TIB} TiB = {data_gib:,} GiB\n")

# 1. bucket to bucket, US -> EU
bucket_to_bucket = data_gib * 0.05
print(f"1. Bucket to bucket, N. America -> Europe")
print(f"   {data_gib:,} GiB x $0.05        = ${bucket_to_bucket:,.2f}")

# 2. the naive way: download, then re-upload (inbound is free)
tiers = [(10 * TIB // GIB, 0.12), (140 * TIB // GIB, 0.11), (None, 0.08)]
left, download = data_gib, 0.0
for size, price in tiers:
    take = left if size is None else min(left, size)
    download += take * price
    left -= take
    if left <= 0:
        break
print(f"\n2. Download to your own datacentre, then re-upload")
print(f"   tiered 0.12 / 0.11 / 0.08      = ${download:,.2f}")
print(f"   (re-upload is free: inbound costs nothing)")
print(f"   -> {download / bucket_to_bucket:.1f}x the cost of doing it inside the cloud")

# 3. operations, if the data sits in 128 MiB objects
objects = data_gib * GIB // 128
reads = objects * 0.0004 / 1000
writes = objects * 0.005 / 1000
print(f"\n3. Operations on {objects:,.0f} objects of 128 MiB")
print(f"   reads  ${reads:,.2f}   writes ${writes:,.2f}   "
      f"= {(reads + writes) / bucket_to_bucket * 100:.2f}% of the transfer")

# 4. what it costs to just keep it
monthly = data_gib * 0.020
print(f"\n4. Storing it in europe-west1 Standard")
print(f"   {data_gib:,} GiB x $0.020       = ${monthly:,.2f} per month")
print(f"   -> the one-off move costs {bucket_to_bucket / monthly:.1f} months of storage")

# 5. the slow bleed: a dashboard reading across the Atlantic
table_gib, reads_per_day = 50, 20
year = table_gib * reads_per_day * 365 * 0.05
print(f"\n5. The slow bleed: a {table_gib} GiB table read {reads_per_day}x a day")
print(f"   from the wrong continent       = ${year:,.2f} per year")
print(f"   same query, same region        = $0.00")
