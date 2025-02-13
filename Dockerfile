FROM python:3.11-slim as builder

WORKDIR /docs
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
RUN mkdocs build

FROM nginx:alpine
COPY --from=builder /docs/site /usr/share/nginx/html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 