local EntityWatcher = require("EntityWatcher")
local Status = require("Status")
local Repository = require("Repository")

function testEntityWatcher()
    EntityWatcher.on("create", function (p)
        if p.type == "player" then 
            p:on("property", function (key, value)
                print(key)
                print(value);
            end)        
        end
    end)

    EntityWatcher.get(GetPlayerId()):on("destroy", function ()
        print("leave");
    end)

    
end

function testStatus()
    local p = EntityWatcher.get(GetPlayerId());
    -- set status
    Status.init(p,
    {   
        bars = {
            pow = {
                index = 1;
                color = "green";
                maxnum = 100;
                showtext = true;
            },
            ang = {
                index = 2;
                color = "red";
                maxnum = 100;
                showtext =  true;
            }
        },
        ui = false,
        headon= true,
    });    

    p:setProperty("pow", 50)
    p:setProperty("ang", 50)

end

function testRepository()
    local slot = 1;
    local itemid = 5;
    local count = 1;
    Repository.setItem(GetPlayerId(), "inventory",slot, itemid, count )


    local item = CreateItemStack(itemid, count);
    SetitemStackInHand(item);
    SetItemStackToInventory(slot, item);

end

function testRouter()
    -- server
    Router.receive("login", function (msg, rep)
        print(tostring(rep.id) .. " login in host " .. tostring(GetPlayerId()))
        print("and say：" .. tostring(msg)) -- hello;
        rep:send("suc"); -- respone
    end)


    -- every client
    Router.send("login", "hello", function (msg)
        if msg == "suc" then 
            print("login suc.");
        end
    end)
end

function testGUI()
    local GUI = require("GUI")

    GUI.setDefaultFont(50, "255 0 0");
    GUI.setDefaultValue("onclick", function ()
        print("click!")
    end)

    local layout = {
        type = "Text",
        text = function ()
            return "test function value"
        end
    }
    GUI.UI(layout)
    Delay(2000, function ()
        layout.text = "ok!"
    end)
end