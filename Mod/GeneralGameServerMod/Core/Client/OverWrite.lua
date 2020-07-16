--[[
Title: OverWrite
Author(s):  wxa
Date: 2020-07-14
Desc: 重写一些 script 脚本函数, 原则维持旧逻辑, 新增逻辑
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Core/Client/OverWrite.lua");
------------------------------------------------------------
]]

-- MovieClipController
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");

local OldOnClosePage = MovieClipController.OnClosePage;
function MovieClipController.OnClosePage()
    -- 表记block
    local self = MovieClipController;
    if(self.activeClip and self.activeClip:GetEntity()) then
        self.activeClip:GetEntity():MarkForUpdate();
    end

    -- 执行原有逻辑
    if (OldOnClosePage) then 
        OldOnClosePage();
     end
end
