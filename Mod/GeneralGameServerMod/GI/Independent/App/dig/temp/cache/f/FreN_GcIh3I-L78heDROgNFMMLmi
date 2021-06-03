CustomerUI = {
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
      ["name"] = "客服框"
    }
  },
  [2] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 650,
      ["y"] = 26,
      ["parent"] = "客服框",
      ["text"] = "欢迎加入官方QQ群提出您的问题和建议",
      ["zorder"] = 3,
      ["x"] = 80,
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
      ["parent"] = "客服框",
      ["zorder"] = 3,
      ["align"] = "_lt",
      ["type"] = "container",
      ["x"] = 268,
      ["background_res"] = {hash="FmmDGlv073CD_bauA_vlGZzNSiaL",pid="49624",ext="JPG",},
      ["name"] = "道具图片",
      ["height"] = 250
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 600,
      ["y"] = 410,
      ["parent"] = "客服框",
      ["text"] = "官方讨论群号——476916578,加群暗号【逮虾户】",
      ["zorder"] = 3,
      ["x"] = 20,
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
      ["parent"] = "客服框",
      ["text"] = "",
      ["zorder"] = 3,
      ["align"] = "_lt",
      ["type"] = "button",
      ["x"] = 606,
      ["height"] = 58,
      ["name"] = "ok",
      ["onclick"] = function()
        CustomerUI.close()
      end
    }
  },
      [6] = {
        ["type"] = "ui",
        ["params"] = {
          ["x"] = 268,
          ["y"] = 340,
          ["font_color"] = "255 255 255",
          ["parent"] = "客服框",
          ["text"] = "手机QQ专用二维码",
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

function CustomerUI.show()
  CustomerUI.close()
  CustomerUI.mUIs = {}
  for _, cfg in ipairs(CustomerUI) do
    local cfg_cpy = clone(cfg)
    cfg_cpy.params.name = "CustomerUI/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = CustomerUI.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    CustomerUI.mUIs[cfg.params.name] = ui
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

function CustomerUI.close()
  if CustomerUI.mUIs then
    CustomerUI.mUIs[CustomerUI[1].params.name]:destroy()
    CustomerUI.mUIs = nil
  end
end
