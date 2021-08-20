--[[
Title: Level
Author(s):  wxa
Date: 2021-06-01
Desc: Level
use the lib:
------------------------------------------------------------
local Level = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Level.lua");
------------------------------------------------------------
]]

local Level = inherit(ToolBase, module("Level"));

Level:Property("LevelName", "level");  -- 关卡名称
Level:Property("ToolBoxXmlText");      -- 定制工具栏文本
Level:Property("WorkspaceXmlText");    -- 定制工作区文本
Level:Property("PassLevelXmlText");    -- 通关工作区xmltext
Level:Property("StatementBlockCount", 0);  -- 语句块的数量
Level:Property("CodeEnv");             -- 代码环境
Level:Property("Speed", 1);            -- 倍速

function Level:ctor()
    -- 左下角
    self.__x__, self.__y__, self.__z__ = 10000, 8, 10000;
    -- 边长
    self.__dx__, self.__dy__, self.__dz__ = 128, 128, 128;
    -- 代码环境
    self:SetCodeEnv(setmetatable({}, {__index = _G}));
end

-- 重置地基
function Level:ResetFoundation()
    -- 模板文件不存在则创建底座
    for x = self.__x__, self.__x__ + self.__dx__ do
        for z = self.__z__, self.__z__ + self.__dz__ do
            SetBlock(x, self.__y__, z, 62);
        end
    end
end

-- 获取中心点坐标
function Level:GetCenterPoint()
    return self.__x__ + math.floor(self.__dx__ / 2), self.__y__, self.__z__ + math.floor(self.__dz__ / 2);
end

function Level:SetCenterPoint(x, y, z, dx, dy, dz)
    self.__x__, self.__y__, self.__z__, self.__dx__, self.__dy__, self.__dz__ = x or self.__x__, y or self.__y__, z or self.__z__, dx or self.__dx__, dy or self.__dy__, dz or self.__dz__;
end

function Level:LoadRegion()
    local cx, cy, cz = self:GetCenterPoint();
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    cmd(format("/loadregion %d %d %d %d", cx, cy, cz, math.max(self.__dx__, self.__dz__) + 10));
    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
end

function Level:ClearRegion()
    for x = self.__x__, self.__x__ + self.__dx__ do
        for z = self.__z__, self.__z__ + self.__dz__ do
            for y = self.__y__, self.__y__ + self.__dy__ do
                SetBlock(x, y, z, 0);
            end
        end
    end
end

function Level:LoadMap(level_name)
    self:LoadRegion();

    local cx, cy, cz = self:GetCenterPoint();
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");

    -- 先清除
    self:ClearRegion();

    -- 加载地图内容
    level_name = level_name or self:GetLevelName();
    if (level_name and level_name ~= "") then cmd(format("/loadtemplate %d %d %d %s", cx, cy, cz, level_name)) end

    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");

    self:ResetFoundation();
end

function Level:UnloadMap(level_name)
    self:LoadRegion();
    -- 加载地图内容
    local cx, cy, cz = self:GetCenterPoint();
    level_name = level_name or self:GetLevelName();
    if (level_name and level_name ~= "") then cmd(format("/loadtemplate -r %d %d %d %s", cx, cy, cz, level_name)) end
end

function Level:Load()
    -- self:UnloadMap();
    self:LoadMap();
    self:LoadLevel();
    self:ShowLevelBlocklyEditor();
    cmd("/mode game");
    cmd("/clearbag");
    cmd("/hide quickselectbar");
end

-- 关卡结束
function Level:Unload()
    self:UnloadLevel();
    self:UnloadMap();
    self:CloseLevelBlocklyEditor();
end

function Level:Export(level_name)
    self:UnloadLevel();

    level_name = level_name or self:GetLevelName();
    if (not level_name or level_name == "") then return end 
    cmd(format("/select %d %d %d (%d %d %d)", self.__x__, self.__y__, self.__z__, self.__dx__, self.__dy__, self.__dz__));
    cmd(format("/savetemplate -auto_pivot %s", level_name));
    cmd("/select -clear");
end

function Level:LoadLevel()
    Emit("LoadLevel");
end

function Level:UnloadLevel()
    Emit("UnloadLevel");
end

function Level:ResetLevel()
    Emit("ResetLevel");
    self:UnloadLevel();
    self:LoadLevel();
    self:ShowLevelBlocklyEditor();
end

function Level:RunLevelCodeBefore()
    Emit("RunLevelCodeBefore");
    self:ResetLevel();
end


function Level:RunLevelCodeAfter()
    Emit("RunLevelCodeAfter");
end

function Level:RunCode(code)
    -- print("=======================Level:RunCode=======================");
    -- 执行关卡代码前
    self:RunLevelCodeBefore();

    -- 执行关卡代码
    local code_func, errormsg = loadstring(code, "loadstring:RunCode");
    if (code_func) then
        setfenv(code_func, self:GetCodeEnv());
        code_func();
    else
        print("run code error:", code, errormsg);
    end

    -- 执行关卡代码后
    self:RunLevelCodeAfter();
end

function Level:ShowLevelBlocklyEditor()
    ShowLevelBlocklyEditorPage({
        Speed = self:GetSpeed(),
        ToolBoxXmlText = self:GetToolBoxXmlText(),
        WorkspaceXmlText = self:GetWorkspaceXmlText(),
        PassLevelXmlText = self:GetPassLevelXmlText(),
        Run = function(code, statementBlockCount)
            self:SetStatementBlockCount(statementBlockCount or 0);
            self:RunCode(code);
        end,
        SetSpeed = function(speed)
            self:SetSpeed(speed);
        end
    });
end

function Level:CloseLevelBlocklyEditor()
    CloseLevelBlocklyEditorPage();
end

function Level:Edit(bLoadMap)
    if (bLoadMap) then self:LoadMap() end
    local cx, cy, cz = self:GetCenterPoint();
    cmd(format("/goto %s %s %s", cx, cy, cz));
    cmd("/mode editor");
    ShowWindow({
        __level__ = self;
    }, {
        url = "%gi%/Independent/UI/Level.html",
        height = 40,
        width = 500,
        alignment = "_ctt",
    });
end

Level:InitSingleton();

--[[
关卡创建:
```lua
-- 代码方块 语言game_inventor环境下执行
-- 获取关卡模块
local Level = GetLevelModule();
-- 设置关卡名 导出方块模板template的名称
Level:SetLevelName("level1");   
-- 搭建关卡, 创建关卡底座, 底座请勿更改每次会被重置  默认以10000, 8, 10000为左下角, dx = 128, dy = 32, dz = 128 大小空间内为关卡空间 
Level:Edit();  -- 创建底座后会跳转至底座中心点
-- 开始场景搭建
-- 角色设置, 角色是关卡的核心内容, 创建一个代码方块, 并将其语言设置为 game_inventor(GI), 也可勾选NPL图块编辑进行图块编写, 编写如下示例代码
-- 创建sunbin角色
local sunbin = CreateEntity({bx = 20090, by = 9, bz = 20067, biped = true, assetfile = "character/CC/artwar/game/sunbin.x", physicsHeight = 1.765});
--旋转-90度
sunbin:Turn(-90);
-- 创建光圈角色 并加gsid=1的物品, 该物品角色被碰到后消失
CreateEntity({bx = 20090, by = 9, bz = 20077, assetfile = "character/CC/05effect/fireglowingcircle.x"}):AddGoods(CreateGoods({gsid = 1}));
-- 创建天书角色
local tianshucanjuan = CreateEntity({bx = 20090, by = 9, bz = 20077, assetfile = "@/blocktemplates/tianshucanjuan.x"});
-- 天书角色添加碰撞消失物品
tianshucanjuan:AddGoods(CreateGoods({gsid = 1}));
-- 天书角色添加可转移天书荣誉物品, 被碰撞后该物品被转移至碰撞这身上 
tianshucanjuan:AddGoods(CreateGoods({gsid = 2, name = "tianshu"})); -- name 物品名称唯一识别物品
-- 创建庞涓角色
local pangjuan = CreateEntity({bx = 20090, by = 9, bz = 20089, physicsRadius = 2, assetfile = "character/CC/artwar/game/pangjuan.x"});
-- 转向90度
pangjuan:Turn(90);
-- 庞涓角色添加碰撞转移位置物品
pangjuan:AddGoods(CreateGoods({gsid = 3, name = "pos"}));  -- name 物品名称唯一识别物品
-- 关卡导出 导出关卡区域内的方块的 template 文件
Level:Export();

-- 游戏
-- 玩家图块编辑接口, 可能置于游戏主题框架中
--ShowBlocklyCodeEditor();
-- 孙膑前行20格, 碰撞光圈和天书后,二者消失, 孙膑获取天书物品,  碰撞庞涓后获取位置物品
sun:MoveForward(20);

-- 检测是否通关 识别孙膑是否获取天书和位置物品, 获得则通关
if (G.sunbin:HasGoods("tianshu") and G.sunbin:HasGoods("pos")) then Tip("恭喜通关") end

核心原理, 角色碰撞会激活物品, 物品是功能的载体, 角色根据拥有物品来来展现不同效果. 框架尽量将逻辑至于角色与物品上, 创建者简单的搭配角色和物品完成相关功能, 
简化使用放便图块化,也可专注关卡本身逻辑.

主游戏流程
- 关卡地图
- 选择关卡
- 发送当前关卡卸载事件
- 加载选择关卡地图
- 发送选择关卡加载事件
- 通关重复选择关卡
```
]]