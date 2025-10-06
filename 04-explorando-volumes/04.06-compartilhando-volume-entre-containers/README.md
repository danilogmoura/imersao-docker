# 4.6. Compartilhando volume entre containers

Essa é uma excelente dúvida: compartilhar volumes é como criar um "espaço comum" para múltiplos containers colaborarem. Isso habilita padrões como sidecars de logs, workers de processamento e pipelines onde um escreve e outro lê.

## Princípio fundamental
Desacople dados do ciclo de vida de containers e defina papéis claros de leitura/escrita. Compartilhar volume não substitui mecanismos de coordenação/concurrency control; ele apenas expõe o mesmo filesystem. Integrações seguras dependem de contratos e bloqueios ao nível da aplicação.

## Conceitos essenciais
- Qualquer volume (nomeado ou bind mount) pode ser montado por múltiplos containers.
- Modo de acesso:
  - `:rw` (padrão): leitura e escrita.
  - `:ro`: somente leitura (protege consumidores).
- Conflitos de escrita simultânea devem ser tratados na aplicação (file locks, atomic writes, diretórios por produtor, etc.).

Analogia: é um diretório compartilhado de equipe. Funciona bem se cada um respeita as regras de uso; sem regras, vira bagunça.

## Exemplo com Docker CLI (volume nomeado)
```bash
# Criar volume nomeado
docker volume create shared_data

# Container produtor escreve no volume
docker run -d --name writer \
  -v shared_data:/shared \
  alpine:3.20 sh -c "sh -c 'i=0; while true; do echo \"linha-$i\" >> /shared/out.txt; i=$((i+1)); sleep 1; done'"

# Container leitor (somente leitura)
docker run -d --name reader \
  -v shared_data:/shared:ro \
  alpine:3.20 sh -c "tail -F /shared/out.txt"

# Ver conteúdo do volume via um container efêmero
docker run --rm -v shared_data:/shared alpine:3.20 head -n 5 /shared/out.txt

# Limpeza
docker rm -f writer reader
```

Observações:
- O leitor monta `:ro` para isolar e evitar alterações acidentais.
- Em caso de arquivo inexistente no início, `tail -F` tolera criação tardia.

## Exemplo com bind mount (host compartilhado)
```bash
# Usando a pasta deste módulo como diretório compartilhado
cd 04-explorando-volumes/04.06-compartilhando-volume-entre-containers

# Produtor escreve em shared_data_dir/
docker run -d --name writer_bind \
  -v $(pwd)/shared_data_dir:/shared \
  alpine:3.20 sh -c "sh -c 'i=0; while true; do echo \"host-$i\" >> /shared/bind.txt; i=$((i+1)); sleep 1; done'"

# Leitor lê em modo ro
docker run -d --name reader_bind \
  -v $(pwd)/shared_data_dir:/shared:ro \
  alpine:3.20 sh -c "tail -F /shared/bind.txt"

# Inspecionar do host
head -n 5 shared_data_dir/bind.txt

# Limpeza
docker rm -f writer_bind reader_bind
```

## Docker Compose: padrão writer/reader
```yaml
# docker-compose.yml
services:
  writer:
    image: alpine:3.20
    command: ["sh", "-c", "i=0; while true; do echo \"line-$i\" >> /shared/out.txt; i=$((i+1)); sleep 1; done"]
    volumes:
      - shared_data:/shared

  reader:
    image: alpine:3.20
    command: ["sh", "-c", "tail -F /shared/out.txt"]
    volumes:
      - shared_data:/shared:ro

volumes:
  shared_data:
```

Dicas:
- Separe responsabilidades por diretórios (ex.: `/shared/in`, `/shared/out`) para minimizar conflitos.
- Para throughput alto e múltiplos produtores, prefira registros atômicos (escritas por arquivo único e `mv` atômico) ou filas (ex.: Redis, NATS) em vez de lock manual.

## Padrões comuns
- Sidecar de logs: app escreve em `/var/log/app`, sidecar envia para destino (S3/ELK) montando o mesmo volume como `:ro`.
- ETL: serviço A exporta CSVs para `/shared/export`, serviço B lê e importa para um banco.
- Cache compartilhado: ferramentas que beneficiam de reuso de artefatos entre etapas.

## Concor­rência e integridade
- Evite múltiplos escritores no mesmo arquivo.
- Para múltiplos arquivos, adote nomes únicos (UUIDs, timestamps) e diretórios por produtor.
- Use operações atômicas: escrever em arquivo temporário e renomear (`mv`) depois de completo.
- Se necessário, use file locking (flock) ou coordenação externa (DB, Redis, etc.).

## Permissões e usuários
- Garanta que todos os containers tenham UID/GID com permissão no volume.
- Em bind mounts, ajuste permissões no host; em volumes nomeados, inicialize permissões via entrypoint.
- Se precisar isolar leitura, monte com `:ro` nos consumidores.

## Troubleshooting
- “Permission denied” ao escrever:
  - Verifique UID/GID e modo de montagem (`:ro`). Ajuste usuário do processo ou permissões do diretório.
- Leitor não vê novos dados:
  - Confirme o mesmo volume está montado e verifique buffers/cache do leitor; use `tail -F` em vez de `-f`.
- Corrupção/linhas truncadas:
  - Evite múltiplos escritores no mesmo arquivo; use escrita atômica e renomeação.

## Exercícios práticos
1) Reproduza o padrão writer/reader com volume nomeado e confirme escrita/leitura simultânea.
2) Modifique para dois writers gravando em arquivos separados e um reader agregando ambos com `tail -F`.
3) Em bind mount, altere permissões do host e observe impacto nos containers. Corrija usando `--user` ou `chown`.
4) Adapte o Compose para um sidecar de logs que apenas lê (ro) e envia para `stdout`.

## Checklist rápido
- Mesma origem de dados montada em múltiplos containers? OK.
- Consumidores montados como `:ro` quando possível? OK.
- Escritas atômicas e nomes únicos para evitar conflitos? OK.
- Permissões/UID/GID alinhados? OK.

## Reflexão guiada
Quando a colaboração ficar mais complexa (múltiplos produtores/consumidores, alto volume, consistência), você manteria o compartilhamento por filesystem ou migraria para uma fila/objeto (S3, Redis Streams, Kafka)? Qual o critério de corte no seu contexto (latência, custo, confiabilidade)?
