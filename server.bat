@echo off 
call "D:\ParacraftDev\ParaEngineClient.exe" IsDevEnv="true" servermode="true" ConfigFile="config.xml" bootstrapper="D:\workspace\npl\GeneralGameServerMod\Mod\GeneralGameServerMod\main.lua" logfile="D:\workspace\npl\GeneralGameServerMod\server.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"


@REM npl IsDevEnv="true" servermode="true" bootstrapper="/mnt/d/workspace/npl/GeneralGameServerMod/Mod/GeneralGameServerMod/main.lua" logfile="/mnt/d/workspace/npl/GeneralGameServerMod/server.log" loadpackage="/mnt/d/workspace/npl/paracraft/,;/mnt/d/workspace/npl/GeneralGameServerMod/"

@REM pm2 start --name "GGS" npl -- xxxx


@REM npl IsDevEnv="true" servermode="true" bootstrapper="Mod/GeneralGameServerMod/main.lua" logfile="server.log" loadpackage="npl_packages/paracraft/"
@REM npl IsDevEnv="true" servermode="true" bootstrapper="Mod/GeneralGameServerMod/main.lua" logfile="server.log" loadpackage="/mnt/d/workspace/npl/paracraft/"

