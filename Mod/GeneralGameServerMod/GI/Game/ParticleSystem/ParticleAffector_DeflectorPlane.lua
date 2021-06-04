NPL.load("./Math.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="DeflectorPlane";
function Affector:ctor()
  self.mPlanePoint=vector3d:new(0,0,0);
  self.mPlaneNormal=vector3d:new(0,1,0);
  self.mBounce=1;
end

function Affector:delete()
end

function Affector:_affectParticles(scene,timeElapsed)
  local planeDistance=-self.mPlaneNormal:dot(self.mPlanePoint)/math.sqrt(self.mPlaneNormal:dot(self.mPlaneNormal));
  local directionPart;
  
  for _,particle in pairs(scene.mActiveParticles) do
    local direction=vector3d:new(particle:getDirection()*timeElapsed);
    if self.mPlaneNormal:dot(particle:getPosition()+direction)+planeDistance<=0 then
      local a=self.mPlaneNormal:dot(particle:getPosition())+planeDistance;
      if a>0 then
        directionPart=direction*(-a/direction:dot(self.mPlaneNormal));
        local pos=particle:getPosition()+directionPart+(directionPart-direction)*self.mBounce;
        particle:setPosition(pos[1],pos[2],pos[3]);
        local dir=(particle:getDirection()-2*particle:getDirection():dot(self.mPlaneNormal)*self.mPlaneNormal)*self.mBounce;
        particle:setDirection(dir[1],dir[2],dir[3]);
      end
    end
  end
end

function Affector:setPlanePoint(x,y,z)
  self.mPlanePoint[1]=x;
  self.mPlanePoint[2]=y;
  self.mPlanePoint[3]=z;
end

function Affector:setPlaneNormal(x,y,z)
  self.mPlaneNormal[1]=x;
  self.mPlaneNormal[2]=y;
  self.mPlaneNormal[3]=z;
end

function Affector:setBounce(bounce)
  self.mBounce=bounce;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.DeflectorPlaneFactory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);