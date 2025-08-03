# беру официальный образ PostgreSQL
FROM postgres:latest
# инициализирую базу данных
COPY init.sql /docker-entrypoint-initdb.d/
# Даю права  (Alpine требует явного указания)
RUN chmod 644 /docker-entrypoint-initdb.d/init.sql
# Открываю порт 5432 для подключения к базе данных
EXPOSE 5432