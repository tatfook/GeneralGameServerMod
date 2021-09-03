
# Independent

Independent 提供独立的沙盒运行环境.
Independent.Load(files) 加载并执行沙盒脚本  加载单个脚本: Independent.LoadFile(file)
Independent.Start()  开始执行沙盒脚本的入口函数
Independent.Stop() 结束沙盒环境执行

```lua
-- 将如下代码放置代码方块中执行
local Independent = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Independent.lua", true);
-- 加载脚本文件
Independent:LoadFile("%gi%/Independent/Example/Empty.lua");     -- 空模板   @/Empty.lua 为世界根目录下Empty.lua  @ 为世界根目录占位符
-- Independent:LoadFile("%gi%/Independent/Example/Event.lua");  -- 系统事件模板
-- Independent:LoadFile("%gi%/Independent/Example/UI.lua");     -- UI 模板
-- Independent:LoadFile("%gi%/Independent/Example/GGS.lua");    -- 联机模板

-- 执行脚本入口函数 main 并启动定时器 间隔执行脚本loop循环函数
Independent:Start();
-- 停止脚本执行
registerStopEvent(function()
    Independent:Stop();
end);
```

## 沙盒脚本模板

沙盒脚本主要由开始入口函数(main), 事件循环函数(loop), 结束清理函数(clear)三部分组成.

```lua
-- 入口函数
function main()
end
-- 消息循环 定时回调 20fps
function loop()
end
-- 清理函数
function clear()
end
```

## 沙盒API (CodeEnv)

沙盒API由 CodeEnv 提供, 内置大量 API 接口, 可根据需求按需加载使用即可. API 命名规则系统级接口默认全小写, 用户级接口驼峰式命名.

常用API介绍:

```lua
-- 自定义模块
module(name);                                                 -- 定义脚本模块
require(name);                                                -- 加载脚本模块  name 可为系统模块名也可为指定路径文件
-- UI
ShowWindow(G, params);                                        -- 显示窗口, 沙盒结束自动关闭所有窗口
-- 系统事件, 外部输入, 如点击, 按键
RegisterEventCallBack(eventType, callback);                   -- 注册事件回调函数 EventType.MOUSE  可用事件类型 MAIN, LOOP, CLEAR, MOUSE, MOUSE_DOWN, MOUSE_MOVE, MOUSE_UP, MOUSE_WHEEL, KEY, KEY_DOWN, KEY_UP
RemoveEventCallBack(eventType, callback);                     -- 移除事件回调函数
-- 定时器
SetTimeout(timeout, callback);                                -- timeout ms 后执行回调 ClearTimeout(SetTimeout())  由Timer模块实现, 更多用法使用 Timer = require("Timer") 相关函数
SetInterval(interval, callback);                              -- 间隔 interval ms 执行回调  ClearInterval(SetInterval())
-- 用户自定义事件机制
On(eventType, callback);                                      -- 监听事件
Off(eventType, callback);                                     -- 移除事件
Emit(eventType, callback);                                    -- 触发事件
-- 多人网络
GGS_Connect(callback);                                        -- 连接多人网络
GGS_Send(data);                                               -- 发送网络数据
GGS_Recv(callback);                                           -- 接收网络数据
GGS_Disconnect(callback);                                     -- 网络断开  callback 为函数则注册断开回调,  否则主动断开网络
-- RegisterTimerCallBack(eventType, callback); -- 注册定时回调函数 EventType.MOUSE, EventType.MOUSE_DOWN, ...
-- RemoveTimerCallBack(eventType, callback);   -- 移除定时回调函数


-- Block API
GetBlockId
GetBlockEntity
CreateBlockPieces
SetBlock
GetBlockFull
ConvertToRealPosition
ConvertToBlockIndex
LoadTemplate

-- Entity API
GetAllEntities
GetEntityById
GetEntitiesInBlock
GetEntityBlockPos
SetEntityBlockPos
EnableEntityPicked

-- Event API 
EventType = EventType
RegisterTimerCallBack
RemoveTimerCallBack
RegisterEventCallBack 
RemoveEventCallBack
TriggerEventCallBack
On
Off 
Emit

-- GGS API
TriggerNetworkEvent       -- 发送网络消息
RegisterNetworkEvent      -- 接收网络消息

-- Player API
GetUserId 
GetUserName
GetNickName 
GetPlayer
GetPlayerEntityId 
IsInWater
IsInAir
SetPlayerVisible
GetPlayerInventory
GetHandToolIndex
SetHandToolIndex 
CreateItemStack 
SetItemStackInHand
GetItemStackInHand
SetItemStackToScene
GetItemStackFromInventory 
SetItemStackToInventory 
RemoveItemFromInventory 

-- Scene API
SwitchOrthoView
SwitchPerspectiveView 
EnableAutoCamera
SetCameraMode
GetCameraMode 
GetCameraRotation 
SetCameraRotation 
CameraZoomInOut
GetFOV 
SetFOV 
GetScreenSize 
GetPickingDist
GetHomePosition
GetFacingFromCamera
GetDirection2DFromCamera
HighlightPickBlock
HighlightPickEntity 
ClearBlockPickDisplay
ClearEntityPickDisplay
ClearPickDisplay
MousePickTimerCallBack 
MousePick

-- System API
Lua 常规API
exit 
require
module
GetTime 
ToolBase
echo
serialize
unserialize
inherit

-- UI API
ShowWindow

-- Utiltiy API
Tip
MessageBox
```
