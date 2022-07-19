
--[[
Title: Const
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local LuaFormat = NPL.load("Mod/GeneralGameServerMod/UI/Blockly/LuaFormat.lua");
LuaFormat.Pretty();
-------------------------------------------------------
]]

local LuaFormat = NPL.export();
local LuaFmt = NPL.load("./LuaFmt.lua");

NPL.load("(gl)script/ide/System/Compiler/nplp.lua");
NPL.load("(gl)script/ide/System/Compiler/nplgen.lua");
local nplp = commonlib.gettable("System.Compiler.nplp");
local nplgen = commonlib.gettable("System.Compiler.nplgen");

local lua_code_text = [[
registerAgentEvent('GetIcon', function(msg)
while(true) do
tip('Start Game!');

end
registerCollisionEvent('name', function(actor)
    playMusic('Audio/Haqi/AriesRegionBGMusics/Area_SunnyBeach.ogg', 1);

end)

end)
]]

-- function LuaFormat.Pretty(code)
--     local ast = nplp:new():src_to_ast(code or lua_code_text, "LuaFormat.npl");
--     local gen = nplgen:new();
--     gen:SetIgnoreNewLine(true);
--     local text = gen.ast_to_str(ast);
--     --echo(ast, true)
--     print(#ast, #ast[1], #(ast[1][1]), #(ast[1][2]))
--     local token_1 = ast[1][1];
--     print(token_1.tag, token_1[1], type(token_1[2]))
--     local token_2 = ast[1][2];
--     print(token_2.tag, token_2[1], type(token_2[2]))
--     print(text)
-- end

local prettycode = LuaFmt.Pretty(lua_code_text);
print(prettycode)
prettycode = string.gsub(prettycode, "\t", "    ")
print(prettycode)