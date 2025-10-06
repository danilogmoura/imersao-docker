# O que são redes Docker? Por que precisamos delas?

Essa é uma excelente pergunta, pois redes Docker são a base da comunicação segura e previsível entre containers e o mundo externo. Entender redes é crucial para construir sistemas distribuídos, isolar ambientes e controlar como serviços se descobrem.

## Princípio fundamental
Isolamento por padrão, conectividade sob demanda. Containers devem estar isolados por segurança e previsibilidade, e conexões devem ser explícitas. As redes do Docker provêm namespaces, roteamento e DNS interno para que serviços conversem de forma controlada.

## O que é uma rede Docker?
- Um domínio de conectividade e isolamento para containers.
- Fornece um espaço de endereçamento IP, roteamento e DNS interno.
- Permite que containers se comuniquem por nome (service discovery) dentro da mesma rede.

Analogia: pense em uma rede Docker como uma “sala” onde apenas quem está dentro se enxerga e conversa pelo nome. Você pode ter várias salas para separar times e propósitos.

## Drivers de rede (built-in)
- bridge (padrão): rede local isolada no host; containers na mesma bridge se comunicam e têm DNS.
- host: container compartilha a stack de rede do host (sem isolamento de portas; Linux apenas).
- none: sem rede (isolamento total; útil para jobs offline).
- overlay: rede distribuída que conecta múltiplos hosts (Swarm).

## DNS interno e descoberta por nome
- Containers numa mesma rede conseguem se resolver por nome do serviço/container.
- Em Compose, o nome do serviço vira hostname: `db`, `api`, etc.
- Evite hardcode de IPs; use nomes de serviço.

## Por que precisamos delas?
- Isolamento: separar ambientes (dev, test) e contextos (banco, app) com regras de acesso claras.
- Observabilidade e previsibilidade: controle quem fala com quem.
- Portabilidade: Compose/Stacks descrevem redes e serviços de forma declarativa.
- Segurança: reduzir superfície de ataque expondo apenas o necessário via mapeamento de portas.

## Exemplos (Docker CLI)
```bash
# Listar redes disponíveis
docker network ls

# Criar uma rede bridge dedicada
docker network create app_net

# Subir um banco conectado à rede
docker run -d --name db --network app_net -e POSTGRES_PASSWORD=alga postgres:16

# Subir uma API na mesma rede e comunicar por hostname
docker run -d --name api --network app_net -p 3000:3000 node:22-alpine sh -c "npm -v && sleep 3600"

# Dentro de um container, testar resolução de nome
docker exec -it api sh -c "apk add --no-cache bind-tools && nslookup db"
```

## Exemplos (Docker Compose)
```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: alga
    networks:
      - app_net
  api:
    image: node:22-alpine
    command: ["sh", "-c", "npm -v && sleep 3600"]
    ports:
      - "3000:3000"
    depends_on:
      - db
    networks:
      - app_net
networks:
  app_net:
    driver: bridge
```

## Boas práticas
- Nomeie redes por domínio funcional (`app_net`, `observability_net`).
- Separe camadas: banco e app na mesma rede; painel admin em outra, expondo o mínimo.
- Evite `--network host` salvo necessidade específica (perde isolamento).
- Use Compose para declarar redes e evitar configurações manuais.

## Troubleshooting rápido
- Container não resolve hostname:
  - Verifique se ambos estão na mesma rede (`docker inspect <container>` -> `.NetworkSettings.Networks`).
  - Em Compose, confirme nomes de serviço.
- Porta inacessível externamente:
  - Mapeie portas com `-p host:container` no serviço que deve ser exposto.
- Conflito de IPs:
  - Ao criar redes customizadas, você pode definir sub-redes para evitar choque.

## Exercícios
1) Crie duas redes `frontend_net` e `backend_net`. Coloque `api` em ambas; `db` apenas em `backend_net`. Valide que `frontend` não acessa `db` diretamente.
2) Adapte um Compose para usar nomes de serviço em vez de IPs hardcoded.
3) Use `nslookup`/`ping`/`curl` para verificar conectividade e DNS entre serviços.

## Reflexão guiada
Quando você desenha redes para um sistema, como decide o nível de isolamento entre serviços? O que muda em produção (observabilidade, WAF, balanceadores) e como isso se reflete nas redes do Docker e nas regras de exposição de portas?
