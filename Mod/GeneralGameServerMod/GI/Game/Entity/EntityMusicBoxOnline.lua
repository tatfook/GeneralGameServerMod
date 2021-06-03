
--[[
    NPL.load("script/Truck/Game/Entity/EntityMusicBoxOnline.lua")
    local EntityMusicBoxOnline = commonlib.gettable("Mod.Truck.Game.EntityMusicBoxOnline")
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMusicBox.lua");
local EntityMusicBox = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMusicBox")
local ResourceSwitcher = NPL.load("script/Truck/Game/Resource/ResourceSwitcher.lua")
local Entity = commonlib.inherit(EntityMusicBox, commonlib.gettable("Mod.Truck.Game.EntityMusicBoxOnline"));
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
NPL.load("(gl)script/Truck/Utility/IOUtility.lua");
local IOUtility = commonlib.gettable("Mod.Truck.Utility.IOUtility");
local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");

Entity.class_name = "EntityMusicBoxOnline";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
    self.switcher = ResourceSwitcher:new();
end


function Entity:OnClick(x, y, z, mouse_button)
    if(mouse_button=="right" and not ModuleManager.checkModule("MultiPlayerMiniGame")) then
        local UIManager= commonlib.gettable("Mod.Truck.Game.UI.UIManager");
        local uimain = UIManager.getUI("UIMain");
        local ui = UIManager.getUI("ResourceSelection");
        
        if ui then 
            return
        end

        ui = UIManager.createUI("ResourceSelection", uimain, nil, {entity = self,type = 5, resourceType = "Audio", readonly = GameLogic.isRemote});
        
	end
	return true;
end


function Entity:ToggleMusic()
    if self.path then 
        self.isPlaying = BackgroundMusic:ToggleMusic(self.path);
    else
        local res = commonlib.LoadTableFromString(self.cmd);
        self.switcher:setResource(res);
    
        self:getResource(function (res)
            if res then 
                res:getFile(function (path)
                    local filename = IOUtility.StripFilename(path) or path;
                    local newpath = string.format("temp/audio/%s.%s", filename, res:getExtension());
                    if not ParaIO.DoesFileExist(newpath) then
                        ParaIO.CopyFile(path, newpath, true);
                    end
                    self.path = newpath;
                    self.isPlaying = BackgroundMusic:ToggleMusic(newpath);
                end)
            else
                
                self:getLocalFile(function (path)
                    self.path = path;
                    self.isPlaying = BackgroundMusic:ToggleMusic(path);
                end)
            end
        end)


        local index = tonumber(self.cmd)
        if not index then 
            Entity._super.ToggleMusic(self);
            return;
        end
    end
end


function Entity:Destroy()
    Entity._super.Destroy(self);
    
    if self.cmd then 
        BackgroundMusic:Stop(self.path or "");
    end
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
