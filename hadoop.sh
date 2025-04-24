#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install Java (OpenJDK 11)
sudo apt install -y openjdk-11-jdk wget ssh

# Setup Java environment
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> ~/.zshrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.zshrc

# Create Hadoop user (optional)
# sudo adduser hadoopuser
# sudo usermod -aG sudo hadoopuser
# su - hadoopuser

# Variables
HADOOP_DIR=/usr/local
HADOP_NAME=hadoop
HADOOP_VERSION=3.4.1
HADOOP_HOME=${HADOOP_DIR}/${HADOP_NAME}
HADOOP_URL=https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

# Check if Hadoop is already installed
if [ -d "$HADOOP_HOME" ]; then
  echo -e "[WARNING] Hadoop appears to be already installed at $HADOOP_HOME."
  echo -e "If you want to reinstall, please remove the directory manually and rerun this script."
  exit 0
fi

# Download and extract Hadoop
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAR_FILE="$CURRENT_DIR/hadoop-${HADOOP_VERSION}.tar.gz"
EXTRACTED_DIR="${CURRENT_DIR}/hadoop-${HADOOP_VERSION}"

# Check if tar file exists
if [ -f "$TAR_FILE" ]; then
  echo "Tar file already exists at $TAR_FILE, skipping download."
else
  echo "Downloading Hadoop ${HADOOP_VERSION}..."
  wget -O "$TAR_FILE" "$HADOOP_URL"
fi

# Check if Hadoop is already extracted
if [ -d "$EXTRACTED_DIR" ]; then
  echo "Hadoop already extracted at $EXTRACTED_DIR, skipping extraction."
  sudo mv "$EXTRACTED_DIR" "$HADOOP_HOME"
else
  sudo tar -xzvf "$TAR_FILE" -C $HADOOP_DIR
  sudo mv "${HADOOP_DIR}/hadoop-${HADOOP_VERSION}" "$HADOOP_HOME"
fi

sudo chown -R $(whoami):$(whoami) "$HADOOP_HOME"

# Set Hadoop environment variables
cat <<EOF >> ~/.zshrc

# Hadoop Environment Variables
export HADOOP_HOME=$HADOOP_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
EOF

ssh-keygen -t rsa -P "" -f ~/.ssh/hadoop_rsa
cat ~/.ssh/hadoop_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Configure Hadoop for pseudo-distributed mode
cd $HADOOP_HOME/etc/hadoop

# core-site.xml
cat > core-site.xml <<EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
  <property>
    <name>hadoop.proxyuser.$(whoami).hosts</name>
    <value>*</value>
  </property>
  <property>
    <name>hadoop.proxyuser.$(whoami).groups</name>
    <value>*</value>
  </property>
</configuration>
EOF

# hdfs-site.xml
cat > hdfs-site.xml <<EOF
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>
EOF

# mapred-site.xml
cat > mapred-site.xml <<EOF
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.application.classpath</name>
    <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
  </property>
</configuration>
EOF


# yarn-site.xml
cat > yarn-site.xml <<EOF
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.env-whitelist</name>
    <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
  </property>
</configuration>
EOF

# Set JAVA_HOME in hadoop-env.sh
sed -i 's|^# export JAVA_HOME=.*|export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64|' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
# Add this if yarn not started and use java 11 above on bottom of hadoop-env.sh
# export HADOOP_OPTS="$HADOOP_OPTS --add-opens=java.base/java.lang=ALL-UNNAMED"

echo -e "\n[SUCCESS] Hadoop ${HADOOP_VERSION} has been installed and configured successfully!"
echo -e "Next Steps:"
echo -e "- Open a new terminal or run 'source ~/.zshrc' to apply changes."
echo -e "- Format the HDFS namenode by running: hdfs namenode -format"
echo -e "- Start Hadoop daemons using: start-dfs.sh && start-yarn.sh"
echo -e "- Check the Hadoop web UI at http://localhost:9870 for HDFS and http://localhost:8088 for YARN."
echo -e "- To stop Hadoop, use: stop-dfs.sh && stop-yarn.sh"

