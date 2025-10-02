#!/bin/sh
# docker-entrypoint.sh
# Script de inicialização para containers Docker
# Este script é executado pelo dockerize após aguardar dependências
# O dockerize já verificou que o MySQL está disponível antes de executar este script

# Para execução em caso de erro (fail-fast behavior)
set -e

# Configurações de JVM padrão
# Estas configurações são aplicadas se JAVA_OPTS não estiver definida
# MaxRAMPercentage: limita uso de memória a 70% do container (configuração do Dockerfile)
# java.security.egd: melhora performance de geração de números aleatórios
if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS="-XX:MaxRAMPercentage=70.0 -Djava.security.egd=file:/dev/./urandom"
fi

# Inicialização da aplicação
# O dockerize já aguardou o MySQL estar disponível, então podemos iniciar diretamente
# Exibe informações de configuração antes de iniciar
echo "MySQL está disponível! Iniciando AlgaTransito API..."
echo "Perfil ativo: ${SPRING_PROFILES_ACTIVE:-dev}"
echo "Porta configurada: ${SERVER_PORT:-9090}"
echo "Opções JVM: ${JAVA_OPTS}"

# Executa a aplicação Java com todas as configurações
# exec: substitui o processo shell pelo Java (torna o Java PID 1)
# $JAVA_OPTS: opções de JVM configuradas acima
# ${JAR_NAME:-app.jar}: nome do JAR (definido no Dockerfile como algatransito-api.jar)
# "$@": passa todos os argumentos recebidos para a aplicação Java
exec java $JAVA_OPTS -jar ${JAR_NAME:-app.jar} "$@"