
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Debug = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Debug.lua");
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua");
local Encoding = commonlib.gettable("System.Encoding");
local SelfProjectList = {};

local GlobalScope = GetGlobalScope();
-- 组件全局变量初始化
GlobalScope:Set("AuthUsername", System.User.keepworkUsername);
GlobalScope:Set("isLogin", System.User.keepworkUsername and true or false);
GlobalScope:Set("isAuthUser", false);
GlobalScope:Set("UserDetail", {username = "", createdAt = "2020-01-01", rank = {}});
GlobalScope:Set("ProjectList", {});

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

_G.GetUserAssets = function()
    -- echo(KeepWorkItemManager.bags, true);
    -- echo(KeepWorkItemManager.items, true);
    local skinBag = nil;
    local assets = {};
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bag.name == "换装") then
            skinBag = bag;
            break;
        end
    end 
    local bagId = skinBag and skinBag.id;
    if (not bagId) then return assets end

    for _, item in ipairs(KeepWorkItemManager.items) do
        if (item.bagId == bagId) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                -- echo(itemTpl, true);
                table.insert(assets, {
                    modelUrl = itemTpl.modelUrl,
                    name = itemTpl.name,
                });
            end
        end
    end

    return assets;
end

-- echo(_G.GetUserAssets(), true);
-- _G.GetUserAssets()

_G.GetUserShowGoods = function()
    local bagId = 4;
    local goods = {}; 
    for _, item in ipairs(KeepWorkItemManager.items) do
        local copies = item.copies or 0;
        if (item.bagId == bagId and copies > 0) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                local icon = itemTpl.icon;
                if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d_32bits.png", item.gsId) end
                -- echo(itemTpl, true);
                table.insert(goods, {
                    icon = icon,
                    copies = copies,
                    name = itemTpl.name,
                });
            end
        end
    end

    -- echo(goods, true);

    return goods;
end

_G.GetUserShowGoods();

LoadUserInfo();