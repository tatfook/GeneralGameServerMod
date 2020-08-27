--[[
Title: UserInfo
Author(s): wxa
Date: 2020/6/30
Desc: 用户信息详情页
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/View/UserInfo.lua");
local UserInfo = commonlib.gettable("Mod.GeneralGameServerMod.App.View.UserInfo");
UserInfo:Show(NpcEntity);
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
NPL.load("Mod/GeneralGameServerMod/App/View/View.lua");
local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
local userMcml2 = true;
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local UserInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.App.View.View"), commonlib.gettable("Mod.GeneralGameServerMod.App.View.UserInfo"));

function UserInfo:ctor() 
end

-- 入口函数
function UserInfo:Init(page)
    -- 初始化基类
    UserInfo._super:Init(page);

    return self;
end

-- 视图渲染完成
function UserInfo:OnCreate()
    -- 设置玩家模型
    local ctl = self:GetPage():FindControl("player");
    local obj_params = ObjEditor.GetObjectParams(self:GetEntityPlayer():GetInnerObject());

    if(ctl and obj_params) then
        obj_params.name = "mc_player";
        obj_params.facing = 1.57;
        -- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
        obj_params.Attribute = 128;
        obj_params.AssetFile = self:GetEntityPlayer():GetMainAssetPath();
        ctl:ShowModel(obj_params);    
    else
        self:GetPage():CallMethod("player", "SetAssetFile", self:GetEntityPlayer():GetMainAssetPath());
    end
end

-- 加载用户信息
function UserInfo:LoadUserInfo(username)
    local Api = UserInfo:GetApi();
    local status, response, data = Api:GetUserDetail(username);
    if (status ~= 200) then
        echo("获取用户详情失败...");
        return false;
    end
    self.UserDetail = data;
    -- 获取用户ID
    local userId = self.UserDetail.id;
    status, response, data = Api:GetUserProjects(userId);
    if (status ~= 200) then
        echo("获取用户项目列表失败");
        return false;
    end
    self.ProjectList = data;

    -- 是否关注判断
    status, _, data = Api:IsFollow(userId);
    self.isFollow = status == 200 and data;

    Log:Debug(self.UserDetail);
    Log:Debug(self.ProjectList);
    Log:Debug(self.isFollow);
    return true;
end

-- 获取用户名
function UserInfo:GetUserName() 
    return self.username;
end

-- 获取实体玩家
function UserInfo:GetEntityPlayer()
    return self.entityPlayer;
end

-- 显示页面
function UserInfo:Show(entityPlayer)
    entityPlayer = entityPlayer or GameLogic.GetPlayerController():GetPlayer();
    local username = entityPlayer:GetUserName() or System.User.keepworkUsername;
    local mainasset = entityPlayer:GetMainAssetPath();
    if (userMcml2) then
        return page.ShowUserInfoPage({username = username, mainasset = mainasset});
    end
    -- 重复点击相同的用户关闭页面
    if (self.username == username and self:IsShow()) then
        return self:Close();
    end

    self.username = username;
    self.entityPlayer = entityPlayer;

    -- 当窗口没有打开时打开窗口
    if (not self:IsShow()) then 
        UserInfo._super.Show(self, {
            url = "Mod/GeneralGameServerMod/App/View/UserInfo.html",
            name = "Mod.GeneralGameServerMod.App.View.UserInfo",
            width = 880,
            height = 584,
            title = "用户信息",
        });
    end

    -- 加载数据
    if (not self:LoadUserInfo(username)) then
        return self:Close();   -- 加载数据失败关闭页面
    end
    
    -- 刷新页面
    self:Refresh();

   
end

-- 初始化成单列模式
UserInfo:InitSingleton();
