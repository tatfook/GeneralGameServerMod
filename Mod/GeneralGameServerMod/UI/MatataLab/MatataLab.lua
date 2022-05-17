

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


function MatataLab:ctor()
    self.__block_option_map__ = {};
end

function MatataLab:Init(xmlnode, window, parent)
    MatataLab._super.Init(self, xmlnode, window, parent);

    opt = opt or {};

    local block_option_list = opt.block_option_list or { {type = "上"}, {type = "下"}, {type = "左"}, {type = "右"}, {type = "NumberBlock1", number = 1, isNumberBlock = true}, {type = "NumberBlock2", number = 2, isNumberBlock = true} };
    local toolbox_block_list = opt.toolbox_block_list or {"上", "右", "下", "左"};
    local toolbox_number_block_list = opt.toolbox_number_block_list or {"NumberBlock1", "NumberBlock2"};

    self:SetBlockWidth(opt.block_width or 80);
    self:SetBlockHeight(opt.block_height or 80);
    self:SetNumberBlockWidth(self:GetBlockWidth());
    self:SetNumberBlockHeight(math.floor(self:GetBlockHeight() / 4));
    
    for _, block_option in ipairs(block_option_list) do
        self.__block_option_map__[block_option.type] = block_option;
    end

    local workspace = Workspace:new():Init(self, opt.workspace);
    local toolbox = ToolBox:new():Init(self, opt.toolbox);

    toolbox:SetXY(self:GetBlockWidth(), 4 * self:GetBlockHeight());
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
