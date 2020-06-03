# ParacraftServer

Paracraft 长连接服务器, 主要用于客户端消息的推送, 以便完成相应的功能, 如paracraft玩家的位置信息同步等


## 实现

服务器与客户端通过 interface.lua 接口文件完成通信, 通信数据格式如下

- cmd 请求的命令
- data 请求的数据
- interface_file 自定义响应的接口文件

## 通信命令

### 用户认证

- cmd = "auth"
- data = 用户token

### 用户位置信息上报

- cmd = "set-agent-position"
- data.x = X 坐标
- data.y = Y 坐标
- data.z = Z 坐标

**客户端将自己的位置上报到服务器后, 服务器会将此信息转发给其它客户端, 转发的数据信息与接收的信息一致**


### TODO 
- 程序优化
