# Versionamento Semântico (Semantic Versioning)

Este guia explica o versionamento semântico (SemVer), suas regras, benefícios e como aplicá-lo em projetos Docker e desenvolvimento de software.

## 📋 O que é Versionamento Semântico?

O **Versionamento Semântico** (Semantic Versioning ou SemVer) é um padrão de versionamento que usa um formato específico para comunicar mudanças em software. Ele segue o padrão `MAJOR.MINOR.PATCH` (ex: `1.2.3`).

### Formato Básico
```
MAJOR.MINOR.PATCH
```

### Componentes:
- **MAJOR**: Mudanças incompatíveis na API
- **MINOR**: Funcionalidades adicionadas de forma compatível
- **PATCH**: Correções de bugs compatíveis

## 🎯 Por que Usar Versionamento Semântico?

### Vantagens:
- ✅ **Comunicação clara**: Desenvolvedores sabem o que esperar
- ✅ **Compatibilidade**: Facilita atualizações seguras
- ✅ **Automação**: Ferramentas podem tomar decisões baseadas na versão
- ✅ **Confiança**: Usuários sabem quando é seguro atualizar
- ✅ **Padronização**: Padrão universalmente aceito

### Benefícios para Docker:
- **Tags organizadas**: Imagens bem versionadas
- **Rollback seguro**: Fácil voltar para versões anteriores
- **CI/CD eficiente**: Automação baseada em versões
- **Ambientes consistentes**: Mesma versão em dev/staging/prod

## 📊 Estrutura do Versionamento Semântico

### Formato Completo
```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

### Exemplos:
- `1.0.0` - Versão inicial
- `1.0.1` - Correção de bug
- `1.1.0` - Nova funcionalidade
- `2.0.0` - Mudança incompatível
- `1.0.0-alpha.1` - Pré-lançamento
- `1.0.0+build.123` - Build específico

## 🔢 Regras do Versionamento Semântico

### 1. MAJOR (X.0.0)
**Quando incrementar:**
- Mudanças incompatíveis na API pública
- Remoção de funcionalidades
- Mudanças que quebram compatibilidade

**Exemplos:**
- `1.0.0` → `2.0.0`: Remoção de endpoint da API
- `1.0.0` → `2.0.0`: Mudança na estrutura do banco de dados
- `1.0.0` → `2.0.0`: Alteração de protocolo de comunicação

### 2. MINOR (X.Y.0)
**Quando incrementar:**
- Novas funcionalidades adicionadas
- Mudanças compatíveis com versões anteriores
- Deprecação de funcionalidades (sem remoção)

**Exemplos:**
- `1.0.0` → `1.1.0`: Novo endpoint na API
- `1.0.0` → `1.1.0`: Nova funcionalidade no frontend
- `1.0.0` → `1.1.0`: Suporte a novo formato de dados

### 3. PATCH (X.Y.Z)
**Quando incrementar:**
- Correções de bugs
- Melhorias de performance
- Correções de segurança
- Mudanças internas que não afetam a API

**Exemplos:**
- `1.0.0` → `1.0.1`: Correção de bug crítico
- `1.0.0` → `1.0.1`: Melhoria de performance
- `1.0.0` → `1.0.1`: Correção de vulnerabilidade

## 🏷️ Pré-lançamentos e Builds

### Pré-lançamentos (-PRERELEASE)
```
1.0.0-alpha.1
1.0.0-beta.2
1.0.0-rc.1
```

**Tipos comuns:**
- **alpha**: Versão inicial para testes internos
- **beta**: Versão para testes com usuários
- **rc** (release candidate): Versão candidata a lançamento

### Builds (+BUILD)
```
1.0.0+build.123
1.0.0+20231002.1
```

**Exemplos:**
- Número do build
- Timestamp
- Hash do commit

## 🐳 Versionamento em Docker

### Tags de Imagens
```bash
# Versões específicas
docker build -t minha-app:1.0.0 .
docker build -t minha-app:1.1.0 .
docker build -t minha-app:2.0.0 .

# Tags de conveniência
docker build -t minha-app:latest .
docker build -t minha-app:stable .
docker build -t minha-app:dev .
```

### Estratégias de Tagging
```bash
# Build com múltiplas tags
docker build -t minha-app:1.0.0 -t minha-app:latest .

# Build com pré-lançamento
docker build -t minha-app:1.1.0-alpha.1 .

# Build com informações de build
docker build -t minha-app:1.0.0+build.123 .
```

## 📝 Exemplos Práticos

### 1. API REST
```
1.0.0 - Versão inicial da API
1.0.1 - Correção de bug no endpoint /users
1.1.0 - Novo endpoint /orders
1.1.1 - Correção de performance no /orders
2.0.0 - Mudança na estrutura de resposta (breaking change)
```

### 2. Aplicação Web
```
1.0.0 - Lançamento inicial
1.0.1 - Correção de bug no login
1.1.0 - Nova funcionalidade de relatórios
1.1.1 - Correção de bug nos relatórios
1.2.0 - Nova funcionalidade de exportação
2.0.0 - Redesign completo da interface
```

### 3. Biblioteca/Framework
```
1.0.0 - Versão inicial
1.0.1 - Correção de bug na função calculate()
1.1.0 - Nova função validate()
1.1.1 - Correção de performance
2.0.0 - Mudança na assinatura da função calculate()
```

## 🔧 Ferramentas e Automação

### 1. Conventional Commits
```
feat: adiciona nova funcionalidade de exportação
fix: corrige bug no cálculo de impostos
docs: atualiza documentação da API
style: formata código
refactor: refatora função de validação
test: adiciona testes para nova funcionalidade
chore: atualiza dependências
```

### 2. Semantic Release
```json
{
  "release": {
    "branches": ["main"],
    "plugins": [
      "@semantic-release/commit-analyzer",
      "@semantic-release/release-notes-generator",
      "@semantic-release/changelog",
      "@semantic-release/npm",
      "@semantic-release/git"
    ]
  }
}
```

### 3. GitHub Actions
```yaml
name: Release
on:
  push:
    branches: [main]
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Semantic Release
        uses: cycjimmy/semantic-release-action@v4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 🏆 Melhores Práticas

### ✅ Recomendações Gerais
1. **Sempre use SemVer** para APIs públicas
2. **Documente mudanças** em CHANGELOG.md
3. **Use tags Git** para marcar versões
4. **Automatize releases** quando possível
5. **Comunique breaking changes** claramente

### ✅ Para Docker
1. **Use tags específicas** para produção
2. **Mantenha tags de conveniência** (latest, stable)
3. **Documente mudanças** entre versões
4. **Use multi-stage builds** para otimização
5. **Teste versões** antes do release

### ✅ Para APIs
1. **Versionamento na URL** ou header
2. **Deprecation warnings** para mudanças futuras
3. **Backward compatibility** quando possível
4. **Documentação clara** de mudanças
5. **Período de transição** para breaking changes

## 📚 Estratégias de Versionamento

### 1. Versionamento de API
```
# URL versioning
https://api.exemplo.com/v1/users
https://api.exemplo.com/v2/users

# Header versioning
Accept: application/vnd.exemplo.v1+json
Accept: application/vnd.exemplo.v2+json
```

### 2. Versionamento de Docker
```dockerfile
# Dockerfile com ARG para versão
ARG VERSION=1.0.0
LABEL version=$VERSION
LABEL maintainer="equipe@exemplo.com"
```

### 3. Versionamento de Dependências
```json
{
  "dependencies": {
    "express": "^4.18.0",  // Compatível com 4.x.x
    "lodash": "~4.17.21",  // Compatível com 4.17.x
    "moment": "2.29.4"     // Versão exata
  }
}
```

## 🚨 Problemas Comuns

### 1. Breaking Changes em MINOR
```bash
# ❌ Errado: Breaking change em 1.1.0
# ✅ Correto: Breaking change em 2.0.0
```

### 2. Funcionalidades em PATCH
```bash
# ❌ Errado: Nova funcionalidade em 1.0.1
# ✅ Correto: Nova funcionalidade em 1.1.0
```

### 3. Versionamento Inconsistente
```bash
# ❌ Errado: 1.0, 1.1, 1.2, 2.0
# ✅ Correto: 1.0.0, 1.1.0, 1.2.0, 2.0.0
```

## 🔍 Ferramentas de Validação

### 1. Validação de Versão
```bash
# Usando semver
npm install -g semver
semver 1.2.3  # Valida versão
semver -r ">=1.0.0" 1.2.3  # Verifica compatibilidade
```

### 2. Geração de Changelog
```bash
# Usando conventional-changelog
npm install -g conventional-changelog-cli
conventional-changelog -p angular -i CHANGELOG.md -s
```

### 3. Verificação de Breaking Changes
```bash
# Usando commitlint
npm install -g @commitlint/cli
echo "feat: nova funcionalidade" | commitlint
```

## 📖 Recursos Adicionais

- [Semantic Versioning Specification](https://semver.org/)
- [Semantic Versioning Specification (Português)](https://semver.org/lang/pt-BR/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Release](https://github.com/semantic-release/semantic-release)
- [Docker Tagging Best Practices](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/#tag)

## 🔧 Comandos Úteis

```bash
# Verificar versão atual
git describe --tags --abbrev=0

# Criar tag de versão
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Listar todas as tags
git tag -l

# Verificar diferenças entre versões
git diff v1.0.0..v1.1.0

# Build Docker com versão
docker build -t minha-app:$(git describe --tags --abbrev=0) .

# Push com múltiplas tags
docker tag minha-app:1.0.0 minha-app:latest
docker push minha-app:1.0.0
docker push minha-app:latest
```

---

**💡 Dica**: O versionamento semântico é essencial para projetos profissionais. Use ferramentas de automação para garantir consistência e comunique claramente as mudanças para seus usuários!
