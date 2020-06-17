# GeneralGameServer

Paracraft 长连接服务器, 主要用于客户端消息的推送, 以便完成相应的功能, 如paracraft玩家的位置信息同步等

## 服务端部署

- 安装 NPL 运行环境, 进入工作目录: `cd /workspace` (可更改工作目录, 此处以 `/workspace`)
- 下载代码: `git clone git@github.com:tatfook/GeneralGameServerMod.git`
- 启动程序: npl servermode="true" bootstrapper="/workspace/GeneralGameServerMod/Mod/GeneralGameServerMod/Server/main.lua" loadpackage="/workspace/GeneralGameServerMod/"
**loadpackage选项中还需加载 paracraft 脚本包**

## 客户端使用

### 应用使用

- 下载客户端模块的ZIP包, 下载地址: https://github.com/tatfook/GeneralGameServerMod
- 将下载好的zip包放在Paracraft安装目录的Mod文件夹里
- 启动Paracraft, 在登录页面, 点登录框下面的MOD加载, 再在弹出的Mod对话框中找到刚放入的zip包模块, 并勾选
- 登录进入世界, 执行 `connectGGS ip port` 命令进入多人世界

### 代码调用

```lua
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameClient.lua");
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient");
local client = GeneralGameClient.GetSingleton();
client.LoadWorld("127.0.0.1", "9000", 12348);
```

### 问题

- 世界数据同步?  实时同步世界所有数据,  同步可视数据