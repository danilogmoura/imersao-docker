# Desafio: Transferindo dados entre volumes (MySQL)

Essa é uma excelente prática do mundo real: começar rápido com um container e depois organizar a persistência. Aqui, você vai migrar dados de um volume anônimo (criado automaticamente) para um volume nomeado, mantendo tudo íntegro.

## Cenário
Você subiu o MySQL assim:
```bash
docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=algatransito \
  -e MYSQL_USER=alga \
  -e MYSQL_PASSWORD=1234567 \
  mysql:8.0
```
Sem mapear volume, o Docker criou um volume anônimo para `/var/lib/mysql`. Você criou a tabela e inseriu dados:
```sql
CREATE TABLE user (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO user (name, email, password) VALUES 
('John Doe', 'john.doe@example.com', 'hashed_password_1'),
('Jane Smith', 'jane.smith@example.com', 'hashed_password_2'),
('Alice Johnson', 'alice.johnson@example.com', 'hashed_password_3'),
('Bob Brown', 'bob.brown@example.com', 'hashed_password_4'),
('Charlie Davis', 'charlie.davis@example.com', 'hashed_password_5'),
('Diana Evans', 'diana.evans@example.com', 'hashed_password_6');
```
Agora você quer migrar tudo para um volume nomeado.

## Objetivos
- Identificar o volume anônimo em uso.
- Criar um volume nomeado.
- Migrar dados do volume anônimo para o nomeado.
- Validar que os dados persistem ao recriar o container.

## Passo 0: Preparação (popular base de teste)
Caso ainda não tenha inserido os dados, você pode usar o SQL deste diretório `algatransito-db.sql` como base.

## Passo 1: Identificar o volume anônimo
```bash
# Ver mounts do container
docker inspect mysql --format '{{ json .Mounts }}' | jq

# Opcional: extrair apenas o nome do volume
VOL=$(docker inspect mysql --format '{{ (index .Mounts 0).Name }}'); echo "$VOL"
```

## Passo 2: Criar o volume nomeado
```bash
docker volume create mysql_data_named
```

## Passo 3A (recomendado): Migrar com container utilitário (cp -a)
```bash
# Pare o MySQL para consistência (evita dados sujos)
docker stop mysql

# Copiar dados com preservação de atributos
docker run --rm \
  -v "$VOL":/source:ro \
  -v mysql_data_named:/dest \
  alpine:3.20 sh -c "cp -a /source/. /dest/"
```

## Passo 3B (alternativa): Migrar via tar (backup/restore)
```bash
# Backup do volume anônimo
cid=$(docker create -v "$VOL":/data alpine:3.20 tar -czf /backup.tar.gz -C /data .)
docker cp "$cid:/backup.tar.gz" ./backup_mysql.tar.gz
docker rm "$cid"

# Restore para o volume nomeado
cid=$(docker create -v mysql_data_named:/data alpine:3.20 sh -c "rm -rf /data/* && tar -xzf /backup.tar.gz -C /data")
docker cp ./backup_mysql.tar.gz "$cid:/backup.tar.gz"
docker start -a "$cid"
docker rm "$cid"
```

## Passo 4: Subir o MySQL usando o volume nomeado
```bash
docker rm -f mysql || true

docker run -d --name mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=algatransito \
  -e MYSQL_USER=alga \
  -e MYSQL_PASSWORD=1234567 \
  -v mysql_data_named:/var/lib/mysql \
  mysql:8.0
```

## Passo 5: Validação
```bash
# Checar se a tabela e os dados existem
docker exec -it mysql mysql -uroot -proot -e "USE algatransito; SHOW TABLES; SELECT COUNT(*) FROM user;"

# Conferir que o volume nomeado está montado
docker inspect mysql --format '{{ json .Mounts }}' | jq
```

## Rollback/limpeza
```bash
# Se precisar retornar ao estado anterior
# (não recomendado apagar o volume anônimo sem ter certeza)
# docker rm -f mysql
# docker volume rm "$VOL"

# Limpeza de containers e volumes de teste (cuidado!)
# docker rm -f mysql
# docker volume rm mysql_data_named
```

## Dicas e armadilhas
- Pare o banco antes de copiar os dados (consistência!).
- Prefira `cp -a` (preserva atributos) ou `tar` (mais robusto e verificável).
- Em sistemas com SELinux, se usar bind mounts, considere `:z`/`:Z`.
- Sempre valide após a migração (queries simples e inspeção de mounts).

## Extra: Verificação de integridade (opcional)
```bash
# Gera checksums no volume origem
docker run --rm -v "$VOL":/source alpine:3.20 \
  sh -c "find /source -type f -exec md5sum {} \\; | sort" > checksums_origem.txt

# Gera checksums no volume destino
docker run --rm -v mysql_data_named:/dest alpine:3.20 \
  sh -c "find /dest -type f -exec md5sum {} \\; | sort" > checksums_destino.txt

# Compara
diff checksums_origem.txt checksums_destino.txt || echo "Diferenças detectadas"
```

## Reflexão guiada
Se esse ambiente fosse de produção, qual estratégia garantiria consistência (janela de manutenção, lock de escrita, réplica para migração a quente)? Como você documentaria esse procedimento para sua equipe evitar volumes anônimos em novos deployments?
