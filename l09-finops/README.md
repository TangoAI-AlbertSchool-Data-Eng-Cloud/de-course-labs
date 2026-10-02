# Lesson 9 · FinOps

| File | What it is |
|---|---|
| `make_bill.py` | generates a realistic-shaped cloud bill in Google's billing-export schema |
| `check_shapes.py` | prints the day-by-day series per SKU, so you can see the shapes are really there |

## Why a generated bill

This course runs inside the free tier, so its real bill is almost entirely
zeros — and **you cannot learn to read a bill from one that says nothing**.

`make_bill.py` writes sixty days of spend for a fictional company, with the
same columns a real Google Cloud billing export has, and the same five ways
costs go wrong:

| Shape | How it appears |
|---|---|
| a runaway query | one day, one SKU, a spike |
| storage that grows | a slope, never a spike |
| small-file overhead | operations cost, not storage cost |
| something nobody turned off | flat, constant, forgotten |
| egress | nothing at all, then a step |

About **30% of the rows carry no labels**, which is the point of the review
exercise: that spend cannot be attributed to anybody, and never will be.

## Running it

```bash
python make_bill.py > bill.ndjson
python check_shapes.py          # confirm the shapes before trusting the file
```

Then load it into BigQuery if you want to query it the way you would a real
export:

```bash
bq --location=europe-west1 mk -f --dataset <your-project>:l09_demo
bq --location=europe-west1 load \
  --source_format=NEWLINE_DELIMITED_JSON --autodetect --replace \
  <your-project>:l09_demo.gcp_billing_export_v1_demo bill.ndjson
```

It is deterministic — the seed is fixed, so everybody gets the same bill and
the answers are comparable.

## What is invented and what is not

**The unit prices are real**, published for `europe-west1` and read on
2026-09-29, so the arithmetic is honest.

**The quantities are invented.** No part of this describes real usage by a real
company. Say so whenever you use it — a FinOps report that quietly mixes
measured and generated numbers is worse than one that omits them.

`billing_account_id` is `0X0X0X-0X0X0X-0X0X0X`, which is deliberately not a
valid account id.

## One thing to know about the real export

A real billing export table is called
`gcp_billing_export_v1_<BILLING_ACCOUNT_ID>` — **the account id is in the table
name**. That is one reason the lesson queries a view with a plain name instead
of the table directly: the view also filters to one project, so nobody reads
anybody else's spend.
