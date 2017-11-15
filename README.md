# automatic-deployment-of-hadoop
hadoop自动化部署脚本

## 安装VirtualBox
下载地址：https://www.virtualbox.org/wiki/Downloads/

## 安装Vagrant
下载安装包：http://downloads.vagrantup.com/，然后安装。

## 下载box
下载适合你的box，地址：http://www.vagrantbox.es/。

例如下载 CentOS6.5：

$ wget https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box
添加box
首先查看已经添加的box：

$ vagrant box list
添加新的box，可以是远程地址也可以是本地文件，建议先下载到本地再进行添加：

$ vagrant box add centos6.5 ./centos65-x86_64-20140116.box
其语法如下：

vagrant box add {title} {url}
box 被安装在 ~/.vagrant.d/boxes 目录下面。