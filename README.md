# GeneralGameServerMod

GeneralGameServerMod 是基于 Paracraft 的一个多人联机的模块, 包含了该功能的客户端和服务端代码.

## 特性

- 支持联机世界, 即多用户进入同一世界, 用户能实时看到彼此相关行为.
- 支持多用户实时编辑世界, 实时同步用户对世界的做更新的.
- 支持平行联机世界, 即同一世界存在多个, 彼此独立.

## 实现原理

客户端负责提取主玩家相关行为信息上报给服务器, 以及收到服务器转发其它玩家行为信息进行虚拟.
服务器负责维护客户端上报行为信息并进行相应转发.

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

### 命令
```
/ggs subcmd [options] args...
subcmd: 
connect                                连接联机世界
	/ggs connect [options] [worldId] [worldName]
disconnect                             退出联机世界
	/ggs disconnect
user                                   用户命令
	/ggs user visible                  显示所有用户 不包含主玩家
	/ggs user hidden                   隐藏所有用户 不包含主玩家
	/ggs user enableclick              玩家可点击
	/ggs user disableclick             玩家不可点击
offlineuser                            离线用户命令
	/ggs offlineuser visible           显示离线用户
	/ggs offlineuser hidden            隐藏离线用户
spawnuser                              创建用户
	/ggs spawnuser username1;username2;username3...  
	示例: /ggs spawnuser xiaoyao;wxatest
setNewLiveModelAutoSync                新增活动模型是否同步(默认为 on)
	/ggs setNewLiveModelAutoSync on    允许新增活动模型同步
	/ggs setNewLiveModelAutoSync off   禁止新增活动模型同步
setLiveModelAutoSync                   所有活动模型是否同步(默认为 on)
	/ggs setLiveModelAutoSync on       允许活动模型同步
	/ggs setLiveModelAutoSync off      禁止活动模型同步
showuserinfo                           显示用户信息
	/ggs showuserinfo [username]
	示例: /ggs showuserinfo xiaoyao
cmd                                    执行软件内置命令
	/ggs cmd [options] cmdname cmdtext
	示例: /ggs cmd tip hello world	

-- 辅助测试命令
debug 调试命令 
	/ggs debug [action]
	/ggs debug debug module            开启或关闭指定客户端模块日志
	/ggs debug serverdebug module      开启或关闭指定服务端模块日志
	/ggs debug options                 显示客户端选项信息
	/ggs debug playerinfo              显示客户端所在世界的玩家信息
	/ggs debug worldinfo               显示客户端所在世界的信息
	/ggs debug serverinfo              显示客户端所在服务器信息	
	/ggs debug serverlist              显示全网服务器列表
	/ggs debug statistics              显示全网统计信息
	/ggs debug ping                    验证是否是有效联机玩家
	/ggs debug syncForceBlockList      显示强制同步块列表

setSyncForceBlock 强制同步指定位置方块(机关类方块状态等信息默认是不同步, 可使用该指令强制去同步):
	/ggs setSyncForceBlock x y z on|off
	/ggs setSyncForceBlock 19200 5 19200 on   强制同步位置19200 5 19200的方块信息
	/ggs setSyncForceBlock 19200 5 19200 off  取消强制同步位置19200 5 19200的方块信息

	/ggs connect -isSyncBlock -isSyncCmd -areaSize=64 -silent -editable 12706

sync 世界同步
	/ggs sync -[block|cmd]
	/ggs sync -block=true  或 /ggs sync -block 开启同步方块  /ggs sync -block=false 禁用方块同步
	/ggs sync -forceBlock=false        禁用强制同步块的同步, 默认开启
filesync
	/ggs filesync                      同步所有文件
	/ggs filesync filepath             同步指定文件
blockly                                图块编程	
developer                              GGS 开发者模式
```

## 流量
### 客户端玩家信息同步大小(512)

GGS 主要工作是同步玩家Entity信息, Entity通过PacketPlayerEntityInfo结构打包序列化字节借助tcp协议发送.
经测试输出PacketPlayerEntityInfo大小为423, 外加协议包也会占用一定的大小, 故均化为512字节. 也就是一个用户
一次信息同步会发送512字节大小.

### 客户端玩家信息同步频率

玩家动画帧频率为30fps, 当玩家处于移动状态每秒发送一次同步请求, 玩家发送请求时间成倍增加直到2分钟发送一次.
每次请求包最大大小为30 * 512 = 15K, 最小大小为512B, 玩家移动时发包频率和大小会比较大, 是占据流量主要操作.

### 心跳包

客户端没2min发送一次心跳包(大小512以内)

### 数据转发

GGS 除了玩家信息同步功能, 另一功能是数据转发. 服务器不维护数据只转发数据. 这种以具体业务而定.

如虚拟玩家同步(/ggs spawnuser username1...)就使用此种方式.

虚拟玩家同步逻辑(与局域网同步逻辑类似):
1. 世界拥有者创建虚拟玩家, 通过数据转发, 同步所有虚拟玩家给其它真实玩家
2. 世界有新真实玩家加入, 世界拥有者通过数据转发同步所有虚拟玩家给其它真实玩家
3. 世界拥有者调用虚拟玩家的(SetBlockPos, SetPosition)方法, 数据转发同步当前虚拟玩家
4. 心跳同步所有虚拟玩家给真实玩家, 每2min同步一次
虚拟玩家可以看作世界拥有者的物品, 每次同步最大大小为N * 512(N 为虚拟玩家数量), 同步频率受真实玩家加入和拥有者主动触发影响.
另虚拟玩家对应真实玩家上线会移除该虚拟玩家. 虚拟玩家由拥有者自行控制其行为.

### 服务器流量

服务器主要做数据转发工作, 维护真实玩家相关信息. 流量消耗为每个玩家流量 * N(真实玩家数) = (U1 + U2 + U3 + ..) * N (UN为玩家流量)