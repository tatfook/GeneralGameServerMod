
local __diffs__ = __diffs__ or {
    __regions__ = {
        ["37_37"] = {
            ["1200_1200"] = {

            }
        }
    }
}
region_list = {};
region_key = "";  -- 当前区域KEY
chunk_key = "";   -- 当前区块KEY

for region_key in pairs(__diffs__.__regions__) do 
    local region_x, region_z = string.match(region_key, "(%d+)_(%d+)");
    table.insert(region_list, {
        region_x = tonumber(region_x),
        region_z = tonumber(region_z),
        region_key = region_key,
    });
end

function chunk_list()
    local region = __diffs__.__regions__[region_key];
    local list = {}
    if (not region) then return list end 

    for chunk_key in pairs(region) do
        local chunk_x, chunk_z = string.match(chunk_key, "(%d+)_(%d+");
        table.insert(list, {
            chunk_x = tonumber(chunk_x),
            chunk_z = tonumber(chunk_z),
            chunk_key = chunk_key,
            region_key = region_key,
        });
    end

    return list;
end

function ClickRegion(region)
    region_key = region.region_key;
end