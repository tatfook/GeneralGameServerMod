
local __diffs__ = __diffs__ or {
    __regions__ = {
        ["37_37"] = {
            ["1200_1200"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62},
            },
            ["1200_1202"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234561"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234562"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234563"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234564"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234565"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234566"] = {x = 19200, y = 5, z = 19200, block_id = 62},
            },
            ["1200_1203"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
            ["1200_1204"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
            ["1200_1205"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
            ["1200_1206"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
        },
        ["36_36"] = {
            ["1100_1100"] = {
                ["223456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            }
        }
    }
}

region_list = {};
chunk_list = {};
block_list = {};
block_detail = {};
region_key = "";              -- 当前区域KEY
chunk_key = "";               -- 当前区块KEY
block_index = "";             -- 当前方块索引

for region_key, region in pairs(__diffs__.__regions__) do 
    local region_x, region_z = string.match(region_key, "(%d+)_(%d+)");
    local chunk_count = 0;
    for _ in pairs(region) do chunk_count = chunk_count + 1 end
    table.insert(region_list, {
        region_x = tonumber(region_x),
        region_z = tonumber(region_z),
        region_key = region_key,
        chunk_count = chunk_count,
    });
end

function get_chunk_list()
    local region = __diffs__.__regions__[region_key];
    local list = {}
    for chunk_key, chunk in pairs(region) do
        local chunk_x, chunk_z = string.match(chunk_key, "(%d+)_(%d+)");
        local block_count = 0;
        for _ in pairs(chunk) do block_count = block_count + 1 end
        table.insert(list, {
            chunk_x = tonumber(chunk_x),
            chunk_z = tonumber(chunk_z),
            chunk_key = chunk_key,
            region_key = region_key,
            block_count = block_count,
        });
    end

    return list;
end

function get_block_list()
    local region = __diffs__.__regions__[region_key];
    local chunk = region[chunk_key];
    local list = {};

    for block_index, block in pairs(chunk) do
        table.insert(list, {x = block.x, y = block.y, z= block.z, block_index = block_index});
    end

    return list;
end

function get_block_detail(block)
    local region = __diffs__.__regions__[region_key];
    local chunk = region[chunk_key];
    local chunk_block = chunk[block.block_index];
    local detail = {x = block.x, y = block.y, z = block.z, block_index = block.block_index};

    if (__is_local__) then
        detail.local_block_id, detail.local_block_data, detail.local_entity_data = chunk_block.local_block_id, chunk_block.local_block_data, chunk_block.local_entity_data;
        detail.remote_block_id, detail.remote_block_data, detail.remote_entity_data = chunk_block.remote_block_id, chunk_block.remote_block_data, chunk_block.remote_entity_data;
    else
        detail.remote_block_id, detail.remote_block_data, detail.remote_entity_data = chunk_block.local_block_id, chunk_block.local_block_data, chunk_block.local_entity_data;
        detail.local_block_id, detail.local_block_data, detail.local_entity_data = chunk_block.remote_block_id, chunk_block.remote_block_data, chunk_block.remote_entity_data;
    end
    
    detail.is_equal_block_id = detail.local_block_id == detail.remote_block_id;
    detail.is_equal_block_data = detail.local_block_data == detail.remote_block_data;
    detail.is_equal_entity_data = detail.local_entity_data == detail.remote_entity_data;

    return detail;
end