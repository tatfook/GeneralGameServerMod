
# UI

UI 是写 2D 窗口界面 UI 库, 使用方式与写 web 前端相似, 使用 html, css, lua 写原生界面, 若只是写简单静态页面使用 html, css 是足够的,
但需要与用户交互和有一定逻辑处理时, 最好使用基于此实现 vue 框架去做. 也因此后续相关教程默认使用 vue 框架的组件式写法去编写示例教程.

## 数据交互

组件间相互引用通过元素属性传递数据, 页面间相互引用通过页面的全局表传递数据.

## 组件模板

```html
<template>
    <!-- html 标签内容 -->
</template>

<script type="text/lua">
<!-- lua 业务逻辑 -->
</script>


<style type="text/css"> 
/* css 样式 会影响子组件 */
</style>

<style scoped=true type="text/css"> 
/* css 样式 不会影响子组件 */
</style>
```

## 指令集

- v-if    显示隐藏组件
- v-for   批量创建元素
- v-bind  绑定元素属性值
- v-on    绑定元素事件, 或时间属性值以on开头也行
- {{expr}} 文本表达式  

## 特殊属性

- ref 元素引用表示符 方便通过 GetRef 全局函数快速获取元素, 当前组件范围内唯一. 暂时不支持v-bind绑定此属性

## 响应式

指令集关联的变量必须为全局变量. 全局变量更新页面会自动更新. 为实现此功能, 框架对全局变量做了hook, 也因此正常用法有所不同, 需注意以下几点:

- 全局变量相比局部变量开销会比较大, 如没有与UI关联可以使用局部变量替代
- 对全局变量表类数据由于hook导致普通打印函数无法打印其类容, 可以使用内置的Log函数来打印输出数据内容以便调试.
- 组件脚本的全局变量仅是当前执行的环境的全局变量, 与框架外lua内置全局_G不同, 但是其继承对象.

## API

```lua
-- 外部显示窗口函数
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
local page = Page.Show({
    -- html 中 lua 执行环境的全局表
}, {
    -- 窗口参数
    x, y, width, height, alignment,  -- 窗口位置参数, 支持百分比和数字 默认 x = 0, y = 0, widht = 600, height = 500
    draggable = false,               -- 窗口是否支持拖拽
    url = "",                        -- 窗口html文件路径
    blockX, blockY, blockZ,          -- 告示牌坐标 Page.Show3D 接口专用
    macroName = "",                  -- 宏示教窗口名称, 存在则支持宏示教, 不存在则不支持
});

page:CloseWindow();                  -- 关闭窗口


-- 组件内默认自定义全局回调函数
function OnReady()
    -- 组件编译完成, 准备就绪回调
end

function OnAttrValueChange(attrName, attrValue, oldAttrValue)
    -- 组件属性更新

    -- NOTES: 框架目前没有将属性值扩展为组件的全局变量, 因有时需监控属性值变化做逻辑处理而不是单纯绑定UI, 开发者可在此自行转化成组件全局变量做UI联动.
end


-- 组件内置的全局函数
CloseWindow();  -- 关闭当前窗口
ShowWindow(G, Params);   -- 显示新窗口, 参数同Page.Show

-- 定时器相关, 参数同此类函数的其它语言版本
SetTimeout(func, timeoutMS)
ClearTimeout(timer)
SetInterval(func, intervalMS)
ClearInterval(timer)

GetTime()    -- 获取当前毫秒数
GetEvent()   -- 获取当前事件对象

ToString()   -- 转字符串, 调试使用, 支持表循坏嵌套


-- 组件相关
RegisterComponent(tagname, htmlpath)     -- 注册子组件
GetRef(refname)                          -- 获取引用元素  与特殊属性ref配合使用
SetAttrValue(attrName, attrValue)        -- 设置当前组件属性值
ComponentScope:GetAttrValue(attrName, defaultValue, valueType)   -- 获取当前组件属性值  valueType 默认为nil, 可以指定类型验证 string number function boolean 或使用简化函数 例: GetAttrStringValue(attrName, defaultValue)


-- 内置全局变量
Log          -- 日志输出  Log() Log.If(condition,  ...) Log.Format(fmt, ...) Log.FormatIf(condition, fmt, ...)
self         -- 当前执行环境   self.globalVal = 1  <==> globalVal = 1    定义局部变量 local localVal = 1


-- 元素常用方法
```

## 常用UI

```lua
-- 字幕UI
Page.ShowSubTitlePage({
    text = "语音文本",    -- 字幕内容 
    isPlayVoice = true,  -- 是否自动播放字幕语音
    isAutoClose = true,  -- 是否自动关闭字幕窗口
    style="",            -- 字幕 css 样式
})
```

## TODO

[x] 滚动条样式设定优化
[x] 性能优化 元素编译, 元素布局
[x-] 圆角 支持较弱 border: 10px  死角统一设置  不支持圆角裁剪图片
[x] xpcall pcall 执行代码
[ ] 远程脚本 动态更新
[ ] 不可见元素需要屏蔽渲染 scroll 优化 blockly 编辑区 优化

## 示教系统
