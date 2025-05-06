FROM node:16 as ui-builder

# Copy the UI code
WORKDIR /build
COPY browser/flagr-ui /build

# Build the UI
RUN npm install && npm run build

# Final image
FROM ghcr.io/openflagr/flagr:1.1.18

# Replace the original UI with our custom built version
COPY --from=ui-builder /build/dist /browser/flagr-ui/dist/ 