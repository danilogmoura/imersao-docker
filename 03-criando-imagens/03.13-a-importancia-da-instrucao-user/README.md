# A Importância da Instrução USER no Docker

Este exemplo demonstra a importância da instrução `USER` no Docker, mostrando como executar aplicações com usuários não-root para melhorar a segurança e seguir as melhores práticas.

## 📋 O que é a instrução USER?

A instrução `USER` define **qual usuário** executará os comandos subsequentes no container. Por padrão, os containers executam como **root** (usuário com privilégios administrativos), o que representa riscos de segurança.

## 🚨 Problemas de Segurança sem USER

### ❌ Container executando como root
```dockerfile
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY app.jar .
ENTRYPOINT java -jar app.jar
```

**Problemas:**
- **Privilégios elevados**: Aplicação executa com permissões de root
- **Vulnerabilidades**: Se a aplicação for comprometida, atacante tem acesso total
- **Conformidade**: Não atende a padrões de segurança corporativos
- **Auditoria**: Dificulta rastreamento de ações

## ✅ Solução: Usando a instrução USER

### 1. Criando um usuário não-root
```dockerfile
FROM eclipse-temurin:21-jre-jammy

# Cria um usuário não-root para executar a aplicação
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Define o diretório de trabalho
WORKDIR /app

# Copia a aplicação
COPY app.jar .

# Muda a propriedade dos arquivos para o usuário appuser
RUN chown -R appuser:appuser /app

# Muda para o usuário não-root
USER appuser

# Executa a aplicação
ENTRYPOINT java -jar app.jar
```

### 2. Usando usuário existente (recomendado)
```dockerfile
FROM eclipse-temurin:21-jre-jammy

# Usa usuário não-root existente na imagem
USER 1001

WORKDIR /app
COPY app.jar .
ENTRYPOINT java -jar app.jar
```

## 🔍 Análise do Dockerfile Atual

```dockerfile
## STAGE BUILD - Primeira etapa: compilação da aplicação
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /app
COPY . .
RUN gradle bootJar

## STAGE PRODUCTION - Segunda etapa: imagem de produção
FROM eclipse-temurin:21-jre-jammy
ARG PROFILE
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$PROFILE
WORKDIR /app
COPY --from=build /app/build/libs/$JAR_NAME .
EXPOSE $SERVER_PORT
ENTRYPOINT java -jar $JAR_NAME
```

**⚠️ Problema**: Este Dockerfile executa como root!

## 🛠️ Dockerfile Melhorado com USER

```dockerfile
## STAGE BUILD - Primeira etapa: compilação da aplicação
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /app
COPY . .
RUN gradle bootJar

## STAGE PRODUCTION - Segunda etapa: imagem de produção
FROM eclipse-temurin:21-jre-jammy

# Cria usuário não-root para segurança
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Define argumento de build para o perfil do Spring
ARG PROFILE

# Define variáveis de ambiente
ENV JAR_NAME=algatransito-api.jar \ 
    SERVER_PORT=8080 \
    SPRING_PROFILES_ACTIVE=$PROFILE

# Define o diretório de trabalho
WORKDIR /app

# Copia o JAR compilado
COPY --from=build /app/build/libs/$JAR_NAME .

# Muda propriedade dos arquivos para o usuário não-root
RUN chown -R appuser:appuser /app

# Muda para usuário não-root
USER appuser

# Expõe a porta
EXPOSE $SERVER_PORT

# Executa a aplicação
ENTRYPOINT java -jar $JAR_NAME
```

## ⚖️ Comparação: Com vs Sem USER

| Aspecto | Sem USER (root) | Com USER (não-root) |
|---------|-----------------|---------------------|
| **Segurança** | ❌ Alto risco | ✅ Baixo risco |
| **Privilégios** | ❌ Administrativos | ✅ Limitados |
| **Conformidade** | ❌ Não atende | ✅ Atende padrões |
| **Auditoria** | ❌ Difícil | ✅ Fácil |
| **Vulnerabilidades** | ❌ Críticas | ✅ Mitigadas |

## 🎯 Tipos de Usuários

### 1. Usuário por ID numérico
```dockerfile
USER 1001
```
**Vantagens:**
- ✅ Não depende de usuário existente
- ✅ Funciona em qualquer imagem base
- ✅ Padrão em Kubernetes/OpenShift

### 2. Usuário por nome
```dockerfile
USER appuser
```
**Vantagens:**
- ✅ Mais legível
- ✅ Fácil de identificar
- ✅ Pode ter grupos específicos

### 3. Usuário existente na imagem
```dockerfile
USER nobody
```
**Vantagens:**
- ✅ Já existe na imagem
- ✅ Não precisa criar
- ✅ Otimizado pela distribuição

## 🏆 Melhores Práticas

### ✅ Recomendações Gerais
1. **Sempre use USER** em imagens de produção
2. **Use IDs numéricos** para compatibilidade
3. **Crie usuário específico** quando necessário
4. **Mude propriedade** dos arquivos antes do USER
5. **Teste permissões** antes de fazer deploy

### ✅ Padrões por Tecnologia

#### Java/Spring Boot
```dockerfile
USER 1001
```

#### Node.js
```dockerfile
USER node
```

#### Python
```dockerfile
USER 1001
```

#### Nginx
```dockerfile
USER nginx
```

## 🚨 Problemas Comuns e Soluções

### 1. Problema: Permissão negada
```bash
# Erro
java.io.FileNotFoundException: /app/logs/app.log (Permission denied)
```

**Solução:**
```dockerfile
# Muda propriedade antes do USER
RUN chown -R appuser:appuser /app
USER appuser
```

### 2. Problema: Porta privilegiada
```bash
# Erro
java.net.BindException: Permission denied (bind)
```

**Solução:**
```dockerfile
# Use porta não-privilegiada (> 1024)
EXPOSE 8080
```

### 3. Problema: Usuário não existe
```bash
# Erro
user: unknown user appuser
```

**Solução:**
```dockerfile
# Crie o usuário primeiro
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

## 🔧 Comandos Úteis

### Verificar usuário atual
```bash
# Dentro do container
whoami
id

# Do host
docker exec container_name whoami
```

### Verificar permissões
```bash
# Listar arquivos com permissões
ls -la /app

# Verificar propriedade
stat /app/app.jar
```

### Testar segurança
```bash
# Tentar executar comando privilegiado
docker run --rm minha-app whoami
docker run --rm minha-app id
```

## 🚀 Como Executar

```bash
# Build da imagem
docker build -t algatransito-api-secure .

# Executar com usuário não-root
docker run -p 8080:8080 algatransito-api-secure

# Verificar usuário
docker exec container_name whoami
# Deve retornar: appuser (ou 1001)
```

## 📚 Recursos Adicionais

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [Kubernetes Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

## 🔍 Verificação de Segurança

```bash
# Verificar se executa como root
docker run --rm algatransito-api whoami
# Se retornar "root", há problema de segurança

# Verificar permissões
docker run --rm algatransito-api id
# Deve mostrar UID > 0 (não-root)

# Verificar arquivos
docker run --rm algatransito-api ls -la /app
# Arquivos devem pertencer ao usuário correto
```

---

**💡 Dica**: A instrução USER é uma das práticas de segurança mais importantes no Docker. Sempre use usuários não-root em produção para proteger sua aplicação e infraestrutura!
