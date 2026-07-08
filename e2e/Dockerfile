FROM mcr.microsoft.com/playwright:v1.61.0-noble@sha256:57b65fdc9ceabe0ef613124c7bbe2babcf9362c4d85e382fe3b03604e84b428a as base
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm i -g pnpm
RUN pnpm i --frozen-lockfile
FROM base as runner
COPY --from=base /app /app
WORKDIR /app
COPY . .
CMD pnpm playwright test
