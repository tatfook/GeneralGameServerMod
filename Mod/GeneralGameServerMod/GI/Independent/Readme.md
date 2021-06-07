
# Independent

Independent 提供独立的沙盒运行环境.

Independent.Load(files) 加载并执行沙盒脚本

Independent.Start()  开始执行沙盒脚本的入口函数

Independent.Stop() 结束沙盒环境执行

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
module(name);                                                 -- 定义脚本模块
require(name);                                                -- 加载脚本模块  name 可为系统模块名也可为指定路径文件
ShowWindow(G, params);                                        -- 显示窗口, 沙盒结束自动关闭所有窗口
RegisterEventCallBack(eventType, callback);                   -- 注册事件回调函数 EventType.MOUSE, EventType.MOUSE_DOWN, ...
RemoveEventCallBack(eventType, callback);                     -- 移除事件回调函数
SetTimeout(timeout, callback);                                -- timeout ms 后执行回调 ClearTimeout(SetTimeout())  由Timer模块实现, 更多用法使用 Timer = require("Timer") 相关函数
SetInterval(interval, callback);                              -- 间隔 interval ms 执行回调  ClearInterval(SetInterval())
-- RegisterTimerCallBack(eventType, callback); -- 注册定时回调函数 EventType.MOUSE, EventType.MOUSE_DOWN, ...
-- RemoveTimerCallBack(eventType, callback);   -- 移除定时回调函数
```
