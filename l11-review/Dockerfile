# Image for the clickstream consumer.
FROM python:3

WORKDIR /app

COPY ingestion/requirements.txt .
RUN pip install -r requirements.txt

COPY ingestion/ .

CMD ["python", "consume_clickstream.py"]
