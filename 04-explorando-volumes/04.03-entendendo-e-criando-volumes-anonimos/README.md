# Entendendo e criando volumes anônimos

Essa é uma excelente dúvida, pois toca na fronteira entre persistência prática e simplicidade operacional. Volumes anônimos são úteis quando você quer persistência temporária/descartável sem amarrar o dado a um nome estável. Vamos entender quando e como usar.

## Princípio fundamental
Persistência deve refletir a intenção do ciclo de vida. Se os dados são efêmeros ou específicos ao container, um volume anônimo reduz atrito e configuração. Se são duráveis e compartilháveis, prefira volumes nomeados. Escolha comunica intenção e evita surpresas.

## O que é um volume anônimo?
- Um volume gerenciado pelo Docker, sem nome definido por você. O Docker gera um identificador (ex.: `8d1c0f...`).
- Criado quando você monta apenas o caminho do container sem especificar host nem nome: `-v /path/no/container`.
- Vive independente do container, mas é comumente tratado como descartável.
- Útil para caches, dados temporários, ou para isolar dados do host sem se preocupar com nomes.

Analogia: é como pegar um armário temporário no coworking sem por etiqueta. Serve bem enquanto você está lá; ao sair, pode descartar sem apego.

## Como criar (Docker CLI)
```bash
# Cria um container com volume anônimo montado em /data
# O Docker criará um volume com nome aleatório e montará em /data

docker run -d --name app \
  -v /data \
  alpine:3.20 sleep 1d

# Listar volumes e identificar o volume anônimo criado
docker volume ls

# Ver os mounts do container para achar o nome do volume anônimo
docker inspect app --format '{{ json .Mounts }}' | jq

# Remover o container e o volume anônimo junto
# (importante: usar -v para remover volumes associados)
docker rm -f -v app
```

Observações importantes:
- `-v /caminho/do/container` => volume anônimo.
- `-v nome:/caminho/do/container` => volume nomeado.
- `-v /caminho/host:/caminho/do/container` => bind mount.

## Docker Compose: volumes anônimos
```yaml
# docker-compose.yml
services:
  app:
    image: alpine:3.20
    command: ["sleep", "1d"]
    volumes:
      - /data  # volume anônimo
```
Com `docker compose up -d`, o Compose cria um volume anônimo para `/data`.

Ciclo de vida no Compose:
- `docker compose down` remove containers, redes e volumes anônimos do projeto por padrão (não remove volumes nomeados sem `-v`).
- Para ter certeza da remoção de todos os volumes (incluindo nomeados), use `docker compose down -v` (cuidado: apaga dados!).

## Dockerfile e a instrução VOLUME
```dockerfile
# Dockerfile
FROM alpine:3.20
RUN mkdir -p /cache
VOLUME ["/cache"]
CMD ["sh", "-c", "echo warming cache && sleep 1d"]
```
- `VOLUME /cache` declara que o caminho deve ser persistente.
- Se você rodar a imagem sem mapear explicitamente, o Docker criará um volume anônimo para `/cache`.
- Para controle explícito, mapeie um volume nomeado ou bind mount em runtime: `-v cache_app:/cache` ou `-v $(pwd)/cache:/cache`.

## Quando usar volumes anônimos
- **Caches e artefatos temporários**: npm/yarn cache, build caches, dados transitórios que aceleram execuções, mas podem ser descartados.
- **Isolamento do host**: você quer persistência durante a vida do container/ambiente, mas não quer vincular a um diretório do host nem gerenciar nomes.
- **Ambientes efêmeros**: pipelines de CI, ambientes de preview, exercícios de laboratório.

Quando NÃO usar:
- Dados de banco de dados ou qualquer dado que precise sobreviver a recriações e migrações controladas. Prefira volumes nomeados.

## Limpeza e gerenciamento
```bash
# Remover container e volumes anônimos associados
docker rm -f -v app

# Remover volumes órfãos não utilizados por nenhum container (cuidado!)
docker volume prune -f

# Identificar o volume anônimo de um container específico
name=$(docker inspect app --format '{{ (index .Mounts 0).Name }}') && echo $name

# Inspecionar um volume anônimo
docker volume inspect <nome_gerado>
```

Dica: Se você remover um container sem `-v`, os volumes anônimos podem ficar órfãos; use `docker volume ls` e `docker volume prune` periodicamente em ambientes de desenvolvimento.

## Diferenças: anônimo vs nomeado vs bind mount
- **Anônimo**: simples, sem nome; criado automaticamente; bom para dados efêmeros; limpeza exige atenção (-v/prune).
- **Nomeado**: identidade estável; ideal para dados duráveis; não é removido por padrão no `down`.
- **Bind mount**: usa diretório do host; ótimo para desenvolvimento (hot reload), mas traz diferenças de permissões/portabilidade.

## Boas práticas
- Expresse intenção: use anônimo para temporário; nomeado para durável.
- Remova com `docker rm -v` para evitar órfãos.
- Em Compose, confie que `down` limpa volumes anônimos do projeto; ainda assim, documente o impacto de `down -v`.
- Evite `VOLUME` no Dockerfile para caminhos que você deseja controlar com bind mount em dev; prefira declarar no Compose para ter previsibilidade.
- Monitore espaço em disco e faça prune regular em ambientes de dev/CI.

## Troubleshooting
- “Por que meus dados sumiram ao recriar o container?”
  - Era volume anônimo (ou nenhum). Dados são descartáveis; use volume nomeado para durabilidade.
- “Tenho vários volumes desconhecidos ocupando espaço.”
  - Provavelmente órfãos de containers removidos sem `-v`. Use `docker volume prune` com cautela.
- “Minha imagem cria volume anônimo mesmo eu mapeando outro.”
  - A instrução `VOLUME` no Dockerfile pode criar um mount extra se o caminho divergir. Garanta que você mapeia exatamente o mesmo caminho.

## Exercícios práticos
1) Rode um container com um volume anônimo e confirme seu nome:
```bash
docker run -d --name anon -v /cache alpine:3.20 sleep 1d

docker inspect anon --format '{{ json .Mounts }}' | jq
```
2) Remova o container preservando o volume (sem `-v`) e liste volumes órfãos. Depois, remova-os com `docker volume prune`.
```bash
docker rm -f anon

docker volume ls

docker volume prune -f
```
3) No Compose, declare um serviço com volume anônimo e valide que `docker compose down` remove o volume automaticamente.
```yaml
services:
  tmp:
    image: alpine:3.20
    command: ["sleep", "1d"]
    volumes:
      - /tmpdata
```
4) Adicione `VOLUME ["/tmpdata"]` em um Dockerfile, suba sem mapear e observe a criação automática do volume anônimo. Depois, rode mapeando `-v tmp_named:/tmpdata` e compare o comportamento.

## Checklist rápido
- Entende diferença entre `-v /path` (anônimo), `-v nome:/path` (nomeado) e `-v host:/path` (bind mount)?
- Sabe remover volumes anônimos com `docker rm -v` e `docker volume prune`?
- Sabe que Compose remove volumes anônimos com `down`, mas preserva nomeados sem `-v`?
- Consegue identificar volumes via `docker inspect` e `docker volume inspect`?

## Reflexão guiada
Se amanhã você precisar acelerar builds de CI com cache persistente entre execuções, você escolheria volumes anônimos, nomeados ou bind mounts? Como balancearia velocidade, limpeza automática e previsibilidade no pipeline? Pense em retenção, isolamento por branch e custo de manutenção.
