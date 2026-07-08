FROM mcr.microsoft.com/playwright:v1.32.0-focal@sha256:a24829b63dfc22676e04207511a7e29b5795fc6ac5d24ee39870a8e9be78b585 as base
WORKDIR /app
COPY package.json .
COPY pnpm-lock.yaml .
RUN npm i -g pnpm
RUN pnpm i --frozen-lockfile
FROM base as runner
COPY --from=base /app /app
WORKDIR /app
COPY . .
CMD pnpm playwright test
