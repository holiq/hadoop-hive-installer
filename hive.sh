#!/bin/bash

set -e

# -------------------- CONFIG --------------------
HIVE_VERSION=4.0.1
HIVE_DIR=/usr/local/hive
HIVE_URL="https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz"
# -----------------------------------------------

# Download Hive
if [ ! -f apache-hive-${HIVE_VERSION}-bin.tar.gz ]; then
  echo "Downloading Hive..."
  wget $HIVE_URL
fi

echo "Extracting Hive..."
sudo tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz -C /usr/local/
sudo mv /usr/local/apache-hive-${HIVE_VERSION}-bin $HIVE_DIR
sudo chown -R $(whoami):$(whoami) $HIVE_DIR

# Set environment variables
cat <<EOF >> ~/.zshrc

# Hive Environment Variables
export HIVE_HOME=$HIVE_DIR
export PATH=\$PATH:\$HIVE_HOME/bin
EOF

# source ~/.zshrc

# Configure Hive
mkdir -p $HIVE_DIR/tmp
mkdir -p $HOME/hive/warehouse

# hive-site.xml
cat > $HIVE_DIR/conf/hive-site.xml <<EOF
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
    <value>$HIVE_DIR/tmp</value>
  </property>

  <property>
    <name>hive.metastore.schema.verification</name>
    <value>false</value>
  </property>
</configuration>
EOF

# Initialize metastore schema (optional in Derby)
schematool -initSchema -dbType derby || echo "Metastore already initialized."

# Success
echo
echo "✅ Hive ${HIVE_VERSION} installed successfully!"
echo "To start Hive shell, run: hive"
