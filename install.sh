#Install Script

#Set variables
StarRocks_version=2.5.0-rc03
StarRocks_home=~/data/deploy
Java_version=java-1.8.0-openjdk-devel.x86_64
StarRocks_url=https://releases.starrocks.io/starrocks/StarRocks-${StarRocks_version}.tar.gz

# Install StarRocks.
sudo yum -y install wget
mkdir -p $StarRocks_home -m 777
wget -SO $StarRocks_home/StarRocks-${StarRocks_version}.tar.gz  $StarRocks_url
cd $StarRocks_home && tar zxf StarRocks-${StarRocks_version}.tar.gz

# Install Java JDK.
sudo yum -y install ${Java_version}
rpm -ql ${Java_version} | grep bin$


JAVA_INSTALL_DIR=/usr/lib/jvm/$(rpm -aq | grep java-1.8.0-openjdk-1.8.0)
export JAVA_HOME=$JAVA_INSTALL_DIR

# Create directories for FE meta and BE storage in StarRocks.
mkdir -p $StarRocks_home/StarRocks-${StarRocks_version}/fe/meta
mkdir -p $StarRocks_home/StarRocks-${StarRocks_version}/be/storage

# Install relevant tools.
sudo yum -y install mysql net-tools telnet

# Start FE.
cd $StarRocks_home/StarRocks-${StarRocks_version}/fe/bin/
./start_fe.sh --daemon

# Start BE.
cd $StarRocks_home/StarRocks-${StarRocks_version}/be/bin/
sudo ./start_be.sh --daemon

# Create and add scripts to startup a file
# Write java variables to the file
echo JAVA_HOME=$JAVA_HOME >> $StarRocks_home/startup.sh;
echo export JAVA_HOME >> $StarRocks_home/startup.sh;
# Write the db services locations
echo sh $StarRocks_home/StarRocks-${StarRocks_version}/fe/bin/start_fe.sh --daemon >> $StarRocks_home/startup.sh;
echo sh $StarRocks_home/StarRocks-${StarRocks_version}/be/bin/start_be.sh --daemon >> $StarRocks_home/startup.sh;
# Add the crontab job for the user to run the startup job on reboot
(crontab -l; echo "@reboot $StarRocks_home/startup.sh") | sort -u | crontab -

# Sleep until the cluster starts.
sleep 30;

# Set the BE server IP.
IP=$(ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{print $2}')
mysql -uroot -h${IP} -P 9030 -e "alter system add backend '${IP}:9050';"

# Loop to detect the process.
while sleep 60; do 
  ps aux | grep starrocks | grep -q -v grep
  PROCESS_STATUS=$?

  if [ ${PROCESS_STATUS} -ne 0 ]; then
    echo "one of the starrocks process already exit."
    exit 1;
  fi
done