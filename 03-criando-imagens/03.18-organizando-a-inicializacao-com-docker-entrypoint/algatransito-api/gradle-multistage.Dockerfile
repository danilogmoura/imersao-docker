## STAGE BUILD - Primeira etapa: compilação da aplicação
# Usa imagem oficial do Gradle com JDK 21 para compilar o projeto
FROM gradle:8.10.2-jdk21 AS build

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia todos os arquivos do projeto para o container
COPY . .

# Executa o build do projeto Spring Boot gerando o JAR
# bootJar: gera o JAR executável do Spring Boot
# NOTA: Não é necessário 'clean' em multi-stage builds pois cada stage é isolado
# O Gradle já gerencia cache e dependências eficientemente
RUN gradle bootJar

## STAGE PRODUCTION - Segunda etapa: imagem de produção
# Usa imagem JRE (Java Runtime Environment) mais leve para produção
FROM eclipse-temurin:21-jre-jammy

# Define argumento de build para o perfil do Spring (dev, prod, test)
ARG ENV=dev

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
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$ENV

# Cria usuário não-root para segurança e instala dependências
# -r: cria usuário/grupo do sistema (sem home directory)
# -g: especifica o grupo primário do usuário
# netcat-openbsd: ferramenta necessária para o script docker-entrypoint.sh
#   - Usado na função check_mysql() para verificar conectividade com banco
#   - Comando: nc -z ${DB_HOST} 3306
RUN groupadd -r spring && useradd -r -g spring spring && \
    apt update && \
    apt install -y netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o JAR compilado da primeira etapa para a imagem de produção
COPY --from=build /app/build/libs/$JAR_NAME .

# Copia o script de entrypoint com propriedade do usuário spring
# --chown: define o proprietário do arquivo como spring:spring
# Este script será executado pelo ENTRYPOINT e contém:
#   - Verificação de conectividade com MySQL
#   - Configuração de opções JVM
#   - Lógica de inicialização da aplicação
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

# Define o script de entrypoint como comando fixo
# O script docker-entrypoint.sh será executado sempre que o container for iniciado
# 
# FLUXO DE EXECUÇÃO:
# 1. Container inicia → ENTRYPOINT executa docker-entrypoint.sh
# 2. Script verifica dependências (MySQL se SPRING_PROFILES_ACTIVE=prod)
# 3. Script configura opções JVM e variáveis de ambiente
# 4. Script executa a aplicação Java com exec java $JAVA_OPTS -jar $JAR_NAME
#
# VANTAGENS:
# - Verificação robusta de dependências antes da aplicação
# - Configuração dinâmica baseada em variáveis de ambiente
# - Múltiplos modos de execução (check-db, produção, desenvolvimento)
# - Logging detalhado do processo de inicialização
ENTRYPOINT ["./docker-entrypoint.sh"]