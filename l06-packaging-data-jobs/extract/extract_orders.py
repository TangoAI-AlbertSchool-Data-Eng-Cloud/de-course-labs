"""Read one table from the company's PostgreSQL and write it as Parquet.

Everything that changes between runs arrives in the environment, which is what
makes the same image usable on a laptop, in a scheduler and in a back-fill.
"""
import os
import sys

import pandas as pd
import psycopg

DSN = os.environ["DATABASE_URL"]
TABLE = os.environ.get("TABLE", "orders")
OUT = os.environ.get("OUT", "/data")
CURSOR_COL = os.environ.get("CURSOR_COL", "order_date")
SINCE = os.environ.get("SINCE")

sql = f"SELECT * FROM {TABLE}"
params = None
if SINCE:
    sql += f" WHERE {CURSOR_COL} > %s"
    params = (SINCE,)

with psycopg.connect(DSN) as conn, conn.cursor() as cur:
    cur.execute(sql, params)
    rows = cur.fetchall()
    cols = [c.name for c in cur.description]

df = pd.DataFrame(rows, columns=cols)
os.makedirs(OUT, exist_ok=True)
path = os.path.join(OUT, f"{TABLE}.parquet")
df.to_parquet(path, index=False)

print(f"{len(df)} rows -> {path}", flush=True)


