--[[
Title: GGSRank
Author(s):  wxa
Date: 2021-06-01
Desc: 排行榜
use the lib:
------------------------------------------------------------
local GGSRank = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/GGSRank.lua");
------------------------------------------------------------
]]
local GGS = require("GGS");
local GGSRank = inherit(ToolBase, module("GGSRank"));

-- 比较方式 使用排序
GGSRank:Property("Sort", nil);   
GGSRank:Property("FieldWidth", 100);
GGSRank:Property("FieldHeight", 30);

-- 窗口对象
local __ui__ = nil;
-- ui scope
local __scope__ = NewScope();
-- 当前用户排行数据 
local __rank__ = {};

function GGSRank:Init()
    __scope__:Set("fields", {});
    __scope__:Set("title", "排行榜");

    self:SetMaxLineCount(10);

    return self;
end

--[[
定义排行字段  {
    key = "nickname",                 -- 字段名
    defaule_value = "xiaoyao",        -- 默认值
    title = "昵称",                   -- 标题名
    no = 1,                           -- 列号 字段顺序
    width = 100,                      -- 字段宽度
    require = true,                   -- 是否是必填字段
}
--]] 

function GGSRank:GetMaxLineCount()
    return __scope__:Get("MaxLineCount") or 0;
end

function GGSRank:SetMaxLineCount(count)
    __scope__:Set("MaxLineCount", count);
    __scope__:Set("ContentHeight", self:GetFieldHeight() * count);
end

function GGSRank:GetFields()
    return __scope__:Get("fields", {});
end

function GGSRank:GetRanks()
    return __scope__:Get("ranks", {});
end

function GGSRank:DefineField(field)
    local fields = self:GetFields();
    
    field.width = field.width or self:GetFieldWidth();
    field.height = self:GetFieldHeight();

    fields[field.key] = field;
    self:SetFieldValue(field.key, field.defaule_value);

    self:RefreshRanks();
end

function GGSRank:SetFieldValue(key, value)
    __rank__[key] = value;
    GGS:SetUserData(__rank__); 
end

function GGSRank:GetFieldValue(key)
    return __rank__[key];
end

function GGSRank:SetTitle(title)
    __scope__:Set("title", title);
end

function GGSRank:Sort()
    local ranks = self:GetRanks();
    local compare = self:GetSort();
    if (type(compare) == "function") then
        return sort(ranks, compare);
    end

    if (type(sort) == "string") then
        return sort(ranks, function(item2, item1)
            return item1[sort] > item2[sort];
        end)
    end
end

function GGSRank:GetWidthHeight()
    local fields = self:GetFields();
    local width, height, fieldCount = 0, 0, 0;
    for _, field in pairs(fields) do
        width = width + (field.width or self:GetFieldWidth());
        fieldCount = fieldCount + 1;
    end
    width = width + fieldCount * 2;  -- 2 margin-left
    height = self:GetFieldHeight() * self:GetMaxLineCount() + 100;

    return width, height;
end

function GGSRank:ShowUI(G, params)
    self:CloseUI();

    G = G or {};
    params = params or {};

    G.GlobalScope = __scope__;
    params.url = params.url or "%gi%/Independent/UI/GGSRank.html";
    params.alignment = params.alignment or "_rt";

    local width, height = self:GetWidthHeight();
    params.width = params.width or width;
    params.height = params.height or height;

    __ui__ = ShowWindow(G, params);

    return __ui__;
end

function GGSRank:CloseUI()
    if (not __ui__) then return end
    __ui__:CloseWindow();
end

function GGSRank:RefreshRank(userdata)
    local ranks = GGSRank:GetRanks();
    local fields = GGSRank:GetFields();
    local rank = nil;

    for _, currank in ipairs(ranks) do
        if (currank.__username__ == userdata.__username__) then
            rank = currank;
            break;
        end        
    end

    if (not rank) then
        table.insert(ranks, {__username__ = userdata.__username__});        
        rank = ranks[#ranks];
    end

    for _, field in pairs(fields) do
        if (field.key == "__username__") then 
            -- 忽略内置字段
        elseif (userdata[field.key] == nil) then
            -- 如果字段值不存在则移除
            for i, item in ipairs(ranks) do
                if (item.__username__ == userdata.__username__) then
                    table.remove(ranks, i);
                    return ;
                end
            end
        else
            -- 填充字段值
            rank[field.key] = userdata[field.key];
        end
    end

    GGSRank:Sort();
end

function GGSRank:RefreshRanks()
    local allUserData = GGS:GetAllUserData();
    for _, userdata in pairs(allUserData) do 
        self:RefreshRank(userdata);
    end
end

GGSRank:InitSingleton():Init();

-- 收到其他用户状态同步
GGS:OnUserData(function(userdata)         
    GGSRank:RefreshRank(userdata);
end);

-- 依赖 GGS 故直接连接
GGS:Connect(function()
    GGS:SetUserData(__rank__);            -- 连接成功直接同步当前用户状态
end);