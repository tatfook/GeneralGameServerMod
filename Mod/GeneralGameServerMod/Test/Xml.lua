
-- local toolbox = [[
-- <toolbox>
--     <category name="运动" color="">
--         <block type="moveForward"></block>
--     </category>
-- </toolbox>
-- ]]

-- local xmlNode = ParaXML.LuaXML_ParseString(toolbox);
-- local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
-- echo(toolboxNode, true)

local xmlnode = {name = "test", [1] = {name="![CDATA[", [1] = "hellow world"}};

local xmltext = commonlib.Lua2XmlString(xmlnode);
print(0, xmltext)

local xmltext1 = string.gsub(xmltext, "%]%]>", "%]%]%]%]><!%[CDATA%[>");
print(1, xmltext1)

local xmlnode2 = {name = "test", [1] = {name="![CDATA[", [1] = xmltext1}};
local xmltext2 = commonlib.Lua2XmlString(xmlnode2)

print(2, xmltext2)

echo(xmlnode2, true)

echo(ParaXML.LuaXML_ParseString(xmltext2), true)


-- NPL.load("Mod/GeneralGameServerMod/Test/Xml.lua");