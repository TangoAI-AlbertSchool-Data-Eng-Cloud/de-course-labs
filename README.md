# Course labs — Data Engineering & Cloud Infrastructure

The runnable material for the course: the DAGs, dbt projects, Dockerfiles,
compose files and measurement scripts that the demos and exercises use.

**This is not the course.** The lessons, the demo guides and the exercises live
on the course platform, and they are what you should be reading. This
repository exists so that nobody has to retype a seven-file dbt project.

The company these labs run against is its own repository:
**[albert-marketplace](https://github.com/TangoAI-AlbertSchool-Data-Eng-Cloud/albert-marketplace)** —
a PostgreSQL database with logical decoding, a Kafka clickstream, a storefront
and a load generator. Start there; most of these folders assume it is running.

## Use the tag for your cohort

`main` moves while lessons are being written, and a folder you cloned in
October may not match the transcript on the lesson page in December. **Clone
the tag your teacher gives you**, not the branch:

```bash
git clone --branch msc2-2026 --depth 1 \
  https://github.com/TangoAI-AlbertSchool-Data-Eng-Cloud/de-course-labs.git
```

## What is here

| Folder | Lesson | What it holds |
|---|---|---|
| `l02-object-storage-foundations/` | 2 · Object storage foundations | the scripts behind the lecture's layout, egress and Parquet numbers |
| `l03-batch-streaming-cdc/` | 3 · Batch, streaming and CDC | change data capture written out in plain SQL |
| `l05-dbt-and-the-medallion-pattern/` | 5 · dbt and the medallion pattern | the reference dbt project, and the recipe for the dbt image |
| `l06-packaging-data-jobs/` | 6 · Packaging data jobs | the extractor, its Dockerfile, and the deliberately bad one |
| `l07-airflow/` | 7 · Airflow | the Airflow compose overlay, the DAG, and a cut-down dbt project |

Each folder has its own README saying what to run and what it should print.

## What is deliberately not here

**Teaching notes, worked answers and anything used for marking.** They live in
the private course repository, in folders that are excluded from every build
and from this one. If you ever find that sort of material here, it is a
mistake — please tell Charles rather than reading it.

## Licence

None. These files are Charles Tanguy's teaching material, shared so the course
can be followed and reused with attribution. You own whatever you write
yourself.
