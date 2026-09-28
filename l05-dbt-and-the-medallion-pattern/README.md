# Lesson 5 · dbt and the medallion pattern

| Path | What it is |
|---|---|
| `dbt-project/` | the reference dbt project: sources, staging, intermediate, marts, tests |
| `Dockerfile` | the eight-line recipe for `charlestng/dbt-bigquery:1.12.1` |

**You do not need to build the image.** It is published, multi-architecture,
and the lesson's setup page tells you to pull it. The Dockerfile is here so the
image is reproducible and so lesson 6 has something real to read.

**Before running anything**, open `dbt-project/profiles.yml`: `project:` and
`dataset:` decide whose Google Cloud project pays and where the models land.
They are not yours yet.

The bronze tables this project reads are the ones lesson 4 loads.
