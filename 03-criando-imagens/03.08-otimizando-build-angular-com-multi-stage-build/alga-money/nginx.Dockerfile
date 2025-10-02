# Use a imagem oficial do Node.js 18 Alpine como imagem base
FROM node:18-alpine AS build

# Define um argumento de build para o ambiente (padrão é 'dev')
ARG ENV=dev

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos package.json e package-lock.json para o diretório de trabalho
COPY package.json package-lock.json ./

# Instala as dependências e instala globalmente o Angular CLI
RUN npm install && npm install -g @angular/cli@13.0.3

# Copia o restante dos arquivos da aplicação para o diretório de trabalho
COPY . .

# Constrói a aplicação Angular com base no ambiente especificado
RUN npm run build:$ENV

# Segunda etapa: imagem de produção com Nginx
FROM nginx:1.21-alpine

# Copia os arquivos buildados da primeira etapa para o diretório do Nginx
COPY --from=build /app/dist/algamoney-ui/ /usr/share/nginx/html

# Copiar configuração customizada do Nginx
COPY ./nginx.conf /etc/nginx/nginx.conf 

# Expõe a porta 80 para a aplicação
EXPOSE 80

# Comando padrão para iniciar o Nginx
CMD ["nginx", "-g", "daemon off;"]