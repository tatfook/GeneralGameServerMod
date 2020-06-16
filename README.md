# GeneralGameServer

Paracraft 长连接服务器, 主要用于客户端消息的推送, 以便完成相应的功能, 如paracraft玩家的位置信息同步等

## 服务端部署

- 安装 NPL 运行环境, 进入工作目录: `cd /workspace` (可更改工作目录, 此处以 `/workspace`)
- 下载代码: `git clone git@github.com:tatfook/GeneralGameServerMod.git`
- 启动程序: npl servermode="true" bootstrapper="/workspace/GeneralGameServerMod/Mod/GeneralGameServerMod/Server/main.lua" loadpackage="/workspace/GeneralGameServerMod/"

