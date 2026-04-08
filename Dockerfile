FROM postgres:18-alpine

ENV PGDATA=/var/lib/postgresql/18/main

COPY ./cinema.sql /docker-entrypoint-initdb.d/