#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

CERT_DIR="/var/lib/neo4j/certificates/bolt" # Path for SSL certificates
KEY_FILE="$CERT_DIR/private.key"
CERT_FILE="$CERT_DIR/public.crt"
# Use LOCAL_CERT_CN from env, default to localhost. For Railway, set LOCAL_CERT_CN to your domain.
CN_NAME="${LOCAL_CERT_CN:-localhost}" 

APOC_STAGING_DIR="/plugins" # Where Dockerfile downloads APOC JAR
# ------ TARGET THE OFFICIAL NEO4J PLUGINS DIRECTORY ------
NEO4J_OFFICIAL_PLUGINS_DIR="/var/lib/neo4j/plugins"

# Dynamically find the APOC JAR filename in the staging directory
# This avoids hardcoding the version in this script if the Dockerfile changes it.
APOC_JAR_FILE_PATH=$(find "$APOC_STAGING_DIR" -name 'apoc-*-core.jar' -print -quit 2>/dev/null || true)

# Create certificate directory
echo "Ensuring certificate directory exists: $CERT_DIR"
mkdir -p "$CERT_DIR"

# Generate SSL certificates if they don't exist
if [ ! -f "$KEY_FILE" ] || [ ! -f "$CERT_FILE" ]; then
  echo "Generating self-signed SSL certificate in $CERT_DIR for CN=$CN_NAME..."
  openssl req -newkey rsa:2048 -nodes -keyout "$KEY_FILE" \
          -x509 -days 3650 -out "$CERT_FILE" \
          -subj "/CN=$CN_NAME"
else
  echo "SSL certificates already exist in $CERT_DIR."
fi
echo "Setting ownership of $CERT_DIR to neo4j:neo4j..."
chown -R neo4j:neo4j "$CERT_DIR"

# --- APOC Plugin Handling - Target /var/lib/neo4j/plugins ---
echo "Ensuring Neo4j official plugins directory exists at $NEO4J_OFFICIAL_PLUGINS_DIR..."
mkdir -p "$NEO4J_OFFICIAL_PLUGINS_DIR" # Ensure target plugins directory exists

if [ -n "$APOC_JAR_FILE_PATH" ] && [ -f "$APOC_JAR_FILE_PATH" ]; then
  APOC_JAR_FILENAME=$(basename "$APOC_JAR_FILE_PATH")
  TARGET_APOC_PATH="$NEO4J_OFFICIAL_PLUGINS_DIR/$APOC_JAR_FILENAME"
  
  echo "Checking for APOC plugin: $APOC_JAR_FILENAME in $APOC_STAGING_DIR (found path: $APOC_JAR_FILE_PATH)"

  if [ ! -f "$TARGET_APOC_PATH" ]; then
    echo "Copying APOC plugin from $APOC_JAR_FILE_PATH to $TARGET_APOC_PATH..."
    cp "$APOC_JAR_FILE_PATH" "$TARGET_APOC_PATH"
    echo "APOC plugin copied. Contents of $NEO4J_OFFICIAL_PLUGINS_DIR:"
    ls -l "$NEO4J_OFFICIAL_PLUGINS_DIR"
  else
    echo "APOC plugin $APOC_JAR_FILENAME already exists in $NEO4J_OFFICIAL_PLUGINS_DIR."
  fi
  # Set ownership for the copied plugin and the plugins directory
  echo "Setting ownership of $NEO4J_OFFICIAL_PLUGINS_DIR and its contents to neo4j:neo4j..."
  chown -R neo4j:neo4j "$NEO4J_OFFICIAL_PLUGINS_DIR"
elif [ -d "$APOC_STAGING_DIR" ]; then
  echo "APOC JAR file not found with pattern 'apoc-*-core.jar' in $APOC_STAGING_DIR."
  echo "Contents of $APOC_STAGING_DIR:"
  ls -l "$APOC_STAGING_DIR" || true # List staging dir contents if JAR not found
else
    echo "APOC staging directory $APOC_STAGING_DIR does not exist."
fi

# Ensure /data itself is owned by neo4j user (still good practice)
echo "Setting ownership of /data to neo4j:neo4j..."
chown -R neo4j:neo4j /data
# --- End APOC Plugin Handling ---

# Debugging: List final environment variables passed to Neo4j
echo "Listing environment variables starting with NEO4J_ or SERVER_ for Neo4j process:"
env | grep -E '^NEO4J_|^SERVER_' | sort

# Execute the original Neo4j entrypoint script
echo "Executing original Neo4j entrypoint: /startup/docker-entrypoint.sh with command: $@"
exec tini -g -- /startup/docker-entrypoint.sh "$@" 