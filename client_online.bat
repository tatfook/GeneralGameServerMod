@echo off 
call "D:\ParacraftDev\ParaEngineClient.exe"  mc="true"   logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;D:\workspace\npl\WorldShare/,;"

@REM call "D:\ParacraftDev\ParaEngineClient.exe" mc="true"  world="worlds/DesignHouse/tutorial" logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"

@REM call "D:\ParacraftDev\ParaEngineClient.exe" IsDevEnv="true" http_env="RELEASE" env="local" mc="true"  world="worlds/DesignHouse/tutorial" logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"

@REM call "D:\ParacraftDev\ParaEngineClient.exe" IsDevEnv="true" http_env="RELEASE" env="local" mc="true"  logfile="D:\workspace\npl\GeneralGameServerMod\client.log" loadpackage="D:\workspace\npl\paracraft/,;D:\workspace\npl\GeneralGameServerMod/,;"
