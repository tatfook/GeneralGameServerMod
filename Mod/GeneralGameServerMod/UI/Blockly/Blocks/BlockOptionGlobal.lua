
local MacroBlock = NPL.load("./MacroBlock.lua", IsDevEnv);
local ListBlock = NPL.load("./ListBlock.lua", IsDevEnv);
local UIBlock = NPL.load("./UIBlock.lua", IsDevEnv);

local BlockOptionGlobal = NPL.export();

local function ExtendBlock(SrcMap, DstMap)
    for key, block in pairs(SrcMap) do
        DstMap[key] = block;
    end
end

function BlockOptionGlobal:New()
    local G = setmetatable({}, {__index = _G});

    -- 内置启动块
    G.System_Main = {
        type = "System_Main",
        category = "事件",
        color = "#2E9BEF",
        output = false,
        previousStatement = false, 
        nextStatement = true,
        message = "程序入口",
        code_description = [[]],
        arg = {  },
    }
    
    ExtendBlock(MacroBlock, G);
    ExtendBlock(ListBlock, G);
    ExtendBlock(UIBlock, G);

    return G;
end
