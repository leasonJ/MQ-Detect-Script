# MQ-Detect-Script
检测MQ通道运行情况

一、注意事项：
1、确保Tomcat服务正常运行；
2、确保MQ通道已联调正常收发；
总而言之：在已正常运行的情况下，运行该脚本实现监控。

二、文件介绍：
1、mqdetect.sh 执行检测程序
2、mqlistenertest.sh 子程序，检测mq监听
3、mqqltest.sh 子程序，检查mq队列

二、运行脚本：
1、使用root用户新建该脚本的文件目录（mkdir XXX），将上述脚本置于该目录中（wget ），并分配执行权限(chmod -R 770 XXX);
2、配置mqdetect.sh文件，修改变量信息如下：
2.1、NetAddress="XXX.XXX.XXX.XXX" MQ对端服务地址；
2.2、MqUser="mqm" mq的启动用户，默认为mqm；（同mqqltest.sh和mqlistenertest.sh中的用户）
2.3、TomcatUser="root" tomcat的启动用户，默认为root;
2.4、ScriptUser="root" 此脚本的启动用户，默认为root;
3、运行./mqdetect.sh &
4、停止ps -ef|grep mqdetect.sh，kill进程即可。
