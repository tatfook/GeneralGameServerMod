Rebirth3UI = {
  [1] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 780,
      ["y"] = 328,
      ["background_res"] = {hash = "FpCOdsIRoitUffNzwEHIqShWWMGv", pid = "43504", ext = "png"},
      ["parent"] = "__root",
      ["zorder"] = 11,
      ["align"] = "_lt",
      ["x"] = 611,
      ["type"] = "container",
      ["height"] = 550,
      ["name"] = "surprise",
      ["events"] = {}
    }
  },
  [2] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["y"] = 26,
      ["x"] = 400,
      ["parent"] = "surprise",
      ["text"] = "逃亡失败",
      ["zorder"] = 1,
      ["height"] = 45,
      ["align"] = "_lt",
      ["font_size"] = 35,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["name"] = "标题",
      ["events"] = {}
    }
  },
  [3] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 464,
      ["background_res"] = {hash = "FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7", pid = "257", ext = "png"},
      ["parent"] = "surprise",
      ["text"] = "",
      ["zorder"] = 1,
      ["align"] = "_lt",
      ["x"] = 614,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "ok",
      ["events"] = {},
      ["onclick"] = function()
        Rebirth3UI.close()
      end
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 580,
      ["y"] = 380,
      ["parent"] = "surprise",
      ["text"] = "很不幸，又被抓回黑煤窑了。但在这次逃亡的路上\13\
幸运地获得了9999枚卡车币",
      ["zorder"] = 1,
      ["x"] = 100,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 300,
      ["name"] = "描述文字，这里的卡车币数量需要你计算一下"
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["y"] = 26,
      ["parent"] = "surprise",
      ["text"] = "99999次",
      ["zorder"] = 1,
      ["x"] = 250,
      ["align"] = "_lt",
      ["font_size"] = 35,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 50,
      ["name"] = "计算一下这是玩家累计第多少次重生"
    }
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
      ["background_res"] = {hash="FvAjgBGM3R7tFs5TP8wYCZhThWeb",pid="49314",ext="png",},
      ["name"] = "玩家被抓回来的搞笑图",
      ["height"] = 250
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

function Rebirth3UI.show()
  Rebirth3UI.close()
  Rebirth3UI.mUIs = {}
  for _, cfg in ipairs(Rebirth3UI) do
    local cfg_cpy = clone(cfg)
    cfg_cpy.params.name = "Rebirth3UI/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = Rebirth3UI.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    Rebirth3UI.mUIs[cfg.params.name] = ui
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
end

function Rebirth3UI.close()
  if Rebirth3UI.mUIs then
    Rebirth3UI.mUIs[Rebirth3UI[1].params.name]:destroy()
    Rebirth3UI.mUIs = nil
  end
end
