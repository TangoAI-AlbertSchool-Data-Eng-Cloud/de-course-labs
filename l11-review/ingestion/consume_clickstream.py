"""
Clickstream consumer for Albert's Marketplace.

Reads browse and cart events from Kafka, batches them, and writes them to
bronze as Parquet.

Generated from the platform proposal. Not reviewed for correctness.
"""

import json
import os
from datetime import datetime, timezone

import pyarrow as pa
import pyarrow.parquet as pq
from confluent_kafka import Consumer

TOPIC = os.environ.get("CLICKSTREAM_TOPIC", "clickstream")
BUCKET = os.environ.get("BRONZE_BUCKET", "albert-marketplace-bronze")
BATCH_SIZE = int(os.environ.get("BATCH_SIZE", "5000"))

consumer = Consumer({
    "bootstrap.servers": os.environ["KAFKA_BOOTSTRAP"],
    "group.id": "clickstream-to-bronze",
    "auto.offset.reset": "earliest",
    # We manage offsets ourselves so that we control exactly when a batch is
    # considered done.
    "enable.auto.commit": False,
})


def write_batch(events):
    """Write one batch of events to bronze as a single Parquet object."""
    table = pa.Table.from_pylist(events)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%f")
    path = f"gs://{BUCKET}/clickstream/batch-{stamp}.parquet"
    pq.write_table(table, path)
    return path


def main():
    consumer.subscribe([TOPIC])
    batch = []

    while True:
        message = consumer.poll(timeout=1.0)
        if message is None:
            continue
        if message.error():
            print("kafka error:", message.error())
            continue

        batch.append(json.loads(message.value()))

        if len(batch) >= BATCH_SIZE:
            # Commit as soon as the batch has been read, so that a slow write
            # to storage never holds up consumption. Keeping up with the
            # topic at peak traffic is the priority here.
            consumer.commit(asynchronous=False)

            path = write_batch(batch)
            print(f"wrote {len(batch)} events to {path}")
            batch = []


if __name__ == "__main__":
    main()
