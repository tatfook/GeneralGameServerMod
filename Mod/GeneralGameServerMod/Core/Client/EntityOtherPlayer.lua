--[[
Title: entity player multiplayer client
Author(s): wxa
Date: 2020/6/15
Desc: the other player entity on the client side. 
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/EntityOtherPlayer.lua");
local EntityOtherPlayer = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerMPOther.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("Mod/GeneralGameServerMod/Core/Common/Log.lua");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local Log = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Log");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local EntityOtherPlayer = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerMPOther"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer"));

local moduleName = "Mod.GeneralGameServerMod.Core.Client.EntityOtherPlayer";

function EntityOtherPlayer:ctor()
    self.playerInfo = {};
end

function EntityOtherPlayer:init(world, username, entityId)
    EntityOtherPlayer._super.init(self, world, username, entityId);
    self:SetSkipPicking(not self:IsCanClick());

    return self;
end

-- 是否可以被点击
function EntityOtherPlayer:IsCanClick() 
    return true;
end

-- 设置玩家信息
function EntityOtherPlayer:SetPlayerInfo(playerInfo)
    commonlib.partialcopy(self.playerInfo, playerInfo);
end

-- 获取玩家信息
function EntityOtherPlayer:GetPlayerInfo()
    return self.playerInfo;
end

-- 实体玩家是否在家
function EntityOtherPlayer:IsOnline()
    return self.playerInfo.state == "online";
end

-- virtual function:
function EntityOtherPlayer:OnClick(x,y,z, mouse_button,entity,side)
-- 返回真 取消默认事件处理程序
    return true;
end

-- 是否可以被其它实体推动
function EntityOtherPlayer:CanBePushedBy(entity)
    return not self:IsOnline();
end

-- 是否存在target
function EntityOtherPlayer:HasTarget()
    -- 在线用户使用 target 移动
    if (self:IsOnline()) then
        return EntityOtherPlayer._super.HasTarget(self);
    end
    -- 离线用户使用 montion 避让
    return false;
end

-- 动画帧
function EntityOtherPlayer:FrameMove(deltaTime)
    if (not self:IsOnline()) then
        EntityOtherPlayer._super.MoveEntity(self, deltaTime);	
    end

    self:OnUpdate();
end

-- 更改人物外观
function EntityOtherPlayer:UpdateEntityActionState()
    local dataWatcher = self:GetDataWatcher();
    -- 模型 character/CC/02human/paperman/boy02.x
    local  assetsWhiteList = {
        "character/CC/02human/paperman/boy01.x",
        "character/CC/02human/paperman/boy02.x",
        "character/CC/02human/paperman/boy03.x",
        "character/CC/02human/paperman/boy04.x",
        "character/CC/02human/paperman/boy05.x",
        "character/CC/02human/paperman/boy06.x",
        "character/CC/02human/paperman/boy07.x",
        "character/CC/02human/paperman/girl01.x",
        "character/CC/02human/paperman/girl02.x",
        "character/CC/02human/paperman/girl03.x",
        "character/CC/02human/paperman/girl04.x",
        "character/CC/02human/paperman/girl05.x",
    }
    local curMainAsset = dataWatcher:GetField(self.dataMainAsset);
    local assetIndex = math.random(1, #assetsWhiteList);
    if(curMainAsset~=self:GetMainAssetPath()) then
        for i = 1, #assetsWhiteList do
            if (curMainAsset == assetsWhiteList[i]) then
                assetIndex = i;
                break;
            end
        end
        self:SetMainAssetPath(assetsWhiteList[assetIndex]);
	end
    -- 改写大小同步规则
    local curScale = dataWatcher:GetField(self.dataFieldScale);
	if(curScale and curScale ~= self:GetScaling()) then
		self:SetScaling(curScale > 1.5 and 1.5 or (curScale < 0.5 and 0.5 or curScale));
    end
    -- 调用基类函数
    EntityOtherPlayer._super.UpdateEntityActionState(self);
end
