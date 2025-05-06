#!/bin/bash

set -e

HIVE_DIR=/media/holiq/disk_ssd/Linux
HIVE_NAME=hive
HIVE_VERSION=3.1.2
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
    <value>jdbc:mysql://localhost/metastore?createDatabaseIfNotExist=true</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.cj.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hivepassword</value>
  </property>
  <property>
    <name>datanucleus.autoCreateSchema</name>
    <value>true</value>
  </property>
  <property>
    <name>datanucleus.fixedDatastore</name>
    <value>false</value>
  </property>
  <property>
    <name>datanucleus.autoCreateTables</name>
    <value>true</value>
  </property>
</configuration>
EOF

echo -e "\n[SUCCESS] Hive ${HIVE_VERSION} has been installed and configured successfully!"
echo -e "Next Steps:"
echo -e "- Run 'source ~/.zshrc' or open a new terminal to load Hive environment."
echo -e "- Start MySQL server and create a database named 'metastore'."
echo -e "- Create a user 'hive' with password 'hivepassword' and grant all privileges on the 'metastore' database."
echo -e "- Download MySQL Connector/J and place it in the Hive lib directory. (https://downloads.mysql.com/archives/c-j/)"
echo -e "- Initialize the Hive metastore with: schematool -initSchema -dbType mysql"
echo -e "- Start HiveServer2 with: hive --service hiveserver2"
echo -e "- Start Hive shell with: hive"
echo -e "- Start Beeline shell with: beeline -u 'jdbc:hive2://localhost:10000/'"
