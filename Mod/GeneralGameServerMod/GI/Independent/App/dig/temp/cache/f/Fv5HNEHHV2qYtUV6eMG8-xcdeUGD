SurpriseUI = {
  [1] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 780,
      ["y"] = 325,
      ["background_res"] = {hash = "FpCOdsIRoitUffNzwEHIqShWWMGv", pid = "43504", ext = "png"},
      ["parent"] = "root",
      ["zorder"] = 13,
      ["align"] = "_lt",
      ["type"] = "container",
      ["x"] = 615,
      ["height"] = 450,
      ["name"] = "surprise"
    }
  },
  [2] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 600,
      ["y"] = 26,
      ["parent"] = "surprise",
      ["text"] = "哇塞！盒子里装的竟然是这个！",
      ["zorder"] = 3,
      ["x"] = 150,
      ["align"] = "_lt",
      ["font_size"] = 35,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 45,
      ["name"] = "标题"
    }
  },
  [3] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 250,
      ["y"] = 113,
      ["clip"] = true,
      ["parent"] = "surprise",
      ["zorder"] = 3,
      ["align"] = "_lt",
      ["type"] = "container",
      ["x"] = 268,
      ["name"] = "道具图片",
      ["height"] = 250
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 500,
      ["y"] = 410,
      ["parent"] = "surprise",
      ["text"] = "然而对于已拥有的你来说，这个并没什么用......",
      ["zorder"] = 3,
      ["x"] = 320,
      ["align"] = "_lt",
      ["font_size"] = 20,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 50,
      ["name"] = "如果这个avatar我已经有了出现的提示"
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 368,
      ["background_res"] = {hash = "FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7", pid = "257", ext = "png"},
      ["parent"] = "surprise",
      ["text"] = "",
      ["zorder"] = 3,
      ["align"] = "_lt",
      ["type"] = "button",
      ["x"] = 40,
      ["height"] = 58,
      ["name"] = "ok",
      ["onclick"] = function()
        SurpriseUI.close()
      end
    }
  },
      [6] = {
        ["type"] = "ui",
        ["params"] = {
          ["x"] = 268,
          ["y"] = 340,
          ["font_color"] = "255 255 255",
          ["parent"] = "surprise",
          ["text"] = "箱子里面东西的名字",
          ["zorder"] = 1,
          ["text_format"] = 9,
          ["align"] = "_lt",
          ["font_size"] = 25,
          ["type"] = "text",
          ["width"] = 250,
          ["name"] = "item_name",
          ["height"] = 50,
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

function SurpriseUI.show(item)
  SurpriseUI.close()
  SurpriseUI.mUIs = {}
  for _, cfg in ipairs(SurpriseUI) do
    local cfg_cpy = clone(cfg)
    cfg_cpy.params.name = "SurpriseUI/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = SurpriseUI.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    SurpriseUI.mUIs[cfg.params.name] = ui
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
  if item.mConfig.mIcon.mResource then
    GetResourceImage(
      item.mConfig.mIcon.mResource,
      function(path, err)
        SurpriseUI.mUIs["道具图片"].background = path
      end
    )
  else
    SurpriseUI.mUIs["道具图片"].background = item.mConfig.mIcon.mFile
  end
  SurpriseUI.mUIs["item_name"].text = item.mConfig.mDefaceName
  if item.mOwnered then
    SurpriseUI.mUIs["如果这个avatar我已经有了出现的提示"].visible = true
  else
    SurpriseUI.mUIs["如果这个avatar我已经有了出现的提示"].visible = false
  end
end

function SurpriseUI.close()
  if SurpriseUI.mUIs then
    SurpriseUI.mUIs[SurpriseUI[1].params.name]:destroy()
    SurpriseUI.mUIs = nil
  end
end
