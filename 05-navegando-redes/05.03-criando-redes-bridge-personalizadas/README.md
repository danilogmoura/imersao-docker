# Criando Redes Bridge Personalizadas no Docker

## 📋 Índice
- [Introdução](#introdução)
- [O que são Redes Bridge](#o-que-são-redes-bridge)
- [Redes Bridge Padrão vs Personalizadas](#redes-bridge-padrão-vs-personalizadas)
- [Criando Redes Bridge Personalizadas](#criando-redes-bridge-personalizadas)
- [Comandos Essenciais](#comandos-essenciais)
- [Exemplos Práticos](#exemplos-práticos)
- [Configurações Avançadas](#configurações-avançadas)
- [Boas Práticas](#boas-práticas)
- [Troubleshooting](#troubleshooting)

## 🎯 Introdução

As redes Bridge personalizadas no Docker são uma funcionalidade essencial para criar ambientes de rede isolados e controlados. Diferentemente da rede bridge padrão, as redes personalizadas oferecem maior controle sobre a comunicação entre containers, resolução de nomes e configurações de rede.

## 🌉 O que são Redes Bridge

Uma rede bridge no Docker é um tipo de rede que permite que containers se comuniquem entre si e com o host. Ela atua como uma ponte virtual entre o namespace de rede do container e a interface de rede do host.

### Características das Redes Bridge:
- **Isolamento**: Containers em redes diferentes não podem se comunicar diretamente
- **Resolução de nomes**: DNS automático entre containers na mesma rede
- **Conectividade externa**: Containers podem acessar a internet através do host
- **Flexibilidade**: Configurações personalizáveis de IP, gateway e DNS

## 🔄 Redes Bridge Padrão vs Personalizadas

### Rede Bridge Padrão (`bridge`)
```bash
# Criada automaticamente pelo Docker
docker network ls
```

**Limitações:**
- Configurações fixas
- Sem resolução de nomes automática
- Menos controle sobre configurações de rede

### Redes Bridge Personalizadas
```bash
# Criadas pelo usuário com configurações específicas
docker network create minha-rede
```

**Vantagens:**
- Resolução de nomes automática
- Configurações personalizáveis
- Melhor isolamento
- Controle total sobre a topologia

## 🛠️ Criando Redes Bridge Personalizadas

### Comando Básico
```bash
docker network create <nome-da-rede>
```

### Comando com Configurações
```bash
docker network create \
  --driver bridge \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  --ip-range=192.168.1.0/28 \
  minha-rede-personalizada
```

### Parâmetros Disponíveis
- `--driver`: Tipo de driver (bridge, overlay, macvlan, etc.)
- `--subnet`: Sub-rede para a rede
- `--gateway`: Gateway da rede
- `--ip-range`: Range de IPs disponíveis
- `--opt`: Opções específicas do driver

## 📝 Comandos Essenciais

### Listar Redes
```bash
# Listar todas as redes
docker network ls

# Listar com detalhes
docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"
```

### Inspecionar Rede
```bash
# Ver detalhes de uma rede específica
docker network inspect minha-rede

# Ver apenas informações de IP
docker network inspect minha-rede --format '{{json .IPAM}}'
```

### Conectar/Desconectar Containers
```bash
# Conectar container a uma rede
docker network connect minha-rede meu-container

# Desconectar container de uma rede
docker network disconnect minha-rede meu-container

# Criar container já conectado à rede
docker run -d --name meu-app --network minha-rede nginx
```

### Remover Rede
```bash
# Remover rede (apenas se não houver containers conectados)
docker network rm minha-rede

# Remover todas as redes não utilizadas
docker network prune
```

## 🚀 Exemplos Práticos

### Exemplo 1: Aplicação Web com Banco de Dados
```bash
# 1. Criar rede personalizada
docker network create --driver bridge app-network

# 2. Criar container do banco de dados
docker run -d \
  --name mysql-db \
  --network app-network \
  -e MYSQL_ROOT_PASSWORD=senha123 \
  -e MYSQL_DATABASE=meuapp \
  mysql:8.0

# 3. Criar container da aplicação
docker run -d \
  --name web-app \
  --network app-network \
  -p 8080:80 \
  nginx

# 4. Verificar conectividade
docker exec web-app ping mysql-db
```

### Exemplo 2: Múltiplas Redes com Isolamento
```bash
# Criar redes para diferentes ambientes
docker network create --subnet=10.0.1.0/24 dev-network
docker network create --subnet=10.0.2.0/24 test-network
docker network create --subnet=10.0.3.0/24 prod-network

# Containers de desenvolvimento
docker run -d --name dev-app --network dev-network nginx
docker run -d --name dev-db --network dev-network mysql:8.0

# Containers de teste
docker run -d --name test-app --network test-network nginx
docker run -d --name test-db --network test-network mysql:8.0
```

### Exemplo 3: Rede com Configurações Específicas
```bash
# Criar rede com configurações avançadas
docker network create \
  --driver bridge \
  --subnet=172.20.0.0/16 \
  --ip-range=172.20.240.0/20 \
  --gateway=172.20.0.1 \
  --opt com.docker.network.bridge.name=docker1 \
  --opt com.docker.network.driver.mtu=1500 \
  rede-avancada

# Verificar configurações
docker network inspect rede-avancada
```

## ⚙️ Configurações Avançadas

### Configuração de DNS Personalizado
```bash
docker network create \
  --driver bridge \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  --opt com.docker.network.bridge.host_binding_ipv4=0.0.0.0 \
  rede-com-dns
```

### Configuração de MTU
```bash
docker network create \
  --driver bridge \
  --opt com.docker.network.driver.mtu=9000 \
  rede-jumbo-frames
```

### Rede com IPs Estáticos
```bash
# Criar rede
docker network create --subnet=192.168.100.0/24 rede-estatica

# Container com IP fixo
docker run -d \
  --name container-ip-fixo \
  --network rede-estatica \
  --ip 192.168.100.10 \
  nginx
```

## ✅ Boas Práticas

### 1. Nomenclatura
```bash
# Use nomes descritivos
docker network create app-frontend-network
docker network create app-backend-network
docker network create app-database-network
```

### 2. Isolamento por Ambiente
```bash
# Separe ambientes em redes diferentes
docker network create dev-network
docker network create staging-network
docker network create prod-network
```

### 3. Documentação
```bash
# Adicione labels para documentação
docker network create \
  --label "environment=development" \
  --label "team=backend" \
  --label "description=Rede para containers de desenvolvimento" \
  dev-network
```

### 4. Limpeza Regular
```bash
# Remover redes não utilizadas
docker network prune -f

# Verificar redes órfãs
docker network ls --filter dangling=true
```

## 🔧 Troubleshooting

### Problema: Container não consegue resolver nomes
```bash
# Verificar se estão na mesma rede
docker network inspect minha-rede

# Testar conectividade
docker exec container1 ping container2
docker exec container1 nslookup container2
```

### Problema: Conflito de IPs
```bash
# Verificar IPs em uso
docker network inspect minha-rede --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'

# Recriar rede com subnet diferente
docker network rm minha-rede
docker network create --subnet=10.0.0.0/24 minha-rede
```

### Problema: Rede não é removida
```bash
# Verificar containers conectados
docker network inspect minha-rede

# Desconectar todos os containers
docker network disconnect minha-rede container1
docker network disconnect minha-rede container2

# Remover rede
docker network rm minha-rede
```

### Comandos de Diagnóstico
```bash
# Ver todas as interfaces de rede
docker network ls

# Ver detalhes completos de uma rede
docker network inspect minha-rede

# Ver logs de rede
docker logs <container-id>

# Testar conectividade
docker exec -it container1 ping -c 4 container2
```

## 📚 Comandos de Referência Rápida

```bash
# Criar rede básica
docker network create minha-rede

# Criar rede com subnet
docker network create --subnet=192.168.1.0/24 minha-rede

# Conectar container
docker network connect minha-rede meu-container

# Desconectar container
docker network disconnect minha-rede meu-container

# Listar redes
docker network ls

# Inspecionar rede
docker network inspect minha-rede

# Remover rede
docker network rm minha-rede

# Limpar redes não utilizadas
docker network prune
```

---

## 🎓 Conclusão

As redes Bridge personalizadas são fundamentais para criar ambientes Docker bem estruturados e isolados. Com elas, você pode:

- ✅ Isolar aplicações em redes separadas
- ✅ Controlar a comunicação entre containers
- ✅ Configurar resolução de nomes automática
- ✅ Gerenciar IPs e subnets de forma personalizada
- ✅ Criar ambientes de desenvolvimento, teste e produção isolados

Domine essas técnicas para criar infraestruturas Docker robustas e escaláveis!

---

*📅 Data: 05.03*  
*🐳 Docker Networks - Bridge Personalizadas*
