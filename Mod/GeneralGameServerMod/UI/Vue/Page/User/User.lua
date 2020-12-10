
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Debug = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Debug.lua");
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua");
local Encoding = commonlib.gettable("System.Encoding");
local SelfProjectList = {};

local player = GameLogic.GetPlayerController():GetPlayer();
local GlobalScope = GetGlobalScope();
-- 组件全局变量初始化
GlobalScope:Set("AuthUsername", System.User.keepworkUsername);
GlobalScope:Set("isLogin", System.User.keepworkUsername and true or false);
GlobalScope:Set("isAuthUser", false);
GlobalScope:Set("UserDetail", {username = "", createdAt = "2020-01-01", rank = {}});
GlobalScope:Set("ProjectList", {});
GlobalScope:Set("MainAsset", player and player:GetMainAssetPath());

-- 加载用户信息
function LoadUserInfo()
    local payload = {};
    if (self.userId) then payload.userId = self.userId 
    elseif (self.username) then payload.username = self.username 
    else  payload.username = System.User.keepworkUsername or "xiaoyao" end
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode(payload));
    -- 获取用户信息
    keepwork.user.getinfo({
        cache_policy = "access plus 0",
        router_params = {id = id},
    }, function(status, msg, data) 
        if (status ~= 200) then return echo("获取用户详情失败...") end
        local UserDetail = data;
        -- echo(UserDetail)
        -- 设置知识豆
        _, _, _, UserDetail.bean = KeepWorkItemManager.HasGSItem(998);

        -- echo(data)
        if (System.User.keepworkUsername == UserDetail.username) then
            GlobalScope:Set("AuthUserId", UserDetail.id);
            GlobalScope:Set("isAuthUser", true);
        end
        GlobalScope:Set("UserDetail", UserDetail);

        -- 获取项目列表
        local userId = UserDetail.id;
        local page, pageSize = 1, 10;
        local isFinish = false;
        local isRequest = false;
        local NextPagePorjectList = function() 
            if (isFinish or isRequest) then return end
            isRequest = true;
            keepwork.project.list({
                -- 请求参数
                userId = userId,
                type = 1,               -- 取世界项目
                -- 分页控制
                ["x-page"] = page,                  -- 页数
                ["x-per-page"] = pageSize,          -- 页大小
                ["x-order"] = "updatedAt-desc",     -- 按更新时间降序
            }, function(status, msg, data)
                isRequest = false;
                if (status ~= 200) then return echo("获取用户项目列表失败") end
                local ProjectList = data;
                -- echo(data);
                if (#ProjectList < pageSize) then isFinish = true end
                local ScopePorjectList = GlobalScope:Get("ProjectList");
                for i = 1, #ProjectList do
                    table.insert(ScopePorjectList, ProjectList[i]);
                end
                GlobalScope:Set("ProjectList", ScopePorjectList);
                page = page + 1;
            end)
        end
        -- 先拉取第一页
        NextPagePorjectList();
        GlobalScope:Set("NextPageProjectList", NextPagePorjectList);

        -- 获取是否关注
        keepwork.user.isfollow({
            objectId = userId,
            objectType = 0,
        }, function(status, msg, data) 
            UserDetail.isFollow = false;
            if (status ~= 200) then return end
            if (data and data ~= "false" and tonumber(data) ~= 0) then
                UserDetail.isFollow = true;
            end
        end)
    end)
end


local function GetItemIcon(item)
    local icon = item.icon;
    if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d_32bits.png", item.gsId) end
    return icon;
end

_G.GetUserAssets = function()
    local bagNo = 1007;
    local assets = {};
    for _, item in ipairs(KeepWorkItemManager.items) do
        if (item.bagNo == bagNo) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                table.insert(assets, {
                    modelUrl = itemTpl.modelUrl,
                    icon = GetItemIcon(itemTpl),
                    name = itemTpl.name,
                });
            end
        end
    end
    return assets;
end

_G.GetUserShowGoods = function()
    local bagNo = 1001;
    local goods = {}; 
    for _, item in ipairs(KeepWorkItemManager.items) do
        -- echo(item, true);
        local copies = item.copies or 0;
        if (item.bagNo == bagNo and copies > 0) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                table.insert(goods, {
                    icon = GetItemIcon(itemTpl),
                    copies = copies,
                    name = itemTpl.name,
                });
            end
        end
    end
    return goods;
end

_G.GetUserHonors = function ()
    local bagNo = 1006;
    local honors = {}; 
    for _, item in ipairs(KeepWorkItemManager.items) do
        if (item.bagNo == bagNo) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                table.insert(honors, {
                    icon = GetItemIcon(itemTpl),
                    name = itemTpl.name,
                });
            end
        end
    end
    return honors;
end

_G.UpdatePlayerEntityInfo = function()
    local isAuthUser = GlobalScope:Get("isAuthUser");
    local AuthUserId = GlobalScope:Get("AuthUserId");
    -- 更新用户信息
    if (not isAuthUser) then return end
    local player = GameLogic.GetPlayerController():GetPlayer();
    local asset = player:GetMainAssetPath();
    local skin = player:GetSkin();
    local extra = UserDetail.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    keepwork.user.setinfo({
        router_params = {id = AuthUserId},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
    end);
end 

_G.SetScrollElement = function(el)
    local verticalScrollBar = el and el:GetVerticalScrollBar();
    if (not verticalScrollBar) then return end
    verticalScrollBar:SetStyleValue("background-color", "#ffffff00");
    verticalScrollBar:GetThumb():SetStyleValue("background", "Texture/Aries/Creator/keepwork/ggs/dialog/xiala_12X38_32bits.png#0 0 12 38:2 15 2 15");
    verticalScrollBar:GetThumb():SetStyleValue("min-height", 38);
end

LoadUserInfo();