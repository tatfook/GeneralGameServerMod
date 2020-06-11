
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/TexturePackage.lua");
NPL.load("Mod/GeneralGameServerMod/Server/PlayerManager.lua");

local TexturePackage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TexturePackage");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local PlayerManager = commonlib.gettable("GeneralGameServerMod.Server.PlayerManager");

local World = commonlib.inherit(nil, commonlib.gettable("GeneralGameServerMod.Server.World"));

-- 一个世界对象, 应该包含世界的所有数据
function World:ctor()
    -- 玩家管理器
    self.playerManager = PlayerManager:new():Init(self);
    
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

    -- 默认出生地点
    self.spawnPosition = {
        x = 20000,
        y = -128,
        z = 20000,
    }
end

function World:Init()
    return self;
end

-- 获取世界的玩家管理器
function World:GetPlayerManager()
    return self.playerManager;
end

-- 获取出生地点数据包
function World:GetPacketSpawnPosition() 
    return Packets.PacketSpawnPosition:new():Init(self.spawnPosition.x, self.spawnPosition.y, self.spawnPosition.z);
end

-- 获取世界环境更新包
function World:GetPacketUpdateEnv()
    return Packets.PacketUpdateEnv:new():Init(self.env.texturePack, self.env.weather, self.env.customBlocks);
end
