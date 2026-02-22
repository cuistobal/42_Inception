FROM python:3.9-slim-bullseye

WORKDIR /app

COPY app/ /app/

EXPOSE 80

CMD ["python", "-m", "http.server", "80"]
