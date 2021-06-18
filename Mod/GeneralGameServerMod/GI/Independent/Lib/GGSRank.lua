--[[
Title: Rank
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
GGSRank:Property("Compare", nil);   
GGSRank:Property("FieldWidth", 100);
GGSRank:Property("FieldHeight", 30);

-- 窗口对象
local __ui__ = nil;
-- ui scope
local __scope__ = NewScope();
-- 当前用户名
local __username__ = GetUserName();
-- 所有用户排行数据
local __ranks__ = GGS:Get("__ranks__", {}); 
local __ranks_keys__ = __ranks__:__get_keys__();   -- keys
-- 当前用户排行数据
local __rank__ = __ranks__:Get(__username__, {});

local function IsInnerGGSRanksScope(keys)
    for i, key in ipairs(__ranks_keys__) do
        if (key ~= keys[i]) then return false end
    end
    return true;
end

-- 依赖 GGS 故直接连接
GGS:Connect(function()
    GGS:SendSyncState(__rank__);   -- 连接成功直接同步当前用户状态
end);

GGS:OnSyncState(function(keys)     -- 收到其他用户状态同步
    if (not keys or not IsInnerGGSRanksScope(keys)) then return end 
    GGSRank:RefreshRanksUI(); 
end);

function GGSRank:ctor()
    __scope__:Set("fields", {});
    __scope__:Set("title", "排行榜");

    self:SetMaxLineCount(30);
end

--[[
定义排行字段  {
    key = "nickname",       -- 字段名
    defaule_value = "xiaoyao",  -- 默认值
    title = "昵称",         -- 标题名
    no = 1,                 -- 列号
    width = 100,            -- 字段宽度
}
--]] 

function GGSRank:GetMaxLineCount()
    return __scope__:Get("MaxLineCount");
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
end

function GGSRank:RemoveField(key)
end

function GGSRank:SetFieldValue(key, value)
    __rank__:Set(key, value);

    self:RefreshRanksUI();
end

function GGSRank:GetFieldValue(key)
    return __rank__:Get(key);
end

function GGSRank:SetTitle(title)
    __scope__:Set("title", title);
end

function GGSRank:RefreshRanksUI()
    local ranks = self:GetRanks();
    local fields = self:GetFields();

    for username, rank in pairs(__ranks__) do
        local uirank = nil;
        for _, item in ipairs(ranks) do
            if (item.username == username) then
                uirank = item;
                break;
            end
        end
        if (not uirank) then
            uirank = {username = username}
            table.insert(ranks, uirank);
        end
        for _, field in pairs(fields) do
            uirank[field.key] = rank[field.key];
        end
    end

    local compare = self:GetCompare();
    if (type(compare) == "function") then
        table.sort(ranks, compare);
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
    height = self:GetFieldHeight() * self:GetMaxLineCount() + 30 + 40;

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

GGSRank:InitSingleton();
