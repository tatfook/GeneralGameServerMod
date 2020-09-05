
# GGS Server

GGS 服务器实现

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

## 负载策略
