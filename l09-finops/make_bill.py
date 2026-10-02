"""Generate a realistic-shaped cloud bill, in Google's billing-export schema.

    python make_bill.py > bill.ndjson

Why this exists: a course that runs inside the free tier produces a bill with
nothing in it, and you cannot learn to read a bill from one that says zero. So
this writes a bill for a fictional company with the same *shape* as a real one
- the same columns, the same SKUs, the same five ways costs go wrong.

Every number here is generated. Nothing in it is a real price for real usage;
the unit prices are the published ones so the arithmetic is honest, but the
quantities are invented. Say so whenever you use it.

The five shapes, which are the point:

  1. a runaway query      one day, one SKU, a spike
  2. storage that grows   a slope, never a spike
  3. small-file overhead  operations cost, not storage cost
  4. nobody turned it off flat, constant, forgotten
  5. egress               appears only when data leaves the region

And one thing that is not a shape: about a fifth of the rows carry **no
labels**, which is why the review cannot attribute them.
"""

import json
import random
from datetime import datetime, timedelta, timezone

random.seed(20260929)          # deterministic: the same bill every time

BILLING_ACCOUNT = "0X0X0X-0X0X0X-0X0X0X"   # deliberately not a real account id
CURRENCY = "EUR"
DAYS = 60
START = datetime(2026, 7, 1, tzinfo=timezone.utc)

# Published unit prices, europe-west1, read 2026-09-29. The quantities below
# are invented; these are not.
PRICE = {
    "bq_analysis":   7.50 / 1024,      # per GiB scanned  ($7.50/TiB)
    "gcs_standard":  0.020,            # per GiB-month
    "gcs_class_a":   0.005 / 1000,     # per operation
    "compute_n2":    0.0972,           # per vCPU-hour, n2-standard, on-demand
    "egress_eu":     0.12,             # per GiB, to internet
}

TEAMS = [
    # project, team label, pipeline label, does it label anything at all?
    ("acme-analytics-prod", "data-platform", "clickstream", True),
    ("acme-analytics-prod", "data-platform", "orders",      True),
    ("acme-ml-sandbox",     "ml",            "experiments", True),
    ("acme-legacy-etl",     None,            None,          False),   # the unlabelled one
]


def row(day, project, team, pipeline, service, svc_id, sku, sku_id,
        amount, unit, cost, region="europe-west1"):
    start = START + timedelta(days=day)
    labels = []
    if team:
        labels = [{"key": "team", "value": team},
                  {"key": "pipeline", "value": pipeline},
                  {"key": "environment", "value": "prod" if "prod" in project else "dev"}]
    return {
        "billing_account_id": BILLING_ACCOUNT,
        "service": {"id": svc_id, "description": service},
        "sku": {"id": sku_id, "description": sku},
        "usage_start_time": start.isoformat(),
        "usage_end_time": (start + timedelta(days=1)).isoformat(),
        "project": {"id": project, "name": project},
        "labels": labels,
        "location": {"location": region, "region": region},
        "cost": round(cost, 6),
        "currency": CURRENCY,
        "usage": {"amount": round(amount, 4), "unit": unit},
    }


rows = []

for d in range(DAYS):
    for project, team, pipeline, _labelled in TEAMS:

        # ---- 1. BigQuery analysis: steady, with ONE runaway day on day 41 ----
        gib = random.uniform(180, 260)
        if d == 41 and project == "acme-analytics-prod" and pipeline == "clickstream":
            gib = 41_000                      # somebody ran SELECT * on everything
        rows.append(row(d, project, team, pipeline,
                        "BigQuery", "24E6-581D-38E5",
                        "Analysis (europe-west1)", "2E22-4EC5-8D1A",
                        gib, "gibibyte", gib * PRICE["bq_analysis"]))

        # ---- 2. GCS standard storage: grows every single day ----------------
        stored = 400 + d * 22 + random.uniform(-5, 5)      # GiB-months, climbing
        rows.append(row(d, project, team, pipeline,
                        "Cloud Storage", "95FF-2EF5-5EA1",
                        "Standard Storage europe-west1", "E5F0-6A5D-7BAD",
                        stored / 30, "gibibyte month", (stored / 30) * PRICE["gcs_standard"]))

        # ---- 3. Class A operations: the small-file tax ----------------------
        if pipeline == "clickstream" or not team:
            ops = random.uniform(5_800_000, 6_400_000)
            rows.append(row(d, project, team, pipeline,
                            "Cloud Storage", "95FF-2EF5-5EA1",
                            "Class A Operations", "8C5B-9F1E-2A73",
                            ops, "count", ops * PRICE["gcs_class_a"]))

        # ---- 4. A VM nobody turned off: dead flat, every day -----------------
        if project == "acme-ml-sandbox":
            hours = 24 * 8                     # 8 vCPUs, all day, every day
            rows.append(row(d, project, team, pipeline,
                            "Compute Engine", "6F81-5844-456A",
                            "N2 Instance Core running in EMEA", "CF4E-A0C7-E3BF",
                            hours, "hour", hours * PRICE["compute_n2"]))

        # ---- 5. Egress: nothing, then a step from day 30 --------------------
        if project == "acme-analytics-prod" and pipeline == "orders":
            gib_out = 0.0 if d < 30 else random.uniform(210, 260)
            if gib_out:
                rows.append(row(d, project, team, pipeline,
                                "Cloud Storage", "95FF-2EF5-5EA1",
                                "Download Worldwide Destinations", "22EB-AAE8-FBCD",
                                gib_out, "gibibyte", gib_out * PRICE["egress_eu"]))

for r in rows:
    print(json.dumps(r))
