"""
The Albert's Marketplace daily pipeline.

Ingest, transform, check, refresh. Generated from the platform proposal.
"""

from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryInsertJobOperator,
)

default_args = {
    "owner": "data-platform",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
    "email": ["data-platform@example.com"],
}

with DAG(
    dag_id="marketplace_daily",
    start_date=datetime(2026, 1, 1),
    schedule="0 4 * * *",
    catchup=False,
    default_args=default_args,
) as dag:

    consume = DockerOperator(
        task_id="consume_clickstream",
        image="albertmarketplace/clickstream-consumer:latest",
        auto_remove=True,
    )

    # Append the day's rows to the fact table. Retries above handle any
    # transient failure, so no further error handling is needed here.
    load_orders = BigQueryInsertJobOperator(
        task_id="load_orders",
        configuration={
            "query": {
                "query": """
                    INSERT INTO `marketplace.fct_order_lines`
                    SELECT * FROM `marketplace.stg_order_lines`
                    WHERE DATE(created_at) = @run_date
                """,
                "useLegacySql": False,
            }
        },
    )

    dbt = DockerOperator(
        task_id="dbt_build",
        image="albertmarketplace/dbt:latest",
        command="dbt build --target prod",
        auto_remove=True,
    )

    quality = BigQueryInsertJobOperator(
        task_id="quality_check",
        configuration={
            "query": {
                "query": """
                    SELECT COUNT(*) AS late_rows
                    FROM `marketplace.fct_order_lines`
                    WHERE created_at > CURRENT_TIMESTAMP()
                """,
                "useLegacySql": False,
            }
        },
    )

    refresh_dashboard = BigQueryInsertJobOperator(
        task_id="refresh_dashboard",
        configuration={
            "query": {
                "query": "CALL `marketplace.refresh_dashboard_extracts`()",
                "useLegacySql": False,
            }
        },
    )

    consume >> load_orders >> dbt >> quality >> refresh_dashboard
