NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
NPL.load("(gl)script/Truck/Utility/MessageSource.lua");
local MessageSourceContainer=commonlib.gettable("Mod.Truck.Utility.MessageSourceContainer");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob"), NPL.export());
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/PhysicsWorld.lua");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local vector3d = commonlib.gettable("mathlib.vector3d");


-- whether this entity can be synchronized on the network by EntityTrackerEntry. 
Entity.isServerEntity = false;
-- class name
Entity.class_name = "EntityCustom";
Entity.entityCollisionReduction = 1.0;
Entity.mNextName=1;
Entity.EMessage={OnClick=1}
-- register class
EntityManager.RegisterEntityClass(Entity.class_name, Entity);

function Entity:init()
  self.mMessageSourceContainer=MessageSourceContainer:new();
  self.name=Entity.class_name..tostring(Entity.mNextName);
  Entity.mNextName=Entity.mNextName+1;
  local x, y, z = self:GetPosition();
  local model = ParaScene.CreateObject("BMaxObject",self.name, x,y,z);
model:SetField("assetfile", self.mModel);
  if self.mReplaceTextures then
    local temp=self.mReplaceTextures;
    repeat
      local split_begin=string.find(temp,':');
      local split_end=string.find(temp,';');
      if not split_end then
        break;
      end
      local tex_index=string.sub(temp,1,split_begin-1);
      tex_index=tonumber(tex_index);
      local tex_name=string.sub(temp,split_begin+1,split_end-1);
      model:SetReplaceableTexture(tex_index,ParaAsset.LoadTexture("", tex_name, 1));
      temp=string.sub(temp,split_end+1);
    until true
  end
  if(self.scale) then
    model:SetScaling(self.scale);
  end
  if(self.facing) then
    model:SetFacing(self.facing);
  end
  -- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
  model:SetAttribute(0x80, true);
  model:SetField("RenderDistance", 100);
  model:SetField("EnablePhysics", self.mEnablePhysics or false);
  self:SetInnerObject(model);
  ParaScene.Attach(model);
  self:UpdateBlockContainer();
  self:EnablePhysics(self.mEnablePhysics or false,true)
  self.entity_id=nil
  EntityManager.AddObject(self);
  return self;
end

function Entity:OnClick(x, y, z, mouse_button)
  mouse_button=mouse_button or "left";
  self.mMessageSourceContainer:getMessageSource():notify(Entity.EMessage.OnClick,x,y,z,mouse_button);
  return true;
end

function Entity:SetBlockPos(x,y,z)
  Entity._super.SetBlockPos(self,x,y,z)
  self:EnablePhysics(false,true);
  self:EnablePhysics(self.mEnablePhysics or false,true);
end

function Entity:SetPosition(x,y,z)
  Entity._super.SetPosition(self,x,y,z)
  self:EnablePhysics(false,true);
  self:EnablePhysics(self.mEnablePhysics or false,true);
end

function Entity:CheckCollision(vel)
    local e = 0.01
    local aabb = self:GetCollisionAABB();
    local ext = aabb:clone()
    local min = ext:GetMin();
    local max = ext:GetMax();
    ext:Extend(min[1] + vel[1], min[2] + vel[2], min[3] + vel[3])
    ext:Extend(max[1] + vel[1], max[2] + vel[2], max[3] + vel[3])

    local listCollisions = PhysicsWorld:GetCollidingBoundingBoxes(ext, self);
  
    local facing = self:GetFacing();
    local dx, dy,  dz;
    dx = vel[1];
    dy = vel[2];
    dz = vel[3];
    local offsetX, offsetY, offsetZ = dx,dy, dz;

    for i= 1, listCollisions:size() do
      offsetY = listCollisions:get(i):CalculateYOffset(aabb, offsetY, e);
    end

    for i= 1, listCollisions:size() do
      offsetX = listCollisions:get(i):CalculateXOffset(aabb, offsetX, e);
    end
    for i= 1, listCollisions:size() do
      offsetZ = listCollisions:get(i):CalculateZOffset(aabb, offsetZ, e);
    end

    -- if offsetY ~= dy then 
    --   offsetX = dx;
    --   offsetZ = dz;
    -- elseif offsetX ~= dx then
    --   offsetY = dy;
    --   offsetZ = dz;
    -- elseif offsetZ ~= dz then 
    --   offsetX = dx;
    --   offsetY = dy;
    -- end




    return offsetX, offsetY, offsetZ
    -- local newFacing = Direction.GetFacingFromOffset(dx, 0, dz);
    -- self:SetFacing(newFacing);
end

function Entity:setCenterOffset(x,y,z)
  self.centerOffset = {x,y,z}
end

function Entity:GetCollisionAABB()
  self.centerOffset = self.centerOffset or {0,0,0};
	if(self.aabb) then
    local x, y, z = self:GetPosition();
    y = y + self.centerOffset[2];
    self.aabb:SetBottomPosition(x, y, z);
    
	else
		self.aabb = ShapeAABB:new();
		local x, y, z = self:GetPosition();
		local radius = self:GetPhysicsRadius();
		local half_height = self:GetPhysicsHeight() * 0.5;
		self.aabb:SetCenterExtend(vector3d:new({x,y + half_height + self.centerOffset[2],z}), vector3d:new({radius,half_height,radius}));
	end
	return self.aabb;
end
