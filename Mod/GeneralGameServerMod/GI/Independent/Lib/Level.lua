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

function Level:ctor()
    -- 左下角
    self.__x__, self.__y__, self.__z__ = 10000, 8, 10000;
    -- 边长
    self.__dx__, self.__dy__, self.__dz__ = 128, 16, 128;

    self.__all_entity__ = {};
    self.__all_goods__ = {};
    self.__scene__ = {};
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

function Level:LoadMap()
    local cx, cy, cz = self:GetCenterPoint();
    cmd("/property UseAsyncLoadWorld false")
    cmd("/property AsyncChunkMode false");
    cmd(format("/loadregion %d %d %d %d", cx, cy, cz, math.max(self.__dx__, self.__dz__) + 10));

    -- 加载地图内容
    local level_name = self:GetLevelName();
    if (level_name and level_name ~= "") then cmd(format("/loadtemplate %d %d %d %s", cx, cy, cz, level_name)) end

    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");

    self:ResetFoundation();
end

function Level:UnloadMap()
    for x = self.__x__, self.__x__ + self.__dx__ do
        for z = self.__z__, self.__z__ + self.__dz__ do
            for y = self.__y__, self.__y__ + self.__dy__ do
                SetBlock(x, y, z, 0);
            end
        end
    end
end

function Level:Export()
    local level_name = self:GetLevelName();
    if (not level_name or level_name == "") then level_name = "level" end 
    cmd(format("/select %d %d %d (%d %d %d)", self.__x__, self.__y__, self.__z__, self.__dx__, self.__dy__, self.__dz__));
    cmd(format("/savetemplate -auto_pivot %s", level_name));
    cmd("/select -clear");
end

function Level:Edit(level_name)
    local cx, cy, cz = self:GetCenterPoint();
    self:ResetFoundation();
    if (level_name) then cmd(format("/loadtemplate %d %d %d %s", cx, cy, cz, level_name)) end
    cmd(format("/goto %s %s %s", cx, cy, cz));

    -- cmd("/mode game");
    cmd("/clearbag");

    -- ShowWindow(nil, {
    --     url = "%gi%/Independent/UI/Level.html",
    --     height = 40,
    --     width = 500,
    --     alignment = "_ctt",
    -- });
end

Level:InitSingleton();
