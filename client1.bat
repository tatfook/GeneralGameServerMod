@echo off 
pushd "%~dp0../../../ParacraftDev/" 
call "ParaEngineClient.exe" IsDevEnv="true" mc="true"  world="worlds/DesignHouse/test" logfile="D:\workspace\npl\GeneralGameServerMod\client1.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"
popd 

