## STAGE BUILD - Primeira etapa: compilação da aplicação
# Usa imagem oficial do Gradle com JDK 21 para compilar o projeto
FROM gradle:8.10.2-jdk21 AS build

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia arquivo de configuração do Gradle primeiro (para cache de dependências)
COPY build.gradle ./

# Baixa dependências (fica em cache quando apenas código muda)
RUN gradle dependencies

# Copia código fonte
COPY src/ src/

# Executa o build
RUN gradle bootJar

## STAGE PRODUCTION - Segunda etapa: imagem de produção
# Usa imagem JRE (Java Runtime Environment) mais leve para produção
FROM eclipse-temurin:21-jre-jammy

# Define argumento de build para o perfil do Spring (dev, prod, test)
ARG ENV=prod

# Define variáveis de ambiente para configuração da aplicação
# Estas variáveis são utilizadas tanto pelo Dockerfile quanto pelo docker-entrypoint.sh
#
# JAR_NAME: nome do arquivo JAR da aplicação
#   - Usado no script: exec java $JAVA_OPTS -jar ${JAR_NAME:-app.jar}
# SERVER_PORT: porta onde a aplicação irá rodar
#   - Usado no script: echo "Porta configurada: ${SERVER_PORT:-9090}"
#   - Usado no HEALTHCHECK: curl -f http://localhost:$SERVER_PORT/actuator/health
# SPRING_PROFILES_ACTIVE: perfil ativo do Spring Boot
#   - Usado no script: verificação de banco apenas em produção
#   - Usado no script: echo "Iniciando AlgaTransito API com perfil: ${SPRING_PROFILES_ACTIVE:-dev}"
# DOCKERIZE_VERSION: versão do dockerize para aguardar dependências
# TZ: configuração de timezone para o container
#   - Define o fuso horário como America/Sao_Paulo (UTC-3)
#   - Afeta logs, timestamps e operações de data/hora da aplicação
#   - IMPORTANTE: Sempre configure timezone em containers de produção
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$ENV \
    DOCKERIZE_VERSION=v0.9.6 \
    TZ=America/Sao_Paulo 

# Cria usuário não-root para segurança e instala dockerize
# -r: cria usuário/grupo do sistema (sem home directory)
# -g: especifica o grupo primário do usuário
# wget: ferramenta temporária para baixar o dockerize
# dockerize: ferramenta para aguardar dependências (substitui netcat)
#   - Usado no ENTRYPOINT: dockerize -wait tcp://${DB_HOST}:3306
#   - Aguarda MySQL estar disponível antes de executar o entrypoint
#   - Mais robusto que netcat para verificação de dependências
#   - VANTAGENS sobre netcat:
#     * Timeout configurável (-timeout 60s)
#     * Não precisa de lógica de retry no script
#     * Suporte a múltiplos tipos (tcp, http, file)
#     * Logging automático do processo de espera
RUN groupadd -r spring && useradd -r -g spring spring \
    && apt update \
    && apt-get install -y wget \
    && wget -O - https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar xzf - -C /usr/local/bin \
    && apt-get autoremove -yqq --purge wget && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o JAR compilado da primeira etapa para a imagem de produção
COPY --from=build /app/build/libs/$JAR_NAME .

# Copia o script de entrypoint com propriedade do usuário spring
# --chown: define o proprietário do arquivo como spring:spring
# Este script será executado pelo dockerize após aguardar dependências:
#   - Configuração de opções JVM
#   - Lógica de inicialização da aplicação
#   - NOTA: Verificação de MySQL é feita pelo dockerize, não pelo script
COPY --chown=spring:spring docker-entrypoint.sh .

# Define permissão de execução para o script de entrypoint
# Necessário para que o script possa ser executado pelo ENTRYPOINT
RUN chmod +x docker-entrypoint.sh

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

# Define o dockerize como entrypoint para aguardar dependências
# O dockerize aguarda MySQL estar disponível antes de executar o script
# 
# FLUXO DE EXECUÇÃO:
# 1. Container inicia → dockerize aguarda MySQL em ${DB_HOST}:3306
# 2. MySQL disponível → dockerize executa docker-entrypoint.sh
# 3. Script configura opções JVM e variáveis de ambiente
# 4. Script executa a aplicação Java com exec java $JAVA_OPTS -jar $JAR_NAME
#
# VANTAGENS DO DOCKERIZE:
# - Aguarda dependências de forma robusta (timeout configurável)
# - Não precisa de lógica de retry no script
# - Mais simples e confiável que netcat
# - Suporte a múltiplos tipos de dependências (tcp, http, file)
# - Logging automático do processo de espera
ENTRYPOINT dockerize -wait tcp://${DB_HOST:-localhost}:3306 -timeout 60s ./docker-entrypoint.sh