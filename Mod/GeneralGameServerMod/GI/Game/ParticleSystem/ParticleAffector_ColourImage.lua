NPL.load("(gl)script/Truck/Network/bit.lua");
NPL.load("./Math.lua");
local bit= NPL.load("../../Utility/bit.lua");
local ParticleAffector = NPL.load("./ParticleAffector.lua");
local System = NPL.load("./ParticleSystem.lua");
local Affector=commonlib.inherit(ParticleAffector, NPL.export());
Affector.mType="ColourImage";
function Affector:ctor()
end

function Affector:delete()
end

function Affector:_initParticle(particle)
  local pixel=self:_getPixel(0);
  particle:setColour(pixel[1],pixel[2],pixel[3],pixel[4]);
end

function Affector:_affectParticles(scene,timeElapsed)  
  local width=#self.mColourImage-1;
  
  for _,particle in pairs(scene.mActiveParticles) do
    local life_time=particle:getTotalTimeToLive();
    local particle_time=1-(particle:getTimeToLive()/life_time);
    if particle_time>1 then
      particle_time=1;
    elseif particle_time<0 then
      particle_time=0;
    end
    local float_index=particle_time*width;
    local index=math.floor(float_index);
    if index<0 then
      local pixel=self:_getPixel(0);
      particle:setColour(pixel[1],pixel[2],pixel[3],pixel[4]);
    elseif index>=width then
      local pixel=self:_getPixel(width);
      particle:setColour(pixel[1],pixel[2],pixel[3],pixel[4]);
    else
      local fract=float_index-index;
      local to_colour=fract;
      local from_colour=1-to_colour;
      local from=self:_getPixel(index,0);
      local to=self:_getPixel(index+1,0);
      particle:setColour(from[1]*from_colour+to[1]*to_colour
        ,from[2]*from_colour+to[2]*to_colour
        ,from[3]*from_colour+to[3]*to_colour
        ,from[4]*from_colour+to[4]*to_colour
        );
    end
  end
end

function Affector:setImageAdjust(imageTable)
  self.mColourImage=imageTable;
end

function Affector:_getPixel(x)
  local ret=self.mColourImage[x+1];
  echo("devilwalk","devilwalk---------------------------------debug:ParticleAffector_ColourImage.lua:Affector:_getPixel:ret:");
  echo("devilwalk",ret);
  return ret;
end

local Factory={}
function Factory.create()
  return Affector:new();
end
ParticleAffector.ColourImageFactory = Factory;
System.singleton().addAffectorFactory(Affector.mType,Factory);