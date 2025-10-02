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
ARG ENV

# Define variáveis de ambiente para configuração da aplicação
# JAR_NAME: nome do arquivo JAR da aplicação
# SERVER_PORT: porta onde a aplicação irá rodar
# SPRING_PROFILES_ACTIVE: perfil ativo do Spring Boot
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$ENV

# Cria usuário não-root para segurança
# -r: cria usuário/grupo do sistema (sem home directory)
# -g: especifica o grupo primário do usuário
RUN groupadd -r spring && useradd -r -g spring spring

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o JAR compilado da primeira etapa para a imagem de produção
COPY --from=build /app/build/libs/$JAR_NAME .

# Muda para o usuário não-root (importante para segurança)
USER spring

# Configura verificação de saúde da aplicação
# --interval=15s: verifica a cada 15 segundos
# --timeout=15s: timeout de 15 segundos para cada verificação
# --start-period=10s: aguarda 10 segundos antes da primeira verificação
# --retries=3: tenta 3 vezes antes de marcar como unhealthy
# CMD: comando que verifica se a aplicação está funcionando
# curl: faz requisição para o endpoint de health do Spring Boot Actuator
# grep: verifica se a resposta contém 'UP' (aplicação saudável)
HEALTHCHECK --interval=15s --timeout=15s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:$SERVER_PORT/actuator/health | grep -i 'UP' || exit 1

# Expõe a porta definida na variável de ambiente
EXPOSE $SERVER_PORT

# Comando padrão para executar a aplicação Spring Boot
ENTRYPOINT java -jar $JAR_NAME