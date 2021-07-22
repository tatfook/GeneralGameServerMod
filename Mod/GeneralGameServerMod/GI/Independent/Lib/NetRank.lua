--[[
Title: NetRank
Author(s):  wxa
Date: 2021-06-01
Desc: 排行榜
use the lib:
------------------------------------------------------------
local NetRank = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/NetRank.lua");
------------------------------------------------------------
]]
local Net = require("Net");
local NetRank = inherit(ToolBase, module("NetRank"));

-- 比较方式 使用排序
NetRank:Property("Sort", "score");   
NetRank:Property("FieldWidth", 100);
NetRank:Property("FieldHeight", 30);

-- 窗口对象
local __ui__ = nil;
-- ui scope
local __scope__ = NewScope();
-- 当前用户排行数据 
local __rank__ = {};

function NetRank:Init()
    __scope__:Set("fields", {});
    __scope__:Set("title", "排行榜");

    self:SetMaxLineCount(10);

    -- 默认字段
    self:DefineField({key = "nickname", title = "昵称", no = 1, width = 200, defaule_value = GetNickName() or GetUserName()});
    self:DefineField({key = "score", title = "得分", no = 2, defaule_value = 0});
    
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

function NetRank:GetMaxLineCount()
    return __scope__:Get("MaxLineCount") or 0;
end

function NetRank:SetMaxLineCount(count)
    __scope__:Set("MaxLineCount", count);
    __scope__:Set("ContentHeight", self:GetFieldHeight() * count);
end

function NetRank:GetFields()
    return __scope__:Get("fields", {});
end

function NetRank:GetRanks()
    return __scope__:Get("ranks", {});
end

function NetRank:DefineField(field)
    local fields = self:GetFields();
    
    field.width = field.width or self:GetFieldWidth();
    field.height = self:GetFieldHeight();

    fields[field.key] = field;
    self:SetFieldValue(field.key, field.defaule_value);

    self:RefreshRanks();
end

function NetRank:SetFieldValue(key, value)
    __rank__[key] = value;
    Net:SetUserData(__rank__); 
end

function NetRank:GetFieldValue(key)
    return __rank__[key];
end

function NetRank:SetTitle(title)
    __scope__:Set("title", title);
end

function NetRank:Sort()
    local ranks = self:GetRanks();
    local compare = self:GetSort();
    if (type(compare) == "function") then
        return sort(ranks, compare);
    end

    if (type(compare) == "string") then
        return sort(ranks, function(item1, item2)
            -- 默认升序
            return item1[compare] and item2[compare] and item1[compare] < item2[compare];
        end)
    end
end

function NetRank:GetWidthHeight()
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

function NetRank:ShowUI(G, params)
    self:CloseUI();

    G = G or {};
    params = params or {};

    G.GlobalScope = __scope__;
    params.url = params.url or "%gi%/Independent/UI/NetRank.html";
    params.alignment = params.alignment or "_rt";
    params.isClickThrough = true;
    params.zorder = params.zorder or -100;

    local width, height = self:GetWidthHeight();
    params.width = params.width or width;
    params.height = params.height or height;

    __ui__ = ShowWindow(G, params);

    return __ui__;
end

function NetRank:CloseUI()
    if (not __ui__) then return end
    __ui__:CloseWindow();
end

function NetRank:RefreshRank(userdata)
    local ranks = NetRank:GetRanks();
    local fields = NetRank:GetFields();
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

    NetRank:Sort();
end

function NetRank:RefreshRanks()
    local allUserData = Net:GetAllUserData();
    for _, userdata in pairs(allUserData) do 
        self:RefreshRank(userdata);
    end
end

NetRank:InitSingleton():Init();

-- 收到其他用户状态同步
Net:OnUserData(function(userdata)         
    NetRank:RefreshRank(userdata);
end);

-- 依赖 Net 故直接连接
Net:Connect(function()
    Net:SetUserData(__rank__);            -- 连接成功直接同步当前用户状态
end);