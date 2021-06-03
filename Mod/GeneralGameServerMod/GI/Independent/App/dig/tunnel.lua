Tunnel = {
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
      ["x"] = 300,
      ["parent"] = "surprise",
      ["text"] = "前往新矿区",
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
      ["events"] = {},
      ["onclick"] = function()
        Tunnel.onClick(Tunnel[3].params.name)
        Tunnel.close()
      end
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
        Tunnel.close()
      end
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 700,
      ["y"] = 120,
      ["parent"] = "surprise",
      ["text"] = "通过本隧道你将进入新的矿区，是否进入",
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

function Tunnel.show(parameter)
  Tunnel.close()
  Tunnel.mUIs = {}
  Tunnel.mParameter = parameter
  for _, cfg in ipairs(Tunnel) do
    local cfg_cpy = clone(cfg)
    if cfg_cpy.params.name == "explain" then
      cfg_cpy.params.text = Tunnel.mParameter.mText or ""
    end
    cfg_cpy.params.name = "Tunnel/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = Tunnel.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    Tunnel.mUIs[cfg.params.name] = ui
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
function Tunnel.close()
  if Tunnel.mUIs then
    Tunnel.mUIs[Tunnel[1].params.name]:destroy()
    Tunnel.mUIs = nil
  end
  Tunnel.mParameter = nil
end

function Tunnel.onClick(uiName)
  if uiName == "ok" then
    if Tunnel.mParameter.mOnClickOK then
      Tunnel.mParameter.mOnClickOK()
    end
  end
end