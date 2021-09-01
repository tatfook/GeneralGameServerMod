NPL.load("(gl)script/ide/math/vector.lua")
NPL.load("(gl)script/ide/math/vector2d.lua")
NPL.load("(gl)script/ide/math/Quaternion.lua")
local Quaternion = commonlib.gettable("mathlib.Quaternion")
local vector3d = commonlib.gettable("mathlib.vector3d")

function vector3d:perpendicular()
    local x, y, z = self[1], self[2], self[3]
    local ret
    if math.abs(x) > math.abs(z) then
        ret = vector3d:new(-y, x, 0)
    else
        ret = vector3d:new(0, -z, y)
    end
    return ret:normalize()
end

function vector3d:randomDeviant(angle, up)
    local newUp
    if up == vector3d:new(0, 0, 0) then
        newUp = self:perpendicular()
    else
        newUp = up
    end
    local q = Quaternion:new():FromAngleAxis(math.random() * 3.1415926 * 2, self)
    newUp = q:rotateVector(newUp)
    q:FromAngleAxis(angle, newUp)
    return q:rotateVector(self)
end

function Quaternion:rotateVector(v)
    local uv, uuv
    local qvec = vector3d:new(self[1], self[2], self[3])
    uv = commonlib.clone(qvec):cross(v)
    uuv = commonlib.clone(qvec):cross(uv)
    uv = uv * 2 * self[4]
    uuv = uuv * 2
    return v + uv + uuv
end
