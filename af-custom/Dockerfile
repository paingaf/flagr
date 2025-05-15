FROM node:16 as ui-builder

# Copy the UI code
WORKDIR /build
COPY browser/flagr-ui /build

# Set environment variables for the build
ARG VUE_APP_TG_API_URL
ARG VUE_APP_TG_API_KEY
ARG VUE_APP_API_URL
ENV VUE_APP_TG_API_URL=${VUE_APP_TG_API_URL}
ENV VUE_APP_TG_API_KEY=${VUE_APP_TG_API_KEY}
ENV VUE_APP_API_URL=${VUE_APP_API_URL}

# Build the UI
RUN npm install && npm run build

# Final image
FROM ghcr.io/openflagr/flagr:1.1.18

# Replace the original UI with our custom built version
COPY --from=ui-builder /build/dist /browser/flagr-ui/dist/ 