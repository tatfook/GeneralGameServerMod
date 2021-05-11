
#!/bin/bash 

# 进入传入目录
if test -n "$1" 
then
    cd "$1"
fi

# 确保在npl_packages目录, 且paracraftbuildinmod.zip文件存在
if ! test -e "paracraftbuildinmod.zip" 
then
    echo "请传入npl_packages目录路径, 或在该目录下执行本脚本"
    exit -1
fi

# 确保ParacraftBuildinMod目录存在
if ! test -d "ParacraftBuildinMod"
then
    unzip paracraftbuildinmod.zip
fi

# 确保 GeneralGameServerMod 存在
if ! test -d "GeneralGameServerMod"
then
    git clone https://github.com/tatfook/GeneralGameServerMod.git
    cd GeneralGameServerMod
    git pull origin master
    # git checkout -b dev origin/dev
    # git pull origin dev
    cd ..
fi

# 更新 GeneralGameServerMod
cd GeneralGameServerMod
git reset --hard HEAD
git pull origin master
# git checkout dev
# git pull origin dev
cd ..
rm -fr ParacraftBuildinMod/Mod/GeneralGameServerMod/
cp -fr GeneralGameServerMod/Mod/GeneralGameServerMod/ ParacraftBuildinMod/Mod/

# zip -r ParacraftBuildinMod.zip ParacraftBuildinMod

# unzip paracraftbuildinmod.zip
# rm -fr paracraftbuildinmod.zip
# if ! test -d "GeneralGameServerMod"
# then
#     git clone https://github.com/tatfook/GeneralGameServerMod.git
# fi
# cd GeneralGameServerMod
# git reset --hard HEAD
# git pull origin master
# rm -fr ParacraftBuildinMod/Mod/GeneralGameServerMod/
# cp -fr GeneralGameServerMod/Mod/GeneralGameServerMod/ ParacraftBuildinMod/Mod/
# zip -r ParacraftBuildinMod.zip ParacraftBuildinMod
# rm -fr ParacraftBuildinMod