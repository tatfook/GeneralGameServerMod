--[[
Title: BlockAPI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local BlockAPI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/API/BlockAPI.lua");
------------------------------------------------------------
]]


local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local BlockAPI = NPL.export();

local function cmd(...)
    CommandManager:RunCommand(...);
end

local function ClearRegion(x, y, z, dx, dy, dz)
    for __x__ = x, x + dx do
        for __z__ = z, z + dz do
            for __y__ = y, y + dy do
                BlockEngine:SetBlock(__x__, __y__, __z__, 0);
            end
        end
    end
end 

local function LoadTemplate(filename, x, y, z, dx, dy, dz)
    if (not filename) then return end

    dx, dy, dz = dx or 128, dy or 128, dz or 128;
    x, y, z = x or math.floor(19200 - dx / 2), y or 5, z or math.floor(19200 - dz / 2); 
    local cx, cy, cz = x + math.floor(dx / 2), y, z + math.floor(dz / 2);

    cmd("/property UseAsyncLoadWorld false");
    cmd("/property AsyncChunkMode false");
    
    ClearRegion(x, y, z, dx, dy, dz);
    cmd(string.format("/loadregion %d %d %d %d", cx, cy, cz, math.max(dx, dz) + 10));
    cmd(string.format("/loadtemplate %d %d %d %s", cx, cy, cz, filename));

    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
end

local function SaveTemplate(filename, x, y, z, dx, dy, dz)
    if (not filename) then return end

    dx, dy, dz = dx or 128, dy or 128, dz or 128;
    x, y, z = x or math.floor(19200 - dx / 2), y or 5, z or math.floor(19200 - dz / 2); 
    local cx, cy, cz = x + math.floor(dx / 2), y, z + math.floor(dz / 2);

    cmd("/property UseAsyncLoadWorld false");
    cmd("/property AsyncChunkMode false");

    cmd(string.format("/loadregion %d %d %d %d", cx, cy, cz, math.max(dx, dz) + 10));
    cmd(string.format("/select %d %d %d (%d %d %d)", x, y, z, dx, dy, dz));
    cmd(string.format("/savetemplate -auto_pivot %s", filename));
    cmd("/select -clear");

    -- cmd(string.format("/loadtemplate -r %d %d %d %s", cx, cy, cz, filename));
    -- ClearRegion(x, y, z, dx, dy, dz);

    cmd("/property AsyncChunkMode true");
    cmd("/property UseAsyncLoadWorld true");
end

setmetatable(BlockAPI, {__call = function(_, CodeEnv)
    CodeEnv.GetBlockId = ParaTerrain.GetBlockTemplateByIdx;
    CodeEnv.GetBlockEntity = EntityManager.GetBlockEntity;
	CodeEnv.CreateBlockPieces = function (blockid, ...) return GameLogic.GetWorld():CreateBlockPieces(block_types.get(blockid), ...) end
	CodeEnv.SetBlock = function(...) BlockEngine:SetBlock(...) end
    CodeEnv.GetBlock = function(...) return BlockEngine:GetBlock(...) end 
	CodeEnv.GetBlockFull = function (...) return BlockEngine:GetBlockFull(...) end
    CodeEnv.ConvertToRealPosition = function (...) return BlockEngine:ConvertToRealPosition_float(...) end
    CodeEnv.ConvertToBlockPosition = function(x, y, z) return BlockEngine:block(x, y, z) end
	CodeEnv.ConvertToBlockIndex = function (...) return BlockEngine:GetSparseIndex(...) end
	CodeEnv.ConvertToBlockPositionFromBlockIndex = function (...) return BlockEngine:FromSparseIndex(...) end

    CodeEnv.ClearRegion = ClearRegion;
    CodeEnv.LoadTemplate = LoadTemplate;
    CodeEnv.SaveTemplate = SaveTemplate;

    CodeEnv.__BlockSize__ = BlockEngine.blocksize;
    CodeEnv.__HalfBlockSize__ = BlockEngine.half_blocksize;
end});