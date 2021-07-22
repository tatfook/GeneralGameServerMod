local NetRank = require("NetRank");

-- 定义排行字段
NetRank:DefineField({key = "nickname", title = "昵称", no = 1, width = 200, defaule_value = GetUserName()});
NetRank:DefineField({key = "score", title = "得分", no = 2, defaule_value = 0});
-- 设置排序方式
NetRank:SetSort(function(item1, item2) 
    return item1.score and item2.score and item1.score < item2.score 
end);
-- 显示UI
NetRank:ShowUI();
-- 定时更新UI
SetInterval(1000, function()
    -- 更新字段值
    NetRank:SetFieldValue("score", NetRank:GetFieldValue("score") + 1);
end);


