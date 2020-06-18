
#!/bin/bash 

pm2 delete GGS
pm2 start --name "GGS" npl --  isDevEnv="true" servermode="true" bootstrapper="/root/workspace/npl/GeneralGameServerMod/Mod/GeneralGameServerMod/Server/main.lua" logfile="/root/workspace/npl/GeneralGameServerMod/server.log" loadpackage="/root/workspace/npl/script/trunk/,;/root/workspace/npl/GeneralGameServerMod/"
while true
do 
    inotifywait -rq -e modify,create,delete,move  '/root/workspace/npl/GeneralGameServerMod/Mod/GeneralGameServerMod/Server'
    sleep 3
    pm2 restart GGS
done
