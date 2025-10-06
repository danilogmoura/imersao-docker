# Entendendo e mapeando Bind Mounts

Essa é uma excelente dúvida, pois bind mounts são a ferramenta certa quando precisamos conectar o filesystem do host diretamente ao container, principalmente em desenvolvimento para hot reload e edição de código.

## Princípio fundamental
Escolha o mecanismo de persistência que melhor comunica a intenção:
- Dados que precisam ser duráveis e portáveis: volumes nomeados.
- Dados temporários/efêmeros: volumes anônimos.
- Arquivos do host que você precisa ler/editar em tempo real: bind mounts.

Bind mounts maximizam produtividade em dev, mas adicionam acoplamento ao host (permissões, caminhos, performance). Use-os com parcimônia em produção.

## O que é um bind mount?
- Um mapeamento direto entre um caminho do host e um caminho do container.
- Sintaxe geral (CLI): `-v /caminho/host:/caminho/container[:opções]` ou `--mount type=bind,src=/host,dst=/container,ro`
- Ideal para:
  - Compartilhar código-fonte do host com o container (hot reload).
  - Montar arquivos de configuração, chaves, certificados em modo somente leitura.
  - Depuração e inspeção de arquivos gerados pelo container direto no host.

Analogia: é como abrir uma janela do container para enxergar um diretório do host. Útil, mas tudo que acontece de um lado afeta o outro.

## Docker CLI: exemplos práticos
```bash
# 1) Mapear diretório de código para dentro do container (leitura/escrita)
docker run --rm -it \
  -v $(pwd):/app \
  -w /app \
  node:22-alpine node -v

# 2) Mapear arquivo de configuração como somente leitura
docker run --rm -it \
  -v $(pwd)/config.yml:/etc/app/config.yml:ro \
  alpine:3.20 cat /etc/app/config.yml

# 3) Usando --mount (mais explícito)
docker run --rm -it \
  --mount type=bind,src=$(pwd)/static,dst=/usr/share/nginx/html,ro \
  -p 8080:80 \
  nginx:stable-alpine

# 4) SELinux (hosts com SELinux): use :z ou :Z
# :z (compartilhável entre containers), :Z (exclusivo)
docker run --rm -it \
  -v $(pwd)/data:/data:Z \
  alpine:3.20 ls -la /data
```

Notas por plataforma:
- Linux: caminhos nativos funcionam diretamente (`/home/usuario/projeto`).
- WSL2: use caminhos dentro do WSL (`/home/<user>/...`) para melhor performance; evitar `C:/` via interop quando possível.
- Windows (Docker Desktop): use `//c/Users/...` ou `C:\Users\...` no PowerShell/CMD; garanta que o diretório está compartilhado nas configurações do Docker Desktop.

## Docker Compose: bind mounts
```yaml
# docker-compose.yml
services:
  api:
    image: node:22-alpine
    working_dir: /app
    command: ["npm", "run", "dev"]
    volumes:
      - ./:/app  # código do host
      - ./config.yml:/app/config.yml:ro  # arquivo somente leitura
    ports:
      - "3000:3000"
```
Dicas:
- Caminhos relativos são relativos ao arquivo `docker-compose.yml`.
- Para evitar sobrepor diretórios com conteúdo da imagem, mapeie apenas o que precisa (ou use subpastas). Caso contrário, arquivos importantes da imagem podem “sumir” sob o bind mount.

## Flags e opções úteis
- `:ro` e `:rw` (padrão): controle de leitura/escrita.
- SELinux: `:z` (compartilhável), `:Z` (rótulo exclusivo) — apenas em hosts com SELinux habilitado.
- Propagação (avançado): `rshared`, `rslave` em `--mount` para cenários com mounts recursivos.

## Permissões, UID/GID e usuários
- O container vê o host com as permissões do filesystem. Se o processo no container roda como usuário não-root, pode não ter permissão de escrita.
- Estratégias:
  - Ajustar o usuário do processo (`--user $(id -u):$(id -g)` em dev) para casar com seu UID/GID.
  - Corrigir permissões/ownership no host (`chown -R`/`chmod`) com cuidado.
  - Em Compose, usar `user: "${UID}:${GID}"` e exportar no ambiente.

Exemplo (dev no Linux/WSL):
```bash
docker run --rm -it \
  -v $(pwd):/app \
  -w /app \
  --user $(id -u):$(id -g) \
  node:22-alpine npm ci
```

## Performance e sincronização
- Bind mounts podem ser mais lentos em certos ambientes (ex.: Mac/Windows/WSL entre discos). Prefira caminhos nativos do engine (no WSL, dentro do ext4 do WSL).
- Para projetos com muitas pequenas operações de FS (ex.: Node.js, monorepos), considere:
  - Ajustar watchers (polling) para hot reload.
  - Evitar montar `node_modules` do host; instale dentro do container e ignore via `.dockerignore`.
  - Quando necessário, use ferramentas de sincronização específicas (ex.: mutagen, cachings do Docker Desktop).

## Diferenças: bind mount vs volumes
- **Bind mount**: acopla ao caminho do host; ótimo para dev e arquivos específicos; sujeito a permissões e diferenças entre sistemas.
- **Volume nomeado**: gerenciado pelo Docker; melhor para dados duráveis/portáveis; não depende de caminhos do host.
- **Volume anônimo**: criado automaticamente; útil para dados efêmeros sem se preocupar com nomes.

## Boas práticas
- Monte apenas o necessário (princípio do menor acoplamento).
- Use `:ro` para arquivos de configuração e segredos sempre que possível.
- Em dev, mantenha o código como bind mount, mas dados (ex.: bancos) em volumes nomeados.
- Documente caminhos absolutos/relativos e variáveis de ambiente usadas nos mounts.
- No WSL2/Mac, mantenha o projeto no filesystem “mais rápido” suportado pelo Docker.

## Troubleshooting
- “Permission denied” ao escrever:
  - Verifique UID/GID do processo no container, permissões do host, e se o mount é `:ro`.
- Mudanças no host não refletem no container:
  - Verifique se o caminho montado está correto e se não foi sobreposto por outro mount.
- Arquivos da imagem “sumiram” ao montar um diretório:
  - Você sobrepôs o diretório do container com o diretório do host vazio. Monte apenas subpastas ou copie os arquivos necessários.
- Em SELinux: “operation not permitted”:
  - Tente `:z`/`:Z` no bind mount.

## Exercícios práticos
1) Mapeie a pasta `teste/` deste módulo para um container Alpine e crie um arquivo de dentro do container. Verifique no host.
```bash
cd 04-explorando-volumes/04.04-entendendo-e-mapeando-bind-mounts

docker run --rm -it \
  -v $(pwd)/teste:/work \
  -w /work \
  alpine:3.20 sh -c "echo 'criado-no-container' >> novo.txt && ls -la && cat novo.txt"
```
2) Monte um arquivo `algatransito-db.sql` como `:ro` em um Postgres e confirme que não é possível alterar o arquivo pelo container.
```bash
docker run -d --name pg_bind \
  -e POSTGRES_PASSWORD=alga \
  -v $(pwd)/algatransito-db.sql:/docker-entrypoint-initdb.d/algatransito-db.sql:ro \
  -v pg_data_bind:/var/lib/postgresql/data \
  postgres:16
```
3) Em Compose, monte apenas o diretório `teste/` e rode um serviço que observe mudanças (ex.: `busybox` tail):
```yaml
services:
  watcher:
    image: busybox:1.36
    command: ["sh", "-c", "inotifyd - /watch:wx & tail -f /dev/null"]
    volumes:
      - ./teste:/watch
volumes:
  pg_data_bind: {}
```

## Checklist rápido
- Entende a sintaxe `-v host:container[:opções]` e `--mount type=bind,...`?
- Sabe quando usar `:ro`, `:z`/`:Z`?
- Consegue resolver problemas de permissão via UID/GID ou ajustes no host?
- Evita sobrepor diretórios críticos da imagem?

## Reflexão guiada
Se você tivesse que rodar o mesmo serviço em dev (com hot reload) e em prod (com durabilidade e isolamento), como mudaria seu mapeamento entre bind mounts e volumes? Que políticas aplicaria para segredos e arquivos somente leitura?
