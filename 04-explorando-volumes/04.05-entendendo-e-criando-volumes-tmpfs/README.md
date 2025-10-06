# Entendendo e criando volumes tmpfs

Essa é uma excelente dúvida: `tmpfs` monta um filesystem na memória (RAM). É perfeito quando você precisa de dados ultrarrápidos e estritamente temporários, como caches, filas transitórias ou dados sensíveis que não devem tocar disco.

## Princípio fundamental
Persistência tem custo e risco; velocidade também. `tmpfs` troca durabilidade por performance e segurança em repouso. Se os dados podem ser descartados na parada do container e o ganho de latência importa, `tmpfs` é uma boa escolha.

## O que é `tmpfs`?
- Um sistema de arquivos em memória (não persistente) montado dentro do container.
- Conteúdo some quando o container para (ou quando é desmontado).
- Muito rápido e evita escrita em disco. Bom para dados sensíveis (reduz risco de vazamento por disco), mas atenção a swap/oom.

Analogia: é como trabalhar em uma lousa branca em vez de papel. Rápido para escrever e apagar, mas nada fica depois.

## Redis + tmpfs (Docker CLI)
Redis é um ótimo exemplo: por padrão ele mantém dados em memória e pode persistir snapshots (RDB) em disco. Com `tmpfs`, até os diretórios de persistência temporária podem ficar em RAM quando o objetivo é puramente efêmero.

```bash
# 1) Redis básico com diretório /data em tmpfs (sem persistência durável)
docker run -d --name redis-tmpfs \
  --tmpfs /data:rw,size=256m,mode=0755 \
  -p 6379:6379 \
  redis:7-alpine redis-server --save "" --appendonly no

# Validar que /data é tmpfs
docker exec -it redis-tmpfs mount | grep /data

# Exercício: set/get
docker exec -it redis-tmpfs redis-cli set key value
docker exec -it redis-tmpfs redis-cli get key

# Ao remover o container, os dados somem (esperado)
docker rm -f redis-tmpfs
```

Explicando opções:
- `--tmpfs /data`: cria um mount tmpfs no caminho `/data` dentro do container.
- `size=256m`: limita o tamanho da memória usada por esse tmpfs.
- `mode=0755`: define permissões do mount.
- `--save "" --appendonly no`: desativam persistência do Redis (puro efêmero em memória).

Alternativa com `--mount` explícito:
```bash
docker run -d --name redis-tmpfs \
  --mount type=tmpfs,destination=/data,tmpfs-size=256m,tmpfs-mode=0755 \
  -p 6379:6379 \
  redis:7-alpine redis-server --save "" --appendonly no
```

## Redis com dados efêmeros em tmpfs e config do host
```bash
# Mapear redis.conf do host como somente leitura e manter /data em tmpfs
cat > redis.conf <<'CFG'
appendonly no
save ""
bind 0.0.0.0
protected-mode no
CFG

docker run -d --name redis-tmpfs-conf \
  -v $(pwd)/redis.conf:/usr/local/etc/redis/redis.conf:ro \
  --tmpfs /data:size=128m \
  -p 6379:6379 \
  redis:7-alpine redis-server /usr/local/etc/redis/redis.conf
```

## Docker Compose: tmpfs
```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    command: ["redis-server", "--save", "", "--appendonly", "no"]
    ports:
      - "6379:6379"
    tmpfs:
      - /data:size=256m,mode=0755
```
Notas:
- Em Compose v2, `tmpfs` aceita lista de caminhos com opções inline.
- Se precisar mais controle, use `mounts` em `deploy` (Swarm) ou `--mount` na CLI.

## Permissões, limites e OOM
- Tamanho: sempre defina `size`/`tmpfs-size` para evitar consumir toda a memória.
- OOM: dados em tmpfs contam para uso de memória; combine com limites de `--memory`/Compose `mem_limit` para contenção.
- UID/GID: herda permissões padrão do processo. Ajuste `mode=` e o usuário do processo conforme necessário.

## Segurança
- Dados não tocam disco (menos risco de exfiltração por mídia persistente).
- Em hosts com swap, parte pode ir a swap; se isso for crítico, desabilite swap ou ajuste políticas.
- Para segredos, prefira mecanismos próprios (Docker secrets/K8s secrets) quando aplicável.

## Quando usar tmpfs
- Caches quentes, filas transitórias, checkpoints temporários.
- Ambientes de teste onde persistência não é necessária.
- Dados sensíveis que não devem ser gravados em disco.

Quando não usar:
- Bancos de dados que exigem durabilidade entre reinícios. Use volumes nomeados.

## Troubleshooting
- Redis não inicia ou não persiste quando esperado:
  - Se `--save` e `appendonly` estiverem desativados, nenhum snapshot será gravado (comportamento desejado para efêmero).
- O container mata por OOM:
  - Reduza chaves, aumente `size`, ou aplique limites de memória; monitore com `docker stats`.
- `Permission denied` em `/data`:
  - Ajuste `mode=` e usuário (`--user`) para casar com o processo do Redis.

## Exercícios práticos
1) Suba o Redis com `/data` em tmpfs (256 MiB) e confirme o mount:
```bash
docker run -d --name r1 \
  --tmpfs /data:size=256m \
  -p 6379:6379 \
  redis:7-alpine redis-server --save "" --appendonly no

docker exec -it r1 mount | grep tmpfs
```
2) Faça um benchmark simples e monitore memória:
```bash
docker exec -it r1 redis-benchmark -n 50000 -q

docker stats r1
```
3) Reinicie e verifique que os dados sumiram (expected):
```bash
docker exec -it r1 redis-cli set foo bar

docker restart r1

docker exec -it r1 redis-cli get foo  # deve retornar (nil)
```
4) Compose com tmpfs e `redis.conf` do host:
```yaml
services:
  redis:
    image: redis:7-alpine
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    volumes:
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro
    tmpfs:
      - /data:size=128m
    ports:
      - "6379:6379"
```

## Checklist rápido
- Entende `--tmpfs dest[:opções]` e `--mount type=tmpfs,...`?
- Define `size` para prevenir consumo excessivo de RAM?
- Sabe que dados somem ao parar o container?
- Ajusta permissões/usuário quando necessário?

## Reflexão guiada
No seu cenário, você usaria `tmpfs` para quais partes do Redis (ex.: `/data`, `/tmp`)? E se amanhã precisar de persistência seletiva (parte em RAM, parte em volume), como desenharia o Compose para equilibrar performance e durabilidade? 
