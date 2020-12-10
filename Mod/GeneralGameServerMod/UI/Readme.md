
# UI

UI 是写 2D 窗口界面 UI 库, 使用方式与写 web 前端相似, 使用 html, css, lua 写原生界面, 若只是写简单静态页面使用 html, css 是足够的,
但需要与用户交互和有一定逻辑处理时, 最好使用基于此实现 vue 框架去做. 也因此后续相关教程默认使用 vue 框架的组件式写法去编写示例教程.

## 数据交互

组件间相互引用通过元素属性传递数据, 页面间相互引用通过页面的全局表传递数据.

## API

```lua
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

local page = Page.Show({
    -- html 中 lua 执行环境的全局表
}, {
    -- 窗口参数
    x, y, width, height, alignment,  -- 窗口位置参数, 支持百分比和数字 默认 x = 0, y = 0, widht = 600, height = 500
    draggable = false,               -- 窗口是否支持拖拽
    url = "",                        -- 窗口html文件路径
});

page:CloseWindow();                  -- 关闭窗口
```
