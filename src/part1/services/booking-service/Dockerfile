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