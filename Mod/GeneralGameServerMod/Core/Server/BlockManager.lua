--[[
Title: BlockManager
Author(s): wxa
Date: 2020/6/10
Desc: 方块管理器
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/BlockManager.lua");
local BlockManager = commonlib.gettable("GeneralGameServerMod.Core.Server.BlockManager");

-------------------------------------------------------
]]

-- 对象定义
local BlockManager = commonlib.inherit(nil, commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.BlockManager"));


function BlockManager:ctor()
    self.blockMap = {};
end

function BlockManager:AddBlock(block)
    self.blockMap[block.blockIndex] = block;
end

function BlockManager:AddBlockList(blockList)
    for i = 1, #blockList do
        self:AddBlock(blockList[i]);
    end
end
