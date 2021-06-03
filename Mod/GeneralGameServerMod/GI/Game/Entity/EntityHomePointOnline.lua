NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityHomePoint.lua");
local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityHomePoint"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityHomePointOnline"));

Entity.class_name = "EntityHomePointOnline";
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

NPL.load("(gl)script/Truck/Independent/Independent.lua");
local Independent = commonlib.gettable("Mod.Truck.Independent");
local Promise = NPL.load("script/Truck/Utility/Promise.lua")
local ResourceManager = NPL.load("script/Truck/Game/Resource/ResourceManager.lua")
NPL.load("(gl)script/Truck/Utility/IOUtility.lua");
local IOUtility = commonlib.gettable("Mod.Truck.Utility.IOUtility");
local ModuleManager = commonlib.gettable("Mod.Truck.Game.ModuleManager");
local TaskExecutor = NPL.load("(gl)script/Truck/Utility/TaskExecutor.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local SavedData = NPL.load("script/Truck/Game/Resource/SavedData.lua")
NPL.load("(gl)script/Truck/Utility/qiniuHash.lua");
local QiniuHash = commonlib.gettable("Mod.Truck.Utility.QiniuHash");
Entity.isServerEntity = true

local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local function prepareFiles(list)
    local tasks = TaskExecutor:new();
    local tipdownload = false;
	local download;
	download = function(path, pid, ext, index, sum)
        tasks:addTask(function (t)
            
            BroadcastHelper.PushLabel({id="download script", label = string.format(TL"下载脚本模块中 %s/%s", index - 1, sum or 1),max_duration = 10000, color =  "255 255 255", scaling=1, bold=true, shadow=true,});

            if path then 
                files[#files + 1] = path;
                t:done();
            else
                ResourceManager.downloadFileByPhysicalId(pid, function (path, err)
                    tipdownload = true;
                    if err then 
                        _guihelper.MessageBox("脚本模块下载失败");
                        tasks:clear();
                        return ;
                    end
                    ext = ext or "lua";
                    if ext == "pkg" then 
                        local list = commonlib.LoadTableFromFile(path);
                        for k,v in ipairs(list or {}) do
                            download(nil, v.pid, v.ext, k, #list);
                        end
                        t:done();
                    else
                        local hash = QiniuHash.hashFile(path)
                        local newpath = "temp/script/" .. hash ..".".. tostring(ext or "");
                        ParaIO.CopyFile(path, newpath, true)
                        files[#files + 1] = newpath;
                        t:done();
                    end
                end, nil, 4)
            end
		end)
	end

    files = {};
    for k,v in ipairs(list) do
        local path , id, pid, ext = v.path , v.id, v.pid, v.ext;
        if not pid and not path then
            error("invalied parameters!")
            tasks:clear();
            break;
        end
        if path then 
            files[#files + 1] = path;
        else            
            download(path, pid, ext,k, #list);
        end
    end

    tasks:execute(function ()
        if tipdownload then
            BroadcastHelper.PushLabel({id="download script", label = TL"模块下载完成", max_duration = 2000, color =  "255 255 255", scaling=1, bold=true, shadow=true,});
        end
        
        BroadcastHelper.PushLabel({id="download saveddata", label = TL"正在加载存档", max_duration = 10000, color =  "255 255 255", scaling=1, bold=true, shadow=true,});
        SavedData.load(function (err)
            if err then 
                BroadcastHelper.PushLabel({id="download saveddata", label = TL"存档加载失败", max_duration = 2000, color =  "255 255 255", scaling=1, bold=true, shadow=true,});
            else
                BroadcastHelper.PushLabel({id="download saveddata", label = TL"存档加载成功", max_duration = 2000, color =  "255 255 255", scaling=1, bold=true, shadow=true,});
            end
            Independent.prepare(files);
        end)
    end)
end

function Entity:ActivateRules()
    Entity._super.ActivateRules(self);
    
    if not self.scripted then 
        self.scripted = true;

        if not ModuleManager.checkModule("GameWorld") then 
            return 
        end

        local scripts = self:getScripts();
        if not scripts or not scripts[1] then 
            return  self;
        end
        --    _guihelper.MessageBox("has script")

        self.scripts = scripts;
        
        prepareFiles(scripts);
    end
end


function Entity:setScripts(list)
    -- for k,v in ipairs(self.scripts or {}) do
    --     if v._id then
    --         ResourceTable.remove(v._id);
    --     end
    -- end
    self.scripts = {};

    for k,v in ipairs(list) do
        local path , id, pid, ext = v.path , v.id, v.pid, v.ext;
        if not id and not path then
            error("invalied parameters!")
            break;
        end
        local res = {path = path, id = id, pid = pid, type = 3 --[[Resource.Script]], ext = ext};
        -- res._id = ResourceTable.add(res);
        self.scripts[k] = res;
    end
    self.cmd = commonlib.serialize({serverside = self.scripts, clientside = self.scriptsClientSide});

    prepareFiles(self.scripts);
    
end

function Entity:getScripts()
    return self.scripts;
end

function Entity:setClientScript(list)
    self.scriptsClientSide = list;
    self.cmd = commonlib.serialize({serverside = self.scripts, clientside = self.scriptsClientSide });
end

function Entity:getClientScript()
    return self.scriptsClientSide;
end

function Entity:init()
    Entity._super.init(self);

    local scripts = commonlib.LoadTableFromString(self.cmd) or {};
    self.scripts = scripts.serverside or {};
    -- for k,v in ipairs(self.scripts or {}) do 
    --     ResourceTable.get(v._id, function (record)
    --         v.path, v.id, v.pid, v.ext = record.path, record.id, record.pid, record.ext;
    --         v._id = record._id;
    --     end);
    -- end   

    self.scriptsClientSide = scripts.clientside or {};

    if self.x then 
        self:SetPosition(self.x, self.y, self.z);
    elseif self.bx then 
        self:SetBlockPos(self.bx, self.by, self.bz);
    end


    return self;
end


function Entity:SetBlockPos(bx, by, bz)
	if(not bx) then 
		return;
	end
	-- if(self.bx~=bx or self.by~=by or self.bz~=bz ) then
		self.bx, self.by, self.bz = bx, by, bz;
		self:UpdateBlockContainer();

		local obj = self:GetInnerObject();
		if(obj) then
			local x, y, z = BlockEngine:real(bx, by, bz);
			y = y - BlockEngine.half_blocksize +  (self.offset_y or 0);
			self.x, self.y, self.z = x, y, z;
			obj:SetPosition(x,y,z);
			obj:UpdateTileContainer();
		end
		self:valueChanged();
	-- end
end

function Entity:SetPosition(x, y, z)
	if(not x) then 
		return;
	end
	-- if(self.x~=x or self.y~=y or self.z~=z ) then
		self.x, self.y, self.z = x, y, z;

		local bx, by, bz = BlockEngine:block(x, y+0.1, z);
		if(self.bx~=bx or self.by~=by or self.bz~=bz ) then
			self.bx, self.by, self.bz = bx, by, bz;
			self:UpdateBlockContainer();
		end

		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetPosition(x,y,z);
			obj:UpdateTileContainer();
		end
		self:valueChanged();
	-- end
end


function Entity:OnClick(x, y, z, mouse_button)

end