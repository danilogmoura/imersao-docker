FROM alpine:3.21

RUN apk add --no-cache openjdk21-jre
ARG PROFILE 
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    ENV_PROFILE=$PROFILE
WORKDIR /app
COPY build/libs/$JAR_NAME .
EXPOSE $SERVER_PORT
CMD ["sh", "-c", "java -jar -Dspring.profiles.active=${ENV_PROFILE} ${JAR_NAME}"]