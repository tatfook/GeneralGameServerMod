
local toolbox = [[
<toolbox>
    <category name="运动" color="">
        <block type="moveForward"></block>
    </category>
</toolbox>
]]

local xmlNode = ParaXML.LuaXML_ParseString(toolbox);
local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
echo(toolboxNode, true)