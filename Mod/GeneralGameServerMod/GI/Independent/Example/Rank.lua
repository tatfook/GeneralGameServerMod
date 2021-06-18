local GGSRank = require("GGSRank");

GGSRank:DefineField({key = "nickname", title = "昵称", no = 1, width = 200, defaule_value = GetUserName()});
GGSRank:DefineField({key = "score", title = "得分", no = 2, defaule_value = 0});

GGSRank:ShowUI();

local TickCount = 0
function loop()
    TickCount = TickCount + 1;
    if (TickCount < 30) then return end
    TickCount = 0;
    GGSRank:SetFieldValue("score", GGSRank:GetFieldValue("score") + 1);
end


