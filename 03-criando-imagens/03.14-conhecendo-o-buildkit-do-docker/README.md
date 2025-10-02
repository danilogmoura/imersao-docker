# Conhecendo o BuildKit do Docker

Este guia explica o que é o BuildKit, suas vantagens, como habilitá-lo e como utilizá-lo para builds mais eficientes e rápidos.

## 📋 O que é o BuildKit?

O **BuildKit** é o novo motor de build do Docker que substitui o legado builder. Ele foi introduzido no Docker 18.09 e se tornou o padrão a partir do Docker 23.0.

### Características Principais:
- **Builds paralelos**: Executa instruções em paralelo quando possível
- **Cache inteligente**: Sistema de cache mais eficiente
- **Multi-stage otimizado**: Melhor gerenciamento de stages
- **Recursos avançados**: Mounts, secrets, e muito mais

## ⚖️ BuildKit vs Legacy Builder

| Característica | Legacy Builder | BuildKit |
|----------------|----------------|----------|
| **Velocidade** | ❌ Lento | ✅ Rápido |
| **Cache** | ⚠️ Básico | ✅ Inteligente |
| **Paralelização** | ❌ Sequencial | ✅ Paralelo |
| **Recursos** | ⚠️ Limitado | ✅ Avançado |
| **Compatibilidade** | ✅ Total | ⚠️ Algumas limitações |

## 🔍 Como Verificar se BuildKit está Habilitado

### 1. Verificar Versão do Docker
```bash
docker version
```
**BuildKit disponível desde**: Docker 18.09+

### 2. Verificar Buildx
```bash
docker buildx version
```
**Buildx**: Interface para BuildKit

### 3. Verificar Variáveis de Ambiente
```bash
echo $DOCKER_BUILDKIT
# Deve retornar: 1 (habilitado) ou vazio (desabilitado)
```

### 4. Teste Prático
```bash
# Build com BuildKit
DOCKER_BUILDKIT=1 docker build -t teste .

# Saída esperada:
# [+] Building 0.1s (2/2) FINISHED
# => [internal] load build definition from Dockerfile
# => [internal] load .dockerignore
```

## 🚀 Como Habilitar BuildKit

### Opção 1: Variável de Ambiente (Temporário)
```bash
export DOCKER_BUILDKIT=1
docker build -t minha-app .
```

### Opção 2: Comando com Flag (Temporário)
```bash
DOCKER_BUILDKIT=1 docker build -t minha-app .
```

### Opção 3: Configuração Permanente
```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
source ~/.bashrc
```

### Opção 4: Arquivo de Configuração
```bash
# Criar ~/.docker/config.json
mkdir -p ~/.docker
echo '{"features": {"buildkit": true}}' > ~/.docker/config.json
```

### Opção 5: Docker Desktop
- **Windows/Mac**: BuildKit já vem habilitado por padrão
- **Linux**: Precisa habilitar manualmente

## 🎯 Recursos Avançados do BuildKit

### 1. Builds Paralelos
```dockerfile
# BuildKit executa em paralelo quando possível
FROM node:18
COPY package.json .
RUN npm install
COPY . .
RUN npm run build
```

### 2. Cache Inteligente
```dockerfile
# Cache é reutilizado mesmo com mudanças em outros arquivos
FROM node:18
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
```

### 3. Multi-stage Otimizado
```dockerfile
# BuildKit otimiza automaticamente as stages
FROM node:18 AS build
WORKDIR /app
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

## 🛠️ Comandos BuildKit

### Build Básico
```bash
# Build simples
DOCKER_BUILDKIT=1 docker build -t minha-app .

# Build com progresso detalhado
DOCKER_BUILDKIT=1 docker build --progress=plain -t minha-app .
```

### Build com Buildx
```bash
# Criar builder personalizado
docker buildx create --name mybuilder --use

# Build com builder personalizado
docker buildx build -t minha-app .

# Build para múltiplas plataformas
docker buildx build --platform linux/amd64,linux/arm64 -t minha-app .
```

### Build com Cache
```bash
# Build com cache externo
DOCKER_BUILDKIT=1 docker build --cache-from=type=local,src=/tmp/.buildx-cache -t minha-app .

# Build com cache registry
DOCKER_BUILDKIT=1 docker build --cache-from=type=registry,ref=minha-app:cache -t minha-app .
```

## 🔧 Recursos Especiais do BuildKit

### 1. Mounts
```dockerfile
# Montar diretório durante o build
FROM alpine
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache git
```

### 2. Secrets
```dockerfile
# Usar secrets durante o build
FROM alpine
RUN --mount=type=secret,id=mysecret \
    cat /run/secrets/mysecret
```

### 3. SSH
```dockerfile
# Usar SSH durante o build
FROM alpine
RUN --mount=type=ssh \
    ssh-add -l
```

## 📊 Comparação de Performance

### Teste com Aplicação Node.js
```bash
# Legacy Builder
time docker build -t app-legacy .
# Real: 2m30s

# BuildKit
time DOCKER_BUILDKIT=1 docker build -t app-buildkit .
# Real: 1m45s (30% mais rápido)
```

### Teste com Multi-stage
```bash
# Legacy Builder
time docker build -t app-legacy .
# Real: 3m15s

# BuildKit
time DOCKER_BUILDKIT=1 docker build -t app-buildkit .
# Real: 2m10s (35% mais rápido)
```

## 🚨 Problemas Comuns e Soluções

### 1. BuildKit não habilitado
```bash
# Erro: BuildKit não disponível
# Solução: Habilitar BuildKit
export DOCKER_BUILDKIT=1
```

### 2. Cache não funcionando
```bash
# Erro: Cache não é reutilizado
# Solução: Verificar ordem das instruções
COPY package.json .
RUN npm install
COPY . .
```

### 3. Builds lentos
```bash
# Erro: Build ainda está lento
# Solução: Usar .dockerignore e otimizar Dockerfile
```

## 🏆 Melhores Práticas

### ✅ Recomendações Gerais
1. **Sempre use BuildKit** em produção
2. **Otimize a ordem** das instruções
3. **Use .dockerignore** para excluir arquivos desnecessários
4. **Aproveite o cache** colocando instruções que mudam pouco primeiro
5. **Use multi-stage** para imagens menores

### ✅ Dockerfile Otimizado
```dockerfile
# ✅ Bom: Instruções que mudam pouco primeiro
FROM node:18
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# ❌ Ruim: Instruções que mudam muito primeiro
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
```

## 🔍 Debugging BuildKit

### Verificar Progresso Detalhado
```bash
DOCKER_BUILDKIT=1 docker build --progress=plain -t minha-app .
```

### Verificar Cache
```bash
DOCKER_BUILDKIT=1 docker build --no-cache -t minha-app .
```

### Verificar Logs
```bash
DOCKER_BUILDKIT=1 docker build --progress=plain --no-cache -t minha-app . 2>&1 | tee build.log
```

## 🚀 Exemplos Práticos

### 1. Aplicação Node.js
```bash
# Build com BuildKit
DOCKER_BUILDKIT=1 docker build -t node-app .

# Build com cache
DOCKER_BUILDKIT=1 docker build --cache-from=node-app:latest -t node-app .
```

### 2. Aplicação Java
```bash
# Build multi-stage com BuildKit
DOCKER_BUILDKIT=1 docker build -t java-app .

# Build para produção
DOCKER_BUILDKIT=1 docker build --target=production -t java-app .
```

### 3. Aplicação Python
```bash
# Build com requirements primeiro
DOCKER_BUILDKIT=1 docker build -t python-app .

# Build com cache de pip
DOCKER_BUILDKIT=1 docker build --cache-from=python-app:latest -t python-app .
```

## 📚 Recursos Adicionais

- [Documentação oficial BuildKit](https://docs.docker.com/build/buildkit/)
- [Buildx Documentation](https://docs.docker.com/buildx/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [BuildKit GitHub](https://github.com/moby/buildkit)

## 🔧 Comandos Úteis

```bash
# Verificar se BuildKit está habilitado
docker buildx version

# Criar builder personalizado
docker buildx create --name mybuilder

# Listar builders
docker buildx ls

# Usar builder específico
docker buildx use mybuilder

# Build com progresso
DOCKER_BUILDKIT=1 docker build --progress=plain -t app .

# Build sem cache
DOCKER_BUILDKIT=1 docker build --no-cache -t app .

# Build com cache externo
DOCKER_BUILDKIT=1 docker build --cache-from=type=local,src=/tmp/.buildx-cache -t app .
```

---

**💡 Dica**: BuildKit é uma evolução significativa do Docker. Sempre use BuildKit em produção para ter builds mais rápidos, eficientes e com recursos avançados!
