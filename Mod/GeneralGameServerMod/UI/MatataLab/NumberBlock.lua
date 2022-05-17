
local NumberBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());


NumberBlock:Property("MatataLab");    -- 所有对象
NumberBlock:Property("ToolBoxBlock", false, "IsToolBoxBlock");         -- 是否是工具块
NumberBlock:Property("Block");        -- 所属块
NumberBlock:Property("Number", 1);    -- 数值
NumberBlock:Property("Type");         -- 图块类型
NumberBlock:Property("Code");         -- 图块代码
NumberBlock:Property("Icon");         -- 图标

function NumberBlock:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
end

function NumberBlock:Init(matatalab, opt)
    opt = opt or {};

    self:SetMatataLab(matatalab);
    self:SetNumber(opt.number or 1);
    self:SetType(opt.type);
    self:SetCode(opt.code);
    self:SetIcon(opt.icon);

    self.__width__ = matatalab:GetNumberBlockWidth();
    self.__height__ = matatalab:GetNumberBlockHeight();

    return self;
end

function NumberBlock:SetXY(x, y)
    self.__x__, self.__y__ = x, y;
end

function NumberBlock:GetWorkspace()
    return self:GetMatataLab():GetWorkspace();
end

function NumberBlock:Render(painter)
    local matatalab = self:GetMatataLab();
    painter:SetPen("#cccccc80");
    painter:DrawRect(self.__x__, self.__y__, self.__width__, self.__height__);
    painter:SetPen("#000000ff");
    painter:DrawText(self.__x__, self.__y__, tostring(self:GetNumber()));
end

function NumberBlock:OnMouseDown(event)
    local matatalab = self:GetMatataLab();
    local number_block = self;
    local x, y = matatalab:GetGloablXY(event);

    if (self:IsToolBoxBlock()) then 
        number_block = matatalab:GetBlockByType(self:GetType());
        number_block:SetToolBoxBlock(false);
    end 
    
    local block = number_block:GetBlock();
    if (block) then block:SetNumberBlock(nil) end 
    number_block:SetBlock(nil);

    number_block.__start_mouse_x__, number_block.__start_mouse_y__ = x, y;
    number_block.__start_x__, number_block.__start_y__ = self.__x__, self.__y__;
    number_block.__x__, number_block.__y__ = self.__x__, self.__y__;
    number_block.__is_mouse_down__ = true;

    matatalab:SetDraggingBlock(number_block);
    matatalab:SetMouseCaptureUI(number_block);
end

function NumberBlock:OnMouseMove(event)
    if (not self.__is_mouse_down__) then return end 
    local matatalab = self:GetMatataLab();
    local x, y = matatalab:GetGloablXY(event);
    self.__x__, self.__y__ = x - self.__start_mouse_x__ + self.__start_x__, y - self.__start_mouse_y__ + self.__start_y__;
end

function NumberBlock:OnMouseUp(event)
    self.__is_mouse_down__ = false;
    local matatalab = self:GetMatataLab();
    local x, y = matatalab:GetLocalXY(event);
    matatalab:SetDraggingBlock(nil);

    local block = matatalab:GetWorkspace():GetBlockByXY(x, y);
    if (not block) then return end
    block:SetNumberBlock(self);
    self:SetBlock(block);
    block:SetXY(block:GetXY());
end

-- return NumberBlock;