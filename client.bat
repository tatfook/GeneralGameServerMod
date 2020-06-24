@echo off 
pushd "%~dp0../../../ParacraftDev/" 
call "ParaEngineClient.exe" IsDevEnv="true" mc="true"  world="worlds/DesignHouse/test" logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"
REM call "ParaEngineClient.exe" IsDevEnv=true mc="true" logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"
popd 

