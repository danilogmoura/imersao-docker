#!/bin/sh
# docker-entrypoint.sh
# Script de inicialização para containers Docker
# Este script é executado pelo ENTRYPOINT definido no Dockerfile
# Permite verificação de dependências e configuração antes da aplicação

# Para execução em caso de erro (fail-fast behavior)
set -e

# Função para verificar a disponibilidade do MySQL
# Esta função é essencial para garantir que o banco esteja disponível
# antes de iniciar a aplicação Spring Boot
check_mysql() {
  echo "Verificando conexão com MySQL em ${DB_HOST}..."
  max_attempts=10  # Número máximo de tentativas
  attempt=0        # Contador de tentativas
  
  # Loop de retry com verificação de conectividade
  while [ $attempt -lt $max_attempts ]; do
    # Usa netcat (nc) instalado no Dockerfile para testar porta 3306
    # 2>/dev/null: redireciona stderr para /dev/null (silencia erros)
    if nc -z ${DB_HOST:-localhost} 3306 2>/dev/null; then
      echo "MySQL está disponível!"
      return 0  # Sucesso: banco está acessível
    fi
    
    # Incrementa contador e aguarda antes da próxima tentativa
    attempt=$((attempt+1))
    echo "Tentativa $attempt/$max_attempts, aguardando MySQL ($DB_HOST)..."
    sleep 2  # Aguarda 2 segundos entre tentativas
  done
  
  # Falha: não conseguiu conectar após todas as tentativas
  echo "Não foi possível conectar ao MySQL após $max_attempts tentativas"
  return 1  # Falha: banco não está acessível
}

# Configurações de JVM padrão
# Estas configurações são aplicadas se JAVA_OPTS não estiver definida
# MaxRAMPercentage: limita uso de memória a 70% do container (configuração do Dockerfile)
# java.security.egd: melhora performance de geração de números aleatórios
if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS="-XX:MaxRAMPercentage=70.0 -Djava.security.egd=file:/dev/./urandom"
fi

# MODO 1: Verificação isolada de banco de dados
# Permite testar conectividade com banco sem iniciar a aplicação
# Uso: docker run minha-app:latest check-db
if [ "$1" = "check-db" ]; then
  echo "Modo de verificação de banco de dados ativado"
  check_mysql
  exit $?  # Retorna o código de saída da verificação
fi

# MODO 2: Verificação automática em produção
# Verifica banco de dados apenas se:
# - SKIP_DB_CHECK não for "true" (permitir pular verificação)
# - SPRING_PROFILES_ACTIVE for "prod" (apenas em produção)
# Esta lógica garante que a aplicação só inicie se o banco estiver disponível
if [ "$SKIP_DB_CHECK" != "true" ] && [ "$SPRING_PROFILES_ACTIVE" = "prod" ]; then
  echo "Verificação automática de banco de dados em produção"
  check_mysql
fi

# MODO 3: Inicialização da aplicação (comportamento padrão)
# Exibe informações de configuração antes de iniciar
echo "Iniciando AlgaTransito API com perfil: ${SPRING_PROFILES_ACTIVE:-dev}"
echo "Porta configurada: ${SERVER_PORT:-9090}"
echo "Opções JVM: ${JAVA_OPTS}"

# Executa a aplicação Java com todas as configurações
# exec: substitui o processo shell pelo Java (torna o Java PID 1)
# $JAVA_OPTS: opções de JVM configuradas acima
# ${JAR_NAME:-app.jar}: nome do JAR (definido no Dockerfile como algatransito-api.jar)
# "$@": passa todos os argumentos recebidos para a aplicação Java
exec java $JAVA_OPTS -jar ${JAR_NAME:-app.jar} "$@"