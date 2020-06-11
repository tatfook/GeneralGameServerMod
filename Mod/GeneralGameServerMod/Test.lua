--[[
local Test = NPL.load("Mod/GeneralGameServerMod/Test.lua");
Test.Start();
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
		
local Test = NPL.export();

function Test.Start()
    echo("start HelloWorld");
    local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC")
	local entity = MyCompany.Aries.Game.EntityManager.EntityNPC:new({});
    entity:Attach();
    LOG.debug(entity);
    -- local x, y, z = ParaScene.GetPlayer():GetPosition();
    -- entity:SetPosition(x + 3, y , z);

end