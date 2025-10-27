# The 'builder' job is to build the static website using the Moonwave application.
FROM node:lts-slim AS builder

WORKDIR /root/moonwave

# the 'Packages' folder is required to be PascalCase for us to use the 'autoSectionPath' on both dev/prod.
COPY Packages /root/moonwave/Packages

# the 'docs' folder is required to be lowercase for the Moonwave application to pick up documentation we've written.
COPY Docs /root/moonwave/docs

# required files for Moonwave.
COPY .moonwave /root/moonwave/.moonwave
COPY moonwave.toml /root/moonwave/moonwave.toml

# install the moonwave application.
RUN npm i -g moonwave

# have moonwave build our documentation site.
RUN moonwave build --code Packages --out-dir /build

# The 'serve' job is to build and host a nginx server with our built moonwave site.
FROM nginx AS serve

COPY --from=builder /root/moonwave/build /usr/share/nginx/html