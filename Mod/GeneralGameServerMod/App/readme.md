
# App

App 目录主要根据业务实现特定功能, 偏向用户交互.

- Api 目录完成接口的编写
- Client GGS 客户端定制
- View 业务交互UI

## 同类业务扩展

- 仿照 App 目录进行定制
- 注册到 GGS 模块内  

```lua
NPL.load("Mod/GeneralGameServerMod/main.lua");                                    -- 此行可省略 GGS是内置模块, 程序启动会自动加载
local GeneralGameServerMod = commonlib.gettable("Mod.GeneralGameServerMod");      -- 获取GGS模块
local SelfGeneralGameClientClass = {};                                            -- 获取自定义的客户端入口类
GeneralGameServerMod:RegisterClientClass("selfAppName", SelfGeneralGameClientClass);      -- 注册入口类
```

- 执行命令启动客户端: `/ggs connect -app=selfAppName`

> 当不需要命令启动时, 也可以直接调用入口类的 LoadWorld 接口, 这样可以省去2,3步骤. 如: SelfGeneralGameClientClass:LoadWorld({})
