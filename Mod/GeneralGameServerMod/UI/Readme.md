
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

## 响应式

指令集关联的变量必须为全局变量. 全局变量更新页面会自动更新. 为实现此功能, 框架对全局变量做了hook, 也因此正常用法有所不同, 需注意以下几点:

- list = {1, 2} 针对列表数据, pairs 遍历失效, 可以使用 ipairs 替代
- list = {1, 2} 列表内部数据暂无响应式支持, 若列表内部数据更新需要更新视图可以使用 list = list 临时方式触发列表变量本身的更新. 此问题由默认table.insert, table.remove等函数无法触发变量内的hook导致, 后续会替换默认table.xxx相关方法解决此问题
- 全局变量相比局部变量开销会比较大, 如没有与UI关联可以使用局部变量替代
- 对全局变量表类数据由于hook导致普通打印函数无法打印其类容, 可以使用内置的Log函数来打印输出数据内容以便调试.

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
