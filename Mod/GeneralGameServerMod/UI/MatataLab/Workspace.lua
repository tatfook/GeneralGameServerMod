
local Workspace = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Workspace:Property("MatataLab");         -- 所属mata
Workspace:Property("RowCount");          -- 行数
Workspace:Property("ColCount");          -- 列数
Workspace:Property("UnitWidth");         -- 单元格宽度
Workspace:Property("UnitHeight");        -- 单元格高度

function Workspace:ctor()
    self.__x__, self.__y__, self.__width__, self.__height__ = 0, 0, 0, 0;
    self.__block_list__ = {};
end

function Workspace:Init(matatalab, opt)
    opt = opt or {};

    self:SetMatataLab(matatalab);
    self:SetRowCount(opt.row_count or 3);
    self:SetColCount(opt.col_count or 6);
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount();
    local BlockWidth = matatalab:GetBlockWidth();
    local BlockHeight = matatalab:GetBlockHeight();
    local NumberBlockWidth = matatalab:GetNumberBlockWidth();
    local NumberBlockHeight = matatalab:GetNumberBlockHeight();
    local UnitWidth = math.max(BlockWidth, NumberBlockWidth);
    local UnitHeight = BlockHeight + NumberBlockHeight;

    self:SetUnitWidth(UnitWidth);
    self:SetUnitHeight(UnitHeight);

    self.__x__, self.__y__, self.__width__, self.__height__ = opt.x or 0, opt.y or 0, ColCount * UnitWidth, RowCount * UnitHeight;
    for i = 1, RowCount do
        self.__block_list__[i] = {};
    end

    return self;
end

function Workspace:SetXY(x, y)
    self.__x__, self.__y__ = x, y;
end

function Workspace:Render(painter)
    local matatalab = self:GetMatataLab();
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount();
    local BlockWidth = matatalab:GetBlockWidth();
    local BlockHeight = matatalab:GetBlockHeight();
    local NumberBlockWidth = matatalab:GetNumberBlockWidth();
    local NumberBlockHeight = matatalab:GetNumberBlockHeight();
    local UnitWidth = math.max(BlockWidth, NumberBlockWidth);
    local UnitHeight = BlockHeight + NumberBlockHeight;

    painter:SetPen("#00000080");
    painter:DrawRect(self.__x__, self.__y__, self.__width__, self.__height__, false, true);
    local line_size = 10;
    for i = 1, RowCount - 1 do
        painter:DrawLine(self.__x__, self.__y__ + i * UnitHeight, self.__x__ + self.__width__, self.__y__ + i * UnitHeight);
    end

    for i = 1, ColCount - 1 do
        painter:DrawLine(self.__x__ + i * UnitWidth, self.__y__, self.__x__ + i * UnitWidth, self.__y__ + self.__height__);
    end

    for i = 1, RowCount do
        for j = 1, ColCount do
            local block = self.__block_list__[i][j];
            if (block) then
                block:Render(painter) 
            end 
        end
    end
end

function Workspace:XYToRowCol(x, y)
    x = x - self.__x__;
    y = y - self.__y__;
    if (x <= 0 or x > self.__width__ or y <= 0 or y > self.__height__) then return end
    local matatalab = self:GetMatataLab();
    local UnitWidth = self:GetUnitWidth();
    local UnitHeight = self:GetUnitHeight();
    local RowIndex = math.ceil(y / UnitHeight);
    local ColIndex = math.ceil(x / UnitWidth);
    return RowIndex, ColIndex;
end

function Workspace:GetBlockByXY(x, y)
    local RowIndex, ColIndex = self:XYToRowCol(x, y);
    if (not RowIndex) then return end
    return self.__block_list__[RowIndex][ColIndex];
end

function Workspace:SetBlockByXY(x, y, block)
    local RowIndex, ColIndex = self:XYToRowCol(x, y);
    if (not RowIndex) then return end
    if (block) then
        local matatalab = self:GetMatataLab();
        local UnitWidth = self:GetUnitWidth();
        local UnitHeight = self:GetUnitHeight();
        block:SetXY((ColIndex - 1) * UnitWidth + self.__x__, (RowIndex - 1) * UnitHeight + self.__y__);
    end
    local old_block = self.__block_list__[RowIndex][ColIndex];
    self.__block_list__[RowIndex][ColIndex] = block;
    return old_block;
end

function Workspace:GetMouseUI(x, y)
    if (x > (self.__x__ + self.__width__) or x < self.__x__ or y > (self.__y__ + self.__height__) or y < self.__y__) then return nil end 
    local block = self:GetBlockByXY(x, y);
    return block and block:GetMouseUI(x, y);
end

function Workspace:GetCode()
    local RowCount = self:GetRowCount();
    local ColCount = self:GetColCount(); 
    local codetext = "";

    for i = 1, RowCount do
        for j = 1, ColCount do
            local block = self.__block_list__[i][j];
            if (block) then
                codetext = codetext .. block:GetCode();
            end
        end
    end

    return codetext;
end

-- return Workspace;