# Use the official Neo4j image as base
FROM neo4j:5.26.6

# APOC Plugin Details
ARG APOC_VERSION=5.26.6
ARG APOC_JAR_NAME=apoc-${APOC_VERSION}-core.jar
ARG APOC_DOWNLOAD_URL=https://github.com/neo4j/apoc/releases/download/${APOC_VERSION}/${APOC_JAR_NAME}

# Create plugins directory and download APOC
# The original entrypoint script will move plugins from /plugins to the correct location
RUN mkdir -p /plugins && \
    echo "Downloading APOC plugin from ${APOC_DOWNLOAD_URL} to /plugins/${APOC_JAR_NAME}..." && \
    wget -O /plugins/${APOC_JAR_NAME} ${APOC_DOWNLOAD_URL}

# Copy our custom entrypoint script into the image
COPY custom-entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Expose standard Neo4j ports (optional, as Railway handles exposure)
EXPOSE 7474 7687

# Set the new entrypoint
# The original CMD ("neo4j") will be passed as arguments ("$@") to our script
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["neo4j"] 