local MacroBlock = NPL.export();

local NPL_Macro_Start = {};
function NPL_Macro_Start.OnCreate(block)
    local player = GameLogic.EntityManager.GetPlayer();
    if (not player) then return end
    local code = "";
    local bx, by, bz = player:GetBlockPos();
    code = code .. string.format("SetMacroOrigin(%s, %s, %s)\n", bx, by, bz);
    local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
    code = code .. string.format("CameraMove(%s, %s, %s)\n", camobjDist, LiftupAngle, CameraRotY);
	local lookatX, lookatY, lookatZ = ParaCamera.GetLookAtPos();
    code = code .. string.format("CameraLookat(%s, %s, %s)\n", lookatX, lookatY, lookatZ);
    local facing = player:GetFacing();
    code = code .. string.format("PlayerMoveTrigger(%s, %s, %s, %s)\n", bx, by, bz, facing);
    code = code .. string.format("PlayerMove(%s, %s, %s, %s)\n", bx, by, bz, facing);
    block:SetFieldValue("MacroCode", code);
end

function NPL_Macro_Start.ToMacroCode(block)
    return block:GetFieldValue("MacroCode");
end

function NPL_Macro_Start.ToCode()
    return "";
end

local NPL_Macro_Finished = {};
function NPL_Macro_Finished.ToMacroCode()
    return 'Broadcast("macroFinished")';
end

function NPL_Macro_Finished.ToCode()
    return "";
end

local NPL_Macro_RunCode = {};
function NPL_Macro_RunCode.ToMacroCode()
    return [[
ButtonClickTrigger("CodeBlockWindow.run","left")
ButtonClick("CodeBlockWindow.run","left")
]];
end

function NPL_Macro_RunCode.ToCode()
    return "";
end

local NPL_Macro_Text = {}
function NPL_Macro_Text.ToMacroCode(block) 
    local TEXT = block:GetFieldValue("TEXT");
    local DURATION = block:GetFieldValue("DURATION");
    local POS = block:GetFieldValue("POS");
    local TYPE = block:GetFieldValue("TYPE");
    return string.format('text("%s", %s, "%s", %s)', TEXT, DURATION, POS, TYPE);
end

function NPL_Macro_Text.ToCode(block)
    return "";
end


MacroBlock.NPL_Macro_Start = NPL_Macro_Start;
MacroBlock.NPL_Macro_Finished = NPL_Macro_Finished;
MacroBlock.NPL_Macro_RunCode = NPL_Macro_RunCode;
MacroBlock.NPL_Macro_Text = NPL_Macro_Text;
