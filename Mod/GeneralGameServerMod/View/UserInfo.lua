--[[
Title: UserInfo
Author(s): wxa
Date: 2020/6/30
Desc: 用户信息详情页
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/View/UserInfo.lua");
local UserInfo = commonlib.gettable("Mod.GeneralGameServerMod.View.UserInfo"):GetSingleton();
UserInfo:Show();
-------------------------------------------------------
]]

NPL.load("Mod/GeneralGameServerMod/View/View.lua");
NPL.load("Mod/GeneralGameServerMod/Common/Log.lua");

local Log = commonlib.gettable("Mod.GeneralGameServerMod.Common.Log");
local UserInfo = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.View.View"), commonlib.gettable("Mod.GeneralGameServerMod.View.UserInfo"));

function UserInfo:ctor() 
end

function UserInfo:Init()
    self._super:Init();
    return self;
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

-- 显示页面
function UserInfo:Show(username)
    if (not username) then return end;
    -- 重复点击相同的用户关闭页面
    if (self.username == username and self:IsShow()) then
        return self:Close();
    end

    self.username = username;
    
    -- 当窗口没有打开时打开窗口
    if (not self:IsShow()) then 
        self._super.Show(self, {
            url = "Mod/GeneralGameServerMod/View/UserInfo.html",
            name = "Mod.GeneralGameServerMod.View.UserInfo",
            width = 590,
            height = 320,
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


