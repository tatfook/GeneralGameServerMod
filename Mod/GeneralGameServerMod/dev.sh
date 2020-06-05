
#!/bin/bash 

workspace_dir=`pwd`
while true
do 
    inotifywait -rq -e modify,create,delete,move --exclude log.txt .
    sleep 1
    pm2 restart ParacraftServer
done
