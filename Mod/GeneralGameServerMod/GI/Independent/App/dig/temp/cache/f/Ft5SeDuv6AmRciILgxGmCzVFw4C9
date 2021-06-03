DiscardUI = {
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
      ["name"] = "discard",
      ["events"] = {}
    }
  },
  [2] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 600,
      ["y"] = 26,
      ["x"] = 150,
      ["parent"] = "discard",
      ["text"] = "主人，你真的决定丢弃我了吗！？",
      ["zorder"] = 4,
      ["height"] = 45,
      ["events"] = {},
      ["font_size"] = 35,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["name"] = "标题",
      ["align"] = "_lt"
    }
  },
  [3] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 250,
      ["y"] = 113,
      ["clip"] = true,
      ["parent"] = "discard",
      ["zorder"] = 4,
      ["align"] = "_lt",
      ["x"] = 268,
      ["type"] = "container",
      ["name"] = "宠物模型",
      ["height"] = 250,
      ["events"] = {}
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["text_border"] = true,
      ["y"] = 280,
      -- ["background_res"] = {hash = "FrzlUqszeg_ofu4pow26jp6QmfIx", pid = "43496", ext = "png"},
      ["parent"] = "discard",
      ["text_format"] = 9,
      ["font_size"] = 25,
      ["clip"] = true,
      ["font_bold"] = true,
      ["text"] = "宠物名字",
      ["zorder"] = 5,
      ["align"] = "_lt",
      ["x"] = 290,
      ["type"] = "text",
      ["name"] = "宠物名字",
      ["height"] = 40,
      ["font_color"] = "255 255 255"
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 374,
      ["background_res"] = {hash = "FtFq7Cxh7NP2JrWjJX2zUPdWFwJ7", pid = "257", ext = "png"},
      ["parent"] = "discard",
      ["text"] = "",
      ["zorder"] = 4,
      ["align"] = "_lt",
      ["x"] = 501,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "ok",
      ["events"] = {}
    }
  },
  [6] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 133,
      ["y"] = 374,
      ["background_res"] = {hash = "FpMuez41eX50SutijZq3d79GSqnY", pid = "43481", ext = "png"},
      ["parent"] = "discard",
      ["text"] = "",
      ["zorder"] = 4,
      ["align"] = "_lt",
      ["type"] = "button",
      ["x"] = 196,
      ["height"] = 58,
      ["name"] = "no",
      ["onclick"] = function()
        DiscardUI.close()
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

function DiscardUI.show(item)
  echo("devilwalk",item)
  DiscardUI.close()
  DiscardUI.mUIs = {}
  for _, cfg in ipairs(DiscardUI) do
    local cfg_cpy = clone(cfg)
    cfg_cpy.params.name = "DiscardUI/" .. cfg_cpy.params.name
    cfg_cpy.params.parent = DiscardUI.mUIs[cfg.params.parent]
    cfg_cpy.params.align = cfg.params.align or "_lt"
    local ui = CreateUI(cfg_cpy.params)
    DiscardUI.mUIs[cfg.params.name] = ui
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
  DiscardUI.mUIs["宠物名字"].text = item.mName or Config.Avatar.Pet[item.mConfigIndex].mDefaceName
  DiscardUI.mEntity = CreateNPC({bx = 0, by = 0, bz = 0, item_id = 10062, can_random_move = false, mDisableSync = true})
  DiscardUI.mEntity._super.SetMainAssetPath(DiscardUI.mEntity, "")
  if Config.Avatar.Pet[item.mConfigIndex].mModel.mFile then
    DiscardUI.mEntity._super.SetMainAssetPath(DiscardUI.mEntity, Config.Avatar.Pet[item.mConfigIndex].mModel.mFile)
  elseif Config.Avatar.Pet[item.mConfigIndex].mModel.mResource then
    GetResourceModel(Config.Avatar.Pet[item.mConfigIndex].mModel.mResource,function(path,err)
      DiscardUI.mEntity._super.SetMainAssetPath(DiscardUI.mEntity, path)
    end)
  end
  DiscardUI.mEntity:SetPosition(0, 0, 0)
  DiscardUI.mEntity:SetFacing(1.57)
  DiscardUI.mMiniScene = CreateMiniScene("DigAHole/Discard", 512, 512)
  DiscardUI.mMiniScene:addMiniGameUI({mInternal = DiscardUI.mUIs["宠物模型"]()})
  DiscardUI.mMiniScene:setCameraLookAtPosition(0, 0.2, 10)
  DiscardUI.mMiniScene:setCameraPosition(0, 0, -3.5)
  DiscardUI.mMiniScene:addEntity(DiscardUI.mEntity)
end

function DiscardUI.close()
  if DiscardUI.mUIs then
    DiscardUI.mEntity:SetDead(true)
    DiscardUI.mEntity = nil
    DestroyMiniScene("DigAHole/Discard")
    DiscardUI.mMiniScene = nil
    DiscardUI.mUIs[DiscardUI[1].params.name]:destroy()
    DiscardUI.mUIs = nil
  end
end
