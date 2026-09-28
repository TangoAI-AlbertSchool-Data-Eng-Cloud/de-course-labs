FROM python:3.12-slim

# git is needed by dbt deps, and dbt debug checks for it.
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# Pinned on purpose. An unpinned dbt is a lesson 6 failure waiting to happen.
RUN pip install --no-cache-dir dbt-bigquery==1.12.1

WORKDIR /usr/app
ENV DBT_PROFILES_DIR=/usr/app
ENTRYPOINT ["dbt"]
CMD ["--version"]
