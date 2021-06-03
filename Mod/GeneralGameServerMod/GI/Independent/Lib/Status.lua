local Status = module("Status")
local EntityWatcher = require("EntityWatcher")


--[[
{
    bars = {
        hp = {
            index = 1;
            color = "red";
            maxnum = 123;
            showtext = true;
        },
    }
    ui : true;
    headon: true;
}

]]

function Status.init(player, params)
    local bars = params.bars or {};

    local function setup(status)
        for k,v in pairs(params.bars or {}) do 
            status:setColor(v.index, v.color);
            status:setVisible(v.index, true);
            status:setValue(v.index, player:getProperty(k) or v.maxnum);

            if v.showtext then 
                status:setText(v.index, string.format("%s/%s", player:getProperty(k) or v.maxnum, v.maxnum));
            end
        end 

        player:on("property",function ( key, value)
            value = tonumber(value)
            if not value then return end;
            local bar = bars[key];
            if not bar then return end;
            status:setValue(bar.index, value / bar.maxnum);
            
            if bar.showtext then 
                status:setText(bar.index, string.format("%s/%s", value, bar.maxnum));
            end
        end)

        player:on("destroy", function ()
            status:close();
        end)
    end

    if params.headon then 
        local status = AddHeadonStatusBar(player.id);
        setup(status);
    end

    if params.ui then 
        local status = createOrGetStatusBar(player.id);
        setup(status);
    end
end

