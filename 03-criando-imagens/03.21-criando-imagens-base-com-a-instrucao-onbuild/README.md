# Criando Imagens Base com a Instrução ONBUILD

Este guia explica como usar a instrução **ONBUILD** do Docker para criar imagens base reutilizáveis e templates para aplicações similares, reduzindo duplicação de código e facilitando a manutenção.

## 📋 O que é ONBUILD?

A instrução **ONBUILD** é uma funcionalidade do Docker que permite definir comandos que serão executados automaticamente quando uma imagem herda de uma imagem base que contém essas instruções.

### Características Principais:
- **Execução Automática**: Comandos executados durante o build da imagem filha
- **Templates Reutilizáveis**: Permite criar imagens base padronizadas
- **Redução de Duplicação**: Elimina código repetitivo entre Dockerfiles
- **Manutenção Simplificada**: Mudanças na base afetam todas as imagens filhas

## 🔍 Como Funciona o ONBUILD?

### **Fluxo de Execução:**
```bash
# 1. Construir imagem base
docker build -t spring-base:1.0.0 -f spring-base.Dockerfile .

# 2. Usar imagem base em aplicação
FROM spring-base:1.0.0
ENV JAR_NAME=minha-app.jar

# 3. Construir aplicação (ONBUILD executa automaticamente)
docker build -t minha-app:latest -f app.Dockerfile .
```

### **Ordem de Execução:**
1. **Build da imagem base**: Instruções normais são executadas
2. **Build da imagem filha**: Instruções ONBUILD são executadas automaticamente
3. **Resultado**: Imagem completa com todas as configurações

## 🏗️ Sintaxe e Uso

### **Sintaxe Básica:**
```dockerfile
ONBUILD <instrução> <argumentos>
```

### **Instruções Suportadas:**
```dockerfile
ONBUILD ADD <src> <dest>
ONBUILD COPY <src> <dest>
ONBUILD RUN <comando>
ONBUILD ENV <key>=<value>
ONBUILD EXPOSE <port>
ONBUILD VOLUME <path>
ONBUILD USER <user>
ONBUILD WORKDIR <path>
ONBUILD ENTRYPOINT <comando>
ONBUILD CMD <comando>
ONBUILD HEALTHCHECK <opções>
```

### **Exemplo Básico:**
```dockerfile
# Imagem base
FROM node:18-alpine
ONBUILD COPY package*.json ./
ONBUILD RUN npm install
ONBUILD COPY . .
ONBUILD EXPOSE 3000
ONBUILD CMD ["npm", "start"]

# Imagem filha
FROM minha-base:1.0.0
# As instruções ONBUILD são executadas automaticamente
```

## 🎯 Casos de Uso Práticos

### **1. Aplicações Spring Boot:**
```dockerfile
# spring-base.Dockerfile
FROM eclipse-temurin:21-jre-jammy

# Configurações base
RUN groupadd -r spring && useradd -r -g spring spring
RUN apt-get update && apt-get install -y wget && \
    wget -O - https://github.com/jwilder/dockerize/releases/download/v0.9.6/dockerize-linux-amd64-v0.9.6.tar.gz | tar xzf - -C /usr/local/bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
USER spring

# Instruções ONBUILD
ONBUILD COPY build/libs/$JAR_NAME .
ONBUILD COPY --chown=spring:spring docker-entrypoint.sh .
ONBUILD RUN chmod +x docker-entrypoint.sh
ONBUILD HEALTHCHECK --interval=15s --timeout=15s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:$SERVER_PORT/actuator/health | grep -i 'UP' || exit 1
ONBUILD EXPOSE $SERVER_PORT
ONBUILD ENTRYPOINT ./docker-entrypoint.sh
```

### **2. Aplicações Node.js:**
```dockerfile
# node-base.Dockerfile
FROM node:18-alpine

# Configurações base
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Instruções ONBUILD
ONBUILD COPY package*.json ./
ONBUILD RUN npm ci --only=production && npm cache clean --force
ONBUILD COPY --chown=nodejs:nodejs . .
ONBUILD USER nodejs
ONBUILD EXPOSE $PORT
ONBUILD CMD ["npm", "start"]
```

### **3. Aplicações Python:**
```dockerfile
# python-base.Dockerfile
FROM python:3.11-slim

# Configurações base
RUN groupadd -r python && useradd -r -g python python
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instruções ONBUILD
ONBUILD COPY requirements.txt .
ONBUILD RUN pip install --no-cache-dir -r requirements.txt
ONBUILD COPY --chown=python:python . .
ONBUILD USER python
ONBUILD EXPOSE $PORT
ONBUILD CMD ["python", "app.py"]
```

## 🔧 Implementação Completa

### **1. Imagem Base (spring-base.Dockerfile):**
```dockerfile
# Imagem base personalizada para aplicações Spring Boot
FROM eclipse-temurin:21-jre-jammy

# Configurações de timezone e locale
ENV TZ=America/Sao_Paulo \
    LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8

# Instalar dependências
RUN apt-get update && \
    apt-get install -y tzdata locales wget && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen pt_BR.UTF-8 && \
    wget -O - https://github.com/jwilder/dockerize/releases/download/v0.9.6/dockerize-linux-amd64-v0.9.6.tar.gz | tar xzf - -C /usr/local/bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurar usuário não-root
RUN groupadd -r spring && useradd -r -g spring spring
WORKDIR /app
USER spring

# Instruções ONBUILD
ONBUILD COPY build/libs/$JAR_NAME .
ONBUILD COPY --chown=spring:spring docker-entrypoint.sh .
ONBUILD RUN chmod +x docker-entrypoint.sh
ONBUILD HEALTHCHECK --interval=15s --timeout=15s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:$SERVER_PORT/actuator/health | grep -i 'UP' || exit 1
ONBUILD EXPOSE $SERVER_PORT
ONBUILD ENTRYPOINT ./docker-entrypoint.sh
```

### **2. Aplicação que Usa a Base (app.Dockerfile):**
```dockerfile
# Dockerfile que utiliza imagem base com ONBUILD
FROM spring-base:1.0.0

# Configurações específicas da aplicação
ARG ENV=dev
ENV SPRING_PROFILES_ACTIVE=$ENV \
    SERVER_PORT=8081 \
    JAR_NAME=minha-app.jar \
    TZ=America/Sao_Paulo

# As instruções ONBUILD são executadas automaticamente:
# 1. ONBUILD COPY build/libs/$JAR_NAME .
# 2. ONBUILD COPY --chown=spring:spring docker-entrypoint.sh .
# 3. ONBUILD RUN chmod +x docker-entrypoint.sh
# 4. ONBUILD HEALTHCHECK ...
# 5. ONBUILD EXPOSE $SERVER_PORT
# 6. ONBUILD ENTRYPOINT ./docker-entrypoint.sh
```

### **3. Script de Entrypoint (docker-entrypoint.sh):**
```bash
#!/bin/sh
set -e

# Configurações de JVM
if [ -z "$JAVA_OPTS" ]; then
  JAVA_OPTS="-XX:MaxRAMPercentage=70.0 -Djava.security.egd=file:/dev/./urandom"
fi

# Inicialização da aplicação
echo "Iniciando aplicação com perfil: ${SPRING_PROFILES_ACTIVE:-dev}"
echo "Porta configurada: ${SERVER_PORT:-8080}"
echo "Opções JVM: ${JAVA_OPTS}"

# Executar aplicação
exec java $JAVA_OPTS -jar ${JAR_NAME:-app.jar} "$@"
```

## 📊 Vantagens e Desvantagens

### ✅ **Vantagens:**
- **Reutilização**: Templates para aplicações similares
- **Padronização**: Configurações consistentes
- **Manutenção**: Mudanças centralizadas na base
- **Produtividade**: Desenvolvimento mais rápido
- **Qualidade**: Configurações testadas e validadas

### ❌ **Desvantagens:**
- **Complexidade**: Pode ser confuso para iniciantes
- **Debugging**: Mais difícil de debugar problemas
- **Flexibilidade**: Menos flexibilidade para casos específicos
- **Dependências**: Imagens filhas dependem da base
- **Versionamento**: Mudanças na base afetam todas as filhas

## 🚨 Problemas Comuns e Soluções

### **1. Variáveis não Definidas:**
```dockerfile
# Problema: Variável $JAR_NAME não definida
ONBUILD COPY build/libs/$JAR_NAME .
# Solução: Definir na imagem filha
ENV JAR_NAME=minha-app.jar
```

### **2. Arquivos não Encontrados:**
```dockerfile
# Problema: Arquivo não existe no contexto
ONBUILD COPY docker-entrypoint.sh .
# Solução: Garantir que o arquivo existe
# Verificar se docker-entrypoint.sh está no contexto de build
```

### **3. Permissões Incorretas:**
```dockerfile
# Problema: Script sem permissão de execução
ONBUILD COPY docker-entrypoint.sh .
# Solução: Definir permissões
ONBUILD RUN chmod +x docker-entrypoint.sh
```

### **4. Ordem de Execução:**
```dockerfile
# Problema: Instruções em ordem incorreta
ONBUILD RUN chmod +x docker-entrypoint.sh
ONBUILD COPY docker-entrypoint.sh .
# Solução: Corrigir ordem
ONBUILD COPY docker-entrypoint.sh .
ONBUILD RUN chmod +x docker-entrypoint.sh
```

## 🔍 Debugging e Troubleshooting

### **1. Verificar Instruções ONBUILD:**
```bash
# Ver instruções ONBUILD de uma imagem
docker inspect spring-base:1.0.0 | grep -A 10 "OnBuild"

# Ver todas as instruções
docker history spring-base:1.0.0
```

### **2. Build com Logs Detalhados:**
```bash
# Build com logs verbosos
docker build --no-cache --progress=plain -t minha-app:latest .

# Build com debug
DOCKER_BUILDKIT=0 docker build -t minha-app:latest .
```

### **3. Testar Imagem Base:**
```bash
# Testar imagem base isoladamente
docker run --rm spring-base:1.0.0 env

# Verificar configurações
docker run --rm spring-base:1.0.0 ls -la /app
```

## 🏆 Melhores Práticas

### ✅ **Recomendações Gerais:**
1. **Use ONBUILD para templates**: Apenas quando há padrões claros
2. **Documente bem**: Explique o que cada ONBUILD faz
3. **Teste extensivamente**: Valide com diferentes aplicações
4. **Versionamento**: Use tags semânticas para a base
5. **Flexibilidade**: Permita sobrescrever configurações

### ✅ **Estrutura Recomendada:**
```dockerfile
# 1. Configurações base (executadas na construção da base)
FROM base-image
RUN install-dependencies
ENV base-variables

# 2. Instruções ONBUILD (executadas na construção da filha)
ONBUILD COPY application-files .
ONBUILD RUN setup-application
ONBUILD EXPOSE $PORT
ONBUILD CMD ["start-application"]
```

### ✅ **Versionamento:**
```bash
# Tags semânticas para imagem base
spring-base:1.0.0    # Versão estável
spring-base:1.1.0    # Nova funcionalidade
spring-base:2.0.0    # Breaking changes
spring-base:latest   # Última versão
```

## 🔧 Comandos Úteis

### **Construir Imagem Base:**
```bash
# Construir imagem base
docker build -t spring-base:1.0.0 -f spring-base.Dockerfile .

# Construir com tag específica
docker build -t spring-base:1.0.0 -t spring-base:latest -f spring-base.Dockerfile .
```

### **Usar Imagem Base:**
```bash
# Construir aplicação que usa a base
docker build -t minha-app:latest -f app.Dockerfile .

# Construir com argumentos
docker build --build-arg ENV=prod -t minha-app:prod -f app.Dockerfile .
```

### **Verificar ONBUILD:**
```bash
# Ver instruções ONBUILD
docker inspect spring-base:1.0.0 | jq '.[0].Config.OnBuild'

# Ver histórico de construção
docker history spring-base:1.0.0
```

## 📚 Exemplos Avançados

### **1. Múltiplas Bases:**
```dockerfile
# base-java.Dockerfile
FROM eclipse-temurin:21-jre-jammy
ONBUILD COPY build/libs/$JAR_NAME .
ONBUILD EXPOSE $PORT

# base-spring.Dockerfile
FROM base-java:1.0.0
ONBUILD COPY docker-entrypoint.sh .
ONBUILD RUN chmod +x docker-entrypoint.sh
ONBUILD HEALTHCHECK --interval=15s CMD curl -f http://localhost:$PORT/health || exit 1
ONBUILD ENTRYPOINT ./docker-entrypoint.sh

# app.Dockerfile
FROM base-spring:1.0.0
ENV JAR_NAME=minha-app.jar PORT=8080
```

### **2. Docker Compose com ONBUILD:**
```yaml
version: '3.8'
services:
  app1:
    build:
      context: ./app1
      dockerfile: Dockerfile
    environment:
      - JAR_NAME=app1.jar
      - SERVER_PORT=8081

  app2:
    build:
      context: ./app2
      dockerfile: Dockerfile
    environment:
      - JAR_NAME=app2.jar
      - SERVER_PORT=8082
```

### **3. CI/CD com ONBUILD:**
```yaml
# .github/workflows/build.yml
name: Build Applications
on: [push, pull_request]

jobs:
  build-base:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build base image
        run: docker build -t spring-base:1.0.0 -f spring-base.Dockerfile .

  build-apps:
    needs: build-base
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: [app1, app2, app3]
    steps:
      - uses: actions/checkout@v3
      - name: Build application
        run: docker build -t ${{ matrix.app }}:latest -f ${{ matrix.app }}/Dockerfile .
```

## 🎯 Casos de Uso Específicos

### **1. Microserviços:**
```dockerfile
# microservice-base.Dockerfile
FROM eclipse-temurin:21-jre-jammy
ONBUILD COPY build/libs/$SERVICE_NAME.jar .
ONBUILD COPY --chown=app:app entrypoint.sh .
ONBUILD RUN chmod +x entrypoint.sh
ONBUILD EXPOSE $SERVICE_PORT
ONBUILD ENTRYPOINT ./entrypoint.sh
```

### **2. Aplicações Web:**
```dockerfile
# web-base.Dockerfile
FROM nginx:alpine
ONBUILD COPY dist/ /usr/share/nginx/html/
ONBUILD COPY nginx.conf /etc/nginx/nginx.conf
ONBUILD EXPOSE 80
ONBUILD CMD ["nginx", "-g", "daemon off;"]
```

### **3. Aplicações de Dados:**
```dockerfile
# data-base.Dockerfile
FROM postgres:15-alpine
ONBUILD COPY init.sql /docker-entrypoint-initdb.d/
ONBUILD ENV POSTGRES_DB=$DB_NAME
ONBUILD ENV POSTGRES_USER=$DB_USER
ONBUILD ENV POSTGRES_PASSWORD=$DB_PASSWORD
```

## 📖 Recursos Adicionais

- [Docker ONBUILD Documentation](https://docs.docker.com/engine/reference/builder/#onbuild)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/#use-multi-stage-builds)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)

---

**💡 Dica**: Use ONBUILD para criar templates reutilizáveis quando você tem múltiplas aplicações com padrões similares. Isso reduz duplicação de código e facilita a manutenção, mas use com moderação para não criar complexidade desnecessária!
