# Imagem base (sistema operacional e pacotes fundamentais)
FROM ubuntu:24.04

# Define o diretório de trabalho dentro da imagem
# As instruções subsequentes (RUN/CMD/ENTRYPOINT etc.) usarão este caminho como base
WORKDIR /app

# Declara um ponto de montagem de volume no caminho /app/shared
# Em tempo de execução, o Docker irá:
# - criar um volume anônimo para /app/shared caso você não mapeie nada;
# - ou usar um volume nomeado/bind mount se você mapear (-v nome:/app/shared ou -v host:/app/shared).
# Isso desacopla os dados das camadas da imagem e permite persistência/compartilhamento entre containers.
VOLUME /app/shared

# Comando padrão ao iniciar o container (útil para testes/demonstrações)
CMD bash