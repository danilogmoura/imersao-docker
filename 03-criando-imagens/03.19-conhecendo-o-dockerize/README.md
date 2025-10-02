# Conhecendo o Dockerize

Este guia explica o **Dockerize**, uma ferramenta essencial para aguardar dependências em containers Docker, tornando a inicialização de aplicações mais robusta e confiável.

## 📋 O que é o Dockerize?

O **Dockerize** é uma ferramenta que permite aguardar que dependências (como bancos de dados, APIs, arquivos) estejam disponíveis antes de executar um comando. É especialmente útil em ambientes containerizados onde a ordem de inicialização dos serviços pode variar.

### Características Principais:
- **Aguarda dependências**: TCP, HTTP, arquivos
- **Timeout configurável**: Evita espera infinita
- **Logging automático**: Informa o progresso da espera
- **Multiplataforma**: Linux, Windows, macOS
- **Leve**: Binário único, sem dependências

## 🔍 Problema que Resolve

### ❌ **Sem Dockerize:**
```bash
# Container inicia e falha imediatamente
docker run minha-app:latest
# ERRO: Connection refused to database
```

### ✅ **Com Dockerize:**
```bash
# Container aguarda banco estar disponível
docker run minha-app:latest
# Aguardando MySQL...
# MySQL disponível! Iniciando aplicação...
```

## 🚀 Instalação do Dockerize

### **1. Download Direto:**
```bash
# Baixar e instalar
wget -O - https://github.com/jwilder/dockerize/releases/download/v0.9.6/dockerize-linux-amd64-v0.9.6.tar.gz | tar xzf - -C /usr/local/bin
```

### **2. No Dockerfile:**
```dockerfile
# Instalar dockerize
RUN apt-get update && \
    apt-get install -y wget && \
    wget -O - https://github.com/jwilder/dockerize/releases/download/v0.9.6/dockerize-linux-amd64-v0.9.6.tar.gz | tar xzf - -C /usr/local/bin && \
    apt-get autoremove -yqq --purge wget && \
    rm -rf /var/lib/apt/lists/*
```

### **3. Versões Disponíveis:**
```bash
# Versões mais recentes
v0.9.6  # Mais estável
v0.9.5  # Versão anterior
v0.9.4  # Versão mais antiga
```

## 🎯 Tipos de Dependências Suportadas

### **1. TCP (Bancos de Dados, APIs):**
```bash
# Aguardar MySQL
dockerize -wait tcp://mysql:3306

# Aguardar PostgreSQL
dockerize -wait tcp://postgres:5432

# Aguardar Redis
dockerize -wait tcp://redis:6379

# Aguardar API
dockerize -wait tcp://api-server:8080
```

### **2. HTTP (APIs, Serviços Web):**
```bash
# Aguardar API REST
dockerize -wait http://api-server:8080/health

# Aguardar com autenticação
dockerize -wait http://user:pass@api-server:8080/health

# Aguardar com headers
dockerize -wait http://api-server:8080/health -wait-http-header "Authorization: Bearer token"
```

### **3. Arquivos:**
```bash
# Aguardar arquivo existir
dockerize -wait file:///tmp/ready

# Aguardar arquivo ser removido
dockerize -wait file:///tmp/processing
```

## 🔧 Sintaxe e Opções

### **Sintaxe Básica:**
```bash
dockerize [opções] -wait <dependência> <comando>
```

### **Opções Principais:**
```bash
-wait <dependência>     # Aguarda dependência estar disponível
-timeout <segundos>     # Timeout para espera (padrão: 10s)
-wait-retry-interval <segundos>  # Intervalo entre tentativas (padrão: 1s)
-wait-http-header <header>       # Header HTTP para requisições
```

### **Exemplos de Uso:**
```bash
# Aguardar MySQL com timeout de 60 segundos
dockerize -wait tcp://mysql:3306 -timeout 60s ./start.sh

# Aguardar múltiplas dependências
dockerize -wait tcp://mysql:3306 -wait tcp://redis:6379 ./start.sh

# Aguardar API com header de autenticação
dockerize -wait http://api:8080/health -wait-http-header "Authorization: Bearer token" ./start.sh
```

## 🏗️ Implementação no Dockerfile

### **Dockerfile Completo:**
```dockerfile
FROM eclipse-temurin:21-jre-jammy

# Instalar dockerize
RUN apt-get update && \
    apt-get install -y wget && \
    wget -O - https://github.com/jwilder/dockerize/releases/download/v0.9.6/dockerize-linux-amd64-v0.9.6.tar.gz | tar xzf - -C /usr/local/bin && \
    apt-get autoremove -yqq --purge wget && \
    rm -rf /var/lib/apt/lists/*

# Copiar aplicação
COPY app.jar /app/
COPY start.sh /app/
RUN chmod +x /app/start.sh

# Usar dockerize como entrypoint
ENTRYPOINT ["dockerize", "-wait", "tcp://mysql:3306", "-timeout", "60s", "/app/start.sh"]
```

### **Script de Inicialização:**
```bash
#!/bin/sh
# start.sh
echo "MySQL está disponível! Iniciando aplicação..."
java -jar /app/app.jar
```

## 📊 Comparação: Dockerize vs Alternativas

### **Dockerize vs Netcat:**
| Aspecto | Dockerize | Netcat |
|---------|-----------|---------|
| **Timeout** | ✅ Configurável | ❌ Manual |
| **Retry Logic** | ✅ Automático | ❌ Manual |
| **HTTP Support** | ✅ Nativo | ❌ Não |
| **File Support** | ✅ Nativo | ❌ Não |
| **Logging** | ✅ Automático | ❌ Manual |
| **Simplicidade** | ✅ Alto | ❌ Baixo |

### **Dockerize vs wait-for-it:**
| Aspecto | Dockerize | wait-for-it |
|---------|-----------|-------------|
| **HTTP Support** | ✅ Nativo | ❌ Não |
| **File Support** | ✅ Nativo | ❌ Não |
| **Headers HTTP** | ✅ Suportado | ❌ Não |
| **Manutenção** | ✅ Ativa | ❌ Abandonada |
| **Performance** | ✅ Otimizada | ❌ Básica |

## 🎯 Casos de Uso Práticos

### **1. Aplicação Spring Boot:**
```dockerfile
ENTRYPOINT ["dockerize", "-wait", "tcp://mysql:3306", "-timeout", "60s", "java", "-jar", "app.jar"]
```

### **2. Aplicação Node.js:**
```dockerfile
ENTRYPOINT ["dockerize", "-wait", "tcp://mongodb:27017", "-wait", "tcp://redis:6379", "node", "server.js"]
```

### **3. Aplicação Python:**
```dockerfile
ENTRYPOINT ["dockerize", "-wait", "tcp://postgres:5432", "-wait", "http://api:8080/health", "python", "app.py"]
```

### **4. Múltiplas Dependências:**
```dockerfile
ENTRYPOINT ["dockerize", \
    "-wait", "tcp://mysql:3306", \
    "-wait", "tcp://redis:6379", \
    "-wait", "http://api:8080/health", \
    "-timeout", "120s", \
    "./start.sh"]
```

## 🚨 Problemas Comuns e Soluções

### **1. Timeout Muito Baixo:**
```bash
# Problema: Timeout muito baixo
dockerize -wait tcp://mysql:3306 -timeout 5s ./start.sh
# Solução: Aumentar timeout
dockerize -wait tcp://mysql:3306 -timeout 60s ./start.sh
```

### **2. Dependência Incorreta:**
```bash
# Problema: Host incorreto
dockerize -wait tcp://localhost:3306 ./start.sh
# Solução: Usar nome do serviço
dockerize -wait tcp://mysql:3306 ./start.sh
```

### **3. Porta Incorreta:**
```bash
# Problema: Porta incorreta
dockerize -wait tcp://mysql:3307 ./start.sh
# Solução: Verificar porta correta
dockerize -wait tcp://mysql:3306 ./start.sh
```

### **4. HTTP sem Endpoint:**
```bash
# Problema: Endpoint não existe
dockerize -wait http://api:8080 ./start.sh
# Solução: Usar endpoint de health
dockerize -wait http://api:8080/health ./start.sh
```

## 🔍 Debugging e Troubleshooting

### **1. Verificar Dependências:**
```bash
# Testar conectividade manualmente
docker exec -it container_name nc -z mysql 3306

# Verificar logs do dockerize
docker logs container_name
```

### **2. Modo Verbose:**
```bash
# Habilitar logs detalhados
dockerize -wait tcp://mysql:3306 -timeout 60s -wait-retry-interval 2s ./start.sh
```

### **3. Testar Localmente:**
```bash
# Testar dockerize localmente
dockerize -wait tcp://localhost:3306 -timeout 10s echo "MySQL disponível!"
```

## 🏆 Melhores Práticas

### ✅ **Recomendações Gerais:**
1. **Use timeout adequado**: 60-120 segundos para bancos de dados
2. **Teste dependências**: Verifique se os serviços estão acessíveis
3. **Use nomes de serviços**: Não use localhost em containers
4. **Monitore logs**: Acompanhe o processo de espera
5. **Configure retry interval**: Ajuste conforme necessário

### ✅ **Configurações Recomendadas:**
```bash
# Para bancos de dados
-timeout 60s -wait-retry-interval 2s

# Para APIs
-timeout 30s -wait-retry-interval 1s

# Para arquivos
-timeout 10s -wait-retry-interval 1s
```

### ✅ **Estrutura de Dockerfile:**
```dockerfile
# 1. Instalar dockerize
RUN apt-get update && apt-get install -y wget && \
    wget -O - https://github.com/jwilder/dockerize/releases/download/v0.9.6/dockerize-linux-amd64-v0.9.6.tar.gz | tar xzf - -C /usr/local/bin && \
    apt-get autoremove -yqq --purge wget && \
    rm -rf /var/lib/apt/lists/*

# 2. Copiar aplicação
COPY app.jar /app/

# 3. Configurar entrypoint
ENTRYPOINT ["dockerize", "-wait", "tcp://mysql:3306", "-timeout", "60s", "java", "-jar", "/app/app.jar"]
```

## 🔧 Comandos Úteis

### **Testar Dependências:**
```bash
# Testar TCP
dockerize -wait tcp://mysql:3306 -timeout 10s echo "MySQL OK"

# Testar HTTP
dockerize -wait http://api:8080/health -timeout 10s echo "API OK"

# Testar arquivo
dockerize -wait file:///tmp/ready -timeout 10s echo "Arquivo OK"
```

### **Debugging:**
```bash
# Ver logs do container
docker logs container_name

# Executar comando no container
docker exec -it container_name /bin/sh

# Testar conectividade
docker exec -it container_name nc -z mysql 3306
```

## 📚 Recursos Adicionais

- [Dockerize GitHub](https://github.com/jwilder/dockerize)
- [Dockerize Releases](https://github.com/jwilder/dockerize/releases)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Orchestration](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

## 🎯 Exemplos Avançados

### **1. Docker Compose com Dockerize:**
```yaml
version: '3.8'
services:
  app:
    build: .
    depends_on:
      - mysql
      - redis
    environment:
      - DB_HOST=mysql
      - REDIS_HOST=redis
    command: dockerize -wait tcp://mysql:3306 -wait tcp://redis:6379 java -jar app.jar

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=app

  redis:
    image: redis:7-alpine
```

### **2. Kubernetes com Init Container:**
```yaml
apiVersion: v1
kind: Pod
spec:
  initContainers:
  - name: wait-for-db
    image: jwilder/dockerize:latest
    command: ['dockerize', '-wait', 'tcp://mysql:3306', '-timeout', '60s']
  containers:
  - name: app
    image: minha-app:latest
```

---

**💡 Dica**: O Dockerize é uma ferramenta essencial para containers robustos em produção. Use-o para garantir que suas aplicações aguardem dependências de forma confiável e eficiente!
