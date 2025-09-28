## STAGE BUILD
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /app
COPY . .
RUN gradle bootJar

## BUILD
FROM eclipse-temurin:21-jre-jammy
ARG PROFILE
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$PROFILE
WORKDIR /app
COPY --from=build /app/build/libs/$JAR_NAME .
EXPOSE $SERVER_PORT
CMD java -jar $JAR_NAME