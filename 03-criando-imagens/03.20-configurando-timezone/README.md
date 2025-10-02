# Configurando Timezone

Este guia explica como configurar corretamente o **timezone** em containers Docker, garantindo que logs, timestamps e operações de data/hora estejam no fuso horário correto.

## 📋 Por que Configurar Timezone?

### **Problemas sem Timezone Configurado:**
- ❌ **Logs em UTC**: Difícil de interpretar
- ❌ **Timestamps incorretos**: Dados com horário errado
- ❌ **Inconsistência**: Diferentes fusos entre containers
- ❌ **Debugging difícil**: Horários confusos nos logs

### **Benefícios com Timezone Configurado:**
- ✅ **Logs legíveis**: Horários no fuso local
- ✅ **Consistência**: Mesmo timezone em todos os containers
- ✅ **Debugging fácil**: Timestamps compreensíveis
- ✅ **Compliance**: Atende regulamentações locais

## 🌍 Timezones Comuns

### **Brasil:**
```bash
America/Sao_Paulo      # UTC-3 (horário de Brasília)
America/Manaus         # UTC-4 (Amazonas)
America/Cuiaba         # UTC-4 (Mato Grosso)
America/Recife         # UTC-3 (Pernambuco)
America/Fortaleza      # UTC-3 (Ceará)
```

### **América do Norte:**
```bash
America/New_York       # UTC-5/-4 (EST/EDT)
America/Los_Angeles    # UTC-8/-7 (PST/PDT)
America/Chicago        # UTC-6/-5 (CST/CDT)
America/Denver         # UTC-7/-6 (MST/MDT)
```

### **Europa:**
```bash
Europe/London          # UTC+0/+1 (GMT/BST)
Europe/Paris           # UTC+1/+2 (CET/CEST)
Europe/Berlin          # UTC+1/+2 (CET/CEST)
Europe/Madrid          # UTC+1/+2 (CET/CEST)
```

### **Ásia:**
```bash
Asia/Tokyo             # UTC+9 (JST)
Asia/Shanghai          # UTC+8 (CST)
Asia/Kolkata           # UTC+5:30 (IST)
Asia/Dubai             # UTC+4 (GST)
```

## 🔧 Métodos de Configuração

### **1. Variável de Ambiente TZ (Recomendado)**

#### **No Dockerfile:**
```dockerfile
# Configura timezone via variável de ambiente
ENV TZ=America/Sao_Paulo

# Ou em uma linha com outras variáveis
ENV TZ=America/Sao_Paulo \
    LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8
```

#### **No docker run:**
```bash
# Configurar timezone no comando
docker run -e TZ=America/Sao_Paulo minha-app:latest

# Com outras variáveis
docker run -e TZ=America/Sao_Paulo -e LANG=pt_BR.UTF-8 minha-app:latest
```

#### **No Docker Compose:**
```yaml
version: '3.8'
services:
  app:
    image: minha-app:latest
    environment:
      - TZ=America/Sao_Paulo
      - LANG=pt_BR.UTF-8
```

### **2. Instalação de tzdata (Para Imagens Base)**

#### **Ubuntu/Debian:**
```dockerfile
# Instalar tzdata e configurar timezone
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -snf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    echo "America/Sao_Paulo" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

#### **Alpine Linux:**
```dockerfile
# Instalar tzdata no Alpine
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    echo "America/Sao_Paulo" > /etc/timezone
```

### **3. Volume Mount (Para Flexibilidade)**

#### **Docker Compose:**
```yaml
version: '3.8'
services:
  app:
    image: minha-app:latest
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=America/Sao_Paulo
```

## 🏗️ Implementação no Dockerfile

### **Dockerfile Completo com Timezone:**
```dockerfile
FROM eclipse-temurin:21-jre-jammy

# Configura timezone e locale
ENV TZ=America/Sao_Paulo \
    LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8

# Instalar tzdata para suporte completo a timezone
RUN apt-get update && \
    apt-get install -y tzdata locales && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen pt_BR.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiar aplicação
COPY app.jar /app/

# Configurar entrypoint
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

### **Dockerfile Multi-stage com Timezone:**
```dockerfile
## STAGE BUILD
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /app
COPY . .
RUN gradle bootJar

## STAGE PRODUCTION
FROM eclipse-temurin:21-jre-jammy

# Configuração de timezone e locale
ENV TZ=America/Sao_Paulo \
    LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8 \
    JAR_NAME=app.jar

# Instalar dependências e configurar timezone
RUN apt-get update && \
    apt-get install -y tzdata locales && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen pt_BR.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiar aplicação
COPY --from=build /app/build/libs/$JAR_NAME /app/

# Configurar entrypoint
ENTRYPOINT ["java", "-jar", "/app/$JAR_NAME"]
```

## 🧪 Verificação e Testes

### **1. Verificar Timezone no Container:**
```bash
# Verificar timezone atual
docker run --rm minha-app:latest date

# Verificar variável TZ
docker run --rm minha-app:latest env | grep TZ

# Verificar arquivo de timezone
docker run --rm minha-app:latest cat /etc/timezone
```

### **2. Testar com Diferentes Timezones:**
```bash
# Testar com timezone do Brasil
docker run --rm -e TZ=America/Sao_Paulo minha-app:latest date

# Testar com timezone de Nova York
docker run --rm -e TZ=America/New_York minha-app:latest date

# Testar com timezone de Londres
docker run --rm -e TZ=Europe/London minha-app:latest date
```

### **3. Verificar Logs da Aplicação:**
```bash
# Executar container e verificar logs
docker run -d --name test-app -e TZ=America/Sao_Paulo minha-app:latest
docker logs test-app
docker rm -f test-app
```

## 📊 Comparação de Métodos

### **Variável TZ vs tzdata:**

| Aspecto | Variável TZ | tzdata |
|---------|-------------|---------|
| **Simplicidade** | ✅ Muito simples | ❌ Mais complexo |
| **Tamanho** | ✅ Sem overhead | ❌ +2-3MB |
| **Flexibilidade** | ✅ Runtime | ❌ Build time |
| **Compatibilidade** | ✅ Universal | ❌ Depende da imagem |
| **Performance** | ✅ Nativo | ❌ Overhead |

### **Recomendação:**
- **Desenvolvimento**: Use variável TZ
- **Produção**: Use tzdata + variável TZ
- **Flexibilidade**: Use volume mount

## 🚨 Problemas Comuns e Soluções

### **1. Timezone não Aplicado:**
```bash
# Problema: TZ não funciona
ENV TZ=America/Sao_Paulo
# Solução: Instalar tzdata
RUN apt-get install -y tzdata
```

### **2. Locale não Configurado:**
```bash
# Problema: Caracteres especiais
ENV TZ=America/Sao_Paulo
# Solução: Configurar locale
ENV LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8
RUN locale-gen pt_BR.UTF-8
```

### **3. Timezone Inconsistente:**
```bash
# Problema: Diferentes timezones
# Solução: Padronizar em todos os containers
ENV TZ=America/Sao_Paulo
```

### **4. Horário de Verão:**
```bash
# Problema: Horário de verão não aplicado
# Solução: Usar timezone com DST
TZ=America/Sao_Paulo  # ✅ Com DST
TZ=America/Manaus     # ❌ Sem DST
```

## 🏆 Melhores Práticas

### ✅ **Recomendações Gerais:**
1. **Sempre configure timezone** em containers de produção
2. **Use variável TZ** para simplicidade
3. **Instale tzdata** para compatibilidade total
4. **Configure locale** para caracteres especiais
5. **Padronize timezone** em todos os containers

### ✅ **Configuração Recomendada:**
```dockerfile
# Configuração completa
ENV TZ=America/Sao_Paulo \
    LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8

RUN apt-get update && \
    apt-get install -y tzdata locales && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen pt_BR.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### ✅ **Docker Compose:**
```yaml
version: '3.8'
services:
  app:
    image: minha-app:latest
    environment:
      - TZ=America/Sao_Paulo
      - LANG=pt_BR.UTF-8
      - LC_ALL=pt_BR.UTF-8
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
```

## 🔧 Comandos Úteis

### **Verificar Timezone:**
```bash
# Verificar timezone atual
date

# Verificar timezone do sistema
cat /etc/timezone

# Verificar link simbólico
ls -la /etc/localtime

# Verificar variável TZ
echo $TZ
```

### **Listar Timezones Disponíveis:**
```bash
# Listar todos os timezones
ls /usr/share/zoneinfo/

# Listar timezones do Brasil
ls /usr/share/zoneinfo/America/ | grep -E "(Sao_Paulo|Manaus|Cuiaba|Recife|Fortaleza)"

# Listar timezones da América
ls /usr/share/zoneinfo/America/
```

### **Testar Timezone:**
```bash
# Testar com date
TZ=America/Sao_Paulo date
TZ=America/New_York date
TZ=Europe/London date

# Testar com timedatectl (se disponível)
timedatectl list-timezones | grep America
```

## 📚 Recursos Adicionais

- [IANA Time Zone Database](https://www.iana.org/time-zones)
- [Docker Timezone Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Linux Timezone Configuration](https://wiki.archlinux.org/title/System_time)
- [Java Timezone Handling](https://docs.oracle.com/javase/8/docs/api/java/util/TimeZone.html)

## 🎯 Exemplos Avançados

### **1. Docker Compose com Múltiplos Timezones:**
```yaml
version: '3.8'
services:
  app-br:
    image: minha-app:latest
    environment:
      - TZ=America/Sao_Paulo
      - LANG=pt_BR.UTF-8

  app-us:
    image: minha-app:latest
    environment:
      - TZ=America/New_York
      - LANG=en_US.UTF-8

  app-eu:
    image: minha-app:latest
    environment:
      - TZ=Europe/London
      - LANG=en_GB.UTF-8
```

### **2. Kubernetes com Timezone:**
```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: minha-app:latest
    env:
    - name: TZ
      value: "America/Sao_Paulo"
    - name: LANG
      value: "pt_BR.UTF-8"
    volumeMounts:
    - name: timezone
      mountPath: /etc/timezone
      readOnly: true
  volumes:
  - name: timezone
    hostPath:
      path: /etc/timezone
```

### **3. Script de Configuração Automática:**
```bash
#!/bin/bash
# configure-timezone.sh

TIMEZONE=${TIMEZONE:-"America/Sao_Paulo"}
LANG=${LANG:-"pt_BR.UTF-8"}

# Configurar timezone
ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /etc/timezone

# Configurar locale
locale-gen $LANG
export LANG=$LANG
export LC_ALL=$LANG

echo "Timezone configurado: $TIMEZONE"
echo "Locale configurado: $LANG"
```

---

**💡 Dica**: Sempre configure timezone em containers de produção para garantir logs legíveis e operações de data/hora consistentes. A configuração adequada de timezone é essencial para aplicações em produção!
