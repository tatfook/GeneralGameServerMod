#!/bin/bash 

IP="127.0.0.1"
PORT="9000"


while true 
do
    # 暂停
    sleep 1

    # 检测程序是否正常
    status_code=`curl -I -m 10 -o /dev/null -s -w %{http_code} http://${IP}:${PORT}/heartbeat`
    if [ ${status_code} = "200" ]; then
        echo "is alive"
    else
        echo "is dead"
    fi

done
