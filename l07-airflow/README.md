# Lesson 7 · Airflow

Everything the demo runs.

| Path | What it is |
|---|---|
| `docker-compose.override.yaml` | merged on top of Airflow's own compose file: our image, the host paths, and the Docker socket |
| `Dockerfile` | `apache/airflow:3.3.2` plus the Docker provider |
| `env.example` | copy to `.env` and set the two host paths to yours |
| `dags/marketplace.py` | the DAG: `extract >> load >> dbt_run >> dbt_test` |
| `transform/` | a cut-down dbt project — two staging models, one mart, six tests |

## Getting it running

The full sequence, with what each command should print, is on the lesson's
**setup page** and **demo guide**. In short:

```bash
curl -sfSLO 'https://airflow.apache.org/docs/apache-airflow/3.3.2/docker-compose.yaml'
cp env.example .env          # then edit the two paths
mkdir -p logs plugins config out
docker compose up airflow-init
docker compose up -d
```

**On Windows, keep this folder near the root of `C:`.** Airflow writes one log
file per task, per run, per attempt, and the paths it builds are long enough to
hit the 260-character limit.

## One thing to know before the demo

`dags/marketplace.py` ships with the **`MERGE`** version of the load step,
which is the correct one. The demo deliberately starts with an `INSERT` so the
room can watch a re-run double the revenue — the demo guide has both, and the
teacher's notes say which one to have loaded when the session starts.
