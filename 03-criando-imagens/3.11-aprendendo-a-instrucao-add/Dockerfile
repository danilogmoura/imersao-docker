FROM openjdk:21-jdk-slim

WORKDIR /app

# ADD com arquivo local: copia e extrai automaticamente arquivos tar.gz
# O ADD descompacta automaticamente arquivos tar, gzip, bzip2, xz
# DIFERENÇA: ADD extrai automaticamente, COPY não
# MELHOR PRÁTICA: Use COPY + RUN tar para maior controle
ADD wildfly-36.0.0.Final.tar.gz .

# ADD com URL: baixa arquivo diretamente da internet
# CUIDADO: este comando baixa o arquivo a cada build, não usa cache
# PROBLEMA DE SEGURANÇA: URLs podem ser interceptadas ou alteradas
# MELHOR PRÁTICA: Use RUN wget/curl + verificação de checksum
ADD https://github.com/wildfly/wildfly/releases/download/36.0.0.Final/wildfly-36.0.0.Final.tar.gz

RUN tar -xzf wildfly-36.0.0.Final.tar.gz && \
     rm wildfly-36.0.0.Final.tar.gz

EXPOSE 8080

CMD ["wildfly-36.0.0.Final/bin/standalone.sh", "-b", "0.0.0.0"]