# Organizando a Inicialização com Docker Entrypoint

Este guia explica o conceito e uso de scripts de entrypoint no Docker, mostrando como organizar e automatizar a inicialização de containers de forma robusta e flexível.

## 📋 O que é um Docker Entrypoint?

O **Docker Entrypoint** é um script executado quando o container é iniciado, permitindo:
- **Configuração dinâmica** antes da execução da aplicação
- **Verificações de dependências** (banco de dados, serviços externos)
- **Inicialização de recursos** necessários
- **Flexibilidade** para diferentes modos de execução

### Diferença entre ENTRYPOINT e CMD:
- **ENTRYPOINT**: Comando fixo que sempre executa
- **CMD**: Argumentos padrão que podem ser sobrescritos
- **ENTRYPOINT + CMD**: Combinação ideal para flexibilidade

## 🔍 Análise do Script docker-entrypoint.sh

### Estrutura do Script
```bash
#!/bin/sh
# docker-entrypoint.sh

set -e

# Função para verificar a disponibilidade do MySQL
check_mysql() {
  echo "Verificando conexão com MySQL em ${DB_HOST}..."
  max_attempts=10
  attempt=0
  
  while [ $attempt -lt $max_attempts ]; do
    if nc -z ${DB_HOST:-localhost} 3306 2>/dev/null; then
      echo "MySQL está disponível!"
      return 0
    fi
    
    attempt=$((attempt+1))
    echo "Tentativa $attempt/$max_attempts, aguardando MySQL ($DB_HOST)..."
    sleep 2
  done
  
  echo "Não foi possível conectar ao MySQL após $max_attempts tentativas"
  return 1
}

# Configurações de JVM padrão
if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS="-XX:MaxRAMPercentage=70.0 -Djava.security.egd=file:/dev/./urandom"
fi

# Se o primeiro argumento for "check-db", apenas verificar banco de dados
if [ "$1" = "check-db" ]; then
  check_mysql
  exit $?
fi

# Para o comportamento padrão, verificar banco de dados antes de iniciar a aplicação
if [ "$SKIP_DB_CHECK" != "true" ] && [ "$SPRING_PROFILES_ACTIVE" = "prod" ]; then
  check_mysql
fi

# Iniciar aplicação com as variáveis e argumentos configurados
echo "Iniciando AlgaTransito API com perfil: ${SPRING_PROFILES_ACTIVE:-dev}"
echo "Porta configurada: ${SERVER_PORT:-9090}"
echo "Opções JVM: ${JAVA_OPTS}"

# Executar aplicação com configurações
exec java $JAVA_OPTS -jar ${JAR_NAME:-app.jar} "$@"
```

## 🛠️ Componentes do Script

### 1. Shebang e Configurações
```bash
#!/bin/sh
# docker-entrypoint.sh

set -e
```

**Explicação:**
- `#!/bin/sh`: Especifica o interpretador shell
- `set -e`: Para execução em caso de erro (fail-fast)

### 2. Função de Verificação de Dependências
```bash
check_mysql() {
  echo "Verificando conexão com MySQL em ${DB_HOST}..."
  max_attempts=10
  attempt=0
  
  while [ $attempt -lt $max_attempts ]; do
    if nc -z ${DB_HOST:-localhost} 3306 2>/dev/null; then
      echo "MySQL está disponível!"
      return 0
    fi
    
    attempt=$((attempt+1))
    echo "Tentativa $attempt/$max_attempts, aguardando MySQL ($DB_HOST)..."
    sleep 2
  done
  
  echo "Não foi possível conectar ao MySQL após $max_attempts tentativas"
  return 1
}
```

**Funcionalidades:**
- **Verificação de conectividade**: Usa `nc` (netcat) para testar porta
- **Retry logic**: Tenta até 10 vezes com intervalo de 2 segundos
- **Variáveis de ambiente**: Usa `${DB_HOST:-localhost}` com fallback
- **Logging**: Informa progresso das tentativas

### 3. Configurações de JVM
```bash
if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS="-XX:MaxRAMPercentage=70.0 -Djava.security.egd=file:/dev/./urandom"
fi
```

**Configurações:**
- **MaxRAMPercentage**: Limita uso de memória a 70% do container
- **java.security.egd**: Melhora performance de geração de números aleatórios

### 4. Modos de Execução
```bash
# Modo de verificação de banco
if [ "$1" = "check-db" ]; then
  check_mysql
  exit $?
fi

# Verificação automática em produção
if [ "$SKIP_DB_CHECK" != "true" ] && [ "$SPRING_PROFILES_ACTIVE" = "prod" ]; then
  check_mysql
fi
```

**Modos disponíveis:**
- **check-db**: Apenas verifica banco de dados
- **padrão**: Verifica banco (se em produção) e inicia aplicação
- **SKIP_DB_CHECK**: Permite pular verificação de banco

### 5. Execução da Aplicação
```bash
echo "Iniciando AlgaTransito API com perfil: ${SPRING_PROFILES_ACTIVE:-dev}"
echo "Porta configurada: ${SERVER_PORT:-9090}"
echo "Opções JVM: ${JAVA_OPTS}"

exec java $JAVA_OPTS -jar ${JAR_NAME:-app.jar} "$@"
```

**Características:**
- **Logging**: Informa configurações antes de iniciar
- **exec**: Substitui o processo shell pelo Java (PID 1)
- **"$@"**: Passa todos os argumentos para a aplicação

## 🎯 Vantagens do Entrypoint Script

### ✅ Benefícios:
1. **Inicialização robusta**: Verifica dependências antes de iniciar
2. **Flexibilidade**: Diferentes modos de execução
3. **Configuração dinâmica**: Ajusta parâmetros baseado no ambiente
4. **Logging**: Informa o que está acontecendo
5. **Fail-fast**: Para imediatamente em caso de erro

### ✅ Casos de Uso:
- **Verificação de banco de dados** antes de iniciar aplicação
- **Configuração de variáveis** baseada no ambiente
- **Inicialização de recursos** necessários
- **Modos de execução** diferentes (dev, prod, test)

## 🚀 Exemplos de Uso

### 1. Execução Normal
```bash
# Inicia aplicação com verificação de banco (se em produção)
docker run -e SPRING_PROFILES_ACTIVE=prod minha-app:latest
```

### 2. Apenas Verificar Banco
```bash
# Apenas verifica se o banco está disponível
docker run minha-app:latest check-db
```

### 3. Pular Verificação de Banco
```bash
# Pula verificação de banco de dados
docker run -e SKIP_DB_CHECK=true minha-app:latest
```

### 4. Configurações Customizadas
```bash
# Com configurações personalizadas
docker run \
  -e DB_HOST=mysql-server \
  -e JAVA_OPTS="-Xmx512m" \
  -e SPRING_PROFILES_ACTIVE=prod \
  minha-app:latest
```

## 🔧 Configuração no Dockerfile

### Dockerfile Multi-stage Otimizado com Entrypoint
```dockerfile
## STAGE BUILD - Primeira etapa: compilação da aplicação
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /app

# OTIMIZAÇÃO 1: Copia apenas arquivos de dependências primeiro
# Isso permite aproveitar cache do Docker quando apenas código muda
COPY build.gradle gradle.properties gradlew gradlew.bat ./
COPY gradle/ gradle/

# OTIMIZAÇÃO 2: Baixa dependências (aproveita cache se build.gradle não mudou)
RUN gradle dependencies --no-daemon --build-cache --parallel

# OTIMIZAÇÃO 3: Copia código fonte apenas depois das dependências
COPY src/ src/

# OTIMIZAÇÃO 4: Build com configurações otimizadas
RUN gradle bootJar --no-daemon --build-cache --parallel --no-build-scan

## STAGE PRODUCTION - Segunda etapa: imagem de produção
FROM eclipse-temurin:21-jre-jammy

# Instalar dependências necessárias para o entrypoint
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Copiar aplicação e script de entrypoint
COPY --from=build /app/build/libs/app.jar /app/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Configurar entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["java", "-jar", "/app/app.jar"]
```

## 🚀 Otimizações de Performance

### ✅ Otimizações de Build
1. **Cache de Dependências**: Copie arquivos de dependências primeiro
2. **Build Paralelo**: Use `--parallel` para compilação simultânea
3. **Cache do Gradle**: Use `--build-cache` para reutilizar builds
4. **Sem Daemon**: Use `--no-daemon` em containers
5. **Multi-stage**: Separe build de produção

### ✅ Otimizações de Runtime
1. **JVM Otimizada**: Configure `-XX:MaxRAMPercentage=70.0`
2. **Entropy**: Use `-Djava.security.egd=file:/dev/./urandom`
3. **Verificações Inteligentes**: Verifique dependências apenas quando necessário
4. **Logging Eficiente**: Evite logs desnecessários em produção

### 📊 Comparação de Performance
```bash
# Build Tradicional
COPY . .
RUN gradle bootJar
# Tempo: ~60-90 segundos

# Build Otimizado
COPY build.gradle gradlew ./
RUN gradle dependencies --no-daemon --build-cache --parallel
COPY src/ src/
RUN gradle bootJar --no-daemon --build-cache --parallel --no-build-scan
# Tempo: ~15-45 segundos (50-70% mais rápido)
```

### 🔧 Flags de Otimização do Gradle
```bash
# Flags explicadas:
--no-daemon          # Não inicia daemon (mais rápido em containers)
--build-cache        # Usa cache de build do Gradle
--parallel           # Compila em paralelo (usa todos os cores)
--no-build-scan      # Desabilita build scan (mais rápido)
--no-configuration-cache # Desabilita cache de configuração (opcional)
```

### 🎯 Estratégias de Cache
```dockerfile
# 1. Cache de Dependências (Layer Caching)
COPY build.gradle gradlew ./
RUN gradle dependencies --no-daemon --build-cache --parallel

# 2. Cache de Código Fonte
COPY src/ src/
RUN gradle bootJar --no-daemon --build-cache --parallel

# 3. Cache Persistente (Opcional)
VOLUME /root/.gradle
```

### 🚀 BuildKit e Cache Avançado
```bash
# Habilitar BuildKit
export DOCKER_BUILDKIT=1

# Build com cache local
docker build \
  --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=type=local,dest=/tmp/.buildx-cache \
  -t minha-app .

# Build com cache registry
docker build \
  --cache-from=type=registry,ref=minha-app:cache \
  --cache-to=type=registry,ref=minha-app:cache \
  -t minha-app .
```

## 🏆 Melhores Práticas

### ✅ Recomendações Gerais
1. **Use `set -e`**: Para parar em caso de erro
2. **Use `exec`**: Para substituir o processo shell
3. **Logging adequado**: Informe o que está acontecendo
4. **Verificações robustas**: Teste dependências antes de iniciar
5. **Flexibilidade**: Permita diferentes modos de execução

### ✅ Padrões de Nomenclatura
```bash
# Nomes comuns para scripts de entrypoint
docker-entrypoint.sh    # Mais popular
entrypoint.sh          # Simples
init.sh               # Para inicialização
start.sh              # Para início
run.sh                # Para execução
```

### ✅ Estrutura Recomendada
```bash
#!/bin/sh
set -e

# 1. Funções auxiliares
check_dependencies() { ... }
configure_environment() { ... }

# 2. Configurações padrão
if [ -z "$VAR" ]; then
  VAR="default_value"
fi

# 3. Modos de execução
if [ "$1" = "mode1" ]; then
  # Lógica para mode1
  exit 0
fi

# 4. Verificações
check_dependencies

# 5. Execução principal
exec main_command "$@"
```

## 🚨 Problemas Comuns e Soluções

### 1. Script não executa
```bash
# Problema: Permission denied
# Solução: Dar permissão de execução
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
```

### 2. Variáveis não definidas
```bash
# Problema: Variável não existe
# Solução: Usar fallback
${VAR:-default_value}
```

### 3. Processo não substituído
```bash
# Problema: Shell continua rodando
# Solução: Usar exec
exec java -jar app.jar "$@"
```

### 4. Verificações muito lentas
```bash
# Problema: Timeout muito longo
# Solução: Ajustar tentativas e intervalos
max_attempts=5
sleep 1
```

## 🔍 Exemplos Avançados

### 1. Entrypoint para Aplicação Node.js
```bash
#!/bin/sh
set -e

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
  echo "Instalando dependências..."
  npm install
fi

# Verificar banco de dados
if [ "$NODE_ENV" = "production" ]; then
  echo "Verificando banco de dados..."
  until nc -z $DB_HOST $DB_PORT; do
    echo "Aguardando banco de dados..."
    sleep 2
  done
fi

exec node server.js "$@"
```

### 2. Entrypoint para Aplicação Python
```bash
#!/bin/sh
set -e

# Ativar ambiente virtual se existir
if [ -f "venv/bin/activate" ]; then
  . venv/bin/activate
fi

# Executar migrações se necessário
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "Executando migrações..."
  python manage.py migrate
fi

exec python app.py "$@"
```

### 3. Entrypoint para Aplicação Go
```bash
#!/bin/sh
set -e

# Verificar se o binário existe
if [ ! -f "app" ]; then
  echo "Binário não encontrado, compilando..."
  go build -o app .
fi

# Verificar dependências
if [ "$CHECK_DEPS" = "true" ]; then
  echo "Verificando dependências..."
  # Lógica de verificação
fi

exec ./app "$@"
```

## 📚 Recursos Adicionais

- [Docker ENTRYPOINT Documentation](https://docs.docker.com/engine/reference/builder/#entrypoint)
- [Docker CMD vs ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact)
- [Best Practices for Docker Entrypoints](https://docs.docker.com/develop/dev-best-practices/)
- [Shell Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)

## 🔧 Comandos Úteis

```bash
# Testar script localmente
./docker-entrypoint.sh check-db

# Executar container em modo debug
docker run -it --entrypoint /bin/sh minha-app:latest

# Ver logs do entrypoint
docker logs container_name

# Executar comando específico
docker run minha-app:latest check-db

# Verificar variáveis de ambiente
docker run -e VAR=value minha-app:latest env
```

---

**💡 Dica**: Scripts de entrypoint são essenciais para containers robustos em produção. Use-os para verificar dependências, configurar ambiente e garantir inicialização adequada da aplicação!
