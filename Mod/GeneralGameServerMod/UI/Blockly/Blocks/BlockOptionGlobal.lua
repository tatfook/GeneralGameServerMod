
local MacroBlock = NPL.load("./MacroBlock.lua", IsDevEnv);
local ListBlock = NPL.load("./ListBlock.lua", IsDevEnv);

local BlockOptionGlobal = NPL.export();

local function ExtendBlock(SrcMap, DstMap)
    for key, block in pairs(SrcMap) do
        DstMap[key] = block;
    end
end

function BlockOptionGlobal:New()
    local G = setmetatable({}, {__index = _G});

    ExtendBlock(MacroBlock, G);
    ExtendBlock(ListBlock, G);

    return G;
end
