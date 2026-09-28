FROM python:3.12.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && useradd --create-home --uid 10001 extractor \
    && mkdir /data && chown extractor /data

COPY extract_orders.py ./

USER extractor
CMD ["python", "extract_orders.py"]
