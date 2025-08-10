
## Part 1. Запуск нескольких Docker-контейнеров с использованием Docker Compose

Создаем Dockerfile для каждого микросервиса, расположенного в папке services

В папке materials есть небольшая подсказка по проекту. Будем работать с ним. </br>
После подготовки окружения (установкa docker, docker-compose)
Начну с двух первых сервисов: 
- rabbitmq;
- postgresql. 

******
## **_rabbitmq_**

Для rabbitmq лучше всего использовать стандартный образ, так как никакой дополнительной настройки не потребуется (например, `rabbitmq:3-management-alpine`).
С официального сайта `https://hub.docker.com/_/rabbitmq` получим последний образ и Dockerfile для него </br>

```
#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM rabbitmq:4.1-alpine

RUN set -eux; \
	rabbitmq-plugins enable --offline rabbitmq_management; \
# make sure the metrics collector is re-enabled (disabled in the base image for Prometheus-style metrics by default)
	rm -f /etc/rabbitmq/conf.d/20-management_agent.disable_metrics_collector.conf; \
# grab "rabbitmqadmin" from inside the "rabbitmq_management-X.Y.Z" plugin folder
# see https://github.com/docker-library/rabbitmq/issues/207
	cp /plugins/rabbitmq_management-*/priv/www/cli/rabbitmqadmin /usr/local/bin/rabbitmqadmin; \
	[ -s /usr/local/bin/rabbitmqadmin ]; \
	chmod +x /usr/local/bin/rabbitmqadmin; \
	apk add --no-cache python3; \
	rabbitmqadmin --version

EXPOSE 15671 15672
```
изменяю порты с 15671 15672 на 5671 5672 </br>
![rabbitmq](./images/part1/rabbitmq/Dockerfile.png)
 
Создаю файл docker-compose и делаю запись для этого сервиса. Создаю сеть docker7 для проекта в docker-compose.yml.
```
services:
  rabbitmq:
    build: ./rabbitmq
    ports:
      - "5672:5672"  # AMQP
      - "15672:15672"  # Web UI
    networks:
      - devops7
networks:  # внутренняя сеть для всего проекта
  devops7:
    driver: bridge
```


![rabbitmq](./images/part1/rabbitmq/docker-compose.png) </br>
проверяю создается ли образ и контейнер 
```
docker-compose up --build -d rabbitmq
docker images
docker ps
```
![rabbitmq](./images/part1/rabbitmq/docker-compose_up.png) <br>
![rabbitmq](./images/part1/rabbitmq/docker_images.png) <br>
![rabbitmq](./images/part1/rabbitmq/docker_ps.png) <br>

******
## **_database_**
Теперь сделаю Dockerfile для базы данных 
в папке `/database/Dockerfile` 

```
#database/Dockerfile
# беру официальный образ PostgreSQL
FROM postgres:latest
# инициализирую базу данных
COPY init.sql /docker-entrypoint-initdb.d/
# Даю права  (Alpine требует явного указания)
RUN chmod 644 /docker-entrypoint-initdb.d/init.sql
# Открываю порт 5432 для подключения к базе данных
EXPOSE 5432
```
![database_psql](./images/part1/datatbase/Dockerfile.png) </br>
Добавлю необходимые строки в docker-compose,
кроме этого создам внутреннюю сеть docker и общее пространство для работы с базами
все переменные буду включать в docker-compose.yml так как их проще менять без пересборки образа, если их указать в Dockerfile нужно будет пересобирать образ, что-бы их поменять. </br>

```
    database:
    build: ./database
    environment:
      # Задаем переменные окружения для базы данных
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_MULTIPLE_DATABASES="users_db,hotels_db,reservations_db,payments_db,balances_db,statistics_db"
    ports:
       - "5432:5432"
    volumes:
       - postgres_data:/var/lib/postgresql/data
    networks:
       - devops7

volumes:
  postgres_data:

networks:
  devops7:
    driver: bridge
```
</br> ![database_psql](./images/part1/datatbase/docker-compose.png) </br>

Создаю образ и запускаю контейнер с базой данных.
```
docker-compose up --build -d database
docker images
docker ps </br>
```
</br> ![database_psql](./images/part1/datatbase/docker-compose_up.png) </br>
</br> ![database_psql](./images/part1/datatbase/docker_images.png) </br>
</br> ![database_psql](./images/part1/datatbase/docker_ps.png) </br>

проверяю работает ли база данных, сведения о созданных базах можно увидеть в файле init.sql
</br> ![database_psql](./images/part1/datatbase/docker_exec_psql.png)

вижу ответ, следовательно, моя база запущена и создан пользователь postgres
</br>

******
## **_session-service_**

Создаю `/session/Dockerfile` для сервиса `session-service`. Нужно отметить, что столкнулся с ошибкой, которая возникала из-за неправинлього определения переменной MAVEN_CONFIG </br>
![session-service/error](./images/part1/session-service/ERROR_MAVEN_CONFIG.png) </br>
![session-service/error](./images/part1/session-service/ERROR_root.png) </br>
В итоге, решил проблему заново переопределив эту переменную в Dockerfile и задав ей пустое значение

```
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8081
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]
``` 
![session-service/Dockerfile](./images/part1/session-service/Dockerfile.png) </br>


Вножу запись в docker-compose.yml
```
  session-service:
    build: ./session-service
    environment:
      - POSTGRES_HOST=database
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_DB=users_db
    networks:
      - devops7
    ports:
      - "8081:8081"
```
![session-service/docker-compose](./images/part1/session-service/docker-compose.png) </br>

Создаю образ и запускаю контейнер с сервисом.
```
docker-compose up --build -в session-service
docker images
docker ps
```
![session-service/docker-compose_up](./images/part1/session-service/docker-compose_up.png) </br>
![session-service/docker_images](./images/part1/session-service/docker_images.png) </br>
![session-service/docker_ps](./images/part1/session-service/docker_ps.png) </br>

Проверяю подключился ли сервис к базе данных </br>
![session-service/docker-compose_exec_psql](./images/part1/session-service/docker-compose_exec_psql.png) </br>

Получаю ответ. Вижу, что подключение создано, дополнительно проверяю версию java </br>  
![session-service/docker-compose_exec_psql](./images/part1/session-service/docker_exec_java_version.png) </br>


******
## **_hotel-service_**

Для сервиса `hotel-service` также сделаю Dockerfile
```
# hotel-service/Dockerfile 
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
# Сбрасываем MAVEN_CONFIG, чтобы избежать конфликта с mvnw
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
# Загрузка зависимостей (без MAVEN_CONFIG=/root/.m2)
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8082
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]

```
 ![hotel-service/Dockerfile](./images/part1/hotel-service/Dockerfile.png) </br>

Делаю запись в docker-compose.yml 
```
  hotel-service:
    build: ./hotel-service
    environment:
      - POSTGRES_HOST=database
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_DB=hotels_db
    networks:
      - devops7
    ports:
      - "8082:8082"
```

![hotel-service/docker-compose](./images/part1/hotel-service/docker-compose.png) </br>

Создаю образ и запускаю контейнер с сервисом. Проверяю его создание и проверяю запущен ли JDK. </br>
```
docker-compose up --build -в hotel-service
docker images
docker ps
```
![hotel-service/docker-compose_up](./images/part1/hotel-service/docker-compose_up.png) </br>
![hotel-service/docker_images](./images/part1/hotel-service/docker_images.png) </br>
![hotel-service/docker_ps](./images/part1/hotel-service/docker_ps.png) </br>

Проверяю версию java</br>

![hotel-service/](./images/part1/hotel-service/docker_exec_version.png) </br>

******
## **_booking-service_**

Создаю Dockerfile для `booking-service`. При работе с этим сервисом столкнулся с ошибкой </br> 
SpringApplication требовала наличие субдиректорий в папке config/*/. Решили ошибку костылем, взял решение в интернете на stackoverflow путем добавления рандомной субдиректории Директивой `RUN mkdir -p  /app/config/*/empty_subdir` в Dockerfile

![booking-service/ERROR](./images/part1/booking-service/ERROR_conf_subdir.png)

```
# booking-service/Dockerfile
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN mkdir -p /app/config/*/empty_subdir
COPY --from=build /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8083
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]
```
![booking-service/Dockerfile](./images/part1/booking-service/Dockerfile.png)

```
  booking-service:
    build: ./booking-service
    environment:
      - POSTGRES_HOST=database
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_DB=reservations_db
      - RABBIT_MQ_HOST=rabbitmq
      - RABBIT_MQ_PORT=5672
      - RABBIT_MQ_USER=postgres
      - RABBIT_MQ_PASSWORD=master
      - RABBIT_MQ_QUEUE_NAME=messagequeue
      - RABBIT_MQ_EXCHANGE=messagequeue-exchange
      - HOTEL_SERVICE_HOST=hotel-service
      - HOTEL_SERVICE_PORT=8082
      - PAYMENT_SERVICE_HOST=payment-service
      - PAYMENT_SERVICE_PORT=8084
      - LOYALTY_SERVICE_HOST=loyalty-service
      - LOYALTY_SERVICE_PORT=8085
    networks:
      - devops7
    ports:
      - "8083:8083"
```

![booking-service/docker-compose](./images/part1/booking-service/docker-compose.png)

Создаю образ и запускаю контейнер с сервисом. роверяю его создание и проверяю запущен ли JDK.
```
docker-compose up --build -в booking-service
docker images
docker ps
docker exec services_payment-service_1 java -version
```

![booking-service/docker-compose_up](./images/part1/booking-service/docker-compose_up.png) </br>
![booking-service/docker_images](./images/part1/booking-service/docker_images.png) </br>
![booking-service/docker_ps](./images/part1/booking-service/docker_ps.png) </br>
![booking-service/docker_exec_java_version](./images/part1/booking-service/docker_exec_java_version.png) </br>


******
## **_payment-service_**

`payment-service/Dockerfile`

```
# payment-service/Dockerfile
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN mkdir -p /app/config/*/empty_subdir
COPY --from=build /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8084
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]
```

![payment-service/Dockerfile](./images/part1/payment-service/Dockerfile.png)

`docker-compose.yml`

```
  payment-service:
    build: ./payment-service
    environment:
      - POSTGRES_HOST=database
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_DB=payments_db
    networks:
      - devops7
    ports:
      - "8084:8084"
```
![payment-service/docker-compose](./images/part1/payment-service/docker-compose.png) </br>

Создаю образ и запускаю контейнер с сервисом, проверяю его создание и проверяю запущен ли JDK. </br>
```
docker-compose up --build -в payment-service
docker images
docker ps
docker exec services_payment-service_1 java -version
```
![payment-service/](./images/part1/payment-service/docker-compose_up.png) </br>
![payment-service/](./images/part1/payment-service/docker_images.png) </br>
![payment-service/](./images/part1/payment-service/docker_ps.png) </br>
![payment-service/](./images/part1/payment-service/docker_exec_java_version.png) </br>

******
## **_loyalty-service_**

`loyalty-service/Dockerfile`

```
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN mkdir -p /app/config/empty_subdir
COPY --from=build /app/target/*.jar app.jar
COPY src/main/resources/application* ./config/
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8085
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]
```
![loyalty-service/Dockerfile](./images/part1/loyalty-service/Dockerfile.png) </br>
`docker-compose`
```
  loyalty-service:
    build: ./loyalty-service
    environment:
      - POSTGRES_HOST=database
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_DB=balances_db
    networks:
      - devops7
    ports:
      - "8085:8085"
```
![loyalty-service/docker-compose](./images/part1/loyalty-service/docker-compose.png) </br>

Создаю образ и запускаю контейнер с сервисом, проверяю его создание и проверяю запущен ли JDK.
```
docker-compose up --build -в payment-service
docker images
docker ps
docker exec services_payment-service_1 java -version
```
![loyalty-service/docker-compose_up](./images/part1/loyalty-service/docker-compose_up.png) </br>
![loyalty-service/docker_images](./images/part1/loyalty-service/docker_images.png) </br>
![loyalty-service/docker_ps](./images/part1/loyalty-service/docker_ps.png) </br>
![loyalty-service/docker_exec_java_version](./images/part1/loyalty-service/docker_exec_java_version.png) </br>

******
## **_report-service_**

`report-service/Dockerfile`

```
# report-service/Dockerfile
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN mkdir -p /app/config/*/empty_subdir
COPY --from=build /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8086
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]
```
![report-service/Dockerfile](./images/part1/report-service/Dockerfile.png)

`docker-compose.yml`

```
  report-service:
    build: ./report-service
    environment:
      - POSTGRES_HOST=database
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=master
      - POSTGRES_DB=statistics_db
      - RABBIT_MQ_HOST=rabbitmq
      - RABBIT_MQ_PORT=5672
      - RABBIT_MQ_USER=postgres
      - RABBIT_MQ_PASSWORD=master
      - RABBIT_MQ_QUEUE_NAME=messagequeue
      - RABBIT_MQ_EXCHANGE=messagequeue-exchange
    networks:
      - devops7
    ports:
      - "8086:8086"
```
![report-service/docker-compose](./images/part1/report-service/docker-compose.png)

Создаю образ и запускаю контейнер с сервисом, проверяю его создание и проверяю запущен ли JDK.
```
docker-compose up --build -в payment-service
docker images
docker ps
docker exec services_payment-service_1 java -version
```

![report-service/docker-compose_up](./images/part1/report-service/docker-compose_up.png) </br>
![report-service/docker_images](./images/part1/report-service/docker_images.png) </br>
![report-service/docker_ps](./images/part1/report-service/docker_ps.png) </br>
![report-service/docker_exec_java_version](./images/part1/report-service/docker_exec_java_version.png) </br>


******
## **_gateway-service_**

`gateway-service/Dockerfile`

```
# gateway-service/Dockerfile
# Стадия сборки
FROM maven:3.8.5-openjdk-17 AS build
ENV MAVEN_CONFIG=
WORKDIR /app
COPY pom.xml mvnw .
COPY .mvn/ .mvn/
RUN chmod 755 ./mvnw
RUN rm -rf /root/.m2/repository
RUN ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests

# Стадия запуска
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN mkdir -p /app/config/*/empty_subdir
COPY --from=build /app/target/*.jar app.jar
COPY wait-for-it.sh .
RUN chmod +x wait-for-it.sh

EXPOSE 8087
CMD ["./wait-for-it.sh", "database:5432", "rabbitmq:5672", "--timeout=60", "--", "java", "-jar", "app.jar"]
```
![gateway-service/Dockerfile](./images/part1/gateway-service/Dockerfile.png)


`docker-compose.yml`
```
  gateway-service:
    build: ./gateway-service
    environment:
      - SESSION_SERVICE_HOST=session-service
      - SESSION_SERVICE_PORT=8081
      - HOTEL_SERVICE_HOST=hotel-service
      - HOTEL_SERVICE_PORT=8082
      - BOOKING_SERVICE_HOST=booking-service
      - BOOKING_SERVICE_PORT=8083
      - PAYMENT_SERVICE_HOST=payment-service
      - PAYMENT_SERVICE_PORT=8084
      - LOYALTY_SERVICE_HOST=loyalty-service
      - LOYALTY_SERVICE_PORT=8085
      - REPORT_SERVICE_HOST=report-service
      - REPORT_SERVICE_PORT=8086
    networks:
      - devops7
    ports:
      - "8087:8087"

```

![gateway-service/docker-compose](./images/part1/gateway-service/docker-compose.png)

Создаю образ и запускаю контейнер с сервисом, проверяю его создание и проверяю запущен ли JDK.
```
docker-compose up --build -в payment-service
docker images
docker ps
docker exec services_payment-service_1 java -version
```
![gateway-service/docker-compose_up](./images/part1/gateway-service/docker-compose_up.png) </br>
![gateway-service/docker_images](./images/part1/gateway-service/docker_images.png) </br>
![gateway-service/docker_ps](./images/part1/gateway-service/docker_ps.png) </br>
![gateway-service/docker_exec_java_version](./images/part1/gateway-service/docker_exec_java_version.png) </br>


******
## **Запуск всего проекта **

Проверяю собранные образы 

![run-service](./images/part1/run-service/docker_images.png) </br>

```
docker-compose up -d
docker ps
```
![run-service](./images/part1/run-service/docker-compose_up.png) </br>
![run-service](./images/part1/run-service/docker_ps.png) </br>

Видно, что контейнеры запустились, работают стабильно. 
Приступаю к тестированию

******
## **Тестирование проекта **


Устанавливаю `Postman` и `Postman Agent` на машину. </br>

![test-service](./images/part1/test-service/web_postman.png) </br>
![test-service](./images/part1/test-service/download.png) </br>
# **Postman**        ![test-service](./images/part1/test-service/postman.png) </br>
# **Postman Agent**  ![test-service](./images/part1/test-service/postman_agent.png) </br>

В папке src лежит файл `application_tests.postman_collection.json`
Он нужен для проведения тестов
После регистрации в Postman, вхожу в панель тестирования, импортирую файл с тестами </br>
![test-service](./images/part1/test/import_tests.png) </br>
Красным обозначена кнопка импорта, синим импортированные тесты. </br>

Провожу тестирование:

`GET login user` </br>
![test-service](./images/part1/test-service/GET_login_user.png) </br>

`GET Get hotels` </br>
![test-service](./images/part1/test-service/GET_get_hotels.png) </br>

`GET hotel` </br>
![test-service](./images/part1/test-service/GET_hotel.png) </br>

`POST book hotel` </br>
![test-service](./images/part1/test-service/POST_book_hotel.png) </br>

`GET user loyalty` </br>
![test-service](./images/part1/test-service/GET_user_loyalty.png) </br>

Все тесты прошли успешно на запросы пришли ответы 200 и 201.
На этом первая часть задания все, закончилась.

## Part 2. Создание виртуальных машин

### Задание 

1) Установи и инициализируй Vagrant в корне проекта. Напиши Vagrantfile для одной виртуальной машины. Перенеси исходный код веб-сервиса в рабочую директорию виртуальной машины. Помощь по vagrant ты найдешь в материалах.

 устанавливаю утилиту Vagrant

можно скачать и запустить файл установки  </br>
![vagrant-test](./images/part2/download_vagrant.png) </br>

или командой 
```
brew tap hashicorp/tap
brew install hashicorp/tap/hashicorp-vagrant
```
для Linux команда другая.

проверяю установку утилиты командой 
`vagrant --version` </br>
![vagrant-test](./images/part2/vagrant_version.png) </br>

устанавливаю небходимое окружение для работы с vagrant </br>
![vagrant-test](./images/part2/install_qemu.png) </br>
![vagrant-test](./images/part2/vagrant_plugin_install.png) </br>

В корне проекта инициализирую vagrant командой 
vagrant init с указание образ который буду использовать для создания виртуальной машины.

```
vagrant init hashicorp-education/ubuntu-24-04 --box-version 0.1.0
```
![vagrant-test](./images/part2/vagrant_init.png) </br>

Запускаю установку командой 
 </br>`vagrant up` </br>

![vagrant-test](./images/part2/vagrant_up_start.png)
![vagrant-test](./images/part2/vagrant_up_end.png)

проверяю появилась ли машина
</br>`VBoxmanage listvms` </br>

![vagrant-test](./images/part2/VBox_listvms.png)


2) Зайди через консоль внутрь виртуальной машины и удостоверься, что исходный код встал, куда нужно. Останови и уничтожь виртуальную машину.

Загружаю файлы в виртуальную машину командой 
</br>
`vagrant upload services services`  </br>

![vagrant-test](./images/part2/vagrant_upload.png)

Захожу в машину и проверяю наличие файлов командой 
```
ls 
tree
```
![vagrant-test](./images/part2/check_files_inside.png)

Вижу, что файлы успешно загрузились и выхожу из машины.
Останавливаю и удаляю машину

```
vagrant halt
vagrant destroy
```
![vagrant-test](./images/part2/logout_halt_destroy.png)




## Part 3. Создание простейшего Docker Swarm

### Задание

1) Модифицируй Vagrantfile для создания трех машин: manager01, worker01, worker02. Напиши shell-скрипты для установки Docker внутрь машин, инициализации и подключения к Docker Swarm. Помощь с Docker Swarm ты найдешь в материалах.

2) Загрузи собранные образы на Docker Hub и модифицируй Docker Compose файл для подгрузки расположенных на Docker Hub образов.

3) Подними виртуальные машины и перенеси на менеджер Docker Compose файл. Запусти стек сервисов, используя написанный Docker Compose файл.

4) Настрой прокси на базе nginx для доступа к gateway service и session service по оверлейной сети. Сами gateway service и session service сделай недоступными напрямую.

5) Прогони заготовленные тесты через Postman и удостоверься, что все они проходят успешно. В отчете отобрази результаты тестирования.

6) Используя команды Docker, отобрази в отчете распределение контейнеров по узлам.

7) Установи отдельным стеком Portainer внутри кластера. В отчете отобрази визуализацию распределения задач по узлам с помощью Portainer.
