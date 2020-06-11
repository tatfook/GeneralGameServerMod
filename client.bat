@echo off 
pushd "%~dp0../../../Paracraft_Dev/" 
call "ParaEngineClient.exe" isDevEnv=true mc="true"  world="worlds/DesignHouse/test" logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\script\trunk/,;D:\workspace\npl\GeneralGameServerMod/,;"
REM call "ParaEngineClient.exe" isDevEnv=true mc="true" logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\script\trunk/,;D:\workspace\npl\GeneralGameServerMod/,;"
popd 

