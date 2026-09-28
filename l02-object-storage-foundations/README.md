# Lesson 2 · Object storage foundations

The scripts that produced the numbers quoted in the lecture. They are here so
you can re-run a measurement rather than take a figure on trust.

| File | What it measures |
|---|---|
| `build_layouts.py` | the same data written under several key layouts |
| `parquet_facts.py` | what Parquet actually stores, and what it costs |
| `egress_sim.py` | what leaving a region costs |
| `measure_bq.sh` | the BigQuery side of the same question |

Run them against your own project and bucket. **Numbers move** — cloud prices
and your own data both change — so if yours differ from the lecture's, that is
a finding rather than a fault. The lesson page names the date each figure was
measured.
