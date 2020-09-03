
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
local Encoding = commonlib.gettable("System.Encoding");

local username = self.username or "xiaoyao";

-- 组件全局变量初始化
GetGlobalScope():Set("AuthUsername", System.User.keepworkUsername);
GetGlobalScope():Set("isLogin", System.User.keepworkUsername and true or false);
GetGlobalScope():Set("isAuthUser", false);
GetGlobalScope():Set("UserDetail", {username = "", createdAt = "2020-01-01", rank = {}});
GetGlobalScope():Set("ProjectList", {});

-- 加载用户信息
function LoadUserInfo(username)
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode({username=username}));
    -- 获取用户信息
    keepwork.user.getinfo({
        cache_policy = "access plus 0",
        router_params = {id = id},
    }, function(status, msg, data) 
        if (status ~= 200) then return echo("获取用户详情失败...") end
        local UserDetail = data;
        if (System.User.keepworkUsername == UserDetail.username) then
            GetGlobalScope():Set("AuthUserId", UserDetail.id);
            GetGlobalScope():Set("isAuthUser", true);
        end
        GetGlobalScope():Set("UserDetail", UserDetail);

        -- echo(data)
        -- 获取项目列表
        local userId = self.UserDetail.id;
        keepwork.project.list({
            userId = userId,
            type = 1,               -- 取世界项目
            headers = {
                ["x-page"] = 1,
                ["x-per-page"] = 1000,           -- 先取全部后续优化
                ["x-order"] = "updatedAt-desc",  -- 按更新时间降序
            }
        }, function(status, msg, data)
            if (status ~= 200) then return echo("获取用户项目列表失败") end
            local ProjectList = data;
            GetGlobalScope():Set("ProjectList", ProjectList);
            -- ui:RefreshWindow();
            -- echo(data);
            -- 获取是否关注
            keepwork.user.isfollow({
                objectId = userId,
                objectType = 0,
            }, function(status, msg, data) 
                UserDetail.isFollow = false;
                if (status ~= 200) then return end
                if (data and data ~= "false" and tonumber(data) ~= 0) then
                    UserDetail.isFollow = true;
                    -- ui:RefreshWindow();
                end
            end)
        end)
    end)
end

LoadUserInfo(username);