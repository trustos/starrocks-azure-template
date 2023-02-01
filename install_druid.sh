# Set variables

ApacheDruid_home=~/data/deploy
ApacheDruid_version=apache-druid-25.0.0
Java_version=java-1.8.0-openjdk-devel.x86_64
ApacheDruid_url=https://dlcdn.apache.org/druid/25.0.0/${ApacheDruid_version}-bin.tar.gz

# Download and install Apache Druid
yum -y install wget ${Java_version}
sudo mkdir -p $ApacheDruid_home -m 777
wget -SO $ApacheDruid_home/${ApacheDruid_version}-bin.tar.gz $ApacheDruid_url
cd $ApacheDruid_home && tar zxf ${ApacheDruid_version}-bin.tar.gz

# Install Java SDK
sudo yum -y install ${Java_version}
rpm -ql ${Java_version} | grep bin$

JAVA_INSTALL_DIR=/usr/lib/jvm/$(rpm -aq | grep java-1.8.0-openjdk-1.8.0)
export JAVA_HOME=$JAVA_INSTALL_DIR

# Install Python
sudo yum -y install python3

cd $ApacheDruid_home/$ApacheDruid_version
./bin/start-druid

# Create and add scripts to startup a file
# Write java variables to the file
echo JAVA_HOME=$JAVA_HOME >> $StarRocks_home/startup.sh;
echo export JAVA_HOME >> $StarRocks_home/startup.sh;
# Write the db services locations
echo sh $ApacheDruid_home/$ApacheDruid_version/bin/start-druid >> $ApacheDruid_home/startup.sh;
# Add the crontab job for the user to run the startup job on reboot
echo "@reboot $ApacheDruid_home/startup.sh" >> /etc/crontab
chmod +x $ApacheDruid_home/startup.sh
