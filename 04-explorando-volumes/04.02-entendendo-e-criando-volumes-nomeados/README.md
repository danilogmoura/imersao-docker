# Entendendo e criando volumes nomeados

Essa é uma excelente dúvida, pois toca no cerne de como garantir persistência de dados em containers de forma segura, portável e fácil de operar. Vamos entender o porquê dos volumes nomeados, como criá-los, inspecioná-los, usá-los no `docker run` e no Docker Compose, além de boas práticas, troubleshooting e exercícios.

## Princípio fundamental
Persistência deve ser desacoplada do ciclo de vida do container. Containers são efêmeros; dados não. Volumes nomeados oferecem um identificador estável, gerenciado pelo Docker, evitando acoplamento a caminhos do host e reduzindo riscos de permissões, portabilidade e limpeza acidental.

## O que é um volume nomeado?
- Um volume gerenciado pelo Docker, referenciado por um nome (ex.: `pg_data`).
- Vive independentemente dos containers que o utilizam.
- É armazenado em um local gerenciado pelo Docker (ex.: Linux: `/var/lib/docker/volumes/<nome>/_data`).
- Pode ser compartilhado por múltiplos containers.

Analogia: pense no volume como um “disco externo” com uma etiqueta. Você pode plugar e desplugar (montar/desmontar) em containers diferentes sem perder o conteúdo.

## Comandos essenciais (Docker CLI)
```bash
# Listar volumes
docker volume ls

# Criar um volume nomeado
docker volume create pg_data

# Inspecionar metadados de um volume
docker volume inspect pg_data

# Remover um volume (só se não estiver em uso)
docker volume rm pg_data

# Limpar volumes não usados (cuidado!)
docker volume prune -f
```

## Usando volumes nomeados no docker run
```bash
# Exemplo: Postgres com volume nomeado para dados
# Cria (se não existir) e monta o volume 'pg_data' em /var/lib/postgresql/data

docker run -d \
  --name pg \
  -e POSTGRES_PASSWORD=senha_segura \
  -p 5432:5432 \
  -v pg_data:/var/lib/postgresql/data \
  postgres:16

# Testar persistência: pare, remova o container e suba de novo usando o mesmo volume
docker rm -f pg

docker run -d \
  --name pg \
  -e POSTGRES_PASSWORD=senha_segura \
  -p 5432:5432 \
  -v pg_data:/var/lib/postgresql/data \
  postgres:16
```

## Usando volumes nomeados no Docker Compose
```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: "senha_segura"
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  pg_data:
    driver: local
```

Comandos úteis:
```bash
# Subir
docker compose up -d

# Ver volumes do projeto
docker compose ls

# Parar e remover containers/pods mas manter volumes
docker compose down

# Parar e remover containers E volumes (cuidado!)
docker compose down -v
```

## Inicialização com scripts (seed/migrations)
Você pode montar arquivos `.sql` de seed (ex.: `algatransito-db.sql`) como um bind mount somente leitura, enquanto mantém os dados em um volume nomeado:
```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: "senha_segura"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./algatransito-db.sql:/docker-entrypoint-initdb.d/algatransito-db.sql:ro
volumes:
  pg_data:
```
Observação: scripts em `/docker-entrypoint-initdb.d/` rodam apenas na primeira inicialização do cluster (quando o diretório de dados está vazio). Se já existir conteúdo no volume, o Postgres não reexecuta os scripts.

## Backup e restore de volumes
- Backup (tar do conteúdo do volume via container utilitário):
```bash
# Backup para arquivo local backup_pg_data.tar
container_id=$(docker create -v pg_data:/data alpine:3.20 tar -czf /backup_pg_data.tar -C /data .)
docker cp "$container_id:/backup_pg_data.tar" ./backup_pg_data.tar
docker rm "$container_id"
```

- Restore:
```bash
# Restaura o tar para o volume pg_data
container_id=$(docker create -v pg_data:/data alpine:3.20 sh -c "rm -rf /data/* && tar -xzf /backup_pg_data.tar -C /data")
docker cp ./backup_pg_data.tar "$container_id:/backup_pg_data.tar"
docker start -a "$container_id"
docker rm "$container_id"
```

## Boas práticas
- Nomeie volumes de acordo com o propósito: `appname_component_data` (ex.: `algatransito_pg_data`).
- Evite montar diretórios de dados em bind mounts do host sem necessidade; volumes nomeados são mais portáveis e menos suscetíveis a diferenças de permissões.
- Controle a propriedade/permissões dentro do container (UID/GID). Em imagens oficializadas, o entrypoint costuma ajustar.
- Nunca use `docker compose down -v` em produção sem absoluta certeza: isso apaga dados.
- Separe dados (volume) de inicialização (scripts `.sql` via bind mount `:ro`).
- Tenha rotinas de backup e teste de restore documentadas e automatizadas.

## Troubleshooting
- “Permission denied” ao iniciar o serviço:
  - Verifique `docker volume inspect` e permissões dentro do container.
  - Em ambientes com SELinux/AppArmor, preferir volumes nomeados em vez de bind mounts ou ajustar contextos.
- Scripts de inicialização não rodam:
  - O volume já tem dados. Remova o volume (com cautela) ou crie um volume novo para reexecutar seeds.
- Volume “não é limpo” mesmo após `down`:
  - `down` não remove volumes por padrão. Use `down -v` (ciente do impacto).
- Espaço em disco crescendo:
  - Verifique volumes órfãos com `docker volume ls` e use `docker volume prune` (apenas se for seguro).

## Exercícios práticos
1) Crie um volume nomeado `algatransito_pg_data` e suba um Postgres com ele.
```bash
docker volume create algatransito_pg_data

docker run -d \
  --name pg_algatransito \
  -e POSTGRES_PASSWORD=alga \
  -p 5432:5432 \
  -v algatransito_pg_data:/var/lib/postgresql/data \
  postgres:16
```

2) Popular o banco na primeira inicialização usando o script `algatransito-db.sql`:
```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: "alga"
    ports:
      - "5432:5432"
    volumes:
      - algatransito_pg_data:/var/lib/postgresql/data
      - ./algatransito-db.sql:/docker-entrypoint-initdb.d/algatransito-db.sql:ro
volumes:
  algatransito_pg_data:
```

3) Pare, remova o container e suba novamente com o mesmo volume. Os dados persistiram?

4) Faça um backup do volume e valide um restore em outro volume `algatransito_pg_data_restored`.

5) Provoque um erro de permissão de propósito (bind mount de diretório do host) e compare com o volume nomeado.

## Checklist rápido
- Volume nomeado criado e inspecionado (`docker volume ls/inspect`).
- Dados persistem após recriar containers.
- Scripts de inicialização executam apenas na primeira vez.
- Backup e restore testados.
- Evitar `down -v` sem necessidade.

## Reflexão guiada
Se amanhã você precisar mover esse serviço para outra máquina/CI/CD, qual estratégia adotaria para migrar os dados de forma segura e reproduzível? Consideraria snapshots, `docker buildx bake` com artefatos, ou automatizaria backups/restore nos pipelines?
