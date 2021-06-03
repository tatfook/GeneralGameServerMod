Rebirth1UI = {
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
      ["width"] = 600,
      ["y"] = 26,
      ["x"] = 200,
      ["parent"] = "surprise",
      ["text"] = "逮虾户！一起逃离黑煤窑！",
      ["zorder"] = 1,
      ["height"] = 45,
      ["align"] = "_lt",
      ["font_size"] = 35,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["name"] = "wow",
      ["events"] = {}
    }
  },
  [3] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 459,
      ["background_res"] = {hash = "FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7", pid = "257", ext = "png"},
      ["parent"] = "surprise",
      ["text"] = "",
      ["zorder"] = 1,
      ["align"] = "_lt",
      ["x"] = 564,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "ok",
      ["events"] = {}
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 461,
      ["background_res"] = {hash = "FpMuez41eX50SutijZq3d79GSqnY", pid = "43481", ext = "png"},
      ["parent"] = "surprise",
      ["text"] = "",
      ["zorder"] = 1,
      ["align"] = "_lt",
      ["x"] = 92,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "no",
      ["events"] = {},
      ["onclick"] = function()
        Rebirth1UI.close()
      end
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 700,
      ["y"] = 120,
      ["parent"] = "surprise",
      ["text"] = "你是否愿意支付￥1000,0000逃离这里？逃离时，你将失去：\13\
1、当前挖掘的方块数和一切成就\13\
2、当前的所有金钱，不过我会根据一定比例折算卡车币给你\13\
3、所有工具、背包和所有非传说级的装备\13\
\13\
不过随着逃亡次数的增多，你将积累更多阅历，矿石收益增高\13\
卡车币可以用来在商店购买老司机礼物盒，极高概率装有宠物\13\
怎么样？要不要试着逃亡一下呢？",
      ["zorder"] = 1,
      ["x"] = 40,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 300,
      ["name"] = "explain"
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

function Rebirth1UI.show()
  Rebirth1UI.close()
  Rebirth1UI.mUIs = {}
  for _, cfg in ipairs(Rebirth1UI) do
    local cfg_cpy = clone(cfg)
    cfg_cpy.params.name = "Rebirth1UI/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = Rebirth1UI.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    Rebirth1UI.mUIs[cfg.params.name] = ui
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

function Rebirth1UI.close()
  if Rebirth1UI.mUIs then
    Rebirth1UI.mUIs[Rebirth1UI[1].params.name]:destroy()
    Rebirth1UI.mUIs = nil
  end
end
