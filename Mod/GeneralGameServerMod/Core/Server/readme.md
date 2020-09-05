
# GGS Server

GGS 服务器实现

## 集群部署

GGS 的集群实现类似 nginx + webserver 的服务方式,  会有一个 GGS 服务的控制节点充当 nginx 角色, 完成工作主机节点的调度与选择. 因此 GGS 的控制节点相当于

整个集群的网关, 尽量避免其处理业务逻辑. 业务逻辑的处理应由工作节点来完成. 工作节点可以任意增减, 工作节点开启后会主动连接控制节点并定时上报其负载情况.


GeneralGameServer.Server.isControlServer = true  表名当前节点为控制节点
GeneralGameServer.Server.isWorkerServer = true   表名当前节点为控制节点