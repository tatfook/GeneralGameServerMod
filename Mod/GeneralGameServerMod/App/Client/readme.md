
# GGS 客户端

客户端由一下五个主类文件实现:

- EntityMainPlayer: 主玩家类
- EntityOtherPlayer: 非主玩家类 
- GeneralGameClient: 主类(入口类)  其它四类由主类提供
- GeneralGameWorld: 世界类
- NetClientHandler: 网络请求处理类

## 业务派生

派生主类, 其它四类根据需要选择性派生.

## 业务功能

- 用户头顶姓名及图标展示
- 点击用户弹出用户信息详情页

## 应用扩展

ggs 模块对外几乎是封闭的, 对外提供相关命令进行操作. 若需针对应有做特定定制, 可使用模块提供的注册应用主客户端类实现:

```lua
-- 注册主类, 再由主类去定制其它相关业务类定义与实现
local GeneralGameServerMod = commonlib.gettable("Mod.GeneralGameServerMod");
GeneralGameServerMod:RegisterClientClass("AppName", AppGenerateGameClientClass);
-- 使用 /ggs connect -app=AppName
-- ggs 模块的命令都集成到了ggs命令, 此方式减少命令数,但再命令输入窗口智能提示效果差, 故其子命令独立存在保留未删
```
