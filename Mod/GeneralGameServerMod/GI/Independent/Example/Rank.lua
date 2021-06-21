local GGSRank = require("GGSRank");

-- 定义排行字段
GGSRank:DefineField({key = "nickname", title = "昵称", no = 1, width = 200, defaule_value = GetUserName()});
GGSRank:DefineField({key = "score", title = "得分", no = 2, defaule_value = 0});
-- 设置排序方式
GGSRank:SetSort(function(item1, item2) 
    return item1.score and item2.score and item1.score > item2.score 
end);
-- 显示UI
GGSRank:ShowUI();

local TickCount = 0
function loop()
    TickCount = TickCount + 1;
    if (TickCount < 30) then return end
    TickCount = 0;
    -- 更新字段值
    GGSRank:SetFieldValue("score", GGSRank:GetFieldValue("score") + 1);
end


