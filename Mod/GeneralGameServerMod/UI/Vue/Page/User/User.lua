
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Debug = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Debug.lua");
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua");
local Encoding = commonlib.gettable("System.Encoding");
local SelfProjectList = {};
local AuthUser = KeepWorkItemManager.GetProfile();
local player = GameLogic.GetPlayerController():GetPlayer();
local GlobalScope = GetGlobalScope();
local PageSize = 10;

-- 组件全局变量初始化
GlobalScope:Set("AuthUsername", AuthUser.username);
GlobalScope:Set("AuthUserId", AuthUser.id or 0);
GlobalScope:Set("isLogin", System.User.keepworkUsername and true or false);
GlobalScope:Set("isAuthUser", false);
GlobalScope:Set("UserDetail", {username = "", createdAt = "2020-01-01", rank = {}});
GlobalScope:Set("ProjectList", {});                      -- 用户项目列表
GlobalScope:Set("FavoriteProjectList", {});              -- 收藏项目列表
GlobalScope:Set("MainAsset", player and player:GetMainAssetPath());
GlobalScope:Set("ProjectListType", "works");

local ProjectMap = {};

local function IsExistScopeProjectList(projectId)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for _, project in ipairs(ScopePorjectList) do
        if (project.id == projectId) then return true end
    end
    return false;
end

local function AddPojectListToScopeProjectList(ProjectList)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for _, project in ipairs(ProjectList) do
        if (not IsExistScopeProjectList(project.id)) then
            table.insert(ScopePorjectList, project);
        end
    end
end

local function GetProjectListPageFunc()
    -- 获取项目列表
    local page, pageSize = 1, PageSize;
    local isFinish = false;
    local isRequest = false;
    
    return function() 
        if (isFinish or isRequest) then return end
        local userId = GlobalScope:Get("UserId");
        local AuthUserId = GlobalScope:Get("AuthUserId");
        if (not userId) then return end
        local BeginTime = GetTime();
        isRequest = true;
        keepwork.project.list({
            -- 请求参数
            userId = userId,                    -- 用户ID
            type = 1,                           -- 取世界项目
            -- 分页控制
            ["x-page"] = page,                  -- 页数
            ["x-per-page"] = pageSize,          -- 页大小
            ["x-order"] = "updatedAt-desc",     -- 按更新时间降序
        }, function(status, msg, data)
            local total = tonumber(string.match(msg.header, "x-total:%s*(%d+)"));
            if (status ~= 200) then 
                isFinish = true;
                return echo("获取用户项目列表失败, userId " .. tostring(userId));
            end
            local ProjectList = data;
            -- Log.Format("page = %s, count = %s", page, #ProjectList);

            -- echo(data, true);
            local projectIds, projects = {}, {};
            for i, project in ipairs(ProjectList) do
                projectIds[i] = project.id;
                projects[project.id] = project;
                project.isFavorite = false;
                project.selected = false;
                project.user = GlobalScope:Get("UserDetail");
            end
            if (AuthUserId and AuthUserId > 0) then
                keepwork.project.favorite_search({
                    objectType = 5,
                    objectId = {
                        ["$in"] = projectIds,
                    }, 
                    userId = AuthUserId,
                }, function(status, msg, data)
                    local rows = data.rows or {};
                    for _, row in ipairs(rows) do projects[row.objectId].isFavorite = true end
                    local EndTime = GetTime();
                    -- print("耗时: ", EndTime - BeginTime);
                    AddPojectListToScopeProjectList(ProjectList);
                end);
            else
                AddPojectListToScopeProjectList(ProjectList);
            end
            local ScopePorjectList = GlobalScope:Get("ProjectList");
            if (total) then
                isFinish = (#ScopePorjectList) >= total;
            else
                isFinish = (#ProjectList) < pageSize; 
            end
            page = page + 1;
            isRequest = false;
        end)
    end
end

local function GetFavoriteProjectListPageFunc()
    -- 获取项目列表
    local page, pageSize = 1, PageSize;
    local isFinish = false;
    local isRequest = false;
    
    return function() 
        if (isFinish or isRequest) then return end
        local userId = GlobalScope:Get("AuthUserId");
        if (not userId) then return end
        isRequest = true;
        keepwork.project.list_favorite({
            -- 请求参数
            userId = userId,                    -- 用户ID
            type = 1,                           -- 取世界项目
            -- 分页控制
            ["x-page"] = page,                  -- 页数
            ["x-per-page"] = pageSize,          -- 页大小
            ["x-order"] = "updatedAt-desc",     -- 按更新时间降序
        }, function(status, msg, data)
            if (status ~= 200) then 
                isFinish = true;
                return echo("获取用户项目列表失败, userId " .. tostring(userId));
            end
            local ProjectList = data.rows;
            local total = data.count;
            -- echo(data, true);
            if (#ProjectList < pageSize) then isFinish = true end
            for _, project in ipairs(ProjectList) do 
                project.isFavorite = true;
                project.selected = false;
            end
            AddPojectListToScopeProjectList(ProjectList);
            local ScopePorjectList = GlobalScope:Get("ProjectList");
            if (total) then
                isFinish = (#ScopePorjectList) >= total;
            else
                isFinish = (#ProjectList) < pageSize; 
            end

            page = page + 1;
            isRequest = false;
        end)
    end
end

-- 取消收藏
local function UnfavoriteProject(projectId)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for i, project in ipairs(ScopePorjectList) do
        if (project.id == projectId) then 
            project.isFavorite = false;
            if (GetProjectListType() == "favorite") then
                table.remove(ScopePorjectList, i);
            end
            break;
        end
    end
    
    -- GlobalScope:Set("ProjectList", ScopePorjectList);

    keepwork.world.unfavorite({objectType = 5, objectId = projectId}, function(status)
        if (status < 200 or status >= 300) then
            Log("无法取消收藏");
        end
    end);
end

-- 收藏
local function FavoriteProject(projectId)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for i, project in ipairs(ScopePorjectList) do
        if (project.id == projectId) then 
            project.isFavorite = true;
            break;
        end
    end
    
    -- GlobalScope:Set("ProjectList", ScopePorjectList);

    keepwork.world.favorite({objectType = 5, objectId = projectId}, function(status)
        if (status < 200 or status >= 300) then
            Log("无法收藏");
        end
    end);
end

_G.UnfavoriteProject = UnfavoriteProject;
_G.FavoriteProject = FavoriteProject;
_G.NextPageProjectList = GetProjectListPageFunc();
_G.SetProjectListType = function(projectListType)
    GlobalScope:Set("ProjectList", {});
    GlobalScope:Set("ProjectListType", projectListType);

    if (projectListType == "favorite") then
        _G.NextPageProjectList = GetFavoriteProjectListPageFunc();
    else
        _G.NextPageProjectList = GetProjectListPageFunc();
    end
    NextPageProjectList();
end
_G.GetProjectListType = function()
    return GlobalScope:Get("ProjectListType");
end

-- SetProjectListType("works");

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
            -- echo("--------------------------------IsAuthUser------------------------------------");
        end

        -- 设置模型
        GlobalScope:Set("UserDetail", UserDetail);
        GlobalScope:Set("UserId", UserDetail.id);

        local ParacraftPlayerEntityInfo = UserDetail.extra and UserDetail.extra.ParacraftPlayerEntityInfo or {};
        if (ParacraftPlayerEntityInfo.asset) then GlobalScope:Set("MainAsset", ParacraftPlayerEntityInfo.asset) end 

        -- 先拉取第一页
        NextPageProjectList();
        if (not GlobalScope:Get("isAuthUser")) then return end
        -- 获取是否关注
        keepwork.user.isfollow({
            objectId = UserDetail.id,
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
            local tpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (tpl) then
                table.insert(assets, {
                    id = tpl.id,
                    modelUrl = tpl.modelUrl,
                    icon = GetItemIcon(tpl),
                    name = tpl.name,
                });
            end
        end
    end
    return assets;
end

_G.GetAllAssets = function()
    local bagId, bagNo = 0, 1007;
    local assets = {}; 
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            bagId = bag.id;
            break;
        end
    end

    local userAssets = _G.GetUserAssets();
    local function IsOwned(id)
        for _, asset in ipairs(userAssets) do
            if (asset.id == id) then return true end
        end
        return false;
    end

    for _, tpl in ipairs(KeepWorkItemManager.globalstore) do
        -- echo(tpl, true)
        if (tpl.bagId == bagId) then
            table.insert(assets, {
                id = tpl.id,
                gsId = tpl.gsId,
                modelUrl = tpl.modelUrl,
                icon = GetItemIcon(tpl),
                name = tpl.name,
                owned = IsOwned(tpl.id),
            });
        end
    end

    -- echo(assets, true);
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
    verticalScrollBar:GetThumb():SetStyleValue("background", "Texture/Aries/Creator/keepwork/ggs/dialog/xiala_12X38_32bits.png#0 0 12 38:2 5 2 5");
    verticalScrollBar:GetThumb():SetStyleValue("min-height", 10);
end

LoadUserInfo();