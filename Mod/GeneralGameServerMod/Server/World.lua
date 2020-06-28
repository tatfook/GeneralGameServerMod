
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackage.lua");
NPL.load("Mod/GeneralGameServerMod/Server/PlayerManager.lua");
NPL.load("Mod/GeneralGameServerMod/Server/BlockManager.lua");

local TexturePackage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local PlayerManager = commonlib.gettable("Mod.GeneralGameServerMod.Server.PlayerManager");
local BlockManager = commonlib.gettable("Mod.GeneralGameServerMod.Server.BlockManager");
local World = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Server.World"));

-- 一个世界对象, 应该包含世界的所有数据
function World:ctor()
    -- 实体ID 所有需要同步的实体都需从此分配
    self.nextEntityId = 0;

    -- 玩家管理器
    self.playerManager = PlayerManager:new():Init(self);
    
    -- 方块管理器
    self.blockManager = BlockManager:new();

    -- 默认世界环境信息
    self.env = {
        texturePack = {
            type = TexturePackage.default_texture_type,
            path = TexturePackage.default_texture_path,
            url = TexturePackage.default_texture_url,
            text = TexturePackage.default_texture_name,
        },
	    weather = nil,
        customBlocks = {
            {
                name = "customblocks",
                attr = { 
                    desc = "ID must be in range:2000-5000",
                },
            },
        }
    }
end

function World:Init()
    return self;
end

function World:SetWorldId(worldId)
    self.worldId = worldId;
end

function World:GetWorldId()
    return self.worldId;
end

function World:GetNextEntityId()
    self.nextEntityId = self.nextEntityId + 1;
    return self.nextEntityId;
end

-- 获取世界用户数
function World:GetClientCount() 
    return self:GetPlayerManager():GetPlayerCount();
end

-- 获取世界的玩家管理器
function World:GetPlayerManager()
    return self.playerManager;
end

-- 获取方块管理器
function World:GetBlockManager() 
    return self.blockManager;
end

-- 获取世界环境更新包
function World:GetPacketUpdateEnv()
    return Packets.PacketUpdateEnv:new():Init(self.env.texturePack, self.env.weather, self.env.customBlocks);
end

-- 移除断开链接的用户
function World:RemoveInvalidPlayer()
    self:GetPlayerManager():RemoveInvalidPlayer();
end

