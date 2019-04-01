#!/bin/bash
#Program:
#	1.To detect log, Problem from it
#	2.To detect network status
#	3.To detect Tomcat status
#	4.To detect MQ status
#	4.1To detect MQ ql depth
#	4.2To detect MQ listener status
#History:
#2019-03-30 Jilb version 1.0
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

PackageRecive=1
NetAddress="10.50.0.22"
SleepTime="30s"
MqQlDetect="mqqltest.sh"
MqListenerDetect="mqlistenertest.sh"
MqUser="mqm"
TomcatUser="root"
ScriptUser="root"

su - root -c updatedb
echo -e "Check ${MqQlDetect} is exist? "
if [ -f "${MqQlDetect}" ]; then
	echo -e "exist\n"
	MqQlScriptPath=$(locate "${MqQlDetect}")
else
	echo -e "not exist, Please check file!\n"
	exit
fi

echo -e "Check ${MqListenerDetect} is exist? "
if [ -f "${MqListenerDetect}" ]; then
	echo -e "exist\n"
	MqListenerScriptPath=$(locate "${MqListenerDetect}")
else
	echo -e "not exist, Please check file!\n"
	exit
fi

echo -e "Check Mbfe startup.sh is exist? "
StartMbfePath=$(locate startup.sh | grep tomcat)
if [ -n ${StartMbfePath} ]; then
	echo -e "exist\n"
	echo -e "Check Mbfe status: "
	TomcatStatus=$(ps -ef|grep tomcat|awk '$7 > "00:00:00" {print $9}')
	if [ -z ${TomcatStatus} ]; then
		echo -e "Stoped. go to start Mbfe\n"
		su - ${TomcatUser} -c "${StartMbfePath}"
		if [ "$?" == "0" ]; then
			echo -e "Mbfe start Successful\n"
			sleep 1s
			TomcatStatusNormal=$(ps -ef|grep tomcat|awk '$7 > "00:00:00" {print $9}')
		else
			echo -e "Mbfe start fail, Please check log\n"
			exit
		fi
	else
		echo -e "Running\n"
		sleep 1s
		TomcatStatusNormal=$(ps -ef|grep tomcat|awk '$7 > "00:00:00" {print $9}')
	fi
else
	echo -e "not exist, Please install Mbfe first!\n"
	exit
fi

while [ "${PackageRecive}" == "1" ]
do
	PackageRecive=$(ping ${NetAddress} -c 1 | sed '/^$/d' | sed '1,3d' | awk 'BEGIN {FS=","} {printf $2 "\t" $3} ' | cut -c 2)
	if [ "${PackageRecive}" == "1" ]; then
		echo -e "The link of ${NetAddress} is successful and go into sleep ${SleepTime}, This time is $(date)\n"

		TomcatStatus=$(ps -ef|grep tomcat|awk '$7 > "00:00:00" {print $9}')
		if [ "${TomcatStatus}" == "${TomcatStatusNormal}" ]; then
			echo -e "Mbfe is running\n"
		else
			echo -e "Mbfe stopped, go to Start MBFE\n"
			su - ${TomcatUser} -c "${StartMbfePath}"
			if [ "$?" == "0" ]; then
				echo -e "Mbfe start Successful\n"
			else
				echo -e "Mbfe start fail, Please check log\n"
			fi
		fi

		MqStatus=$(dspmq | awk '{print $2}')
		if [ "${MqStatus}" == "STATUS(Running)" ]; then
			echo -e "MQ is running\n"
			CheckQueueFlag=1
		else
			echo -e "MQ stopped, go to start MQ\n"
			su - ${MqUser} -c "strmqm QMEMBFE"
			if [ "$?" == "0" ]; then
                                echo -e "MQ start Successful\n"
				CheckQueueFlag=1
                        else
                                echo -e "MQ start fail, Please check log\n"
				CheckQueueFlag=0
                        fi
		fi

#		if [ ]; then
			
#		else
			
#		fi

		if [ ${CheckQueueFlag} == 1 ]; then
			echo -e "Go to MQ, and check QL depth\n"
			unset CheckQueueFlag
			for ((line=6;line<=21;line=line+3))
			do
				depth=$(su - ${ScriptUser} -c "${MqQlScriptPath}" | sed -e '/^$/d' | awk 'NR=="'${line}'"' | cut -c 13)
				qlnameline=$[${line}-1]
				qlname=$(su - ${ScriptUser} -c "${MqQlScriptPath}" | sed -e '/^$/d' | awk 'NR=="'${qlnameline}'" {printf $1}')
				if [ "${depth}" != "0" ]; then
					echo -e "${qlname} is Blocking, Please restart ECDS server\n"
				else
					echo -e "${qlname} is Smooth\n"
				fi
			done
			echo -e "Go to restart Listener\n"
			ListenerStatus=$(su - ${ScriptUser} -c "${MqListenerScriptPath}" | sed -e '/^$/d' | awk 'BEGIN{FS=":"} NR==4 {printf $1}')
			if [ "${ListenerStatus}" == "AMQ8730" ]; then
				echo -e "Listener already active\n"
			elif [ "${ListenerStatus}" == "AMQ8021"]; then
				echo -e "Listener start successful\n"
			else
				echo -e "Listener start fail, Please check Listener\n"
			fi
		else
			echo -e "Please start MQ first!\n"			
		fi
		sleep ${SleepTime}
	else
		echo -e "The link of ${NetAddress} is fail, Problem fund at $(date)\n"
	fi
done
