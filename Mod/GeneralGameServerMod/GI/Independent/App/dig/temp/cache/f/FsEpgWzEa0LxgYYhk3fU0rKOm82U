NickNameUI = {
  [1] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 780,
      ["y"] = 328,
      ["background_res"] = {hash = "FpCOdsIRoitUffNzwEHIqShWWMGv", pid = "43504", ext = "png"},
      ["parent"] = "__root",
      ["zorder"] = 14,
      ["align"] = "_lt",
      ["x"] = 611,
      ["type"] = "container",
      ["height"] = 450,
      ["name"] = "改名框",
      ["events"] = {}
    }
  },
  [2] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 600,
      ["y"] = 26,
      ["x"] = 150,
      ["parent"] = "改名框",
      ["text"] = "主人，给我取一个好听的名字吧",
      ["zorder"] = 4,
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
      ["width"] = 250,
      ["y"] = 113,
      ["clip"] = true,
      ["parent"] = "改名框",
      ["zorder"] = 4,
      ["align"] = "_lt",
      ["x"] = 268,
      ["type"] = "container",
      ["name"] = "宠物的图片",
      ["height"] = 250,
      ["events"] = {}
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 250,
      ["y"] = 198,
      ["parent"] = "宠物的图片",
      ["text"] = "editbox",
      ["background_res"] = {hash = "Fj_ujvCUxZ1b01FklbHHMmMxOCJT", pid = "43480", ext = "png"},
      ["zorder"] = 5,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["font_color"] = "255 255 255",
      ["type"] = "imeeditbox",
      ["x"] = 1,
      ["height"] = 50,
      ["name"] = "名字输入框"
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 374,
      ["background_res"] = {hash = "FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7", pid = "257", ext = "png"},
      ["parent"] = "改名框",
      ["text"] = "",
      ["zorder"] = 4,
      ["align"] = "_lt",
      ["x"] = 501,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "ok",
      ["events"] = {},
      ["onclick"] = function()
        if not NickNameUI.mUIs["名字输入框"].text or
        NickNameUI.mUIs["名字输入框"].text == ""
        then
          MessageBox("输入一个好听的名字吧!")
          return
        end
        Router.send("RenamePet",{mID = GetPlayerId(),mBagItemIndex = NickNameUI.mItem.mBagItemIndex,mName = NickNameUI.mUIs["名字输入框"].text})
        if PetInfoUI.mUIs then
          PetInfoUI.mUIs["name"].text = NickNameUI.mUIs["名字输入框"].text
        end
        if BagUI.mUIs then
          BagUI.mBag["宠物框"].mItems[NickNameUI.mItem.mBagItemIndex].mName = NickNameUI.mUIs["名字输入框"].text
          BagUI.refresh()
        end
        NickNameUI.close()
      end
    }
  },
  [6] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 374,
      ["background_res"] = {hash = "FpMuez41eX50SutijZq3d79GSqnY", pid = "43481", ext = "png"},
      ["parent"] = "改名框",
      ["text"] = "",
      ["zorder"] = 4,
      ["align"] = "_lt",
      ["x"] = 196,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "no",
      ["events"] = {},
      ["onclick"] = function()
        NickNameUI.close()
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

function NickNameUI.show(item)
  NickNameUI.close()
  NickNameUI.mItem = item
  NickNameUI.mUIs = {}
  for _, cfg in ipairs(NickNameUI) do
    local cfg_cpy = clone(cfg)
    cfg_cpy.params.name = "NickNameUI/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = NickNameUI.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    NickNameUI.mUIs[cfg.params.name] = ui
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
  NickNameUI.mUIs["名字输入框"].text = item.mName or ""
  GetResourceImage(
    Config.Avatar.Pet[item.mConfigIndex].mIcon.mResource,
    function(path, err)
      NickNameUI.mUIs["宠物的图片"].background = path
    end
  )
end

function NickNameUI.close()
  if NickNameUI.mUIs then
    NickNameUI.mUIs[NickNameUI[1].params.name]:destroy()
    NickNameUI.mUIs = nil
  end
end
