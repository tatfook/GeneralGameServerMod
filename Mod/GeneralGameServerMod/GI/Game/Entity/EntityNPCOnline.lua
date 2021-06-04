

local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");

local Entity = commonlib.inherit(EntityNPC, commonlib.gettable("Mod.Truck.Game.EntityNPCOnline"));

local ResourceManager = NPL.load("script/Truck/Game/Resource/ResourceManager.lua")
local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");
local ResourceSwitcher = NPL.load("script/Truck/Game/Resource/ResourceSwitcher.lua")
local UIManager = commonlib.gettable("Mod.Truck.Game.UI.UIManager");
NPL.load("(gl)script/Truck/Utility/FZip.lua");
local FZip = commonlib.gettable("Mod.Truck.Utility.FZip");
local FileCaches = NPL.load("script/Truck/Utility/FileCaches.lua")
NPL.load("(gl)script/Truck/Utility/qiniuHash.lua");
local QiniuHash = commonlib.gettable("Mod.Truck.Utility.QiniuHash");

Entity.class_name = "EntityNPCOnline";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:ctor()
    self.switcher = ResourceSwitcher:new();
    self.dataFieldModelRes = self.dataWatcher:AddField(nil, nil);
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

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
    -- TODO: move this to a separate file to handle editors for all kinds of object. 
    if(self:IsServerEntity() and self:IsRemote()) then
        LOG.std(nil, "info", "Entity:OpenEditor", "access denied, entity is only editable on server");
        return;
    end
    if(editor_name == "entity") then
        NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
        local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
        EditEntityPage.ShowPage(self, entity);
    elseif(editor_name == "property") then
        UIManager.createUI("ResourceSelection", UIManager.getUI("UIMain"), nil, {type = 6, resourceType = "Model", readonly = false,entity = self});

    end
end


function Entity:SyncDataWatcher()
	if(self:IsRemote()) then
		-- on client: update entity's value according to watched data received from server.
		local dataWatcher = self:GetDataWatcher();
		local obj = self:GetInnerObject();
		if(not obj) then
			return;
		end
		
        local curAsset = dataWatcher:GetField(self.dataFieldAsset);
        if(curAsset and self.switcher.res ~= curAsset) then
            self.switcher:setResource(curAsset);
            self:Refresh();
        end
		local curAnimId = dataWatcher:GetField(self.dataFieldAnim);
		if(obj:GetField("AnimID", 0) ~= curAnimId and curAnimId) then
			obj:SetField("AnimID", curAnimId);
		end
		local curScale = dataWatcher:GetField(self.dataFieldScale);
		if(obj:GetScale() ~= curScale and curScale) then
			obj:SetScale(curScale);
		end
		local curSkinId = dataWatcher:GetField(self.dataFieldSkin);
		if(self:GetSkin() ~= curSkinId and curSkinId) then
			self:SetSkin(curSkinId, true);
        end
        
        local curModelRes = dataWatcher:GetField(self.dataFieldModelRes);
        if (not curModelRes ~= not self.modelFromRes) or (curModelRes and curModelRes.pid ~= self.modelFromRes.pid) then
            self.modelFromRes = curModelRes;
            self:Refresh();
        end
	elseif(GameLogic.isServer) then
		-- on server: update watched data according to current entity's value
		local dataWatcher = self:GetDataWatcher();
		local obj = self:GetInnerObject();
		if(not obj) then
			return;
		end
        local watchedAsset = dataWatcher:GetField(self.dataFieldAsset);
		if(watchedAsset ~= self.switcher.res) then
			dataWatcher:SetField(self.dataFieldAsset, self.switcher.res);
		end
		local watchedAnimId = dataWatcher:GetField(self.dataFieldAnim);
		local curAnimId = obj:GetField("AnimID", curAnimId);
		if(watchedAnimId ~= curAnimId) then
			dataWatcher:SetField(self.dataFieldAnim, curAnimId);
		end
		local watchedScale = dataWatcher:GetField(self.dataFieldScale);
		local curScale = obj:GetScale();
		if(watchedScale ~= curScale) then
			dataWatcher:SetField(self.dataFieldScale, curScale);
		end
		local watchedSkin = dataWatcher:GetField(self.dataFieldSkin);
		local curSkin = self:GetSkin();
		if(watchedSkin ~= curSkin and curSkin) then
			dataWatcher:SetField(self.dataFieldSkin, curSkin);
        end
        
        local watchedModelRes = dataWatcher:GetField(self.dataFieldModelRes);
        if( not watchedModelRes ~= not self.modelFromRes) or (watchedModelRes and watchedModelRes.pid ~= self.modelFromRes.pid) then
            dataWatcher:SetField(self.dataFieldModelRes,self.modelFromRes);
        end
	end
end

function Entity:convertToModel(path, name,ext)
    local obj = self:GetInnerObject();
    if not obj then 
        return 
    end
    local newpath = "";
    if ext == "zip"  then 
        ParaIO.CreateDirectory(string.format("temp/model/%s", name));
        newpath = string.format("temp/model/%s/model.zip", name);
        ParaIO.CopyFile(path, newpath, true)
        FZip.UnZipFile(newpath);

        local ret = {};
        commonlib.Files.SearchFiles(ret,string.format("temp/model/%s", name),"*.fbx",0,1,true);
        if not ret[1] then return end

        newpath = string.format("temp/model/%s", name) .. ret[1];

    else
        newpath = string.format("temp/model/%s.%s",name, ext);
        ParaIO.CopyFile(path, newpath,false);
    end

    self.filename = newpath;
    --obj:SetField("assetfile", self.filename or self.default_file);
    --obj:SetField("render_tech", -1)
    self._super.SetMainAssetPath(self,self.filename or self.default_file)
end

function Entity:Refresh()
	local obj = self:GetInnerObject();
    if(obj) then
        if self.modelFromRes and self.modelFromRes.pid then 
            local res = self.modelFromRes;
            if res.hash then 
                local cachepath = FileCaches.getFile(res.hash);
                if cachepath then 
                    self:convertToModel(cachepath, res.hash, res.ext or "fbx");
                    return 
                end
            end
            ResourceManager.downloadFileByPhysicalId(res.pid, function (path)
                local hash = res.hash or QiniuHash.hashFile(path);
                self:convertToModel(path,hash, res.ext or "fbx");
            end, res.hash)
        else
            self:getResource(function (res)
                if res then 
                    res:getFile(function (path, err)
                        if err  then 
                            return LOG.std(nil, "error", "EntityNPCOnline.init", "failed to get resource, %s ", err );
                        end
                        self:convertToModel(path, res:getHash(), res:getExtension());
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
end

function Entity:LoadFromXMLNode(node)
    Entity._super.LoadFromXMLNode(self, node);
	local attr = node.attr;
	if(attr) then
        if(attr.resource) then
            self.switcher:setResource( commonlib.LoadTableFromString( attr.resource ));
		end
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
    node.attr.resource = commonlib.serialize( self.switcher.res);
	return node;
end

function Entity:SetModelFile()
    error("api is forbidden in entitynpconline")
end

function Entity:SetMainAssetPath()
    error("api is forbidden in entitynpconline")
end

function Entity:setModelFromResource(tbl)
    if not tbl then 
        self.modelFromRes = nil
    elseif tbl.pid or (tbl.getPhysicalId and tbl:getPhysicalId()) then 
        tbl.pid = tbl.pid or tbl:getPhysicalId()
        self.modelFromRes = { pid = tbl.pid, ext = tbl.ext, hash = tbl.hash};
    else
        error("setModelFromResource need parameter which has member 'pid'.")
    end
    self:EndEdit();
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

function Entity:setResource(res)
    self.switcher:setResource(res)
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


function Entity:FrameMove(deltaTime)
	if(GameLogic.isRemote) then
		Entity._super.FrameMove(self, deltaTime);
	else
        if(not self:HasFocus()) then
            Entity._super.FrameMove(self, deltaTime);
		else
			self:UpdatePosition();
			EntityManager.EntityMob.FrameMove(self, deltaTime);
		end	
	end
end

function Entity:FrameMove(deltaTime)
    self:SyncDataWatcher();
	if(GameLogic.isRemote and not self:HasFocus()) then
		if (self.smoothFrames > 0) then
            local x = self.targetX - self.x
			local y = self.targetY - self.y;
			local z = self.targetZ - self.z;
			if(math.abs(x) < 20 and math.abs(y) < 20 and math.abs(z) < 20) then
				x = self.x + x / self.smoothFrames;
				y = self.y + y / self.smoothFrames;
				z = self.z + z / self.smoothFrames;
			else
				x = self.targetX;
				y = self.targetY;
				z = self.targetZ;
			end
			local lastFacing = self:GetFacing();
			local deltaFacing = mathlib.ToStandardAngle(self.targetFacing - lastFacing);
			local facing = lastFacing + deltaFacing / self.smoothFrames;
			local lastRotPitch = self.rotationPitch or 0;
			local rotationPitch = lastRotPitch + (self.targetPitch - lastRotPitch) / self.smoothFrames;
			self.smoothFrames = self.smoothFrames - 1;

			self:SetPosition(x, y, z);
			self:SetRotation(facing, lastRotPitch);
		else
			if(self.lastFrameMoveInterval) then
				self:SetFrameMoveInterval(self.lastFrameMoveInterval);
			end
        end
	else
		local mob = self:UpdatePosition();
		if(not mob) then
			return;
		end
		-- if(not mob:IsSentient()) then
		-- 	-- only update non-critical data here. since object is far from the player. 
		-- 	return;
		-- end
		if(self:HasFocus() and not self:HasMotion()) then
			self.moveForward = 0;
		else
			-- only move physically and autonomously when not focused. 
			if(not self:IsDummy()) then
				self:MoveEntity(deltaTime);
			end
        end
        

        if(not self:IsPaused()) then
            self:FrameMoveRules(deltaTime);
            self:AdvanceTime(deltaTime);
        end
		-- .FrameMove(self, deltaTime);	
	end
end