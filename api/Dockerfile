FROM node:22-bookworm-slim AS build
WORKDIR /service
COPY package*.json ./
RUN npm ci
COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

FROM node:22-bookworm-slim
ENV NODE_ENV=production
WORKDIR /service
COPY package*.json ./
RUN npm ci --omit=dev && mkdir -p /data/sessions /data/correspondencias /data/backups && chown -R node:node /data /service
COPY --from=build /service/dist ./dist
COPY database ./database
ENV SESSION_DIR=/data/sessions
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
