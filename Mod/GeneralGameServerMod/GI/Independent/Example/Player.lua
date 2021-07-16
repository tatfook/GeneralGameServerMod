local KeyBoard = require("KeyBoard");


-- local player = GetPlayer();
local player = CreatePlayer();
player:SetFocus();
-- 
-- FreeCameraMode();
DisableDefaultWASDKey();

local is_w_pressed = false;
KeyBoard:OnKeyDown("w", function()
    is_w_pressed = true;
end);

KeyBoard:OnKeyUp("w", function()
    is_w_pressed = false;
end)
SetCameraFacing(-90)
function loop()
    local dist = 0.2;
    if (is_w_pressed) then
        local facing = GetCameraFacing() / 180 * math.pi;
        local x, y, z = player:GetPosition();
        local xx = x + dist * math.cos(facing);
        local yy = y;
        local zz = z - dist * math.sin(facing);
        player:SetFacing(GetFacingFromOffset(xx - x, yy - y, zz -z ));
        player:SetPosition(xx, y, zz);
        player:GetInnerObject():SetField("AnimID", 5)
    else 
        player:GetInnerObject():SetField("AnimID", 0)
    end
end

-- SetInterval(200, function()
--     if (not x) then return end
--     print(1, x, y, z);
--     print(player:GetPosition());
--     x, y, z = nil, nil, nil;
-- end)

-- -- EnableAutoCamera(false)
-- local last_time = 0
-- local last_x, last_y, last_z =0, 0, 0;
-- local count = 0;
-- RegisterEventCallBack(EventType.KEY, function(event)
--     local keyname = event.keyname
--     local dist = 0.2;
--     if (keyname == "DIK_W") then
--         is_w_pressed = true;
--         local facing = GetCameraFacing() / 180 * math.pi;
--         x, y, z = player:GetPosition();
--         -- z = z - dist * math.sin(facing);
--         -- x = x + dist * math.cos(facing);
--         -- player:SetPosition(x, y, z);
--         -- player:SetFacing(math.pi * 3 / 2);
--         -- player:GetInnerObject():SetField("AnimID", 5)

--     end
--     if (keyname == "DIK_A") then
--         local facing = GetCameraFacing() / 180 * math.pi;
--         x, y, z = player:GetPosition();
--         z = z - dist * math.cos(facing);
--         x = x + dist * math.sin(facing);
--         -- player:SetPosition(x, y, z);
--         -- player:SetFacing(math.pi);
--         -- player:GetInnerObject():SetField("AnimID", 5)
--     end
--     if (keyname == "DIK_S") then
--         local facing = GetCameraFacing() / 180 * math.pi;
--         x, y, z = player:GetPosition();
--         z = z + dist * math.sin(facing);
--         x = x - dist * math.cos(facing);
--         -- player:SetPosition(x, y, z);
--         -- player:SetFacing(math.pi / 2);
--         -- player:GetInnerObject():SetField("AnimID", 5)
--     end
--     if (keyname == "DIK_D") then
--         local facing = GetCameraFacing() / 180 * math.pi;
--         x, y, z = player:GetPosition();
--         z = z + dist * math.cos(facing);
--         x = x - dist * math.sin(facing);
--         -- player:SetPosition(x, y, z);
--         -- player:SetFacing(0);
--         -- player:GetInnerObject():SetField("AnimID", 5)
--     end
-- end)