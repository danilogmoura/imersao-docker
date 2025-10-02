# Construindo uma Imagem Multi-plataforma

Este guia explica como construir imagens Docker que funcionam em múltiplas arquiteturas (AMD64, ARM64, ARMv7, etc.) usando o BuildKit e Buildx.

## 📋 O que são Imagens Multi-plataforma?

Imagens multi-plataforma são imagens Docker que contêm manifestos para diferentes arquiteturas de CPU, permitindo que a mesma imagem funcione em:

- **AMD64/x86_64**: Intel/AMD 64-bit (servidores, desktops)
- **ARM64/aarch64**: ARM 64-bit (Apple Silicon, servidores ARM)
- **ARMv7**: ARM 32-bit (Raspberry Pi, dispositivos IoT)
- **s390x**: IBM Z (mainframes)
- **ppc64le**: IBM Power (servidores Power)

## 🎯 Por que Usar Multi-plataforma?

### Vantagens:
- ✅ **Compatibilidade universal**: Funciona em qualquer hardware
- ✅ **Deploy simplificado**: Uma imagem para todos os ambientes
- ✅ **CI/CD eficiente**: Build uma vez, deploy em qualquer lugar
- ✅ **Cloud-native**: Essencial para Kubernetes e orquestração
- ✅ **IoT e Edge**: Suporte para dispositivos ARM

### Casos de Uso:
- **Aplicações web**: Deploy em diferentes data centers
- **Microserviços**: Kubernetes com nós heterogêneos
- **IoT**: Dispositivos Raspberry Pi e similares
- **Cloud**: AWS Graviton, Azure ARM, Google Cloud ARM

## 🛠️ Configuração Inicial

### 1. Verificar Buildx
```bash
# Verificar se buildx está disponível
docker buildx version

# Deve retornar algo como:
# github.com/docker/buildx v0.28.0 b1281b81bba797b21d9eaf256e6a13eb14419836
```

### 2. Criar Builder Multi-plataforma
```bash
# Criar builder personalizado para multi-plataforma
docker buildx create --name multiarch --driver docker-container --use

# Verificar builders disponíveis
docker buildx ls
```

### 3. Verificar Plataformas Suportadas
```bash
# Verificar plataformas disponíveis
docker buildx inspect multiarch

# Deve mostrar algo como:
# Name:   multiarch
# Driver: docker-container
# Platforms: linux/amd64, linux/arm64, linux/arm/v7, linux/arm/v6
```

## 🚀 Comandos Básicos

### Build para Múltiplas Plataformas
```bash
# Build para AMD64 e ARM64
docker buildx build --platform linux/amd64,linux/arm64 -t minha-app:latest .

# Build para todas as plataformas disponíveis
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t minha-app:latest .
```

### Build e Push para Registry
```bash
# Build e push para Docker Hub
docker buildx build --platform linux/amd64,linux/arm64 -t usuario/minha-app:latest --push .

# Build e push para registry privado
docker buildx build --platform linux/amd64,linux/arm64 -t registry.exemplo.com/minha-app:latest --push .
```

### Build Local (sem Push)
```bash
# Build local para plataforma específica
docker buildx build --platform linux/amd64 -t minha-app:latest --load .

# Build local para múltiplas plataformas (sem --load)
docker buildx build --platform linux/amd64,linux/arm64 -t minha-app:latest .
```

## 📝 Exemplo Prático: Aplicação Node.js

### Dockerfile Multi-plataforma
```dockerfile
# Use imagem base multi-plataforma
FROM --platform=$BUILDPLATFORM node:18-alpine

# Instalar dependências de build
RUN apk add --no-cache python3 make g++

# Definir diretório de trabalho
WORKDIR /app

# Copiar package.json
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production

# Copiar código fonte
COPY . .

# Build da aplicação
RUN npm run build

# Expor porta
EXPOSE 3000

# Comando de execução
CMD ["npm", "start"]
```

### Build da Aplicação
```bash
# Build para múltiplas plataformas
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t minha-app-node:latest \
  --push .
```

## 🏗️ Exemplo Prático: Aplicação Java

### Dockerfile Multi-stage Multi-plataforma
```dockerfile
# Stage 1: Build
FROM --platform=$BUILDPLATFORM maven:3.8-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM --platform=$TARGETPLATFORM openjdk:17-jre-slim
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

### Build da Aplicação Java
```bash
# Build para múltiplas plataformas
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t minha-app-java:latest \
  --push .
```

## 🔧 Configurações Avançadas

### 1. Build com Cache
```bash
# Build com cache local
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=type=local,dest=/tmp/.buildx-cache \
  -t minha-app:latest \
  --push .
```

### 2. Build com Cache Registry
```bash
# Build com cache no registry
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from=type=registry,ref=minha-app:cache \
  --cache-to=type=registry,ref=minha-app:cache \
  -t minha-app:latest \
  --push .
```

### 3. Build com Progresso Detalhado
```bash
# Build com progresso detalhado
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --progress=plain \
  -t minha-app:latest \
  --push .
```

## 🎯 Variáveis de Ambiente Especiais

### Variáveis Disponíveis
```dockerfile
# Variáveis automáticas do BuildKit
ARG BUILDPLATFORM    # Plataforma onde o build está sendo executado
ARG TARGETPLATFORM   # Plataforma de destino
ARG BUILDOS          # OS do build (linux, windows, darwin)
ARG BUILDARCH        # Arquitetura do build (amd64, arm64, arm)
ARG TARGETOS         # OS de destino
ARG TARGETARCH       # Arquitetura de destino
ARG TARGETVARIANT    # Variante da arquitetura (v7, v8)
```

### Exemplo de Uso
```dockerfile
FROM --platform=$BUILDPLATFORM alpine:latest AS downloader

# Download baseado na plataforma de destino
ARG TARGETPLATFORM
RUN case ${TARGETPLATFORM} in \
    "linux/amd64")  DOWNLOAD_URL="https://example.com/amd64" ;; \
    "linux/arm64")  DOWNLOAD_URL="https://example.com/arm64" ;; \
    "linux/arm/v7") DOWNLOAD_URL="https://example.com/armv7" ;; \
    esac && \
    wget -O binary ${DOWNLOAD_URL}

FROM --platform=$TARGETPLATFORM alpine:latest
COPY --from=downloader /binary /usr/local/bin/
```

## 🚨 Problemas Comuns e Soluções

### 1. Builder não encontrado
```bash
# Erro: builder "multiarch" not found
# Solução: Criar o builder
docker buildx create --name multiarch --driver docker-container --use
```

### 2. Plataforma não suportada
```bash
# Erro: platform "linux/arm64" not supported
# Solução: Verificar plataformas disponíveis
docker buildx inspect multiarch
```

### 3. Build lento
```bash
# Problema: Build muito lento
# Solução: Usar cache e otimizar Dockerfile
docker buildx build --cache-from=type=local,src=/tmp/.buildx-cache ...
```

### 4. Push falha
```bash
# Erro: push failed
# Solução: Verificar autenticação
docker login
```

## 🏆 Melhores Práticas

### ✅ Recomendações Gerais
1. **Use imagens base multi-plataforma** quando possível
2. **Otimize o Dockerfile** para diferentes arquiteturas
3. **Use cache** para builds mais rápidos
4. **Teste em diferentes plataformas** antes do deploy
5. **Use .dockerignore** para excluir arquivos desnecessários

### ✅ Dockerfile Otimizado
```dockerfile
# ✅ Bom: Usar variáveis de plataforma
FROM --platform=$BUILDPLATFORM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM --platform=$TARGETPLATFORM node:18-alpine
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### ✅ Scripts de Build
```bash
#!/bin/bash
# build-multiarch.sh

set -e

# Configurar builder
docker buildx create --name multiarch --driver docker-container --use 2>/dev/null || true

# Build e push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from=type=registry,ref=minha-app:cache \
  --cache-to=type=registry,ref=minha-app:cache \
  -t minha-app:latest \
  -t minha-app:$(git rev-parse --short HEAD) \
  --push .
```

## 🔍 Verificação e Teste

### Verificar Manifesto
```bash
# Verificar manifestos da imagem
docker buildx imagetools inspect minha-app:latest

# Deve mostrar algo como:
# Name:      minha-app:latest
# MediaType: application/vnd.docker.distribution.manifest.list.v2+json
# Digest:    sha256:...
# Platforms: linux/amd64, linux/arm64
```

### Testar em Diferentes Plataformas
```bash
# Testar em AMD64
docker run --rm --platform linux/amd64 minha-app:latest

# Testar em ARM64
docker run --rm --platform linux/arm64 minha-app:latest
```

## 🚀 Exemplos por Tecnologia

### Node.js
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t minha-app-node:latest \
  --push .
```

### Java/Spring Boot
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t minha-app-java:latest \
  --push .
```

### Python
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t minha-app-python:latest \
  --push .
```

### Go
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t minha-app-go:latest \
  --push .
```

## 📚 Recursos Adicionais

- [Docker Buildx Documentation](https://docs.docker.com/buildx/)
- [Multi-platform Images](https://docs.docker.com/build/building/multi-platform/)
- [BuildKit GitHub](https://github.com/moby/buildkit)
- [Docker Manifest](https://docs.docker.com/engine/reference/commandline/manifest/)

## 🔧 Comandos Úteis

```bash
# Criar builder multi-plataforma
docker buildx create --name multiarch --driver docker-container --use

# Listar builders
docker buildx ls

# Inspecionar builder
docker buildx inspect multiarch

# Build multi-plataforma
docker buildx build --platform linux/amd64,linux/arm64 -t app:latest --push .

# Verificar manifestos
docker buildx imagetools inspect app:latest

# Remover builder
docker buildx rm multiarch
```

---

**💡 Dica**: Imagens multi-plataforma são essenciais para aplicações modernas. Use BuildKit e Buildx para criar imagens que funcionam em qualquer hardware, desde servidores x86 até dispositivos ARM!
