# Diferença entre CMD e ENTRYPOINT no Docker

Este exemplo demonstra as diferenças fundamentais entre as instruções `CMD` e `ENTRYPOINT` no Docker, mostrando quando usar cada uma e seus comportamentos específicos.

## 📋 O que são CMD e ENTRYPOINT?

Ambas são instruções do Docker que definem **o que executar** quando o container é iniciado, mas com comportamentos diferentes:

- **CMD**: Define o comando padrão que pode ser sobrescrito
- **ENTRYPOINT**: Define o comando fixo que sempre será executado

## 🔍 Análise do Dockerfile

### Estrutura Multi-Stage
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

# ENTRYPOINT: comando fixo que sempre será executado
ENTRYPOINT java -jar $JAR_NAME
```

## ⚖️ Comparação: CMD vs ENTRYPOINT

| Característica | CMD | ENTRYPOINT |
|----------------|-----|------------|
| **Sobrescrita** | ✅ Fácil de sobrescrever | ❌ Não pode ser sobrescrito |
| **Argumentos** | ❌ Substitui completamente | ✅ Anexa argumentos |
| **Flexibilidade** | ⚠️ Muito flexível | ✅ Flexível com argumentos |
| **Segurança** | ❌ Pode ser alterado | ✅ Comando fixo |
| **Uso recomendado** | Scripts, comandos simples | Aplicações, comandos fixos |

## 🎯 Comportamentos Práticos

### 1. Com CMD
```dockerfile
CMD java -jar app.jar
```

**Execução:**
```bash
# Comando padrão
docker run minha-app
# Executa: java -jar app.jar

# Sobrescrevendo completamente
docker run minha-app /bin/bash
# Executa: /bin/bash (ignora o CMD)
```

### 2. Com ENTRYPOINT
```dockerfile
ENTRYPOINT java -jar app.jar
```

**Execução:**
```bash
# Comando padrão
docker run minha-app
# Executa: java -jar app.jar

# Passando argumentos
docker run minha-app --server.port=9090
# Executa: java -jar app.jar --server.port=9090

# Tentando sobrescrever (não funciona)
docker run minha-app /bin/bash
# Executa: java -jar app.jar /bin/bash
```

### 3. Combinando ENTRYPOINT + CMD
```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=8080"]
```

**Execução:**
```bash
# Comando padrão
docker run minha-app
# Executa: java -jar app.jar --server.port=8080

# Passando argumentos
docker run minha-app --server.port=9090
# Executa: java -jar app.jar --server.port=9090
```

## 🚨 Problemas e Riscos

### ❌ Problemas com CMD
```dockerfile
CMD java -jar app.jar
```

**Riscos:**
- **Sobrescrita acidental**: `docker run app /bin/bash` quebra a aplicação
- **Inconsistência**: Comportamento imprevisível
- **Segurança**: Usuários podem executar comandos arbitrários

### ✅ Vantagens do ENTRYPOINT
```dockerfile
ENTRYPOINT java -jar app.jar
```

**Benefícios:**
- **Comando fixo**: Sempre executa a aplicação
- **Argumentos flexíveis**: Permite configuração via argumentos
- **Segurança**: Impossível sobrescrever o comando principal
- **Previsibilidade**: Comportamento consistente

## 🏆 Melhores Práticas

### ✅ Use CMD quando:
- Criar **imagens base** para outros desenvolvedores
- Comandos **opcionais** ou **substituíveis**
- **Scripts** que podem ter diferentes comportamentos
- **Ferramentas** que precisam de flexibilidade total

```dockerfile
# Exemplo: imagem base do Node.js
FROM node:18
CMD ["node"]
```

### ✅ Use ENTRYPOINT quando:
- **Aplicações** que sempre devem executar
- **Comandos fixos** que não devem ser alterados
- **APIs** ou **serviços** que precisam de argumentos
- **Produção** onde segurança é importante

```dockerfile
# Exemplo: aplicação Spring Boot
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=8080"]
```

## 🎯 Casos de Uso Específicos

### 1. Aplicação Web (Spring Boot)
```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=8080"]
```

### 2. Ferramenta CLI
```dockerfile
ENTRYPOINT ["python", "cli.py"]
CMD ["--help"]
```

### 3. Imagem Base
```dockerfile
CMD ["/bin/bash"]
```

### 4. Serviço com Configuração
```dockerfile
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
```

## 🚀 Como Executar

```bash
# Build da imagem
docker build -t algatransito-api .

# Executar com porta padrão
docker run -p 8080:8080 algatransito-api

# Executar com porta customizada
docker run -p 9090:9090 algatransito-api --server.port=9090

# Executar com perfil específico
docker run -p 8080:8080 algatransito-api --spring.profiles.active=prod
```

## 📚 Recursos Adicionais

- [Documentação oficial CMD](https://docs.docker.com/engine/reference/builder/#cmd)
- [Documentação oficial ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage builds](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/#use-multi-stage-builds)

## 🔧 Comandos Úteis

```bash
# Verificar o comando padrão
docker inspect algatransito-api | grep -A 5 -B 5 "Cmd\|Entrypoint"

# Executar com shell interativo (se CMD permitir)
docker run -it algatransito-api /bin/bash

# Ver logs da aplicação
docker logs algatransito-api

# Executar com variáveis de ambiente
docker run -e SPRING_PROFILES_ACTIVE=prod algatransito-api
```

---

**💡 Dica**: Para aplicações de produção, sempre prefira `ENTRYPOINT` para garantir que sua aplicação sempre execute, independentemente de como o container for iniciado!
