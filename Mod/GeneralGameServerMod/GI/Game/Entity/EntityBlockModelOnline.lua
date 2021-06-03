NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockModel.lua");
local EntityBlockModel = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockModel")
local Entity = commonlib.inherit(EntityBlockModel, commonlib.gettable("Mod.Truck.Game.EntityBlockModelOnline"));
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ResourceManager = NPL.load("script/Truck/Game/Resource/ResourceManager.lua")
local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");
local ResourceSwitcher = NPL.load("script/Truck/Game/Resource/ResourceSwitcher.lua")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local UIManager = commonlib.gettable("Mod.Truck.Game.UI.UIManager");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

Entity.class_name = "EntityBlockModelOnline";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
    self.switcher = ResourceSwitcher:new();
end

function Entity:init()

    if not self.filename or not ParaIO.DoesFileExist(self.filename) then
        self.filename = self.default_file;
    end

	if(not Entity._super.init(self)) then
		return
	end

    self:Refresh();

	return self;
end

function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button=="left") then
			GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		end
	else
		if(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			local ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
			if(ctrl_pressed or self:HasRealPhysics()) then
                UIManager.createUI("ResourceSelection", UIManager.getUI("UIMain"), nil, {type = 6, resourceType = "Model", readonly = false,entity = self});
				return true;
			end
		elseif(mouse_button=="left") then
			self:OnActivated(entity);
		end
	end

	-- this is run for both client and server. 
	if(entity and entity == EntityManager.GetPlayer()) then
		local obj = self:GetInnerObject();
		if(obj) then
			-- check if the entity has mount position. If so, we will set current player to this location.  
			if(obj:HasAttachmentPoint(0)) then
				local x, y, z = obj:GetAttachmentPosition(0);
				local entityPlayer = entity;
				if(entityPlayer) then
					entityPlayer:SetPosition(x,y,z);
				end
				return true;
			end
		end
	end
	
	if(self:HasRealPhysics() or self:HasAnyRule()) then
		return true;
	end
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
	local x,y,z = self:GetBlockPos();
	return Packets.PacketUpdateEntityBlock:new():Init(x,y,z,commonlib.serialize( self.switcher.res), self:getYaw(), self:getScale());
end

-- update from packet. 
function Entity:OnUpdateFromPacket(packet_UpdateEntityBlock)
	if(packet_UpdateEntityBlock:isa(Packets.PacketUpdateEntityBlock)) then
		local resource = packet_UpdateEntityBlock.data1;
		local yaw = packet_UpdateEntityBlock.data2;
		local scaling = packet_UpdateEntityBlock.data3;
		if(resource) then
			self.switcher:setResource(commonlib.LoadTableFromString(resource) )
		end
		if(yaw) then
			self:setYaw(yaw);
		end
		if(scaling) then
			self:setScale(scaling);
		end
		self:Refresh();
	end
end


function Entity:Refresh()
	local obj = self:GetInnerObject();
	if(obj) then
        self:getResource(function (res)
            if res then 
                res:getFile(function (path, err)
                    if err  then 
                        return LOG.std(nil, "error", "EntityBlockModelOnline.init", "failed to get resource, %s ", err );
                    end
    
                    local newpath = string.format("temp/model/%s.%s", res:getHash(), res:getExtension());
                    ParaIO.CopyFile(path, newpath,false);
                    self.filename = newpath;
                    obj:SetField("assetfile", self.filename or self.default_file);
                    obj:SetField("render_tech", -1)
                end)
            else
                self:getLocalFile(function (path)
                    self.filename = path;
                    obj:SetField("assetfile", self.filename or self.default_file);
                    obj:SetField("render_tech", -1)
                end)
            end
            
        end)
	end
end

function Entity:LoadFromXMLNode(node)
    Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr) then
        if(attr.resource) then
            self.switcher:setResource(commonlib.LoadTableFromString(attr.resource));
		end
		if(attr.scale) then
			self:setScale(tonumber(attr.scale));
		end
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
    node.attr.resource = commonlib.serialize(self.switcher.res);
	if(self:getScale()~= 1) then
		node.attr.scale = self:getScale();
	end
	return node;
end



function Entity:Destroy()
    Entity._super.Destroy(self);
    self:DestroyInnerObject();
end

function Entity:getResource(callback)
    return self.switcher:getResource(callback);
end

function Entity:getLocalFile(callback)
    return self.switcher:getLocalFile(callback);
end

function Entity:setLocalResource(path, type)
    self.switcher:setLocalResource(path, type)
    self:EndEdit();
end

function Entity:setRemoteResource(res)
    self.switcher:setRemoteResource(res)
    self:EndEdit();
end

function Entity:EndEdit()
    Entity._super.EndEdit(self);
    self:Refresh()
	self:MarkForUpdate();
end