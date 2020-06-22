# GeneralGameServerMod

GeneralGameServerMod 是基于 Paracraft 的一个多人联机的模块, 包含了该功能的客户端和服务端代码.

## 特性

- 多个用户进入同一联机世界观赏, 编辑, 创造等
- 同时提供多个联机世界, 用户可以随时切换联机世界
- 提供联机世界保存, 多人编辑.

## 实现原理

要将整个世界完全数据化, 存在服务端内存中, 这样式同时支持不了多少个联机世界, 这是核心问题, 其次就是如何更好的降低通信流量和高效数据通信来提升联机的用户体验. 目前实现并没有解决问题, 仍旧是世界数据化存于内存, 转发用户世界的更改到其它用户, 以达到用户世界的一致性.

### 客户端程序流程

- 执行命令: `connectGGS ip port worldId` 进入联机世界 worldId(keepwork项目Id)
- 如 worldId 为 0, 则进入默认空世界, 否则加载并打开 worldId 对应的世界
- 与服务器建立TCP链接, 并登陆服务端对应的 worldId 世界中
- 接受服务端 worldId 世界更新数据并应用数据到客户端世界
- 接受新世界更新并应用, 监听当前用户的更新并发送至服务器(以便同步到其它用户世界)

### 服务端程序流程

- 程序启动, 启动TCP Server并监听客户端连接
- 客户端接入, 完成认证交互
- 认证通过后, 建立世界新玩家, 并将当前世界相关信息(玩家信息, 方块信息等)下发给新用户.
- 接受客户端对世界的更新信息, 将新更新存于后端数据化世界中, 并转发给其它玩家

## 服务端部署

- 安装 NPL 运行环境, 进入工作目录: `cd /workspace` (可更改工作目录, 此处以 `/workspace`)
- 下载代码: `git clone git@github.com:tatfook/GeneralGameServerMod.git`
- 启动程序: npl servermode="true" bootstrapper="/workspace/GeneralGameServerMod/Mod/GeneralGameServerMod/Server/main.lua" loadpackage="/workspace/GeneralGameServerMod/"
**loadpackage选项中还需加载 paracraft 脚本包**

### 开发

```sh
pm2 start npm npl --name "GGS" --  isDevEnv="true" servermode="true" bootstrapper="/root/workspace/GeneralGameServerMod/Mod/GeneralGameServerMod/Server/main.lua" logfile="/root/workspace/GeneralGameServerMod/server.log" loadpackage="/root/workspace/GeneralGameServerMod/,;/root/workspace/npl/script/trunk/"
```

## 客户端部署

- 下载客户端模块的ZIP包, 下载地址: https://github.com/tatfook/GeneralGameServerMod
- 将下载好的zip包放在Paracraft安装目录的Mod文件夹里
- 启动Paracraft, 在登录页面, 点登录框下面的MOD加载, 再在弹出的Mod对话框中找到刚放入的zip包模块, 并勾选
- 登录进入世界, 执行 `connectGGS worldId` 命令进入多人世界, 或按F12执行如下代码:

```lua
NPL.load("Mod/GeneralGameServerMod/Client/GeneralGameClient.lua");
local GeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.Client.GeneralGameClient");
local client = GeneralGameClient.GetSingleton();
client.LoadWorld("127.0.0.1", "9000", 0);
```

### 问题

- 世界数据同步?  实时同步世界所有数据,  同步可视数据
- 链接的断开与链接   fixed
- 世界重复打开       fixed
- 客户端只能选择服务器
- 世界打开失败

### 版本
