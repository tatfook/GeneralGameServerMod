
local MacroBlock = NPL.load("./MacroBlock.lua", IsDevEnv);

local BlockCodeGlobal = NPL.export();

local function ExtendBlock(SrcMap, DstMap)
    for key, block in pairs(SrcMap) do
        DstMap[key] = block;
    end
end

function BlockCodeGlobal:New()
    local G = setmetatable({}, {__index = _G});
    ExtendBlock(MacroBlock, G);

    return G;
end



