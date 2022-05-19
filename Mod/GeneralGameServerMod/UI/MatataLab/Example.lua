

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

NPL.load(GameLogic.GetWorldDirectory() .. "MatataLab/MatataLab.lua");

function ShowMatataLabPage()
    local params = {};
    params.url = "%world_directory%/MatataLab/MatataLab.html";
    params.draggable = false;
    params.G = {};
    params.width = 1280;
    params.height = 720;
    -- params.width = params.width or "100%";
    -- params.height = params.height or "100%";
    -- params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    -- params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    params.G.matatalab = {
        title = "火星救援", description = "MatataLab 图块编程图块编程图块编程图块编程图块编程",   
        block_option_list = {   -- 块定义
            {
                type = "上",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/shang_68x50_32bits.png#0 0 68 50",
                code = "MoveUp()",
            }, 
            {
                type = "下",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/xia_68x50_32bits.png#0 0 68 50",
                code = "MoveDown()",
            }, 
            {
                type = "左",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/zuo_68x50_32bits.png#0 0 68 50",
                code = "MoveLeft()",
            }, 
            {
                type = "右",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/you_68x50_32bits.png#0 0 68 50",
                code = "MoveRight()",
            }, 
            {
                type = "NumberBlock2", 
                number = 2, 
                isNumberBlock = true,
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/2_68x40_32bits.png#0 0 68 40",
                code = "2",
            },
            {
                type = "NumberBlock3", 
                number = 3, 
                isNumberBlock = true,
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/3_68x40_32bits.png#0 0 68 40",
                code = "3",
            }, 
        },
        toolbox_block_list = {"上", "右", "下", "左"},   -- toolbox 工具栏块列表
        toolbox_number_block_list = {"NumberBlock2", "NumberBlock3"},   -- toolbox 工具栏数字块列表
        OnStart = function(matatalab)             -- 点击运行回调
            local code = matatalab:GetCode();
            print(code);
            -- TODO RunCode

            matatalab:GetWorkspace():ClickStateBtn(); -- 再次点击变为开始状态
        end,
        OnStop = function(matatalab)              -- 点击停止回调
            -- TODO StopCode
        end
    };

    Page.Show(params.G, params);
end

ShowMatataLabPage()

--[[
-- 代码方块执行如下代码
NPL.load(GameLogic.GetWorldDirectory() .. "MatataLab/Example.lua", true)
]]