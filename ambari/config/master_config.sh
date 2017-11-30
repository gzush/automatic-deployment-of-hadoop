#!/bin/sh

readonly PROGDIR=$(readlink -m $(dirname $0))


echo Install pssh expect
cd /root/config/software/pssh-2.3.1    
python setup.py install

yum install -q -y expect


echo Copy ssh...
NN_FILE=$PROGDIR/conf/namenode
DN_FILE=$PROGDIR/conf/datanode
NN="`cat $NN_FILE |sort -n | uniq | tr '\n' ' '|  sed 's/,$//'`"
DN="`cat $DN_FILE |sort -n | uniq | tr '\n' ' '|  sed 's/,$//'`"
ALL="`cat $NN_FILE $DN_FILE |sort -n | uniq | tr '\n' ' '|  sed 's/,$//'`"
PASSWORD='redhat'

auto_ssh_copy_id() {
    expect -c "set timeout -1;
        spawn ssh-copy-id $1;
        expect {
            *(yes/no)* {send -- yes\r;exp_continue;}
            *password* {send -- $2\r;exp_continue;}
            eof        {exit 0;}
        }";
}

ssh_copy_id_to_all() {
    for SERVER in $DN
    do
        auto_ssh_copy_id $SERVER $PASSWORD
    done
}

ssh_copy_id_to_all


echo Backup private key...
[ -f ~/config/id_rsa ] && ( rm -rf ~/config/id_rsa )
cp  ~/.ssh/id_rsa ~/config/


echo Config mysql...
yum install -y -q mysql-server
echo "bind-address = 0.0.0.0"  >>  /etc/my.cnf

systemctl start mysqld

password="`grep 'root@localhost' /var/log/mysqld.log | awk '{ print $11; }'`"
echo "SET PASSWORD  = PASSWORD('Root-123');" | mysql -u root --password=$password -b --connect-expired-password

mysql -u root -pRoot-123 <<EOF
    create database ambari character set utf8 ;  
    CREATE USER 'ambari'@'%'IDENTIFIED BY 'Ambari-123';
    GRANT ALL PRIVILEGES ON *.* TO 'ambari'@'%';
    FLUSH PRIVILEGES;

    create database hive character set utf8 ;  
    CREATE USER 'hive'@'%'IDENTIFIED BY 'Hive-123';
    GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%';
    FLUSH PRIVILEGES;

    create database oozie character set utf8 ;  
    CREATE USER 'oozie'@'%'IDENTIFIED BY 'Oozie-123';
    GRANT ALL PRIVILEGES ON *.* TO 'oozie'@'%';
    FLUSH PRIVILEGES;    
EOF

yum -y -q install mysql-connector-java


echo Config ambari-server...
yum -y -q install ambari-server

config_ambari() {
    expect -c "spawn ambari-server setup;
        expect {
            *daemon* {send -- \r;exp_continue;}
            *change* {send -- y\r;exp_continue;}
            *Custom* {send -- 3\r;exp_continue;}
            *JAVA_HOME* {send -- $1\r;exp_continue;}
            *configuration* {send -- y\r;exp_continue;}
            *choice* {send -- 3\r;exp_continue;}
            *Hostname* {send -- \r;exp_continue;}
            *Port* {send -- \r;exp_continue;}
            *(ambari)* {send -- \r;exp_continue;}
            *Password* {send -- $2\r;exp_continue;}
            *Re-enter* {send -- $2\r;exp_continue;}
            *connection* {send -- \r;exp_continue;}
            eof        {exit 0;}
        }";
}
config_ambari $JAVA_HOME 'Ambari-123'

mysql -u ambari -pAmbari-123 <<EOF
    use ambari;
    source /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql;
EOF

ambari-server start
