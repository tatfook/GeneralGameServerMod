
print("========entertainment==========");

entertainment = module();

entertainment.delivery_direction = 1;
entertainment.delivery_step = 0.03;
entertainment.delivery_speed = 1;
entertainment.delivery_stop = true;

function delivery_tuopan()
    local tuopan_list = {};
    local function add_tuopan_entity(bx, by, bz)
        local entities = GetEntitiesInBlock(bx, by, bz);
        if (not entities) then return end 
        for entity in pairs(entities) do
            local asset = entity:GetMainAssetPath();
            local filename = string.match(asset or "", "([^\\/]*)$");
            if (filename == "tuopan.bmax" and entity.class_name == "LiveModel") then
                entity:SetCanDrag(false);
                local x, y, z = entity:GetPosition();
                local bx, by, bz = entity:GetBlockPos();
                local facing = entity:GetFacing();
                local _x, _y, _z = ConvertToRealPosition(bx, by, bz);
                table.insert(tuopan_list, {
                    entity = entity,
                    bx = bx, by = by, bz = bz,
                    x = _x, y = _y, z = _z,
                    facing = facing,
                });
                return ;
            end
        end
    end
    local facing_map = {dx = {[1] = 180, [-1] = 0}, dz = {[1] = 90, [-1] = -90}};
    local points = {
        {19210,6,19256},
        {19222,6,19256},
        {19222,6,19273},
        {19210,6,19273},
    }

    local size = (#points) - 1;
    local pos = points[1];
    local dx, dy, dz = 0, 0, 0;

    for i = 1, size do 
        dx, dy, dz = points[i + 1][1] - points[i][1], points[i + 1][2] - points[i][2], points[i + 1][3] - points[i][3];
        local max_dist = math.max(math.abs(dx), math.max(dz));
        dx, dy, dz = dx > 0 and 1 or (dx < 0 and -1 or 0), dy > 0 and 1 or (dy < 0 and -1 or 0),  dz > 0 and 1 or (dz < 0 and -1 or 0);
        for j = 1, max_dist do
            add_tuopan_entity(pos[1], pos[2], pos[3]);
            pos[1], pos[2], pos[3] = pos[1] + dx, pos[2] + dy, pos[3] + dz;
        end
    end
    add_tuopan_entity(pos[1], pos[2], pos[3]);

    async_run(function()
        while(true) do
            if (not entertainment.delivery_stop) then
                local size = #tuopan_list;
                local total_step_count = math.floor(__BlockSize__ / entertainment.delivery_step);
                local step_count = total_step_count;
                local delivery_direction = entertainment.delivery_direction;
                local delivery_step = entertainment.delivery_step;
                local delivery_speed = entertainment.delivery_speed;
                local is_move = true;
                while (step_count > 0) do
                    local step_delivery_direction = entertainment.delivery_direction;
                    if (is_move and delivery_direction ~= step_delivery_direction) then
                        step_count = total_step_count - step_count;
                        is_move = false;
                    end
                    if (not is_move and delivery_direction == step_delivery_direction) then
                        step_count = total_step_count - step_count;
                        is_move = true;
                    end
                    local index = 1;
                    local dx, dy, dz = 0, 0, 0;
                    for i = 1, size do
                        local next_index = index + step_delivery_direction;
                        next_index = next_index > size and 1 or (next_index < 1 and size or next_index);
                        local tuopan = tuopan_list[index];
                        local next_tuopan = tuopan_list[next_index];
                        if (delivery_direction > 0 and index == size) then
                            dx, dy, dz = tuopan_list[index].bx - tuopan_list[index - 1].bx, tuopan_list[index].by - tuopan_list[index - 1].by, tuopan_list[index].bz - tuopan_list[index - 1].bz;
                        elseif (delivery_direction < 0 and index == 1) then 
                            dx, dy, dz = tuopan_list[index].bx - tuopan_list[index + 1].bx, tuopan_list[index].by - tuopan_list[index + 1].by, tuopan_list[index].bz - tuopan_list[index + 1].bz;
                        else 
                            dx, dy, dz = tuopan_list[index + delivery_direction].bx - tuopan_list[index].bx, tuopan_list[index + delivery_direction].by - tuopan_list[index].by, tuopan_list[index + delivery_direction].bz - tuopan_list[index].bz;
                        end
                        local x, y, z = tuopan.entity:GetPosition();
                        if (step_delivery_direction == delivery_direction) then
                            tuopan.entity:SetPosition(x + dx * delivery_step, y + dy * delivery_step, z + dz * delivery_step);
                        else
                            tuopan.entity:SetPosition(x - dx * delivery_step, y - dy * delivery_step, z - dz * delivery_step);
                        end
                        tuopan.entity:SetFacing(dx == 0 and (facing_map.dz[dz] * math.pi / 180) or (facing_map.dx[dx] * math.pi / 180));
                        index = next_index;
                    end
                    step_count = step_count - 1;
                    sleep(math.floor(50 / entertainment.delivery_speed));
                end

                if (is_move) then
                    local index = 1;
                    local first_entity = tuopan_list[index].entity;
                    for i = 1, size do
                        local next_index = index - delivery_direction;
                        next_index = next_index > size and 1 or (next_index < 1 and size or next_index);
                        local tuopan = tuopan_list[index];
                        local next_tuopan = tuopan_list[next_index];
                        if (next_index == 1) then 
                            tuopan.entity = first_entity;
                        else
                            tuopan.entity = next_tuopan.entity;
                        end 
                        tuopan.entity:SetPosition(tuopan.x, tuopan.y, tuopan.z);
                        tuopan.entity:SetFacing(tuopan.facing);
                        index = next_index;
                    end
                end
            else
                sleep(100);
            end
        end
    end);
end

delivery_tuopan();

local function GetEntityByMsg(msg)
    local __commonlib__ = __CodeGlobal__.shared_API.commonlib;
    local __GameLogic__ = __CodeGlobal__.shared_API.GameLogic;
    msg = __commonlib__.LoadTableFromString(msg);
    local entity = __GameLogic__.EntityManager.GetEntity(msg.name);
    return entity;
end

RegisterCodeBlockBroadcastEvent("delivery_stop", function(msg)
    entertainment.delivery_stop = not entertainment.delivery_stop;
end);

RegisterCodeBlockBroadcastEvent("delivery_direction_left", function(msg)
    local entity = GetEntityByMsg(msg);
    if (not entity) then return end 
    local filename = entity:GetModelFile();
    if (entertainment.delivery_direction ~= 1 or filename == "blocktemplates/qianjin-1.bmax") then
        entertainment.delivery_direction = 1;
        entertainment.delivery_speed = 1;
        entity:SetModelFile("blocktemplates/qianjin-2.bmax");
    else
        entertainment.delivery_direction = 1;
        entertainment.delivery_speed = 5;
        entity:SetModelFile("blocktemplates/qianjin-1.bmax");
    end
end);

RegisterCodeBlockBroadcastEvent("delivery_direction_right", function(msg)
    local entity = GetEntityByMsg(msg);
    if (not entity) then return end 
    local filename = entity:GetModelFile();
    if (entertainment.delivery_direction ~= -1 or filename == "blocktemplates/houtui-1.bmax") then
        entertainment.delivery_direction = -1;
        entertainment.delivery_speed = 1;
        entity:SetModelFile("blocktemplates/houtui-2.bmax");
    else
        entertainment.delivery_direction = -1;
        entertainment.delivery_speed = 5;
        entity:SetModelFile("blocktemplates/houtui-1.bmax");
    end
end);

-- 点击切换模型做法
-- 模型实体添加点击事件 click_switch_model
-- 未点击未激活模型 xxx_off.bmax 点击激活模型名 xxx_on.bmax
local click_switch_model_config = {
    -- ["blocktemplates/pingbang.bmax"] = "blocktemplates/pingbang1.bmax",
    -- ["blocktemplates/pingbang1.bmax"] = "blocktemplates/pingbang.bmax",
    -- ["blocktemplates/tv.bmax"] = "blocktemplates/tv1.bmax",
    -- ["blocktemplates/tv1.bmax"] = "blocktemplates/tv.bmax",
}
RegisterCodeBlockBroadcastEvent("click_switch_model", function(msg)
    local entity = GetEntityByMsg(msg);
    if (not entity) then return end 
    local filename = entity:GetModelFile();
    if (click_switch_model_config[filename]) then 
        return entity:SetModelFile(click_switch_model_config[filename]);
    end 
    if ((string.match(filename, "_on.bmax$"))) then
        return entity:SetModelFile(string.gsub(filename, "_on%.bmax$", "_off.bmax"));
    end
    if ((string.match(filename, "_off.bmax$"))) then
        return entity:SetModelFile(string.gsub(filename, "_off%.bmax$", "_on.bmax"));
    end
end);

-- 点击旋转 (绕模型x(红色), y(蓝色), z(绿色)轴旋转, 故注意其位置正确性)
-- 点击事件名:  click_rotate
-- 静态标签: 方向轴_角度 ([正则表示: [rxzy]{1,2}_%d+)  示例: z_45(绕Z轴顺时针45度)  rz_45(绕Z轴逆时针45度)
RegisterCodeBlockBroadcastEvent("click_rotate", __safe_callback__(function(msg)
    local entity = GetEntityByMsg(msg);
    if (not entity) then return end 
    local filename = entity:GetModelFile();
    local tag = entity:GetTag();
    local static_tag = entity:GetStaticTag();
    local direction, angle = string.match(string.lower(static_tag), "([rxyz]+)%_(%d+)");
    angle = tonumber(angle)
    if (not direction or not angle) then return end 
    local dir1 = tag == "open" and 1 or -1;
    local dir2 = (string.find(direction, "r", 1, true)) and -1 or 1;
    local dir = dir1 * dir2;
    -- print(dir, dir1, dir2)
    local facing = entity:GetFacing();
    local roll = entity:GetRoll();
    local pitch = entity:GetPitch();
    for i = 0, angle, 10 do
        if (string.find(direction, "x", 1, true)) then
            entity:SetRoll(roll + dir * i * math.pi / 180);
        end
        if (string.find(direction, "y", 1, true)) then
            entity:SetFacing(facing + dir * i * math.pi / 180);
        end
        if (string.find(direction, "z", 1, true)) then
            entity:SetPitch(pitch + dir * i * math.pi / 180);
        end
        sleep(10);
    end
    entity:SetTag(tag == "open" and "close" or "open");
end));



function clear()
    for _, tuopan in ipairs(tuopan_list) do
        tuopan.entity:SetPosition(tuopan.x, tuopan.y, tuopan.z);
    end
end
