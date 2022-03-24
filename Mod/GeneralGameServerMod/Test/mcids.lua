
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local xmltext = CommonLib.GetFileText("D:/mcids.xml")

print(#xmltext)

local xmlnodes = ParaXML.LuaXML_ParseString(xmltext);
echo(ParaXML.LuaXML_ParseString(xmltext), true)
print(#xmlnodes)

local mc_id_name_list = {}

for _, xmlnode in ipairs(xmlnodes) do
    local id_name = {
        id_data = xmlnode[1][1],
        legacy_item_id = xmlnode[3][2][1],
        name = xmlnode[3][1][1],
    }
    id_name.legacy_item_id = string.gsub(id_name.legacy_item_id, "^[%s%(]*", "");
    id_name.legacy_item_id = string.gsub(id_name.legacy_item_id, "[%s%)]*$", "");
    id_name.item_id = "minecraft:" .. string.lower(id_name.name);
    id_name.item_id = string.gsub(id_name.item_id, " ", "_");
    local index = string.find(id_name.id_data, ":", 1, true);
    if (index) then
        id_name.id = tonumber(string.sub(id_name.id_data, 1, index - 1));
        id_name.data = tonumber(string.sub(id_name.id_data, index + 1));
    else
        id_name.id = tonumber(id_name.id_data);
        id_name.data = 0;
    end
    if (id_name.id < 200) then
        table.insert(mc_id_name_list, id_name)
    end
end

echo(mc_id_name_list, true)

for _, id_name in ipairs(mc_id_name_list) do
    print(string.format('AddMinecraftBlock(%s, %s, "%s");', id_name.id, id_name.data, id_name.item_id));
end



-- System.os.GetUrl({
--     url = "https://api.minecraftitemids.com/v1/search",
--     method = "POST",

-- }, function(err, code, data)
--     print(err, code, data)
--     echo(code);
--     echo(data)
-- end)


-- https://minecraft-ids.grahamedgecombe.com/