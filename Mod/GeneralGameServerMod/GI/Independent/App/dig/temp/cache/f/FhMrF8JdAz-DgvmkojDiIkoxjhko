Rebirth2UI = {
    [1] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 780,
            ["y"] = 328,
            ["background_res"] = {hash = "FpCOdsIRoitUffNzwEHIqShWWMGv", pid = "43504", ext = "png", },
            ["parent"] = "__root",
            ["zorder"] = 11,
            ["align"] = "_lt",
            ["x"] = 611,
            ["type"] = "container",
            ["height"] = 550,
            ["name"] = "surprise",
            ["events"] = {
            },
        },
    },
    [2] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 26,
            ["x"] = 250,
            ["parent"] = "surprise",
            ["text"] = "逃亡中",
            ["zorder"] = 1,
            ["height"] = 45,
            ["align"] = "_lt",
            ["font_size"] = 35,
            ["type"] = "text",
            ["font_color"] = "255 255 255",
            ["name"] = "标题",
            ["events"] = {
            },
        },
    },
    [3] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 133,
            ["y"] = 464,
            ["background_res"] = {hash = "FnMQfVulkQFuH57H4f5dhNJ4ZsFF", pid = "43503", ext = "png", },
            ["parent"] = "surprise",
            ["text"] = "",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["x"] = 614,
            ["type"] = "button",
            ["height"] = 58,
            ["name"] = "skip按钮",
            ["events"] = {
            },
        },
    },
    [4] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 380,
            ["y"] = 380,
            ["parent"] = "surprise",
            ["text"] = "翻越了一座山",
            ["zorder"] = 1,
            ["x"] = 200,
            ["align"] = "_lt",
            ["font_size"] = 25,
            ["type"] = "text",
            ["font_color"] = "255 255 255",
            ["height"] = 300,
            ["name"] = "滚动播放的文字信息池子",
        },
    },
    [5] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 26,
            ["parent"] = "surprise",
            ["text"] = "1天",
            ["zorder"] = 1,
            ["x"] = 400,
            ["align"] = "_lt",
            ["font_size"] = 35,
            ["type"] = "text",
            ["font_color"] = "255 255 255",
            ["height"] = 50,
            ["name"] = "计算出的用户这次重生能够获得的卡车币数值对等的天数",
        },
    },
    [6] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 400,
            ["y"] = 119,
            ["clip"] = true,
            ["parent"] = "surprise",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["x"] = 186,
            ["type"] = "container",
            ["background_res"] = {hash = "FtZCvDJGJvF6lcvuGZgU107uYBN6", pid = "43486", ext = "jpg", },
            ["name"] = "滚动播放的图片",
            ["height"] = 250,
        },
    },
}

local RandomInformation = {
    {mText = "穿越沙漠，然而不巧遇到了流沙陷阱", mPicture = {mResource = {hash="FuX3cJJK3wLoJEmexY0vv-lmx8qI",pid="49318",ext="png",}}},
    {mText = "路过一座山村，有不少女孩摇着手绢，想上车多搭一程", mPicture = {mResource = {hash="Fvbe1mPfZAsSb8cPkgzSi9vZckyW",pid="49317",ext="png",}}},
    {mText = "晚上睡在空地上，数着天上的星星，感觉已经好久没吃饭了", mPicture = {mResource = {hash="Fpncjo6nfqtPEWZCCEbhwXj6vUTj",pid="49320",ext="png",}}},
    {mText = "意外发现了一个湖，立即跳进去洗澡，上来时整个湖的水都黑了", mPicture = {mResource = {hash="Fh59eoTYgRe9TtIe6beZ_dNe4H89",pid="49319",ext="png",}}},
    {mText = "今天不开车，决定好好思考一下人生", mPicture = {mResource = {hash="Fkc0O6oeOvO3wVDCNAZtROy6Ihnu",pid="49321",ext="png",}}},
    {mText = "来到了世外桃源，赶紧拍个视频上传抖抖病，获得了老铁们的点赞", mPicture = {mResource = {hash = "FtZCvDJGJvF6lcvuGZgU107uYBN6", pid = "43486", ext = "jpg", }}},
}

local function clone(from)
    local ret
    if type(from) == "table" then
        ret = {}
        for key, value in pairs(from) do
            ret[key] = clone(value)
        end
    else
        ret = from
    end
    return ret
end
local function new(class, parameters)
    local new_table = {}
    setmetatable(new_table, {__index = class})
    for key, value in pairs(class) do
        new_table[key] = clone(value)
    end
    if parameters and parameters.mInitMembers then
        for key, value in pairs(parameters.mInitMembers) do
            new_table[key] = value
        end
    end
    local list = {}
    local dst = new_table
    while dst do
        list[#list + 1] = dst
        dst = dst._super
    end
    for i = #list, 1, -1 do
        list[i].construction(new_table, parameters)
    end
    return new_table
end
local function delete(inst)
    if inst then
        local list = {}
        local dst = inst
        while dst do
            list[#list + 1] = dst
            dst = dst._super
        end
        for i = 1, #list do
            list[i].destruction(inst)
        end
    end
end

local Timer = {}
function Timer:construction()
    self.mInitTime = GetTime() * 0.001
    self.mTime = self.mInitTime
end

function Timer:destruction()
end

function Timer:delta()
    local new_time = GetTime() * 0.001
    local ret = new_time - self.mTime
    self.mTime = new_time
    return ret
end

function Timer:total()
    local new_time = GetTime() * 0.001
    local ret = new_time - self.mInitTime
    return ret
end


function Rebirth2UI.show(days)
    Rebirth2UI.close()
    Rebirth2UI.mUIs = {}
    for _, cfg in ipairs(Rebirth2UI) do
        local cfg_cpy = clone(cfg)
        cfg_cpy.params.name = "Rebirth2UI/" .. cfg_cpy.params.name
        cfg_cpy.params.parent = Rebirth2UI.mUIs[cfg.params.parent]
        cfg_cpy.params.align = cfg.params.align or "_lt"
        local ui = CreateUI(cfg_cpy.params)
        Rebirth2UI.mUIs[cfg.params.name] = ui
        if cfg.params.background_res then
            GetResourceImage(cfg.params.background_res, function(path, err)
                ui.background = path
            end)
        else
            ui.background = ""
        end
    end
    Rebirth2UI.mTimer = new(Timer)
    Rebirth2UI.mDays = days
end

function Rebirth2UI.update()
    if Rebirth2UI.mTimer then
        local delta_second = math.floor(Rebirth2UI.mTimer:total())
        if Rebirth2UI.mDays < delta_second then
            Rebirth2UI.close()
            return
        end
        if delta_second == 0 or math.floor((delta_second + 1) % 5) == 0 then
            if not Rebirth2UI.mRandomed then
                local info = RandomInformation[math.random(1, #RandomInformation)]
                Rebirth2UI.mUIs["滚动播放的文字信息池子"].text = info.mText
                if info.mPicture.mResource then
                    GetResourceImage(info.mPicture.mResource, function(path, err)
                        Rebirth2UI.mUIs["滚动播放的图片"].background = path
                    end)
                end
                Rebirth2UI.mRandomed = true
            end
        else
            Rebirth2UI.mRandomed = nil
        end
        Rebirth2UI.mUIs["计算出的用户这次重生能够获得的卡车币数值对等的天数"].text = tostring(delta_second + 1) .. "天"
    end
end

function Rebirth2UI.close()
    if Rebirth2UI.mUIs then
        Rebirth2UI.mUIs[Rebirth2UI[1].params.name]:destroy()
        Rebirth2UI.mUIs = nil
        delete(Rebirth2UI.mTimer)
        Rebirth2UI.mTimer = nil
        Rebirth2UI.mDays = nil
        Rebirth2UI.mRandomed = nil
        if Rebirth2UI.mOnClose then
            Rebirth2UI.mOnClose()
        end
    end
end
