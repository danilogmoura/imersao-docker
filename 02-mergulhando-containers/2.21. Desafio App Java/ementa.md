# Desafio: App Java

## Comando para executar o container

```bash
docker run -d --name app-java -p 9090:8080 --memory=1g --cpus=1 -e JAVA_TOOL_OPTIONS="-Duser.timezone=America/Sao_Paulo -XX:InitialRAMPercentage=70.0 -XX:MaxRAMPercentage=70.0" algaworks/hello-world-java-app
```

## Comando para verificar configurações da JVM

```bash
docker exec -it app-java java -XshowSettings:vm -version 2>&1 | grep -i "Max. Heap Size"
```

## Parâmetros utilizados

- `-d`: Executa o container em modo detached (background)
- `--name app-java`: Define o nome do container
- `-p 9090:8080`: Mapeia a porta 9090 do host para a porta 8080 do container
- `--memory=1g`: Limita o uso de memória para 1GB
- `--cpus=1`: Limita o uso de CPU para 1 core
- `-e JAVA_TOOL_OPTIONS`: Define opções da JVM para configuração de timezone e heap size