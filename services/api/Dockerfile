FROM node:24.11.1-bookworm-slim
WORKDIR /app/services/api
COPY services/api/package*.json ./
RUN npm ci
COPY services/api/ ./
COPY PoP_2_Demo_Coding_Pack/assets/ /app/PoP_2_Demo_Coding_Pack/assets/
RUN npm run build
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
