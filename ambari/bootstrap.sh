#!/usr/bin/env bash

# The output of all these installation steps is noisy. With this utility
# the progress report is nice and concise.
function install {
    echo Installing $1
    shift
    yum -y install "$@" >/dev/null 2>&1
}

echo "Update /etc/hosts"
cat > /etc/hosts <<EOF
127.0.0.1       localhost

192.168.56.121	cdh1	cdh1.hadoop.com
192.168.56.122	cdh2	cdh2.hadoop.com
192.168.56.123	cdh3	cdh3.hadoop.com
EOF

echo -e  "NETWORKING=yes\nHOSTNAME=$HOSTNAME.hadoop.com" >> /etc/sysconfig/network

echo "Remove unused logs"
sudo rm -rf /root/anaconda-ks.cfg /root/install.log /root/install.log.syslog /root/install-post.log

echo "Disable iptables"
setenforce 0 >/dev/null 2>&1 && iptables -F

### Set env ###
echo "export LC_ALL=en_US.UTF-8"  >>  /etc/profile
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "Disable SELinux"
[ -f /etc/init.d/boot.apparmor ] && SELINUX="boot.apparmor"
[ -f /usr/sbin/setenforce ] && SELINUX="selinux"
if [ $SELINUX == "selinux" ]; then
    sed -i "s/.*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
    setenforce 0  >/dev/null 2>&1
elif [ $SELINUX == "boot.apparmor" ]; then
    service boot.apparmor stop >/dev/null 2>&1
    chkconfig boot.apparmor off > /dev/null 2>&1
fi

echo "Setup yum repos"
rm -rf /etc/yum.repos.d/*
cp /vagrant/*.repo /etc/yum.repos.d/
cd /etc/yum.repos.d/
sudo wget -q http://mirrors.163.com/.help/CentOS7-Base-163.repo
# sudo wget -q  http://mirrors.aliyun.com/repo/epel-7.repo
yum -q clean all >/dev/null 2>&1
sudo yum -q makecache

echo "Setup root account"
# Setup sudo to allow no-password sudo for "admin". Additionally,
# make "admin" an exempt group so that the PATH is inherited.
cp /etc/sudoers /etc/sudoers.orig
echo "root            ALL=(ALL)               NOPASSWD: ALL" >> /etc/sudoers
echo 'redhat'|passwd root --stdin >/dev/null 2>&1

echo "Setup nameservers"
# http://ithelpblog.com/os/linux/redhat/centos-redhat/howto-fix-couldnt-resolve-host-on-centos-redhat-rhel-fedora/
# http://stackoverflow.com/a/850731/1486325
echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf
echo "nameserver 8.8.4.4" | tee -a /etc/resolv.conf

echo "Setup ssh"
[ ! -d ~/.ssh ] && ( mkdir ~/.ssh ) && ( chmod 600 ~/.ssh )
[ ! -f ~/.ssh/id_rsa.pub ] && ( yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "" ) && ( chmod 600 ~/.ssh/id_rsa.pub ) && ( cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys )



# install Git git
install "Base tools" vim wget curl ntp

( systemctl disable chronyd ) && ( systemctl enable ntpd ) && ( systemctl start ntpd )

echo Installing java sdk ...
sudo rpm -i /root/config/software/jdk/jdk-8u131-linux-x64.rpm
java -version

echo Setting up java environment variables ...
cat << EOF >> ~/.bashrc
#set oracle jdk environment
export JAVA_HOME=/usr/java/default
export JRE_HOME=\${JAVA_HOME}/jre
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib
export PATH=\${JAVA_HOME}/bin:\$PATH
EOF
source ~/.bashrc
# echo ${JAVA_HOME}
# echo ${JRE_HOME}
# echo ${PATH}

#install PostgreSQL postgresql-server postgresql-jdbc
#sudo -u postgres createuser --superuser vagrant
#sudo -u postgres createdb -O vagrant test1
#sudo -u postgres createdb -O vagrant test2


echo 'All set, rock on!'
