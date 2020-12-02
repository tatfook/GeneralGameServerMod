# GeneralGameServerMod

GeneralGameServerMod 是基于 Paracraft 的一个多人联机的模块, 包含了该功能的客户端和服务端代码.

## 特性

- 多个用户进入同一联机世界观赏, 编辑, 创造等
- 同时提供多个联机世界, 用户可以随时切换联机世界
- 提供联机世界保存, 多人编辑.

## 实现原理

采用后端的集群模式, 服务器作为集群控制节点主负责客户端数据转发工作, 客户端可以看做集群中的工作节点.

### 客户端程序流程

- 执行命令: `ggs connect worldId` 进入联机世界 worldId(keepwork项目Id)
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
- 启动程序: npl servermode="true" bootstrapper="/workspace/GeneralGameServerMod/Mod/GeneralGameServerMod/main.lua" loadpackage="/workspace/GeneralGameServerMod/"
**loadpackage选项中还需加载 paracraft 脚本包**

### 开发

```sh
pm2 start npm npl --name "GGS" --  isDevEnv="true" servermode="true" bootstrapper="/root/workspace/GeneralGameServerMod/Mod/GeneralGameServerMod/Server/main.lua" logfile="/root/workspace/GeneralGameServerMod/server.log" loadpackage="/root/workspace/GeneralGameServerMod/,;/root/workspace/npl/script/trunk/"
```

## 客户端部署

- 下载 GGS 模块的ZIP包, 并解压获得 GeneralGameServerMod 源码目录. 下载地址: <https://github.com/tatfook/GeneralGameServerMod>
- 进入 Paracraft 的安装目录的 npl_packages 目录(路径为: 安装目录/npl_packges), 解压 paracraftbuildinmod.zip 模块压缩包, 得到 ParacraftBuildinMod 目录
- 进入 ParacraftBuildinMod 目录下 Mod 的目录(ParacraftBuildinMod/Mod), 删除里面已有 GeneralGameServerMod 目录, 并将下载解压后的GeneralGameServerMod 拷贝此, 用于替换原有的 GeneralGameServerMod 目录.
- 回退到 npl_packages 目录, 将 ParacraftBuildinMod 目压缩成zip, 获得替换后的 paracraftbuildinmod.zip
- 重启 Paracraft 即可使用 GGS 模块的最新代码

### 版本

### 集群实现方式

集群由控制服务和工作服务组成, 通常控制服务一个, 工作服务若干. 控制服链接地址提供客户端.

客户单进入联机世界流程:

- 连接控制服务  
- 向控制服务发送进入联机世界 WorldId 请求, 控制服务找出合适的工作服务并返回该工作服务连接地址
- 关闭控制服务连接, 连接获取到的工作服务地址
- 登录联机世界, 以及相关操作与请求

服务器间的负载信息同步:

- 程序启动, 工作服务连接控制服务, 定时每隔3分钟发送一次本工作服务的负载信息给控制服务.
负载信息: 工作服务存在世界数, 用户数, 每个世界的用户数

最优工作服务选择:

- 排除更新时间超过5分钟(判定工作服务已停止), 用户数已超过最大值(8000)  
- 优先选择工作服务已存在该世界信息, 且世界用户数不超过世界用户数的最大值(200)
- 其次选择工作服务的用户数最少
- 若工作服务可用, 选择控制服务

### TODO

[x] 世界里自动创建的entity的entityId 无法同步, 可能会导致程序异常  通过区域化分解决, 自动创建去临界值以上, 服务器分配取临界值一下  
[x] 当世界人数到达上限, 新接入用户进入新的虚拟世界  
[x] 连接的断开重连  
[x] 世界重复打开  
[x] 世界打开失败    /loadworld 未处理世界打开失败情况,  本模块无法处理  
[x] 玩家进入世界, 起始位置小范围随机  
[x] 维持世界最小玩家, 当玩家数量过少维持离线玩家在世界中  
[x] 支持平行世界(同一世界多开)  
[x] 区域化离线人物 ParaWorldMinimapSurface.lua

### 对外接口只有命令
