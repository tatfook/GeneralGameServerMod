
local __diffs__ = __diffs__ or {
    __regions__ = {
        ["37_37"] = {
            ["1200_1200"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            }
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
region_key = "";              -- 当前区域KEY
chunk_key = "";               -- 当前区块KEY
block_index = "";             -- 当前方块索引

for region_key in pairs(__diffs__.__regions__) do 
    local region_x, region_z = string.match(region_key, "(%d+)_(%d+)");
    table.insert(region_list, {
        region_x = tonumber(region_x),
        region_z = tonumber(region_z),
        region_key = region_key,
    });
end

function get_chunk_list()
    local region = __diffs__.__regions__[region_key];
    local list = {}
    for chunk_key in pairs(region) do
        local chunk_x, chunk_z = string.match(chunk_key, "(%d+)_(%d+)");
        table.insert(list, {
            chunk_x = tonumber(chunk_x),
            chunk_z = tonumber(chunk_z),
            chunk_key = chunk_key,
            region_key = region_key,
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

