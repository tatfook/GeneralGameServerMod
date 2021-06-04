NPL.load("./Math.lua")
local vector3d = commonlib.gettable("mathlib.vector3d")
local Particle = commonlib.inherit(nil, NPL.export())

function Particle:ctor()
    self.mOwnDimensions = false
    self.mWidth = 0
    self.mHeight = 0
    self.mRotation = 0
    self.mPosition = vector3d:new(0, 0, 0)
    self.mDirection = vector3d:new(0, 0, 0)
    self.mColour = {1, 1, 1, 1}
    self.mTimeToLive = 10
    self.mTotalTimeToLive = 10
    self.mRotationSpeed = 0
    self.mUVOffset = {0, 0}
    self.mUVScale = {1, 1}
    self.mParticleType = "Visual"
end

function Particle:delete()
end

function Particle:setParticleType(particleType)
    self.mParticleType = particleType
end

function Particle:getParticleType()
    return self.mParticleType
end

function Particle:setDimensions(width, height)
    self.mOwnDimensions = true
    self.mWidth = width
    self.mHeight = height
end

function Particle:hasOwnDimensions()
    return self.mOwnDimentsions
end

function Particle:getOwnDimensions()
    return self.mWidth, self.mHeight
end

function Particle:resetDimensions()
    self.mOwnDimentsions = false
    self.mWidth = 0
    self.mHeight = 0
end

function Particle:setPosition(x, y, z)
    self.mPosition[1] = x
    self.mPosition[2] = y
    self.mPosition[3] = z
end

function Particle:getPosition()
    return self.mPosition
end

function Particle:setRotation(radian)
    self.mRotation = radian
end

function Particle:getRotation()
    return self.mRotation
end

function Particle:setColour(r, g, b, a)
    self.mColour[1] = r
    self.mColour[2] = g
    self.mColour[3] = b
    self.mColour[4] = a
end

function Particle:getColour()
    return self.mColour
end

function Particle:setDirection(x, y, z)
    self.mDirection[1] = x
    self.mDirection[2] = y
    self.mDirection[3] = z
end

function Particle:getDirection()
    return self.mDirection
end

function Particle:setTimeToLive(time)
    self.mTimeToLive = time
end

function Particle:getTimeToLive()
    return self.mTimeToLive
end

function Particle:setTotalTimeToLive(time)
    self.mTotalTimeToLive = time
end

function Particle:getTotalTimeToLive()
    return self.mTotalTimeToLive
end

function Particle:setRotationSpeed(radian)
    self.mRotationSpeed = radian
end

function Particle:getRotationSpeed()
    return self.mRotationSpeed
end

function Particle:setUVOffset(u, v)
    self.mUVOffset = {u, v}
end

function Particle:getUVOffset()
    return self.mUVOffset
end

function Particle:setUVScale(u, v)
    self.mUVScale = {u, v}
end

function Particle:getUVScale()
    return self.mUVScale
end
