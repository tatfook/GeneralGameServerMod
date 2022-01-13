
print("========entertainment==========");

entertainment = module();

entertainment.delivery_direction = 1;
entertainment.delivery_step = 0.01;
entertainment.delivery_speed = 1;
entertainment.delivery_stop = false;

function delivery_tuopan()
    local tuopan_list = {};
    local function add_tuopan_entity(bx, by, bz, dx, dy, dz)
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
                table.insert(tuopan_list, {
                    entity = entity,
                    dx = dx, dy = dy, dz = dz,
                    bx = bx, by = by, bz = bz,
                    x = x, y = y, z = z,
                    facing = facing,
                });
                -- print(bx, by, bz)
                return ;
            end
        end
    end

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
            add_tuopan_entity(pos[1], pos[2], pos[3], dx, dy, dz);
            pos[1], pos[2], pos[3] = pos[1] + dx, pos[2] + dy, pos[3] + dz;
        end
    end
    add_tuopan_entity(pos[1], pos[2], pos[3], dx, dy, dz);

    async_run(function()
        while(true) do
            if (not entertainment.delivery_stop) then
                local size = #tuopan_list;
                local count = math.floor(__BlockSize__ / entertainment.delivery_step);
                local direction = entertainment.delivery_direction;
                local step = entertainment.delivery_step;
                local speed = entertainment.delivery_speed;
                while (count > 0) do
                    for i = 1, size do
                        local tuopan = tuopan_list[i];
                        local dx, dy, dz = tuopan.dx * direction * step, tuopan.dy * direction * step, tuopan.dz * direction * step;
                        local x, y, z = tuopan.entity:GetPosition();
                        tuopan.entity:SetPosition(x + dx, y + dy, z + dz);
                    end
                    count = count - 1;
                    sleep(math.floor(20 / speed));
                end

                local index = 1;
                local first_entity = tuopan_list[index].entity;
                for i = 1, size do
                    local next_index = index - direction;
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
            else
                sleep(300);
            end
        end
    end);
end

delivery_tuopan();

RegisterCodeBlockBroadcastEvent("delivery_stop", function(msg)
    entertainment.delivery_stop = not entertainment.delivery_stop;
end);

RegisterCodeBlockBroadcastEvent("delivery_direction_left", function(msg)
    if (entertainment.delivery_direction < 0) then
        entertainment.delivery_direction = 1;
        entertainment.delivery_speed = 1;
    else
        entertainment.delivery_speed = math.min(entertainment.delivery_speed * 2, 8);
    end
end);

RegisterCodeBlockBroadcastEvent("delivery_direction_right", function(msg)
    if (entertainment.delivery_direction > 0) then
        entertainment.delivery_direction = -1;
        entertainment.delivery_speed = 1;
    else
        entertainment.delivery_speed = math.min(entertainment.delivery_speed * 2, 8);
    end
end);