# Explorando a instrução VOLUME do Dockerfile

Essa é uma excelente dúvida: `VOLUME` no Dockerfile declara pontos de montagem persistentes/externos ao sistema de arquivos da imagem. Isso influencia o runtime e como os dados são tratados, impactando persistência, portabilidade e segurança.

## Princípio fundamental
Imagens são imutáveis; dados não. `VOLUME` sinaliza que certo caminho deve ser persistido fora das camadas da imagem. Em runtime, o Docker monta um volume (anônimo por padrão) naquele caminho — a menos que você mapeie explicitamente um volume nomeado ou um bind mount.

## O que `VOLUME` faz exatamente?
- Na build: apenas declara um ponto de montagem; não cria volumes nem copia dados automaticamente para o host.
- No runtime:
  - Se você NÃO mapear nada: o Docker cria um volume anônimo para aquele caminho.
  - Se você mapear: usa o volume nomeado (`-v nome:/caminho`) ou bind mount (`-v host:/caminho`).
- Efeito colateral: tudo gravado nesse caminho não vai para camadas da imagem (bom para evitar inchar a imagem; ruim se esperava conteúdo embalado lá).

Analogia: é como marcar uma gaveta como “externa”: a gaveta existe, mas o conteúdo passa a viver fora do armário (imagem), plugado quando você usa.

## Exemplo do módulo
Trecho do `Dockerfile` deste diretório:

```1:16:/mnt/d/github/imersao-docker/04-explorando-volumes/04.07-explorando-a-instrucao-volume-do-dockerfile/Dockerfile
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
```

## Como rodar e observar o comportamento
```bash
# Construir imagem
docker build -t demo-volume .

# Rodar sem mapear: criará volume anônimo em /app/shared
docker run --rm -d --name demo1 demo-volume

docker inspect demo1 --format '{{ json .Mounts }}' | jq

# Rodar mapeando volume nomeado: identidade estável
docker volume create shared_named

docker run --rm -d --name demo2 \
  -v shared_named:/app/shared \
  demo-volume

# Rodar com bind mount: usa diretório do host
docker run --rm -d --name demo3 \
  -v $(pwd)/shared_data_dir:/app/shared \
  demo-volume
```

## Populando dados no volume declarado
Cuidado: ao montar um volume, o conteúdo existente no caminho da imagem fica “escondido” atrás do volume. Estratégias para popular o volume:
- No entrypoint, se `/app/shared` estiver vazio, copie dados de um local somente leitura da imagem (ex.: `/seed/shared/*`).
- Use um container inicializador (init job) que escreve no volume antes dos consumidores.
- Para binds, pré-popule o diretório no host.

Exemplo simples de entrypoint:
```dockerfile
# Dentro do Dockerfile
COPY seed/ /seed/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```
```bash
# entrypoint.sh
set -euo pipefail
if [ -z "$(ls -A /app/shared 2>/dev/null || true)" ]; then
  cp -R /seed/* /app/shared/
fi
exec "$@"
```

## CLI vs Compose com VOLUME
- CLI: `-v nome:/caminho` ou `-v host:/caminho[:ro]` sobrepõem o comportamento padrão (volume anônimo).
- Compose:
```yaml
services:
  app:
    image: demo-volume
    volumes:
      - shared_named:/app/shared  # volume nomeado
      # - ./shared_data_dir:/app/shared:ro  # bind mount somente leitura
volumes:
  shared_named:
```

## Armadilhas comuns
- Conteúdo “sumiu” ao montar: você sobrepôs o diretório da imagem com um volume/bind vazio. Popule antes ou copie no entrypoint.
- Muitos volumes órfãos: rodar sem mapear cria volumes anônimos; limpe com `docker volume prune` ou remova containers com `-v`.
- Permissões: garanta UID/GID compatíveis quando usar bind mounts; ajuste usuário do processo ou permissões.

## Boas práticas
- Declare `VOLUME` apenas para caminhos que devem ser persistentes/externos em qualquer ambiente.
- Para dev, considere não usar `VOLUME` no Dockerfile para diretórios de código (monte via Compose), evitando mounts implícitos.
- Prefira volumes nomeados para dados duráveis; use bind mounts para código/config; evite anônimos em produção.
- Documente claramente o que deve ser montado e por quê.

## Exercícios práticos
1) Construa a imagem e rode três variações (anônimo, nomeado, bind). Compare `docker inspect`.
2) Crie um entrypoint que popula `/app/shared` apenas quando vazio e valide comportamento com/sem bind.
3) Adapte um Compose com dois serviços compartilhando `shared_named` (um escreve, outro lê em `:ro`).

## Checklist rápido
- Entende que `VOLUME` cria volume anônimo se nada for mapeado?
- Sabe diferenciar nomeado, anônimo e bind mount e quando usar cada um?
- Planejou como popular os dados do volume declarado?
- Tem estratégia de limpeza de volumes órfãos?

## Reflexão guiada
No seu contexto, é melhor declarar `VOLUME` no Dockerfile ou deixar essa decisão para o Compose em cada ambiente? Como essa escolha afeta portabilidade, previsibilidade e manutenção ao longo do tempo?
