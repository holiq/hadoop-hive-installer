#!/bin/bash

set -e

HIVE_DIR=/media/holiq/disk_ssd/Linux #/media/holiq/disk_ssd/Linux/hive_linux
HIVE_NAME=hive
HIVE_VERSION=4.0.1
HIVE_HOME=${HIVE_DIR}/${HIVE_NAME}
HIVE_URL="https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz"

# Check if Hive is already installed
if [ -d "$HIVE_HOME" ]; then
  echo -e "[WARNING] Hive is already installed at $HIVE_HOME."
  echo -e "If you want to reinstall, remove the directory manually and rerun this script."
  exit 0
fi

# Get install script directory
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAR_FILE="$CURRENT_DIR/apache-hive-${HIVE_VERSION}-bin.tar.gz"
EXTRACTED_DIR="${CURREENT_DIR}/apache-hive-${HIVE_VERSION}-bin"

# Download Hive if not already downloaded
if [ -f "$TAR_FILE" ]; then
  echo "Tar file already exists at $TAR_FILE, skipping download."
else
  echo "Downloading Hive ${HIVE_VERSION}..."
  wget -O "$TAR_FILE" "$HIVE_URL"
fi

# Extract Hive if not already extracted
if [ -d "$EXTRACTED_DIR" ]; then
  echo "Hive archive already extracted at $EXTRACTED_DIR, skipping extraction."
  sudo mv "$EXTRACTED_DIR" "$HIVE_HOME"
else
  echo "Extracting Hive..."
  sudo tar -xzf "$TAR_FILE" -C $HIVE_DIR
  sudo mv "${HIVE_DIR}/apache-hive-${HIVE_VERSION}-bin" "$HIVE_HOME"
fi

sudo chown -R $(whoami):$(whoami) "$HIVE_HOME"

# Set environment variables
cat <<EOF >> ~/.zshrc

# Hive Environment Variables
export HIVE_HOME=$HIVE_HOME
export PATH=\$PATH:\$HIVE_HOME/bin
EOF

# Configure Hive directories
mkdir -p "$HIVE_HOME/tmp"
mkdir -p "$HOME/hive/warehouse"

# Generate hive-site.xml
cat > "$HIVE_HOME/conf/hive-site.xml" <<EOF
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:derby:;databaseName=$HOME/hive/metastore_db;create=true</value>
    <description>JDBC connect string for a JDBC metastore</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.apache.derby.jdbc.EmbeddedDriver</value>
  </property>

  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>file://$HOME/hive/warehouse</value>
  </property>

  <property>
    <name>hive.exec.local.scratchdir</name>
    <value>$HIVE_HOME/tmp</value>
  </property>

  <property>
    <name>hive.metastore.schema.verification</name>
    <value>false</value>
  </property>
</configuration>
EOF

echo -e "\n[SUCCESS] Hive ${HIVE_VERSION} has been installed and configured successfully!"
echo -e "Next Steps:"
echo -e "- Run 'source ~/.zshrc' or open a new terminal to load Hive environment."
echo -e "- Initialize the Hive metastore with: schematool -initSchema -dbType derby"
echo -e "- Start Hive shell with: hive"
echo -e "- Start hise server with: hive --service metastore"
echo -e "- Start HiveServer2 with: hive --service hiveserver2"
echo -e "- Start Beeline shell with: beeline -u 'jdbc:hive2://localhost:10000/'"
