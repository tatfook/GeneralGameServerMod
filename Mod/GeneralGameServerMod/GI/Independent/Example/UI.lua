

-- ShowGIBlocklyEditorPage();
-- ShowCodeBlockBlocklyEditorPage();
-- local GlobalScope = NewScope({
--     LoopCount = 10,
-- });

-- ShowWindow({
--     GlobalScope = GlobalScope,
--     ResetLoopCount = function()
--         GlobalScope.LoopCount = 200;
--     end,
-- }, {
--     template = [[
-- <template>
-- <div>
-- 循环函数执行次数: {{LoopCount or 0}}
-- </div>
-- <div onclick=ResetLoopCount>重置</div>
-- </template>
--     ]],
--     width = 300,
--     height = 300,
-- });

-- function loop()
--     GlobalScope.LoopCount = GlobalScope.LoopCount + 1;
--     if (GlobalScope.LoopCount > 400) then
--         exit();
--     end
-- end

-- local LoopCount = 0;
-- local ui = ShowWindow({
--     ResetLoopCount = function()
--         LoopCount = 200;
--     end,
-- }, {
--     template = [[
-- <template>
-- <div>
-- 循环函数执行次数: {{LoopCount or 0}}
-- </div>
-- <div onclick=ResetLoopCount>重置</div>
-- </template>
-- <script>
-- -- 使用全局 Scope 定义响应式变量, 方便UI外部代码更新相关值进行更新 
-- GlobalScope = GetGlobalScope();
-- GlobalScope:Set("LoopCount", 0);
-- </script>
--     ]],
--     width = 300,
--     height = 300,
-- });
-- local uiGlobalScope = ui:GetG().GetGlobalScope();

-- function main()
--     print("main exec"); 
-- end

-- function loop()
--     LoopCount = LoopCount + 1;
--     print("loop count: ", LoopCount);
--     uiGlobalScope:Set("LoopCount", LoopCount);

--     if (LoopCount > 500) then
--         exit(); -- 主动退出
--     end
-- end

-- function clear()
--     print("clear exec");
-- end

