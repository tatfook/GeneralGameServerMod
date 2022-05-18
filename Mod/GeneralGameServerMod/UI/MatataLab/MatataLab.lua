

local Element = NPL.load("Mod/GeneralGameServerMod/UI/Window/Element.lua");
local ElementManager = NPL.load("Mod/GeneralGameServerMod/UI/Window/ElementManager.lua");

local MatataLab = commonlib.inherit(Element, NPL.export());

ElementManager:RegisterByTagName("MatataLab", MatataLab);


local Block = NPL.load("./Block.lua", IsDevEnv);
local NumberBlock = NPL.load("./NumberBlock.lua", IsDevEnv);
local ToolBox = NPL.load("./ToolBox.lua", IsDevEnv);
local Workspace = NPL.load("./Workspace.lua", IsDevEnv);

MatataLab:Property("BlockWidth"); 
MatataLab:Property("BlockHeight");
MatataLab:Property("NumberBlockWidth");
MatataLab:Property("NumberBlockHeight");
MatataLab:Property("DraggingBlock");
MatataLab:Property("ToolBox");
MatataLab:Property("Workspace");
MatataLab:Property("MouseCaptureUI");           -- 捕获鼠标UI
MatataLab:Property("IconPathPrefix", "Texture/Aries/Creator/keepwork/ggs/matatalab/");
local DEFAULT_BLOCK_WIDTH = 80;
local DEFAULT_BLOCK_HEIGHT = 56;
local DEFAULT_NUMBER_BLOCK_WIDTH = DEFAULT_BLOCK_WIDTH;
local DEFAULT_NUMBER_BLOCK_HEIGHT = 34;
local DEFAULT_ROW_COUNT = 5;
local DEFAULT_COL_COUNT = 5;

function MatataLab:ctor()
    self.__block_option_map__ = {};
end

function MatataLab:Init(xmlnode, window, parent)
    MatataLab._super.Init(self, xmlnode, window, parent);

    opt = opt or {};

    local block_option_list = opt.block_option_list or {
        {
            type = "上",
            icon = self:GetIconPathPrefix() .. "shang_68x50_32bits.png#0 0 68 50",
        }, 
        {
            type = "下",
            icon = self:GetIconPathPrefix() .. "xia_68x50_32bits.png#0 0 68 50",
        }, 
        {
            type = "左",
            icon = self:GetIconPathPrefix() .. "zuo_68x50_32bits.png#0 0 68 50",
        }, 
        {
            type = "右",
            icon = self:GetIconPathPrefix() .. "you_68x50_32bits.png#0 0 68 50",
        }, 
        {
            type = "NumberBlock2", 
            number = 2, 
            isNumberBlock = true,
            icon = self:GetIconPathPrefix() .. "2_68x40_32bits.png#0 0 68 40"
        },
        {
            type = "NumberBlock3", 
            number = 3, 
            isNumberBlock = true,
            icon = self:GetIconPathPrefix() .. "3_68x40_32bits.png#0 0 68 40"
        }, 
    };
    local toolbox_block_list = opt.toolbox_block_list or {"上", "右", "下", "左"};
    local toolbox_number_block_list = opt.toolbox_number_block_list or {"NumberBlock2", "NumberBlock3"};

    self:SetBlockWidth(opt.block_width or DEFAULT_BLOCK_WIDTH);
    self:SetBlockHeight(opt.block_height or DEFAULT_BLOCK_HEIGHT);
    self:SetNumberBlockWidth(opt.number_block_width or DEFAULT_NUMBER_BLOCK_WIDTH);
    self:SetNumberBlockHeight(opt.number_block_height or DEFAULT_NUMBER_BLOCK_HEIGHT);
    
    for _, block_option in ipairs(block_option_list) do
        self.__block_option_map__[block_option.type] = block_option;
    end

    opt.workspace = opt.workspace or {};
    opt.workspace.row_count = opt.workspace.row_count or DEFAULT_ROW_COUNT;
    opt.workspace.col_count = opt.workspace.col_count or DEFAULT_ROW_COUNT;

    local workspace = Workspace:new():Init(self, opt.workspace);
    local toolbox = ToolBox:new():Init(self, opt.toolbox);

    toolbox:SetXY(120, 590);
    toolbox:SetBlockList(toolbox_block_list, toolbox_number_block_list);

    self:SetToolBox(toolbox);
    self:SetWorkspace(workspace);
    return self;
end

function MatataLab:GetBlockByType(block_type)
    local block_opt = self.__block_option_map__[block_type];
    if (not block_opt) then return nil end 
    if (block_opt.isNumberBlock) then
        return NumberBlock:new():Init(self, block_opt);
    else 
        return Block:new():Init(self, block_opt);
    end
end

function MatataLab:OnAfterUpdateLayout()
    local width, height = self:GetSize();
    self:GetWorkspace():SetXY(width - 414, 0);
    self:GetToolBox():SetXY(width - 1160, height - 130);
end

function MatataLab:OnRender(painter)
    local x, y = self:GetPosition();

    painter:Translate(x, y);

    self:GetToolBox():Render(painter);
    self:GetWorkspace():Render(painter);

    local draggingBlock = self:GetDraggingBlock();
    if (draggingBlock) then draggingBlock:Render(painter) end 

    painter:Translate(-x, -y);
end

function MatataLab:OnMouseDown(event)
    local x, y = self:GetLocalXY(event);
    local ui = self:GetMouseUI(x, y);

    self:SetMouseCaptureUI(ui);
    self:CaptureMouse();

    if (ui ~= self) then ui:OnMouseDown(event) end 
end

function MatataLab:OnMouseMove(event)
    local x, y = self:GetLocalXY(event);
    local ui = self:GetMouseUI(x, y);

    if (ui ~= self) then ui:OnMouseMove(event) end 

end

function MatataLab:GetLocalXY(event)
    return self:GetRelPoint(event.x, event.y);
end

function MatataLab:GetGloablXY(event)
    return event.x, event.y;
end

function MatataLab:OnMouseUp(event)
    local x, y = self:GetLocalXY(event);
    local ui = self:GetMouseUI(x, y);
    if (ui ~= self) then ui:OnMouseUp(event) end 

    self:SetMouseCaptureUI(nil);
    self:ReleaseMouseCapture();
end

function MatataLab:GetMouseUI(x, y)
    local ui = self:GetMouseCaptureUI();
    if (ui) then return ui end 

    ui = self:GetToolBox():GetMouseUI(x, y);
    if (ui) then return ui end 

    ui = self:GetWorkspace():GetMouseUI(x, y);
    if (ui) then return ui end 

    return self;
end

function MatataLab:GetCode()
    return self:GetWorkspace():GetCode();
end
