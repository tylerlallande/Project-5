FROM python:3.12-slim

WORKDIR /app
COPY server /app/server
ENV HOST=0.0.0.0 PORT=8080 DB_PATH=/data/tailgates.sqlite3
EXPOSE 8080
VOLUME ["/data"]
CMD ["python", "/app/server/server.py"]
