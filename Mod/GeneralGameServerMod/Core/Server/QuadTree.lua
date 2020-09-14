--[[
Title: QuadTree
Author(s): wxa
Date: 2020/6/10
Desc: 四叉树实现类
use the lib: 
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Server/QuadTree.lua");
local QuadTree = commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.QuadTree");
-------------------------------------------------------
]]

local QuadTree = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.Core.Server.QuadTree"));
local QuadTreeNode = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

local QuadTreeNodeNid = 0;

local function GetObjectKey(object)
    return type(object) .. "-" .. tostring(object);
end

function QuadTreeNode:ctor()
    self.childNodes = nil;
    self.objects = {};       -- 区间对象集
    self.objectCount = 0;    -- 对象数
end

function QuadTreeNode:Init(left, top, right, bottom)
    self.left, self.top, self.right, self.bottom = left, top, right, bottom;
    return self;
end

function QuadTreeNode:IsSubArea(left, top, right, bottom)
    if (left < self.left or right > self.right or top < self.top or bottom > self.bottom) then return false end
    return true;
end

function QuadTreeNode:GetSubArea(left, top, right, bottom)
    left = left < self.left and self.left or left;
    top = top < self.top and self.top or top;
    right = right > self.right and self.right or right;
    bottom = bottom > self.bottom and self.bottom or bottom;
    return left, top, right, bottom, right >= left and bottom >= top;
end

function QuadTreeNode:Split(isSplitWidth, isSplitHeight)
    if (self.childNodes) then return end
    local left, top, right, bottom = self.left, self.top, self.right, self.bottom;
    local width, height = right - left, bottom - top;
    local centerX = left + math.floor(width / 2);
    local centerY = top + math.floor(height / 2);

    self.childNodes = {};
    if (isSplitWidth) then
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, top, centerX, centerY));   -- 左上角
        table.insert(self.childNodes, QuadTreeNode:new():Init(centerX, top, right, centerY));  -- 右上角
    end

    if (isSplitHeight) then
        table.insert(self.childNodes, QuadTreeNode:new():Init(left, centerY, centerX, bottom));    -- 左下角
        table.insert(self.childNodes, QuadTreeNode:new():Init(centerX, centerY, right, bottom));   -- 右下角
    end
end

function QuadTreeNode:GetChildNodes()
    return self.childNodes;
end

function QuadTreeNode:GetObjects()
    return self.objects;
end

function QuadTreeNode:IsSplit()
    return self.childNodes and true or false;
end

function QuadTreeNode:AddObject(object)
    local key = GetObjectKey(object);
    if (self.objects[key] ~= nil) then return end

    self.objectCount = self.objectCount + 1;
    self.objects[key] = object;
end

function QuadTreeNode:RemoveObject(object)
    local key = GetObjectKey(object);
    if (not self.objects[key]) then return end

    self.objectCount = self.objectCount - 1;
    self.objects[key] = nil;
end

function QuadTreeNode:GetObjectCount()
    return self.objectCount;
end

function QuadTreeNode:GetWidthHeight()
    return self.right - self.left, self.bottom - self.top;
end


function QuadTree:ctor()

end

function QuadTree:Init(opts)
    self.objects = {};
    self.objectCount = 0;
    self.minWidth = opts.minWidth or 0;
    self.minHeight = opts.minHeight or 0;
    self.splitThreshold = opts.splitThreshold or 20;   -- 当对象数小于此值不进分割区域
    self.root = QuadTreeNode:new():Init(opts.left, opts.top, opts.right, opts.bottom);
    return self;
end

function QuadTree:AddObject(object, left, top, right, bottom)
    local minWidth, minHeight, splitThreshold = self.minWidth, self.minHeight, self.splitThreshold;
    
    -- 添加前先移除旧对象
    self:RemoveObject(object);

    -- 添加新对象
    local function AddObjectToNode(node, object, left, top, right, bottom)
        local key = GetObjectKey(object);
        self.objects[key] = {node = node, left = left, right = right, top = top, bottom = bottom};
        self.objectCount = self.objectCount + 1;
        node:AddObject(object);
        -- echo({"------------------AddObjectToNode", object, node.left, node.top, node.right, node.bottom, node:GetObjects()});
        return node;
    end

    local function AddObject(node, object, left, top, right, bottom)
        -- echo({"------------------IsSubArea", object, node.left, node.top, node.right, node.bottom, node:IsSubArea(left, top, right, bottom), left, top, right, bottom});

        local width, height = right - left, bottom - top;
        local nodeWidth, nodeHeight = node:GetWidthHeight();
        local childNodeWidth, childNodeHeight = math.floor(nodeWidth / 2), math.floor(nodeHeight / 2);
        local splitThreshold, objectCount = self.splitThreshold, node:GetObjectCount();
        
        -- 不在当前节点区域内 直接返回
        if (not node:IsSubArea(left, top, right, bottom)) then return end

        -- 添加区域大于子区域, 子区域小于最小区域
        if ((childNodeWidth <= width and childNodeHeight <= height) or (childNodeWidth <= minWidth and childNodeHeight <= minHeight)) then
            return AddObjectToNode(node, object, left, top, right, bottom);
        end

        if (not node:IsSplit()) then
            -- 未分割,且节点对象小于阈值直接添加
            if (objectCount < splitThreshold) then
                return AddObjectToNode(node, object, left, top, right, bottom);
            end

            -- 已超过分割阈值 进行分割
            node:Split(childNodeWidth > minWidth, childNodeHeight > minHeight);  -- 子节点宽高大于最小宽高时才执行分割
            -- 分割完, 节点对象需进行重新分配
            local objects = node:GetObjects();
            for key, val in pairs(objects) do
                local ov = self.objects[key];
                node:RemoveObject(val);
                AddObject(node, val, ov.left, ov.top, ov.right, ov.bottom);
            end
        end

        -- 是否分割
        local childNodes = node:GetChildNodes();
        for i = 1, #childNodes do
            local childNode = childNodes[i];
            if (childNode:IsSubArea(left, top, right, bottom)) then
                return AddObject(childNode, object, left, top, right, bottom);
            end
        end

        -- 没有添加到子区域则添加到当前区域
        AddObjectToNode(node, object, left, top, right, bottom);
    end

    return AddObject(self.root, object, left, top, right, bottom);
end

function QuadTree:RemoveObject(object)
    local key = GetObjectKey(object);
    local value = self.objects[key];
    if (not value) then return end
    value.node:RemoveObject(object);
    self.objects[key] = nil;
    self.objectCount = self.objectCount - 1;
end

function QuadTree:GetObjects(left, top, right, bottom)
    if (not left or not top or not right or not bottom) then
        return self.objects;
    end
    
    local function GetObjects(node, left, top, right, bottom)
        left, top, right, bottom, isValidArea = node:GetSubArea(left, top, right, bottom);
        -- echo({"--------------------isValidArea", left, top, right, bottom, isValidArea, node.left, node.top, node.right, node.bottom, node:GetObjects()});
        local objects = {};
        -- 交集区域无效 直接返回
        if (not isValidArea) then return objects end;

        local nodeObjects = node:GetObjects();   -- 当前节点存的在对象都不在子区域内, 对象占多个子区域, 所以需加入遍历列表
        for key, val in pairs(nodeObjects) do
            objects[key] = val;
        end
        
        if (not node:IsSplit()) then return objects end

        -- 已分割查找子区域
        local childNodes = node:GetChildNodes();
        for i = 1, #childNodes do
            local childNode = childNodes[i];
            local subobjects = GetObjects(childNode, left, top, right, bottom);
            for key, val in pairs(subobjects) do
                objects[key] = val;
            end
        end
        return objects;
    end

    local list = {}
    local objects = GetObjects(self.root, left, top, right, bottom);
    for key, object in pairs(objects) do
        local o = self.objects[key];
        local l, t, r, b = o.left, o.top, o.right, o.bottom;
        -- 所选区域完全包含对象才算
        if (l >= left and r <= right and t >= top and b <= bottom) then
            table.insert(list, object);
        end
    end
    return list;
end

function QuadTree:GetObjectCount()
    return self.objectCount;
end

-- 测试代码
function QuadTree.Test()
    local quadtree = QuadTree:new():Init({splitThreshold = 2, left = 0, top = 0, right = 100, bottom = 100});
    quadtree:AddObject(1, 10, 10, 10, 10);
    quadtree:AddObject(2, 60, 10, 60, 10);
    quadtree:AddObject(3, 10, 60, 10, 60);
    quadtree:AddObject(4, 60, 60, 60, 60);

    echo(quadtree:GetObjects(10, 10, 10, 60));
    quadtree:RemoveObject(1);
    echo(quadtree:GetObjects(10, 10, 10, 60));
end

