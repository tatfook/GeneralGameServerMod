
--[[
    NPL.load("script/Truck/Game/Entity/EntityImageOnline.lua")
    local EntityImageOnline = commonlib.gettable("Mod.Truck.Game.EntityImageOnline")
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityImage.lua");
local EntityImage = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityImage")
local Entity = commonlib.inherit(EntityImage, commonlib.gettable("Mod.Truck.Game.EntityImageOnline"));
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ResourceTable = NPL.load("script/Truck/Game/Resource/ResourceTable.lua")
local ResourceManager = NPL.load("script/Truck/Game/Resource/ResourceManager.lua")
local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");
local ResourceSwitcher = NPL.load("script/Truck/Game/Resource/ResourceSwitcher.lua")

Entity.class_name = "EntityImageOnline";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
    self.switcher = ResourceSwitcher:new();
end

function Entity:OnClick(x, y, z, mouse_button)
    if mouse_button=="right" and not ModuleManager.checkModule("MultiPlayerMiniGame") then
        local UIManager= commonlib.gettable("Mod.Truck.Game.UI.UIManager");
        local uimain = UIManager.getUI("UIMain");
        local ui = UIManager.getUI("ResourceSelection");
        
        if ui then 
            return
        end

        ui = UIManager.createUI("ResourceSelection", uimain, nil, {entity = self,type = 1, resourceType = "Image", readonly = GameLogic.isRemote});
        
	end
	return true;
end

function Entity:GetImageFilePath()
	return self.filepath;
end


-- change the current image displayed according to current settings. 
function Entity:Refresh(bForceRefresh)
	self.bNeedUpdate = nil;
    local res = commonlib.LoadTableFromString(self.cmd);
    self.switcher:setResource(res);

    self:getResource(function(res)
        if res then
            res:getFile(function (path, error)
                if error then 
                    return 
                end
                self.filepath = path;
                Entity._super.Refresh(self,bForceRefresh);
            end)
        else
            self:getLocalFile(function (path)
                self.filepath = path;
                Entity._super.Refresh(self,bForceRefresh);
            end)
        end
    end)

end

function Entity:GetFullFilePath(filename)
	local bExist
	local old_filename = filename;
	if(filename and filename~="") then
        if(not ParaIO.DoesAssetFileExist(filename, true)) then
            filename = ParaWorld.GetWorldDirectory()..filename;
            if(ParaIO.DoesAssetFileExist(filename, true)) then
                return ParaWorld.GetWorldDirectory()..old_filename, true;
            end
        else
            bExist = true;
        end
	end
	return old_filename, bExist;
end

function Entity:Destroy()
    Entity._super.Destroy(self);
    
end

function Entity:getResource(callback)
    return self.switcher:getResource(callback);
end

function Entity:getLocalFile(callback)
    return self.switcher:getLocalFile(callback);
end

function Entity:setLocalResource(path, type)
    self.switcher:setLocalResource(path, type)
    self:SetCommand(commonlib.serialize(self.switcher.res));
    self:EndEdit()
end

function Entity:setRemoteResource(res)
    self.switcher:setRemoteResource(res)
    self:SetCommand(commonlib.serialize(self.switcher.res));
    self:EndEdit()
end
