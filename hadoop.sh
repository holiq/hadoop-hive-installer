#!/bin/bash

# # Update system
sudo apt update && sudo apt upgrade -y

# Install Java (OpenJDK 11)
sudo apt install -y openjdk-11-jdk wget ssh

# Setup Java environment
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> ~/.bashrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc
source ~/.bashrc

# Create Hadoop user (optional)
# sudo adduser hadoopuser
# sudo usermod -aG sudo hadoopuser
# su - hadoopuser

# Variables
HADOOP_VERSION=3.4.1
HADOOP_HOME=/usr/local/hadoop
HADOOP_URL=https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

# Download and extract Hadoop
cd /tmp
wget $HADOOP_URL
sudo tar -xzvf hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/
sudo mv /usr/local/hadoop-${HADOOP_VERSION} $HADOOP_HOME
sudo chown -R $(whoami):$(whoami) $HADOOP_HOME

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
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
EOF

source ~/.zshrc

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

# Format Namenode
hdfs namenode -format

# Start Hadoop daemons
start-dfs.sh
start-yarn.sh

echo "Hadoop ${HADOOP_VERSION} installation completed!"
