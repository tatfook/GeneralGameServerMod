local Team = module("Team")
local EntityWatcher = require("EntityWatcher")
local props = EntityWatcher.create("__team", "team");
local myid = GetPlayerId();
local myprops = EntityWatcher.get(myid);
Team.Red = "red";
Team.Green = "green";
Team.Blue = "blue";

Team.Colors = 
{
    [Team.Red] = {color = "255 100 100", team = Team.Red}, 
    [Team.Green] = {color = "100 200 100", team = Team.Green},
    [Team.Blue] = {color = "100 180 255", team = Team.Blue},
}

function Team.addMember(team, memid)
    props:setProperty(string.format("Team.%s.%s", team, memid), true);
    local p = EntityWatcher.get(memid);
    if p then 
        p:setProperty("team", team);
    end
end

function Team.removeMember(team, memid)
    props:setProperty(string.format("Team.%s.%s", team, memid), nil);
    local p = EntityWatcher.get(memid);
    if p then 
        p:setProperty("team", nil);
    end
end

function Team.hasMember(team, memid)
    return props:getProperty(string.format("Team.%s.%s", team, memid));
end

function Team.getAllMembers(team)
    return props:getProperty(string.format("Team.%s", team)) or {};
end

function Team.getNumMembers(team)
    local list = Team.getAllMembers(team);
    local num = 0;
    for k,v in pairs(list) do 
        num = num + 1;
    end
    return num;
end

function Team.cleanTeam(team)
    local list = Team.getAllMembers(team); 
    for k,v in pairs(list) do 
        local e = EntityWatcher.get(k);
        if e then 
            e:setProperty("team", nil);
        end
    end
    props:setProperty(string.format("Team.%s", team ), {});
end

-- function Team.setProperty(team, key, value)
--     props:setProperty(string.format("Team.properties.%s.%s",team, key), value);
-- end

-- function Team.getProperty(team, key)
--     return props:getProperty(string.format("Team.properties.%s.%s",team, key));
-- end

Team.HideAllName = 0;
Team.ShowPartnerName = 1;
Team.ShowAllName = 2;
function Team.showHeadonName(type)
    props:setProperty("showHeadonName", type);
end

Timer(1000, function ()
    local myTeam = myprops:getProperty("team");
    local showNameType = props:getProperty("showHeadonName")
    local teams = {}
    if showNameType == Team.ShowAllName then 
        for k,v in pairs(Team.Colors) do 
            table.insert(teams, v);
        end
    else
        -- remove
        for k,v in pairs(Team.Colors) do 
            for k,v in pairs(Team.getAllMembers(v.team)) do 
                local e = GetEntityById(tonumber(k))
                local d = EntityWatcher.get(tonumber(k));
                if e then 
                    e:ShowAllHeadonObjects(false);
                end
            end
        end

        if showNameType == Team.ShowPartnerName then 
            teams = {Team.Colors[myTeam]};
        end
    end
    for k,c in ipairs(teams) do 
        for k,v in pairs(Team.getAllMembers(c.team)) do 
            local e = GetEntityById(tonumber(k))
            if e then 
                e:ShowAllHeadonObjects(true);
                local name = e:GetHeadonObject("name");
                name:setText(e.nickname)
                name:setColor(c.color);
            end
        end
    end
end)