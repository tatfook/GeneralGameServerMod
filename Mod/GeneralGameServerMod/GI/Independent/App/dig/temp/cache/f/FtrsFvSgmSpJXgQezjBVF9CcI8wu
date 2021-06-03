ItemInfoUI = {
    [1] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 400,
            ["y"] = 286,
            ["background_res"] = {hash = "Fk4z2uPQI_S6qcP1MJM3wo-PHdxp", pid = "43477", ext = "png"},
            ["parent"] = "__root",
            ["zorder"] = 13,
            ["align"] = "_lt",
            ["x"] = 790,
            ["type"] = "container",
            ["height"] = 450,
            ["name"] = "info",
            ["events"] = {}
        }
    },
    [2] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 400,
            ["y"] = 20,
            ["x"] = 20,
            ["parent"] = "info",
            ["text"] = "道具名字",
            ["zorder"] = 3,
            ["height"] = 50,
            ["events"] = {},
            ["font_size"] = 35,
            ["type"] = "text",
            ["font_color"] = "255 255 255",
            ["name"] = "name",
            ["align"] = "_lt"
        }
    },
    [3] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 100,
            ["y"] = 80,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "基础技能",
            ["zorder"] = 3,
            ["height"] = 30,
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["x"] = 20,
            ["name"] = "ability1",
            ["align"] = "_lt"
        }
    },
    [4] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 80,
            ["x"] = 150,
            ["parent"] = "info",
            ["text"] = "99999999",
            ["zorder"] = 3,
            ["height"] = 30,
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["font_color"] = "255 255 255",
            ["name"] = "ability1_value",
            ["align"] = "_lt"
        }
    },
    [5] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 100,
            ["y"] = 120,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "辅助技能",
            ["zorder"] = 3,
            ["name"] = "ability2",
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["x"] = 20,
            ["height"] = 36,
            ["align"] = "_lt"
        }
    },
    [6] = {
        ["type"] = "ui",
        ["params"] = {
            ["x"] = 20,
            ["y"] = 160,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "辅助技能",
            ["zorder"] = 3,
            ["name"] = "ability3",
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["width"] = 100,
            ["height"] = 36,
            ["align"] = "_lt"
        }
    },
    [7] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 100,
            ["y"] = 200,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "辅助技能",
            ["zorder"] = 3,
            ["height"] = 36,
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["x"] = 20,
            ["name"] = "ability4",
            ["align"] = "_lt"
        }
    },
    [8] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 120,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "+5000",
            ["zorder"] = 3,
            ["height"] = 36,
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["x"] = 150,
            ["name"] = "ability2_value",
            ["align"] = "_lt"
        }
    },
    [9] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 160,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "text",
            ["zorder"] = 3,
            ["height"] = 36,
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["x"] = 150,
            ["name"] = "ability3_value",
            ["align"] = "_lt"
        }
    },
    [10] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 200,
            ["font_color"] = "255 255 255",
            ["parent"] = "info",
            ["text"] = "*1.15",
            ["zorder"] = 3,
            ["height"] = 36,
            ["events"] = {},
            ["font_size"] = 25,
            ["type"] = "text",
            ["x"] = 150,
            ["name"] = "ability4_value",
            ["align"] = "_lt"
        }
    },
    [11] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 20,
            ["x"] = 280,
            ["parent"] = "info",
            ["text"] = "Lv.11",
            ["zorder"] = 3,
            ["height"] = 50,
            ["events"] = {},
            ["font_size"] = 35,
            ["type"] = "text",
            ["font_color"] = "255 255 255",
            ["name"] = "level",
            ["align"] = "_lt"
        }
    },
    [12] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 133,
            ["y"] = 370,
            ["parent"] = "info",
            ["text"] = "",
            ["zorder"] = 3,
            ["align"] = "_lt",
            ["type"] = "button",
            ["background_res"] = {hash = "FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7", pid = "257", ext = "png"},
            ["x"] = 134,
            ["height"] = 58,
            ["name"] = "确定并关闭",
            ["onclick"] = function()
                ItemInfoUI.close()
            end
        }
    }
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

function ItemInfoUI.show(item)
    ItemInfoUI.close()
    ItemInfoUI.mUIs = {}
    for _, cfg in ipairs(ItemInfoUI) do
        local cfg_cpy = clone(cfg)
        cfg_cpy.params.name = "ItemInfoUI/" .. cfg_cpy.params.name
        cfg_cpy.params.parent = ItemInfoUI.mUIs[cfg.params.parent]
        cfg_cpy.params.align = cfg.params.align or "_lt"
        local ui = CreateUI(cfg_cpy.params)
        ItemInfoUI.mUIs[cfg.params.name] = ui
        if cfg.params.background_res then
            GetResourceImage(
                cfg.params.background_res,
                function(path, err)
                    ui.background = path
                end
            )
        end
    end
    local item_config
    if item.mType == "工具框" then
        item_config = Config.Tool[item.mConfigIndex]
        ItemInfoUI.mUIs["level"].text = "Lv." .. tostring(item.mConfigIndex)
    elseif item.mType == "背包框" then
        item_config = Config.Bag[item.mConfigIndex]
        ItemInfoUI.mUIs["level"].text = "Lv." .. tostring(item.mConfigIndex)
    elseif item.mType == "头部框" then
        item_config = Config.Avatar.Head[item.mConfigIndex]
        ItemInfoUI.mUIs["level"].visible = false
    elseif item.mType == "上身框" then
        item_config = Config.Avatar.Body[item.mConfigIndex]
        ItemInfoUI.mUIs["level"].visible = false
    elseif item.mType == "下身框" then
        item_config = Config.Avatar.Leg[item.mConfigIndex]
        ItemInfoUI.mUIs["level"].visible = false
    end
    for i = 1, 4 do
        ItemInfoUI.mUIs["ability" .. tostring(i)].visible = false
        ItemInfoUI.mUIs["ability" .. tostring(i) .. "_value"].visible = false
    end
    ItemInfoUI.mUIs["name"].text = item_config.mDefaceName
    local index = 1
    for k, buff_value in pairs(item_config) do
        local buff_name
        if k == "mSpeed" then
            buff_name = "移动速度"
        elseif k == "mJump" then
            buff_name = "跳跃"
        elseif k == "mPowerAddition" then
            buff_name = "挖掘效率"
        elseif k == "mOreValue" then
            buff_name = "矿石价值"
        end
        if buff_name then
            ItemInfoUI.mUIs["ability" .. tostring(index)].visible = true
            ItemInfoUI.mUIs["ability" .. tostring(index)].text = buff_name
            ItemInfoUI.mUIs["ability" .. tostring(index) .. "_value"].visible = true
            ItemInfoUI.mUIs["ability" .. tostring(index) .. "_value"].text = tostring(buff_value)
            index = index + 1
        end
    end
    if item_config.mBuff then
        for k, v in pairs(item_config.mBuff) do
            ItemInfoUI.mUIs["ability" .. tostring(index)].visible = true
            ItemInfoUI.mUIs["ability" .. tostring(index)].text = k
            ItemInfoUI.mUIs["ability" .. tostring(index) .. "_value"].visible = true
            ItemInfoUI.mUIs["ability" .. tostring(index) .. "_value"].text = tostring(v)
            index = index + 1
        end
    end
end

function ItemInfoUI.close()
    if ItemInfoUI.mUIs then
        ItemInfoUI.mUIs[ItemInfoUI[1].params.name]:destroy()
        ItemInfoUI.mUIs = nil
    end
end
