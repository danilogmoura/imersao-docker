# Imagem base personalizada para aplicações Spring Boot
# Esta imagem contém todas as configurações base e utiliza instruções ONBUILD
# para automatizar a construção de imagens de aplicações Spring Boot
#
# CONCEITO ONBUILD:
# - Instruções ONBUILD são executadas quando uma imagem herda desta base
# - Permite criar templates reutilizáveis para aplicações similares
# - Reduz duplicação de código entre Dockerfiles de aplicações
# - Facilita manutenção e padronização de imagens
#
# FLUXO DE USO:
# 1. Construir esta imagem base: docker build -t spring-base:1.0.0 -f spring-base.Dockerfile .
# 2. Usar em aplicações: FROM spring-base:1.0.0 (como no on-build.Dockerfile)
# 3. As instruções ONBUILD são executadas automaticamente durante o build da aplicação

FROM eclipse-temurin:21-jre-jammy

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
ENV DOCKERIZE_VERSION=v0.9.6

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
RUN groupadd -r spring && useradd -r -g spring spring && \   
    apt-get update \
    && apt-get install -y wget \
    && wget -O - https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar xzf - -C /usr/local/bin \
    && apt-get autoremove -yqq --purge wget && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho dentro do container
WORKDIR /app

# INSTRUÇÃO ONBUILD: Copia o JAR da aplicação
# Esta instrução será executada automaticamente quando uma imagem herdar desta base
# 
# COMPORTAMENTO:
# - Executa durante o build da imagem que herda desta base
# - Copia o JAR do diretório build/libs/ (padrão do Gradle/Maven)
# - Usa a variável $JAR_NAME definida na imagem filha
# - Exemplo: se JAR_NAME=algatransito-api.jar, copia build/libs/algatransito-api.jar
#
# PRÉ-REQUISITOS:
# - A imagem filha deve ter o JAR compilado em build/libs/
# - A variável JAR_NAME deve estar definida na imagem filha
# - O contexto de build deve conter o diretório build/libs/
ONBUILD COPY build/libs/$JAR_NAME .

# INSTRUÇÃO ONBUILD: Copia o script de entrypoint
# Esta instrução será executada automaticamente quando uma imagem herdar desta base
#
# COMPORTAMENTO:
# - Executa durante o build da imagem que herda desta base
# - Copia o script docker-entrypoint.sh do contexto de build
# - Define o proprietário como spring:spring (usuário não-root)
# - O script será executado pelo dockerize após aguardar dependências
#
# PRÉ-REQUISITOS:
# - A imagem filha deve ter o arquivo docker-entrypoint.sh no contexto
# - O script deve ter as permissões corretas (será definido na próxima instrução)
# - O script deve ser compatível com a lógica de inicialização da aplicação
#
# CONTEÚDO DO SCRIPT:
#   - Configuração de opções JVM
#   - Lógica de inicialização da aplicação
#   - NOTA: Verificação de MySQL é feita pelo dockerize, não pelo script
ONBUILD COPY --chown=spring:spring docker-entrypoint.sh .

# INSTRUÇÃO ONBUILD: Define permissão de execução
# Esta instrução será executada automaticamente quando uma imagem herdar desta base
#
# COMPORTAMENTO:
# - Executa durante o build da imagem que herda desta base
# - Define permissão de execução para o script docker-entrypoint.sh
# - Necessário para que o script possa ser executado pelo ENTRYPOINT
#
# PRÉ-REQUISITOS:
# - A instrução anterior (ONBUILD COPY) deve ter copiado o script
# - O script deve existir no diretório de trabalho (/app)
ONBUILD RUN chmod +x docker-entrypoint.sh

# Muda para o usuário não-root (importante para segurança)
USER spring

# INSTRUÇÃO ONBUILD: Configura verificação de saúde
# Esta instrução será executada automaticamente quando uma imagem herdar desta base
#
# COMPORTAMENTO:
# - Executa durante o build da imagem que herda desta base
# - Configura healthcheck para monitorar a saúde da aplicação
# - Usa a variável $SERVER_PORT definida na imagem filha
#
# PARÂMETROS:
# --interval=15s: verifica a cada 15 segundos
# --timeout=15s: timeout de 15 segundos para cada verificação
# --start-period=10s: aguarda 10 segundos antes da primeira verificação
# --retries=3: tenta 3 vezes antes de marcar como unhealthy
#
# COMANDO DE VERIFICAÇÃO:
# curl: faz requisição para o endpoint de health do Spring Boot Actuator
# grep: verifica se a resposta contém 'UP' (aplicação saudável)
# exit 1: retorna erro se a aplicação não estiver saudável
#
# PRÉ-REQUISITOS:
# - A aplicação deve ter Spring Boot Actuator configurado
# - O endpoint /actuator/health deve estar disponível
# - A variável SERVER_PORT deve estar definida na imagem filha
ONBUILD HEALTHCHECK --interval=15s --timeout=15s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:$SERVER_PORT/actuator/health | grep -i 'UP' || exit 1

# INSTRUÇÃO ONBUILD: Expõe a porta da aplicação
# Esta instrução será executada automaticamente quando uma imagem herdar desta base
#
# COMPORTAMENTO:
# - Executa durante o build da imagem que herda desta base
# - Expõe a porta definida na variável $SERVER_PORT
# - Documenta qual porta a aplicação utiliza
#
# PRÉ-REQUISITOS:
# - A variável SERVER_PORT deve estar definida na imagem filha
# - A aplicação deve estar configurada para usar a mesma porta
ONBUILD EXPOSE $SERVER_PORT

# INSTRUÇÃO ONBUILD: Define o entrypoint da aplicação
# Esta instrução será executada automaticamente quando uma imagem herdar desta base
#
# COMPORTAMENTO:
# - Executa durante o build da imagem que herda desta base
# - Define o script docker-entrypoint.sh como entrypoint
# - O script será executado pelo dockerize após aguardar dependências
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
#
# PRÉ-REQUISITOS:
# - O script docker-entrypoint.sh deve ter sido copiado e ter permissão de execução
# - A variável JAR_NAME deve estar definida na imagem filha
# - O JAR deve ter sido copiado para o diretório de trabalho
ONBUILD ENTRYPOINT ./docker-entrypoint.sh