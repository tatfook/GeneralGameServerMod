
# GGS Server

GGS 服务器实现

## 玩家管理

GGS 核心功能便是同步玩家实时信息, 所以必然存在玩家管理逻辑. 每个玩家都有一个唯一的标识符(用户名). 当系统出现多个同名玩家时, 后者会踢出前者. 根据玩家的在线状态

可分为离线玩家和在线玩家, 玩家管理器使用线性列表,和四叉树来同时管理在线玩家, 使用队列和四叉树管理离线玩家. 列表和队列方便全遍历, 四叉树用来检索区域玩家. 由于世界

的可视距离非常有限(64个方块便可), 而世界本身很大, 当玩家很多时, 任何一个玩家信息的变更都去通知其它所有玩家是一种非常低效的行为, 对此提供世界玩家可视距离配置项(World.areaSIze),

开启该选项后所有玩家的信息的同步只会在彼此可视的情况下进行. 这样可以降低网络流量同时实时交互性.

### 玩家上线流程

1. 客户端发送登录联机世界请求
2. 服务器检测自身处理能力, 超载拒绝登录
3. 进行认证逻辑校对
4. 提出同名的在线或离线玩家
5. 创建新玩家, 并通知客户端登录成功
6. 客户端接受登录成功后, 上传自己的用户实体信息
7. 服务端接受用户实体信息, 转发给其它在线玩家, 并判断其是否为新登录玩家, 若是新玩家则发送玩家列表给当前玩家

### 玩家下线流程

用户下线场景有:

1. 客户端主动退出
2. 被服务器同名踢出
3. 服务器检测不到用户的心跳包, 主动关闭连接并下线用户. 此种客户端有链接断开重连机制, 会在客户端唤醒后重连.

下线流程:

1. 用户是否满足离线缓存策略, 满足进入离线队列并发送玩家离线数据包给其它在线玩家, 否则从玩家管理器彻底移除, 并发送玩家退出数据包给其它在线玩家.
2. 服务器定时检测离线超过48小时的离线玩家, 并将其退出系统

## 集群部署

GGS 的集群实现类似 nginx + webserver 的服务方式,  会有一个 GGS 服务的控制节点充当 nginx 角色, 完成工作主机节点的调度与选择. 因此 GGS 的控制节点相当于

整个集群的网关, 尽量避免其处理业务逻辑. 业务逻辑的处理应由工作节点来完成. 工作节点可以任意增减, 工作节点开启后会主动连接控制节点并定时上报其负载情况.

GeneralGameServer.Server.isControlServer = true  表明当前节点为控制节点
GeneralGameServer.Server.isWorkerServer = true   表明当前节点为控制节点

集群部署: 起一个控制节点, 起N(N >= 1)个工作节点即可.

附加配置项:
GeneralGameServer.Server.listenIp  当前节点服务监听的IP
GeneralGameServer.Server.listenPort  当前节点服务监听的Port
GeneralGameServer.Server.ControlServer  控制节点配置信息, 必须存在
GeneralGameServer.Server.ControlServer.innerIp 控制节点的内网IP
GeneralGameServer.Server.ControlServer.innerPort 控制节点的内网端口
GeneralGameServer.Server.ControlServer.outerIp 控制节点的内网IP
GeneralGameServer.Server.ControlServer.outerPort 控制节点的内网端口
GeneralGameServer.Server.WorkerServer  工作节点配置信息, 若为工作节点则必须存在
GeneralGameServer.Server.WorkerServer.innerIp 工作节点的内网IP
GeneralGameServer.Server.WorkerServer.innerPort 工作节点的内网端口
GeneralGameServer.Server.WorkerServer.outerIp 工作节点的内网IP
GeneralGameServer.Server.WorkerServer.outerPort 工作节点的内网端口

**tips**: 当只有一个节点时isControlServer,isWorkerServer应同时为真, ControlServer, WorkerServer 相应IP应该是相同的.

## 负载策略

```xml
<!-- 控制主机 isWorkerServer=true同时也是工作主机, 集群方式建议关闭, 单独开工作进程-->
<Server 
    isControlServer=true
    isWorkerServer=true
    maxClientCount=8000
    maxWorldCount=200>
    <!-- 控制节点配置  内网Ip和Port用于服务端互联, 外网Ip和Port用于客户端与服务端互联 
      innerIp 内网IP 
      innerPort 内网端口 
      outerIp 外网IP
      outerPort 外网端口 
    -->
    <ControlServer
      innerIp="129.204.55.98"
      innerPort="9900"
      outerIp="129.204.55.98"
      outerPort="9900">
    </ControlServer>   
    <!-- 控制节点配置 内网Ip和Port用于服务端互联, 外网Ip和Port用于客户端与服务端互联 
      innerIp 内网IP 
      innerPort 内网端口 
      outerIp 外网IP
      outerPort 外网端口 
    -->
    <WorkerServer
      innerIp="129.204.55.98"
      innerPort="9900"
      outerIp="129.204.55.98"
      outerPort="9900">
    </WorkerServer>
</Server>

<!-- 工作主机1 -->
<Server 
    isControlServer=false
    isWorkerServer=true
    maxClientCount=1000
    maxWorldCount=200>
    <!-- 控制节点配置  内网Ip和Port用于服务端互联, 外网Ip和Port用于客户端与服务端互联 
      innerIp 内网IP 
      innerPort 内网端口 
      outerIp 外网IP
      outerPort 外网端口 
    -->
    <ControlServer
      innerIp="129.204.55.98"
      innerPort="9900"
      outerIp="129.204.55.98"
      outerPort="9900">
    </ControlServer>   
    <!-- 控制节点配置 内网Ip和Port用于服务端互联, 外网Ip和Port用于客户端与服务端互联 
      innerIp 内网IP 
      innerPort 内网端口 
      outerIp 外网IP
      outerPort 外网端口 
    -->
    <WorkerServer
      innerIp="129.204.55.98"
      innerPort="9901"
      outerIp="129.204.55.98"
      outerPort="9901">
    </WorkerServer>
</Server>

<!-- 工作主机2 -->
<Server 
    isControlServer=false
    isWorkerServer=true
    maxClientCount=1000
    maxWorldCount=200>
    <!-- 控制节点配置  内网Ip和Port用于服务端互联, 外网Ip和Port用于客户端与服务端互联 
      innerIp 内网IP 
      innerPort 内网端口 
      outerIp 外网IP
      outerPort 外网端口 
    -->
    <ControlServer
      innerIp="129.204.55.98"
      innerPort="9900"
      outerIp="129.204.55.98"
      outerPort="9900">
    </ControlServer>   
    <!-- 控制节点配置 内网Ip和Port用于服务端互联, 外网Ip和Port用于客户端与服务端互联 
      innerIp 内网IP 
      innerPort 内网端口 
      outerIp 外网IP
      outerPort 外网端口 
    -->
    <WorkerServer
      innerIp="129.204.55.98"
      innerPort="9902"
      outerIp="129.204.55.98"
      outerPort="9902">
    </WorkerServer>
</Server>
```
