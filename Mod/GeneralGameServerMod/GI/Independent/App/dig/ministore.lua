MiniStoreUI = {
    [1] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 960,
            ["y"] = 295,
            ["background_res"] = {hash = "Fs_LiV_0DICfgEc69wE5uk3iG7s6", pid = "23", ext = "png"},
            ["parent"] = "root",
            ["zorder"] = 11,
            ["align"] = "_lt",
            ["type"] = "container",
            ["name"] = "mini_store",
            ["height"] = 560,
            ["x"] = 493
        }
    },
    [2] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 50,
            ["y"] = 6,
            ["background_res"] = {hash = "FrPtA9xoYDJw40tLtcvty5GtUGWo", pid = "43485", ext = "png"},
            ["parent"] = "mini_store",
            ["text"] = "",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["type"] = "button",
            ["x"] = 892,
            ["height"] = 60,
            ["name"] = "关闭icon",
            ["onclick"] = function()
                MiniStoreUI.close()
            end
        }
    },
    [3] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 400,
            ["y"] = 20,
            ["x"] = 280,
            ["parent"] = "mini_store",
            ["text"] = "惊奇商店",
            ["zorder"] = 1,
            ["font_color"] = "255 255 255",
            ["align"] = "_lt",
            ["font_size"] = 40,
            ["type"] = "text",
            ["text_format"] = 5,
            ["height"] = 50,
            ["name"] = "商店对应的名字"
        }
    },
    [4] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 200,
            ["y"] = 120,
            ["clip"] = true,
            ["parent"] = "mini_store",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["x"] = 380,
            ["type"] = "container",
            ["background_res"] = {hash = "FmItZUWYKBR83l7y7wqaU7Tsjg6y", pid = "43933", ext = "png"},
            ["name"] = "销售物品icon",
            ["height"] = 200
        }
    },
    [5] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 150,
            ["y"] = 170,
            ["clip"] = true,
            ["parent"] = "mini_store",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["x"] = 50,
            ["type"] = "container",
            ["background_res"] = {hash = "Fp4dZh7iDoill9pPJSDJfaeb0Hdi", pid = "43936", ext = "png"},
            ["name"] = "左边上物品icon",
            ["height"] = 150
        }
    },
    [6] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 150,
            ["y"] = 170,
            ["clip"] = true,
            ["parent"] = "mini_store",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["x"] = 760,
            ["type"] = "container",
            ["background_res"] = {hash = "FuI_qAasQgp-TwVruc1vUdph2-zd", pid = "43914", ext = "png"},
            ["name"] = "右边上物品icon",
            ["height"] = 150
        }
    },
    [7] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 400,
            ["y"] = 330,
            ["x"] = 280,
            ["parent"] = "mini_store",
            ["text"] = "Lv.+物品名称",
            ["zorder"] = 1,
            ["font_color"] = "255 255 255",
            ["align"] = "_lt",
            ["font_size"] = 35,
            ["type"] = "text",
            ["text_format"] = 5,
            ["height"] = 50,
            ["name"] = "物品的等级描述信息"
        }
    },
    [8] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 300,
            ["y"] = 480,
            ["clip"] = true,
            ["parent"] = "mini_store",
            ["zorder"] = 1,
            ["x"] = 330,
            ["align"] = "_lt",
            ["font_size"] = 25,
            ["type"] = "container",
            ["background_res"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
            ["name"] = "购买按钮底框",
            ["height"] = 70
        }
    },
    [9] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 40,
            ["y"] = 15,
            ["clip"] = true,
            ["parent"] = "购买按钮底框",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["x"] = 9,
            ["type"] = "container",
            ["background_res"] = {hash = "Fj7IIHK0FAaJhSVWR8iN63cfJTDE", pid = "24", ext = "png"},
            ["background_res_on"] = {hash = "Fpgm6Y6C88bMRX1dvxfNeiujh2ru", pid = "44196", ext = "png"},
            ["name"] = "货币图标",
            ["height"] = 40
        }
    },
    [10] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 240,
            ["y"] = 15,
            ["x"] = 60,
            ["parent"] = "购买按钮底框",
            ["text"] = "9999,9999,9999",
            ["zorder"] = 1,
            ["font_color"] = "255 255 255",
            ["align"] = "_lt",
            ["font_size"] = 30,
            ["type"] = "text",
            ["text_format"] = 8,
            ["height"] = 40,
            ["name"] = "货币数值"
        }
    },
    [11] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 300,
            ["y"] = 0,
            ["parent"] = "购买按钮底框",
            ["text"] = "",
            ["zorder"] = 1,
            ["align"] = "_lt",
            ["type"] = "button",
            ["x"] = 0,
            ["height"] = 70,
            ["name"] = "购买的透明按钮"
        }
    },
    [12] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 86,
            ["y"] = 180,
            ["background_res"] = {hash = "FhbLWPEZqHROxcJb5I-G_5gvESQQ", pid = "38", ext = "png"},
            ["parent"] = "mini_store",
            ["text"] = "",
            ["zorder"] = 2,
            ["align"] = "_lt",
            ["type"] = "button",
            ["x"] = 20,
            ["height"] = 100,
            ["name"] = "向前更换商品",
            ["onclick"] = function()
                MiniStoreUI.mItemIndex = MiniStoreUI.mItemIndex - 1
                while MiniStoreUI.mItemIndex < 1 do
                    MiniStoreUI.mItemIndex = MiniStoreUI.mItemIndex + #Config.Box
                end
                MiniStoreUI.refresh()
            end
        }
    },
    [13] = {
        ["type"] = "ui",
        ["params"] = {
            ["width"] = 86,
            ["y"] = 180,
            ["background_res"] = {hash = "Fgk5RuHiM_pzzi7LKKcqjLjmDgES", pid = "37", ext = "png"},
            ["parent"] = "mini_store",
            ["text"] = "",
            ["zorder"] = 2,
            ["align"] = "_lt",
            ["type"] = "button",
            ["x"] = 855,
            ["height"] = 100,
            ["name"] = "向后更换商品",
            ["onclick"] = function()
                MiniStoreUI.mItemIndex = MiniStoreUI.mItemIndex + 1
                while MiniStoreUI.mItemIndex > #Config.Box do
                    MiniStoreUI.mItemIndex = MiniStoreUI.mItemIndex - #Config.Box
                end
                MiniStoreUI.refresh()
            end
        }
    },
      [14] = {
        ["type"] = "ui",
        ["params"] = {
          ["width"] = 940,
          ["x"] = 10,
          ["y"] = 380,
          ["height"] = 50,
          ["parent"] = "mini_store",
          ["text"] = "物品第一行信息",
          ["zorder"] = 1,
          ["text_format"] = 5,
          ["events"] = {
          },
          ["font_size"] = 35,
          ["type"] = "text",
          ["align"] = "_lt",
          ["name"] = "物品第一行信息",
          ["font_color"] = "255 255 255",
        },
      },
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

function MiniStoreUI.show()
    MiniStoreUI.close()
    MiniStoreUI.mUIs = {}
    for _, cfg in ipairs(MiniStoreUI) do
        local cfg_cpy = clone(cfg)
        cfg_cpy.params.name = "MiniStoreUI/" .. cfg_cpy.params.name
        cfg_cpy.params.parent = MiniStoreUI.mUIs[cfg.params.parent]
        cfg_cpy.params.align = cfg.params.align or "_lt"
        local ui = CreateUI(cfg_cpy.params)
        MiniStoreUI.mUIs[cfg.params.name] = ui
        if cfg.params.background_res then
            GetResourceImage(
                cfg.params.background_res,
                function(path, err)
                    ui.background = path
                end
        )
        else
            ui.background = ""
        end
    end
    MiniStoreUI.mItemIndex = 1
    MiniStoreUI.refresh()
end

function MiniStoreUI.refresh()
    local cfg = Config.Box[MiniStoreUI.mItemIndex]
    if cfg.mIcon.mResource then
        GetResourceImage(
            cfg.mIcon.mResource,
            function(path, err)
                MiniStoreUI.mUIs["销售物品icon"].background = path
            end
    )
    elseif cfg.mIcon.mFile then
        MiniStoreUI.mUIs["销售物品icon"].background = cfg.mIcon.mFile
    end
    if cfg.mPrice.mType == "卡车币" then
        GetResourceImage(
            MiniStoreUI[9].params.background_res_on,
            function(path, err)
                MiniStoreUI.mUIs["货币图标"].background = path
            end
    )
    elseif cfg.mPrice.mType == "金币" then
        GetResourceImage(
            MiniStoreUI[9].params.background_res,
            function(path, err)
                MiniStoreUI.mUIs["货币图标"].background = path
            end
    )
    end
    MiniStoreUI.mUIs["货币数值"].text = tostring(cfg.mPrice.mValue)
    MiniStoreUI.mUIs["物品的等级描述信息"].text = cfg.mDefaceName
    MiniStoreUI.mUIs["物品第一行信息"].text = cfg.mDefaceInfo
    
    local left_item_index = MiniStoreUI.mItemIndex - 1
    while left_item_index < 1 do
        left_item_index = left_item_index + #Config.Box
    end
    local cfg = Config.Box[left_item_index]
    if cfg.mIcon.mResource then
        GetResourceImage(
            cfg.mIcon.mResource,
            function(path, err)
                MiniStoreUI.mUIs["左边上物品icon"].background = path
            end
    )
    elseif cfg.mIcon.mFile then
        MiniStoreUI.mUIs["左边上物品icon"].background = cfg.mIcon.mFile
    end
    
    local right_item_index = MiniStoreUI.mItemIndex + 1
    while right_item_index > #Config.Box do
        right_item_index = right_item_index - #Config.Box
    end
    local cfg = Config.Box[right_item_index]
    if cfg.mIcon.mResource then
        GetResourceImage(
            cfg.mIcon.mResource,
            function(path, err)
                MiniStoreUI.mUIs["右边上物品icon"].background = path
            end
    )
    elseif cfg.mIcon.mFile then
        MiniStoreUI.mUIs["右边上物品icon"].background = cfg.mIcon.mFile
    end
end

function MiniStoreUI.close()
    if MiniStoreUI.mUIs then
        MiniStoreUI.mUIs[MiniStoreUI[1].params.name]:destroy()
        MiniStoreUI.mUIs = nil
        MiniStoreUI.mItemIndex = nil
    end
end
