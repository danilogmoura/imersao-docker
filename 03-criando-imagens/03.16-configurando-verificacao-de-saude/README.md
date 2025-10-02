# Configurando Verificações de Saúde (HEALTHCHECK)

Este guia explica como configurar e utilizar a instrução `HEALTHCHECK` no Docker para monitorar a saúde das aplicações em containers.

## 📋 O que é HEALTHCHECK?

O `HEALTHCHECK` é uma instrução do Docker que permite definir um comando para verificar se um container está funcionando corretamente. Ele é executado periodicamente pelo Docker daemon para determinar o status de saúde do container.

### Status de Saúde:
- **healthy**: Container está funcionando corretamente
- **unhealthy**: Container não está respondendo adequadamente
- **starting**: Container ainda está inicializando

## 🎯 Por que Usar HEALTHCHECK?

### Vantagens:
- ✅ **Monitoramento automático**: Docker verifica a saúde automaticamente
- ✅ **Orquestração inteligente**: Kubernetes/Docker Swarm podem tomar decisões baseadas na saúde
- ✅ **Debugging facilitado**: Identifica problemas de saúde rapidamente
- ✅ **Deploy seguro**: Evita tráfego para containers não saudáveis
- ✅ **Recuperação automática**: Permite restart automático de containers

### Casos de Uso:
- **Aplicações web**: Verificar se a API está respondendo
- **Bancos de dados**: Verificar se o banco está aceitando conexões
- **Microserviços**: Monitorar dependências e recursos
- **Load balancers**: Determinar quais containers receber tráfego

## 🔍 Análise do Dockerfile

### HEALTHCHECK Configurado
```dockerfile
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
```

## 🛠️ Sintaxe do HEALTHCHECK

### Sintaxe Básica
```dockerfile
HEALTHCHECK [OPTIONS] CMD command
```

### Opções Disponíveis
- **--interval=DURATION**: Intervalo entre verificações (padrão: 30s)
- **--timeout=DURATION**: Timeout para cada verificação (padrão: 30s)
- **--start-period=DURATION**: Período de inicialização (padrão: 0s)
- **--retries=N**: Número de tentativas antes de marcar como unhealthy (padrão: 3)

### Códigos de Retorno
- **0**: Container está saudável (healthy)
- **1**: Container não está saudável (unhealthy)

## 🚀 Exemplos Práticos

### 1. Aplicação Web (Spring Boot)
```dockerfile
# Verificação via endpoint de health
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1
```

### 2. Aplicação Node.js
```dockerfile
# Verificação via endpoint customizado
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

### 3. Banco de Dados (PostgreSQL)
```dockerfile
# Verificação de conexão com banco
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pg_isready -U postgres || exit 1
```

### 4. Banco de Dados (MySQL)
```dockerfile
# Verificação de conexão MySQL
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD mysqladmin ping -h localhost || exit 1
```

### 5. Aplicação Python (Flask)
```dockerfile
# Verificação via endpoint de health
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1
```

### 6. Verificação de Arquivo
```dockerfile
# Verificação de arquivo de status
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD test -f /app/status.txt || exit 1
```

### 7. Verificação de Processo
```dockerfile
# Verificação de processo específico
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f "java.*app.jar" || exit 1
```

## 🔧 Configurações Avançadas

### 1. HEALTHCHECK com Script Personalizado
```dockerfile
# Copiar script de health check
COPY healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck.sh

# Usar script personalizado
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh
```

### 2. HEALTHCHECK com Múltiplas Verificações
```dockerfile
# Script que verifica múltiplos aspectos
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health && \
        curl -f http://localhost:8080/actuator/info && \
        test -f /app/ready.txt || exit 1
```

### 3. HEALTHCHECK com Variáveis de Ambiente
```dockerfile
# Usar variáveis de ambiente no health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:${SERVER_PORT}/actuator/health || exit 1
```

## 📊 Monitoramento e Verificação

### Verificar Status de Saúde
```bash
# Verificar status de todos os containers
docker ps

# Verificar status detalhado
docker inspect container_name | grep -A 10 "Health"

# Verificar logs de health check
docker inspect container_name | grep -A 5 "Health"
```

### Exemplo de Saída
```json
"Health": {
    "Status": "healthy",
    "FailingStreak": 0,
    "Log": [
        {
            "Start": "2023-10-02T03:43:53.716Z",
            "End": "2023-10-02T03:44:08.716Z",
            "ExitCode": 0,
            "Output": "{\"status\":\"UP\"}\n"
        }
    ]
}
```

## 🚨 Problemas Comuns e Soluções

### 1. HEALTHCHECK sempre falha
```bash
# Problema: Container sempre unhealthy
# Solução: Verificar se o comando está correto
docker exec container_name curl -f http://localhost:8080/actuator/health
```

### 2. HEALTHCHECK muito lento
```bash
# Problema: Verificações demoram muito
# Solução: Ajustar timeout e interval
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=2
```

### 3. HEALTHCHECK falha durante startup
```bash
# Problema: Falha durante inicialização
# Solução: Aumentar start-period
HEALTHCHECK --start-period=120s
```

### 4. Comando não encontrado
```bash
# Problema: curl não encontrado
# Solução: Instalar dependências
RUN apk add --no-cache curl
```

## 🏆 Melhores Práticas

### ✅ Recomendações Gerais
1. **Use endpoints dedicados** para health check
2. **Configure start-period** adequado para sua aplicação
3. **Use timeouts apropriados** para evitar falsos positivos
4. **Teste o comando** manualmente antes de usar
5. **Monitore os logs** de health check

### ✅ Configurações Recomendadas

#### Aplicações Web
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1
```

#### Bancos de Dados
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pg_isready -U postgres || exit 1
```

#### Microserviços
```dockerfile
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

## 🔍 Endpoints de Health Check

### Spring Boot Actuator
```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always
```

### Node.js (Express)
```javascript
// health.js
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});
```

### Python (Flask)
```python
# health.py
@app.route('/health')
def health():
    return {'status': 'UP'}, 200
```

## 🚀 Integração com Orquestração

### Docker Compose
```yaml
version: '3.8'
services:
  app:
    build: .
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### Kubernetes
```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: minha-app:latest
    livenessProbe:
      httpGet:
        path: /actuator/health
        port: 8080
      initialDelaySeconds: 60
      periodSeconds: 30
      timeoutSeconds: 10
      failureThreshold: 3
```

## 📚 Recursos Adicionais

- [Docker HEALTHCHECK Documentation](https://docs.docker.com/engine/reference/builder/#healthcheck)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Docker Compose Health Checks](https://docs.docker.com/compose/compose-file/compose-file-v3/#healthcheck)

## 🔧 Comandos Úteis

```bash
# Verificar status de saúde
docker ps
docker inspect container_name | grep -A 10 "Health"

# Executar health check manualmente
docker exec container_name curl -f http://localhost:8080/actuator/health

# Ver logs de health check
docker logs container_name

# Testar comando de health check
docker run --rm minha-app curl -f http://localhost:8080/actuator/health

# Verificar health check em Docker Compose
docker-compose ps
docker-compose exec app curl -f http://localhost:8080/actuator/health
```

---

**💡 Dica**: HEALTHCHECK é essencial para aplicações em produção. Configure verificações adequadas para garantir que seus containers estejam sempre saudáveis e prontos para receber tráfego!
