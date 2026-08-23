FROM oven/bun:1.3.14-alpine AS deps

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

FROM deps AS builder

ARG NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
ARG NEXT_PUBLIC_DASHBOARD_BASE_PATH=/admin
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}
ENV NEXT_PUBLIC_DASHBOARD_BASE_PATH=${NEXT_PUBLIC_DASHBOARD_BASE_PATH}
ENV NEXT_TELEMETRY_DISABLED=1

COPY . .
RUN bun run build

FROM node:22.18.0-alpine3.22 AS production

ARG BUILD_VERSION=development
ARG BUILD_REVISION=unknown
ARG NEXT_PUBLIC_DASHBOARD_BASE_PATH=/admin

LABEL org.opencontainers.image.title="MediGuide Dashboard" \
      org.opencontainers.image.version="${BUILD_VERSION}" \
      org.opencontainers.image.revision="${BUILD_REVISION}"

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_PUBLIC_DASHBOARD_BASE_PATH=${NEXT_PUBLIC_DASHBOARD_BASE_PATH}

COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static
COPY --from=builder --chown=node:node /app/public ./public

USER node
EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=6 \
  CMD node -e "const p=process.env.NEXT_PUBLIC_DASHBOARD_BASE_PATH||'';fetch('http://127.0.0.1:3000'+p).then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
