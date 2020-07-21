
# GGS 客户端

客户端由一下五个主类文件实现:

- EntityMainPlayer: 主玩家类
- EntityOtherPlayer: 非主玩家类 
- GeneralGameClient: 主类(入口类)  其它四类由主类提供
- GeneralGameWorld: 世界类
- NetClientHandler: 网络请求类

## 业务派生

派生主类, 其它四类根据需要选择性派生.

## 业务功能

- 用户头顶姓名及图标展示
- 点击用户弹出用户信息详情页

## TODO

[x] 用户昵称显示
