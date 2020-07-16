--[[
Title: PlayerController
Author(s):  wxa
Date: 2020-06-12
Desc: 玩家控制器
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/PlayerController.lua");
local PlayerController = commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerController");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/PlayerController.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local Packets = commonlib.gettable("Mod.GeneralGameServerMod.Core.Common.Packets");
local PlayerController = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.PlayerController"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.PlayerController"));

function PlayerController:ctor()
end

function PlayerController:Init(client)
    self.client = client;
    return self;
end

function PlayerController:GetWorld()
    return self.client:GetWorld();
end

-- return true if processed. 
function PlayerController:OnClickBlock(blockId, bx, by, bz, mouseButton, entity, side)
    -- 告知世界方块点击
    self:GetWorld():OnClickBlock(blockId, bx, by, bz, mouseButton, entity, side);

    -- 本地世界事件处理
    self:SuperOnClickBlock(blockId, bx, by, bz, mouseButton, entity, side);
    
    -- 编辑模式不同步
    if(GameLogic.GetMode() == "editor") then return end
    
    -- 获取方块
    local block = blockId and block_types.get(blockId);
    
    -- 方块不存在则不管
    if (not block) then return end;
    
    -- 网络同步
    -- if (block.hasAction) then
    --     self:GetWorld():GetNetHandler():AddToSendQueue(Packets.PacketGeneral:new():Init({
    --         action = "ClickBlock",
    --         data = {
    --             blockId = blockId,
    --             bx = bx,
    --             by = by,
    --             bz = bz,
    --             mouseButton = mouseButton,
    --             entityId = entity and entity.entityId,
    --             side = side,
    --         }
    --     }));
    -- end
end

function PlayerController:SuperOnClickBlock(blockId, bx, by, bz, mouseButton, entity, side)
    return PlayerController._super.OnClickBlock(self, blockId, bx, by, bz, mouseButton, entity, side);
end
