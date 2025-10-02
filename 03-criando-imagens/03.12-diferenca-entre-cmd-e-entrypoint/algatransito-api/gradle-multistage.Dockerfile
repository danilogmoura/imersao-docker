## STAGE BUILD - Primeira etapa: compilação da aplicação
# Usa imagem oficial do Gradle com JDK 21 para compilar o projeto
FROM gradle:8.10.2-jdk21 AS build

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia todos os arquivos do projeto para o container
COPY . .

# Executa o build do projeto Spring Boot gerando o JAR
RUN gradle bootJar

## STAGE PRODUCTION - Segunda etapa: imagem de produção
# Usa imagem JRE (Java Runtime Environment) mais leve para produção
FROM eclipse-temurin:21-jre-jammy

# Define argumento de build para o perfil do Spring (dev, prod, test)
ARG PROFILE

# Define variáveis de ambiente para configuração da aplicação
# JAR_NAME: nome do arquivo JAR da aplicação
# SERVER_PORT: porta onde a aplicação irá rodar
# SPRING_PROFILES_ACTIVE: perfil ativo do Spring Boot
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$PROFILE

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o JAR compilado da primeira etapa para a imagem de produção
COPY --from=build /app/build/libs/$JAR_NAME .

# Expõe a porta definida na variável de ambiente
EXPOSE $SERVER_PORT

# Comando padrão para executar a aplicação Spring Boot
# CMD java -jar $JAR_NAME

# ENTRYPOINT: comando fixo que sempre será executado
# DIFERENÇAS entre CMD e ENTRYPOINT:
# - CMD: pode ser sobrescrito facilmente no docker run
# - ENTRYPOINT: comando fixo, argumentos do docker run são anexados
# - ENTRYPOINT + CMD: ENTRYPOINT fixo + CMD como argumentos padrão
# - Para Spring Boot, ENTRYPOINT é melhor para garantir que java -jar sempre execute
ENTRYPOINT java -jar $JAR_NAME