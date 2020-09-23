--[[
Title: ScrollBar
Author(s): wxa
Date: 2020/8/14
Desc: 滚动条
-------------------------------------------------------
local ScrollBar = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Controls/ScrollBar.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local defaultScrollBarSize = "10px";

local ScrollBarButton = commonlib.inherit(Element, {});
function ScrollBarButton:ctor()
    self:SetName("ScrollBarButton");
end
function ScrollBarButton:Init(xmlNode, window)
    ScrollBarButton._super.Init(self, xmlNode, window);
    local ScrollBarDirection = self:GetAttrValue("ScrollBarDirection");
    local BaseStyle = {
        ["position"] = "absolute",
        ["width"] = ScrollBarDirection == "horizontal" and defaultScrollBarSize or "100%",
        ["height"] = ScrollBarDirection == "horizontal" and "100%" or defaultScrollBarSize,
    }

    if (self:GetTagName() == "ScrollBarPrevButton") then
        NormalStyle["left"] = "0px";
        NormalStyle["top"] = "0px";
    else
        NormalStyle["right"] = "0px";
        NormalStyle["bottom"] = "0px";
    end

    self:SetBaseStyle(BaseStyle);
end

local ScrollBarThumb = commonlib.inherit(Element, {});
function ScrollBarThumb:ctor()
    self:SetName("ScrollBarThumb");
end

local ScrollBarTrack = commonlib.inherit(Element, {});
function ScrollBarTrack:ctor()
    self:SetName("ScrollBarTrack");
end

local ScrollBar = commonlib.inherit(Element, NPL.export());
ScrollBar:Property("Value");  
ScrollBar:Property("Direction");  -- 方向                               

function ScrollBar:ctor()
    self:SetName("ScrollBar");
end

function ScrollBar:Init(xmlNode, window)
    ScrollBar._super.Init(self, xmlNode, window);

    self:SetDirection(self:GetAttrValue("direction") or "horizontal"); -- horizontal  vertical
    local isHorizontal = self:GetDirection() == "horizontal";

    if (isHorizontal) then
        self:SetBaseStyle({
            NormalStyle = {
                ["position"] = "relative",
                ["height"] = defaultScrollBarSize,
                ["width"] = "100%",
            }
        });
    else 
        self:SetBaseStyle({
            NormalStyle = {
                ["position"] = "relative",
                ["width"] = defaultScrollBarSize,
                ["height"] = "100%",
            }
        });
    end

    self.prevButton = ScrollBarButton:new():Init({name = "ScrollBarPrevButton", attr = {ScrollBarDirection = self:GetDirection()}}, window);
    self.track = ScrollBarTrack:new():Init({name = "ScrollBarTrack"}, window);
    self.thumb = ScrollBarThumb:new():Init({name = "ScrollBarThumb"}, window);
    self.nextButton = ScrollBarButton:new():Init({name = "ScrollBarNextButton", attr = {ScrollBarDirection = self:GetDirection()}}, window);
    -- self.trackPiece = Element:new():Init({name = "ScrollBarTrackPiece"}, window);
    -- self.corner = Element:new():Init({name = "ScrollBarTrackCorner"}, window);
    -- self.resizer = Element:new():Init({name = "ScrollBarTrackResizer"}, window);
    table.insert(self.childrens, self.prevButton);
    self.prevButton:SetParentElement(self);
    table.insert(self.childrens, self.track);
    self.track:SetParentElement(self);
    table.insert(self.childrens, self.thumb);
    self.thumb:SetParentElement(self);
    table.insert(self.childrens, self.nextButton);
    self.nextButton:SetParentElement(self);
end

