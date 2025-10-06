# Dockerfile que utiliza imagem base com ONBUILD
# Este arquivo demonstra como usar uma imagem base que contém instruções ONBUILD
# A imagem spring-base:1.0.0 contém todas as configurações base e executa
# automaticamente as instruções ONBUILD quando esta imagem é construída

# Herda de imagem base personalizada com instruções ONBUILD
# A imagem spring-base:1.0.0 contém:
#   - Configurações de segurança (usuário não-root)
#   - Instalação do dockerize
#   - Instruções ONBUILD para copiar JAR e scripts
#   - Configurações de healthcheck e entrypoint
FROM spring-base:1.0.0

# Define argumento de build para o perfil do Spring
# Este argumento será usado para configurar o perfil ativo da aplicação
ARG ENV=dev 

# Define variáveis de ambiente específicas para esta aplicação
# Estas variáveis sobrescrevem ou complementam as da imagem base
# 
# SPRING_PROFILES_ACTIVE: perfil ativo do Spring Boot
#   - Usado pela aplicação para carregar configurações específicas
#   - Valores comuns: dev, prod, test
# SERVER_PORT: porta onde a aplicação irá rodar
#   - Usado pelo Spring Boot para configurar o servidor embarcado
#   - Usado no HEALTHCHECK da imagem base
# JAR_NAME: nome do arquivo JAR da aplicação
#   - Usado pelas instruções ONBUILD da imagem base para copiar o JAR
#   - Deve corresponder ao nome do JAR gerado pelo build
# TZ: configuração de timezone
#   - Define o fuso horário para logs e operações de data/hora
ENV SPRING_PROFILES_ACTIVE=$ENV \
    SERVER_PORT=8081 \
    JAR_NAME=algatransito-api.jar \
    TZ=America/Sao_Paulo

# RELAÇÃO COM spring-base.Dockerfile:
# 
# Quando este Dockerfile é construído, as seguintes instruções ONBUILD da imagem base
# são executadas automaticamente na ordem definida:
#
# 1. ONBUILD COPY build/libs/$JAR_NAME .
#    - Copia build/libs/algatransito-api.jar para /app/
#    - Usa a variável JAR_NAME definida acima
#
# 2. ONBUILD COPY --chown=spring:spring docker-entrypoint.sh .
#    - Copia docker-entrypoint.sh para /app/
#    - Define proprietário como spring:spring
#
# 3. ONBUILD RUN chmod +x docker-entrypoint.sh
#    - Define permissão de execução para o script
#
# 4. ONBUILD HEALTHCHECK --interval=15s --timeout=15s --start-period=10s --retries=3 \
#    CMD curl -f http://localhost:$SERVER_PORT/actuator/health | grep -i 'UP' || exit 1
#    - Configura healthcheck usando SERVER_PORT=8081
#
# 5. ONBUILD EXPOSE $SERVER_PORT
#    - Expõe a porta 8081
#
# 6. ONBUILD ENTRYPOINT ./docker-entrypoint.sh
#    - Define o script como entrypoint
#
# RESULTADO:
# - Imagem completa com todas as configurações base
# - Aplicação pronta para execução
# - Configurações específicas da aplicação (porta 8081, perfil dev)
# - Todas as funcionalidades da imagem base (dockerize, healthcheck, segurança)