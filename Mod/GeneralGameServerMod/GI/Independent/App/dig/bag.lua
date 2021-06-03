BagUI = {
  [1] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 1374,
      ["text_border"] = true,
      ["y"] = 88,
      ["background_res"] = {hash = "FgnBqabkOLjjU1QzPDgXud9iNVGL", pid = "43478", ext = "png"},
      ["parent"] = "__root",
      ["text"] = "",
      ["zorder"] = 12,
      ["align"] = "_lt",
      ["font_color"] = "255 255 255",
      ["events"] = {},
      ["height"] = 765,
      ["type"] = "container",
      ["visible"] = true,
      ["name"] = "bag",
      ["x"] = 225
    }
  },
  [2] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 35,
      ["y"] = 13,
      ["background_res"] = {hash = "FrPtA9xoYDJw40tLtcvty5GtUGWo", pid = "43485", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["x"] = 1316,
      ["type"] = "button",
      ["height"] = 35,
      ["name"] = "关闭窗口icon",
      ["events"] = {},
      ["onclick"] = function()
        BagUI.close()
      end
    }
  },
  [3] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 100,
      ["x"] = 20,
      ["y"] = 3,
      ["height"] = 170,
      ["parent"] = "bag",
      ["text"] = "仓库",
      ["zorder"] = 2,
      ["text_format"] = 16,
      ["events"] = {},
      ["font_size"] = 40,
      ["type"] = "text",
      ["align"] = "_lt",
      ["name"] = "窗口标题背包",
      ["font_color"] = "255 255 255"
    }
  },
  [4] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 431,
      ["y"] = 68,
      ["clip"] = true,
      ["parent"] = "bag",
      ["zorder"] = 2,
      ["x"] = 8,
      ["events"] = {},
      ["name"] = "换装预览窗口底图",
      ["type"] = "container",
      ["background_res"] = {hash = "Fk4z2uPQI_S6qcP1MJM3wo-PHdxp", pid = "43477", ext = "png"},
      ["height"] = 688,
      ["align"] = "_lt"
    }
  },
  [5] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 250,
      ["y"] = 31,
      ["clip"] = true,
      ["parent"] = "换装预览窗口底图",
      ["zorder"] = 2,
      ["x"] = 87,
      ["events"] = {},
      ["name"] = "换装角色模型预览",
      ["type"] = "container",
      ["background_res"] = {hash = "FsL7Y1031b0g-7C_cRDhYxYU7uQg", pid = "43476", ext = "png"},
      ["height"] = 460,
      ["align"] = "_lt"
    }
  },
  [6] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 39,
      ["y"] = 36,
      ["clip"] = true,
      ["parent"] = "换装预览窗口底图",
      ["zorder"] = 2,
      ["x"] = 13,
      ["align"] = "_lt",
      ["name"] = "角色获得跳跃buff的icon",
      ["type"] = "container",
      ["background_res"] = {hash = "Fk4JvdgwVDAL4u4k1kS_vlOwoQg2", pid = "43499", ext = "png"},
      ["height"] = 41,
      ["events"] = {},
      ["onmouseenter"] = function()
        BagUI.mUIs[BagUI[36].params.name].visible = true
      end,
      ["onmouseleave"] = function()
        BagUI.mUIs[BagUI[36].params.name].visible = false
      end
    }
  },
  [7] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 39,
      ["y"] = 83,
      ["clip"] = true,
      ["parent"] = "换装预览窗口底图",
      ["zorder"] = 2,
      ["x"] = 13,
      ["align"] = "_lt",
      ["name"] = "角色获得速度buff的icon",
      ["type"] = "container",
      ["background_res"] = {hash = "FhaJF4rjnUgcP_xl4jgzBQUrjmNH", pid = "43500", ext = "png"},
      ["height"] = 42,
      ["events"] = {},
      ["onmouseenter"] = function()
        BagUI.mUIs[BagUI[37].params.name].visible = true
      end,
      ["onmouseleave"] = function()
        BagUI.mUIs[BagUI[37].params.name].visible = false
      end
    }
  },
  [8] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 920,
      ["y"] = 135,
      ["clip"] = true,
      ["parent"] = "bag",
      ["zorder"] = 2,
      ["x"] = 449,
      ["events"] = {},
      ["name"] = "道具列表框",
      ["type"] = "container",
      ["background_res"] = {hash = "FhXfddnVt8DcgUAGJcZF_4d3-OP1", pid = "43498", ext = "png"},
      ["height"] = 525,
      ["align"] = "_lt"
    }
  },
  [9] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 0,
      ["width"] = 115,
      ["y"] = 0,
      ["parent"] = "道具列表框",
      ["name"] = "单个道具底框",
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "container",
      ["background_res"] = {hash = "Fjq-WaEy64NFP6H9RK8vkLgh6NmH", pid = "43497", ext = "png"},
      ["background_res_on"] = {hash = "FkbbnuH0rivEsSisM7pK0jfyglzE", pid = "43674", ext = "png"},
      ["height"] = 165,
      ["events"] = {}
    }
  },
  [10] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 100,
      ["y"] = 12,
      ["parent"] = "单个道具底框",
      ["align"] = "_lt",
      ["x"] = 7,
      ["type"] = "container",
      ["name"] = "道具展示图",
      ["height"] = 100,
      ["events"] = {}
    }
  },
  [11] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 100,
      ["y"] = 125,
      ["font_color"] = "0 0 0",
      ["parent"] = "单个道具底框",
      ["text"] = "道具名",
      ["height"] = 30,
      ["align"] = "_lt",
      ["font_size"] = 20,
      ["text_format"] = 9,
      ["type"] = "text",
      ["x"] = 0,
      ["name"] = "展示道具的名字",
      ["events"] = {}
    }
  },
  [12] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 66,
      ["y"] = 0,
      ["parent"] = "单个道具底框",
      ["x"] = 0,
      ["align"] = "_lt",
      ["name"] = "目前装备着的道具",
      ["type"] = "container",
      ["background_res"] = {hash = "Fj9FyhkHoOZu7ugaKWNAnhBPVkUj", pid = "43490", ext = "png"},
      ["height"] = 69,
      ["events"] = {}
    }
  },
  [13] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 120,
      ["y"] = 68,
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["parent"] = "bag",
      ["events"] = {},
      ["font_size"] = 30,
      ["visible"] = true,
      ["clip"] = true,
      ["text"] = "工具",
      ["zorder"] = 2,
      ["font_color"] = "255 255 255",
      ["align"] = "_lt",
      ["height"] = 58,
      ["type"] = "button",
      ["x"] = 444,
      ["name"] = "工具框",
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("工具框")
      end
    }
  },
  [14] = {
    ["type"] = "ui",
    ["params"] = {
      ["font_color"] = "255 255 255",
      ["width"] = 120,
      ["name"] = "背包框",
      ["x"] = 574,
      ["y"] = 68,
      ["clip"] = true,
      ["parent"] = "bag",
      ["text"] = "背包",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["events"] = {},
      ["font_size"] = 30,
      ["type"] = "button",
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["height"] = 58,
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("背包框")
      end
    }
  },
  [15] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 120,
      ["y"] = 68,
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["parent"] = "bag",
      ["events"] = {},
      ["font_size"] = 30,
      ["visible"] = true,
      ["clip"] = true,
      ["text"] = "头部",
      ["zorder"] = 2,
      ["font_color"] = "255 255 255",
      ["align"] = "_lt",
      ["height"] = 58,
      ["type"] = "button",
      ["x"] = 703,
      ["name"] = "头部框",
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("头部框")
      end
    }
  },
  [16] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 120,
      ["font_color"] = "255 255 255",
      ["name"] = "上身框",
      ["x"] = 832,
      ["y"] = 68,
      ["clip"] = true,
      ["parent"] = "bag",
      ["text"] = "上身",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["events"] = {},
      ["font_size"] = 30,
      ["type"] = "button",
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["height"] = 58,
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("上身框")
      end
    }
  },
  [17] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 120,
      ["font_color"] = "255 255 255",
      ["name"] = "下身框",
      ["x"] = 962,
      ["y"] = 68,
      ["clip"] = true,
      ["parent"] = "bag",
      ["text"] = "下身",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["events"] = {},
      ["font_size"] = 30,
      ["type"] = "button",
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["height"] = 58,
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("下身框")
      end
    }
  },
  [18] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 120,
      ["font_color"] = "255 255 255",
      ["name"] = "礼物盒框",
      ["x"] = 1222,
      ["y"] = 68,
      ["clip"] = true,
      ["parent"] = "bag",
      ["text"] = "礼物盒",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["events"] = {},
      ["font_size"] = 30,
      ["type"] = "button",
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["height"] = 58,
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("礼物盒框")
      end
    }
  },
  [19] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 120,
      ["font_color"] = "255 255 255",
      ["name"] = "宠物框",
      ["x"] = 1091,
      ["y"] = 68,
      ["clip"] = true,
      ["parent"] = "bag",
      ["text"] = "宠物",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["events"] = {},
      ["font_size"] = 30,
      ["type"] = "button",
      ["background_res"] = {hash = "FpTlEm8rZqUJPacRJgaEXwIEJL60", pid = "43483", ext = "png"},
      ["background_res_on"] = {hash = "FqhMO7WCsRogjrINVe81Qql-QheF", pid = "43484", ext = "png"},
      ["height"] = 58,
      ["shadow"] = true,
      ["onclick"] = function()
        BagUI.onClickType("宠物框")
      end
    }
  },
  [20] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 1000,
      ["font_color"] = "255 255 255",
      ["name"] = "分类框的名字",
      ["y"] = 65,
      ["clip"] = true,
      ["parent"] = "bag",
      ["text"] = "工具     背包      头部     上身     下身      宠物      礼盒\13\
",
      ["zorder"] = 2,
      ["x"] = 465,
      ["events"] = {},
      ["font_size"] = 40,
      ["type"] = "text",
      ["align"] = "_lt",
      ["height"] = 68,
      ["shadow"] = true
    }
  },
  [21] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 134,
      ["y"] = 670,
      ["background_res"] = {hash = "Fg3tlQHFgxEHN3AB2RDKDjgNZM-a", pid = "43494", ext = "png"},
      ["background_res_on"] = {hash = "FuH8rKKz3bWOeAcsolrbFnmBsUeW", pid = "43493", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["x"] = 444,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "装备按钮",
      ["events"] = {},
      ["onclick"] = function()
        local item_type
        local avatar_info
        if BagUI.mType == "工具框" then
          item_type = "tool"
        elseif BagUI.mType == "背包框" then
          item_type = "bag"
        elseif BagUI.mType == "头部框" or BagUI.mType == "上身框" or BagUI.mType == "下身框" or BagUI.mType == "宠物框" then
          avatar_info = {}
          avatar_info.mType = BagUI.mType
          if not BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mEquiped then
            avatar_info.mIndex = BagUI.mItemIndex
          end
        elseif BagUI.mType == "礼物盒框" then
          local item = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex]
          table.remove(BagUI.mBag[BagUI.mType].mItems, BagUI.mItemIndex)
          local box_cfg = Config.Box[item.mConfigIndex]
          local boxName = box_cfg.mDefaceName
          local random_item_indices = {}
          if BagUI.mBag[BagUI.mType].mLuckies and BagUI.mBag[BagUI.mType].mLuckies[item.mConfigIndex] == 99 then
            for i, item in pairs(box_cfg.mItems) do
              if item.mSpecial == "稀有" then
                random_item_indices[#random_item_indices + 1] = i
              end
            end
            BagUI.mBag[BagUI.mType].mLuckies[item.mConfigIndex] = 0
          else
            for i, item in pairs(box_cfg.mItems) do
              random_item_indices[#random_item_indices + 1] = i
            end
            BagUI.mBag[BagUI.mType].mLuckies = BagUI.mBag[BagUI.mType].mLuckies or {}
            BagUI.mBag[BagUI.mType].mLuckies[item.mConfigIndex] =
              BagUI.mBag[BagUI.mType].mLuckies[item.mConfigIndex] or 0
            BagUI.mBag[BagUI.mType].mLuckies[item.mConfigIndex] =
              BagUI.mBag[BagUI.mType].mLuckies[item.mConfigIndex] + 1
          end
          local total_chance = 0
          for _, index in pairs(random_item_indices) do
            total_chance = total_chance + box_cfg.mItems[index].mChance
          end
          local random_number = math.random(1, total_chance)
          local item_index = random_item_indices[1]
          for _, index in pairs(random_item_indices) do
            if random_number <= box_cfg.mItems[index].mChance then
              item_index = index
              break
            end
            random_number = random_number - box_cfg.mItems[index].mChance
          end
          local box_item_config = box_cfg.mItems[item_index]
          local item
          for avatar_type, avatar in pairs(Config.Avatar) do
            if item then
              break
            end
            for i, component in pairs(avatar) do
              if component.mName == box_item_config.mName then
                item = {}
                item.mType = avatar_type
                item.mConfigIndex = i
                break
              end
            end
          end
          local bag_type
          if item.mType == "Head" then
            bag_type = "头部框"
          elseif item.mType == "Body" then
            bag_type = "上身框"
          elseif item.mType == "Leg" then
            bag_type = "下身框"
          elseif item.mType == "Pet" then
            bag_type = "宠物框"
          end
          local ownered
          if item.mType == "Pet" then
            item.mRGB = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}
            item.mLevel = 0
            item.mExp = {0, 0, 0}
          else
            for _, test in pairs(BagUI.mBag[bag_type].mItems) do
              if test.mConfigIndex == item.mConfigIndex then
                ownered = true
                break
              end
            end
          end
          local presentName = Config.Avatar[item.mType][item.mConfigIndex].mDefaceName
          Router.send(
            "OpenBox",
            {
              mID = GetPlayerId(),
              mBagItemIndex = BagUI.mItemIndex,
              boxName =boxName,
              presentName = presentName,
              mItem = {
                mType = bag_type,
                mConfigIndex = item.mConfigIndex,
                mRGB = item.mRGB,
                mLevel = item.mLevel,
                mExp = item.mExp,
                mOwnered = ownered
              }


            }
          )
          if not ownered then
            BagUI.mBag[bag_type].mItems[#BagUI.mBag[bag_type].mItems + 1] = {
              mConfigIndex = item.mConfigIndex,
              mRGB = item.mRGB,
              mLevel = item.mLevel,
              mExp = item.mExp
            }
          end
          SurpriseUI.show({mConfig = Config.Avatar[item.mType][item.mConfigIndex], mOwnered = ownered})

          BagUI.mItemIndex = nil
        end
        if item_type then
          Router.send(
            "equip",
            {
              id = GetPlayerId(),
              itemType = item_type,
              grade = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mConfigIndex
            }
          )
        elseif avatar_info then
          Router.send("EquipAvatar", {mID = GetPlayerId(), mAvatarInfo = {avatar_info}})
        end
        if BagUI.mType ~= "礼物盒框" then
          for k, item in pairs(BagUI.mBag[BagUI.mType].mItems) do
            BagUI.mBag[BagUI.mType].mItems[k].mEquiped = nil
          end
          if not avatar_info or avatar_info.mIndex then
            BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mEquiped = true
          end
        end
        BagUI.refresh()
      end
    }
  },
  [22] = {
    ["type"] = "ui",
    ["params"] = {
      ["clip"] = true,
      ["width"] = 100,
      ["height"] = 35,
      ["text_border"] = true,
      ["y"] = 600,
      ["background_res"] = {hash = "Fj_ujvCUxZ1b01FklbHHMmMxOCJT", pid = "43480", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "挖掘效率",
      ["zorder"] = 2,
      ["font_color"] = "255 255 255",
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["events"] = {},
      ["name"] = "挖掘效率",
      ["x"] = 50
    }
  },
  [23] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 50,
      ["font_color"] = "255 255 255",
      ["y"] = 640,
      ["background_res"] = {hash = "Fj_ujvCUxZ1b01FklbHHMmMxOCJT", pid = "43480", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "挖掘速度",
      ["zorder"] = 2,
      ["height"] = 36,
      ["events"] = {},
      ["font_size"] = 25,
      ["type"] = "text",
      ["width"] = 100,
      ["name"] = "挖掘速度",
      ["align"] = "_lt"
    }
  },
  [24] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 50,
      ["font_color"] = "255 255 255",
      ["y"] = 680,
      ["background_res"] = {hash = "Fj_ujvCUxZ1b01FklbHHMmMxOCJT", pid = "43480", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "背包容量",
      ["zorder"] = 2,
      ["height"] = 36,
      ["events"] = {},
      ["font_size"] = 25,
      ["type"] = "text",
      ["width"] = 100,
      ["name"] = "背包容量",
      ["align"] = "_lt"
    }
  },
  [25] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["x"] = 160,
      ["y"] = 600,
      ["background_res"] = {hash = "FrzlUqszeg_ofu4pow26jp6QmfIx", pid = "43496", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "50000",
      ["zorder"] = 2,
      ["height"] = 36,
      ["events"] = {},
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["name"] = "挖掘效率的值",
      ["align"] = "_lt"
    }
  },
  [26] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 160,
      ["width"] = 200,
      ["y"] = 640,
      ["background_res"] = {hash = "FrzlUqszeg_ofu4pow26jp6QmfIx", pid = "43496", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "9999999",
      ["zorder"] = 2,
      ["height"] = 38,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["name"] = "挖掘速度的值",
      ["events"] = {}
    }
  },
  [27] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 160,
      ["width"] = 200,
      ["y"] = 680,
      ["background_res"] = {hash = "FrzlUqszeg_ofu4pow26jp6QmfIx", pid = "43496", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "88888888888",
      ["zorder"] = 2,
      ["height"] = 38,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["name"] = "背包容量的值",
      ["events"] = {}
    }
  },
  [28] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 134,
      ["y"] = 669,
      ["background_res"] = {hash = "FuJAHjIAsdC6CXVKfysPfmCSPVBP", pid = "43495", ext = "png"},
      ["parent"] = "bag",
      ["text"] = "",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["x"] = 583,
      ["type"] = "button",
      ["height"] = 58,
      ["name"] = "详情按钮",
      ["events"] = {},
      ["onclick"] = function()
        local item = {}
        item.mType = BagUI.mType
        item.mConfigIndex = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mConfigIndex
        item.mBagItemIndex = BagUI.mItemIndex
        if item.mType == "宠物框" then
          item.mName = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mName
          item.mRGB = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mRGB
          item.mLevel = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mLevel
          item.mExp = BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex].mExp
          PetInfoUI.show(item)
        else
          ItemInfoUI.show(item)
        end
      end
    }
  },
  [29] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 134,
      ["y"] = 669,
      ["clip"] = true,
      ["parent"] = "bag",
      ["zorder"] = 2,
      ["align"] = "_lt",
      ["x"] = 1217,
      ["type"] = "button",
      ["background_res"] = {hash = "Fqi5RM8joscvFwthwrk6Oc68uZ1e", pid = "43487", ext = "png"},
      ["name"] = "放生按钮",
      ["height"] = 58,
      ["onclick"] = function()
        DiscardUI[5].params.onclick = function()
          DiscardUI.close()
          Router.send("DiscardPet", {mID = GetPlayerId(), mBagItemIndex = BagUI.mItemIndex})
          if BagUI.mUIs then
            table.remove(BagUI.mBag[BagUI.mType].mItems, BagUI.mItemIndex)
            BagUI.mEquipAvatar.mPet = nil
            BagUI.mItemIndex = nil
            BagUI.refresh()
          end
        end
        DiscardUI.show(BagUI.mBag[BagUI.mType].mItems[BagUI.mItemIndex])
      end
    }
  },
  [30] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["y"] = 36,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "X ",
      ["zorder"] = 3,
      ["x"] = 55,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 40,
      ["name"] = "当前跳跃加成总和"
    }
  },
  [31] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["y"] = 85,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "X ",
      ["zorder"] = 3,
      ["font_color"] = "255 255 255",
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["x"] = 55,
      ["height"] = 36,
      ["name"] = "当前速度加成总和"
    }
  },
  [32] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 39,
      ["y"] = 130,
      ["clip"] = true,
      ["parent"] = "换装预览窗口底图",
      ["zorder"] = 2,
      ["x"] = 13,
      ["align"] = "_lt",
      ["name"] = "挖掘效率buff的icon",
      ["type"] = "container",
      ["background_res"] = {hash = "FkK-pip5fQvPit6RCldzcgyRrjdl", pid = "52949", ext = "png"},
      ["height"] = 41,
      ["events"] = {},
      ["onmouseenter"] = function()
        BagUI.mUIs[BagUI[38].params.name].visible = true
      end,
      ["onmouseleave"] = function()
        BagUI.mUIs[BagUI[38].params.name].visible = false
      end
    }
  },
  [33] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 39,
      ["y"] = 177,
      ["clip"] = true,
      ["parent"] = "换装预览窗口底图",
      ["zorder"] = 2,
      ["x"] = 13,
      ["align"] = "_lt",
      ["name"] = "矿石价值buff的icon",
      ["type"] = "container",
      ["background_res"] = {hash = "FucobnjHKwnvfrszkwZlCv9A0WMo", pid = "52948", ext = "png"},
      ["height"] = 42,
      ["events"] = {},
      ["onmouseenter"] = function()
        BagUI.mUIs[BagUI[39].params.name].visible = true
      end,
      ["onmouseleave"] = function()
        BagUI.mUIs[BagUI[39].params.name].visible = false
      end
    }
  },
  [34] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["y"] = 130,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "X ",
      ["zorder"] = 3,
      ["x"] = 55,
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["font_color"] = "255 255 255",
      ["height"] = 40,
      ["name"] = "当前挖掘效率加成总和"
    }
  },
  [35] = {
    ["type"] = "ui",
    ["params"] = {
      ["width"] = 200,
      ["y"] = 177,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "X ",
      ["zorder"] = 3,
      ["font_color"] = "255 255 255",
      ["align"] = "_lt",
      ["font_size"] = 25,
      ["type"] = "text",
      ["x"] = 55,
      ["height"] = 36,
      ["name"] = "当前矿石价值加成总和"
    }
  },
  [36] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 50,
      ["text_format"] = 1,
      ["y"] = 30,
      ["height"] = 40,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "弹跳力加成",
      ["zorder"] = 8,
      ["width"] = 200,
      ["align"] = "_lt",
      ["font_size"] = 20,
      ["type"] = "text",
      ["events"] = {},
      ["name"] = "弹跳力tips",
      ["background_res"] = {hash = "Fsm20EortYXqQlQn-ZsD0DTrQrSv", pid = "52808", ext = "png"},
      ["font_color"] = "0 0 0"
    }
  },
  [37] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 50,
      ["text_format"] = 1,
      ["y"] = 77,
      ["height"] = 40,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "速度加成",
      ["zorder"] = 8,
      ["width"] = 150,
      ["align"] = "_lt",
      ["font_size"] = 20,
      ["type"] = "text",
      ["events"] = {},
      ["name"] = "速度tips",
      ["background_res"] = {hash = "Fsm20EortYXqQlQn-ZsD0DTrQrSv", pid = "52808", ext = "png"},
      ["font_color"] = "0 0 0"
    }
  },
  [38] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 50,
      ["text_format"] = 1,
      ["y"] = 124,
      ["height"] = 40,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "挖掘效率加成",
      ["zorder"] = 8,
      ["width"] = 150,
      ["align"] = "_lt",
      ["font_size"] = 20,
      ["type"] = "text",
      ["events"] = {},
      ["name"] = "挖掘效率tips",
      ["background_res"] = {hash = "Fsm20EortYXqQlQn-ZsD0DTrQrSv", pid = "52808", ext = "png"},
      ["font_color"] = "0 0 0"
    }
  },
  [39] = {
    ["type"] = "ui",
    ["params"] = {
      ["x"] = 50,
      ["text_format"] = 1,
      ["y"] = 171,
      ["height"] = 40,
      ["parent"] = "换装预览窗口底图",
      ["text"] = "矿石价值加成",
      ["zorder"] = 8,
      ["width"] = 150,
      ["align"] = "_lt",
      ["font_size"] = 20,
      ["type"] = "text",
      ["events"] = {},
      ["name"] = "矿石价值tips",
      ["background_res"] = {hash = "Fsm20EortYXqQlQn-ZsD0DTrQrSv", pid = "52808", ext = "png"},
      ["font_color"] = "0 0 0"
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

function BagUI.show(bag)
  BagUI.mBag = bag or {}
  BagUI.mEquipAvatar = {}
  BagUI.mUIs = {}
  for _, cfg in ipairs(BagUI) do
    if cfg.params.name ~= "单个道具底框" and cfg.params.parent ~= "单个道具底框" then
      local cfg_cpy = clone(cfg)
      cfg_cpy.params.name = "BagUI/" .. cfg_cpy.params.name
      cfg_cpy.params.parent = BagUI.mUIs[cfg.params.parent]
      cfg_cpy.params.align = cfg.params.align or "_lt"
      local ui = CreateUI(cfg_cpy.params)
      BagUI.mUIs[cfg.params.name] = ui
      if cfg.params.background_res then
        GetResourceImage(
          cfg.params.background_res,
          function(path, err)
            ui.background = path
          end
        )
      end
    end
  end

  for i = 36, 39 do
    BagUI.mUIs[BagUI[i].params.name].visible = false
  end

  BagUI.mMiniScene = CreateMiniScene("DigAHole/Bag", 512, 512)
  BagUI.mMiniScene:addMiniGameUI({mInternal = BagUI.mUIs["换装角色模型预览"]()})
  BagUI.mMiniScene:setCameraLookAtPosition(0, 1.5, 10)
  BagUI.mMiniScene:setCameraPosition(0, 0, -3.5)

  BagUI.onClickType("工具框")
end

function BagUI.close()
  if BagUI.mMiniScene then
    if BagUI.mAvatarEntity then
      BagUI.mAvatarEntity:SetDead(true)
    end
    BagUI.mAvatarEntity = nil
    DestroyMiniScene("DigAHole/Bag")
    BagUI.mMiniScene = nil
    BagUI.mUIs[BagUI[1].params.name]:destroy()
    BagUI.mUIs = nil
    BagUI.mItemGridView = nil
    BagUI.mEquipAvatar = nil
    BagUI.mEquipTool = nil
    BagUI.mEquipBag = nil
  end
end

function BagUI.refresh()
  if not BagUI.mUIs then
    return
  end
  local item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == BagUI.mType then
      item_list = list.mItems
      break
    end
  end
  BagUI.mItemGridView =
    BagUI.mItemGridView or
    CreateUI(
      {
        ext = "TABLE",
        type = "container",
        x = 0,
        y = 0,
        width = 920,
        height = 525,
        stride = 7,
        item_width = 115,
        item_height = 165,
        margin = 5,
        align = "_lt",
        parent = BagUI.mUIs["道具列表框"]
      }
    )
  BagUI.mItemGridView:reset()
  local configs
  if BagUI.mType == "工具框" then
    configs = Config.Tool
  elseif BagUI.mType == "背包框" then
    configs = Config.Bag
  elseif BagUI.mType == "头部框" then
    configs = Config.Avatar.Head
  elseif BagUI.mType == "上身框" then
    configs = Config.Avatar.Body
  elseif BagUI.mType == "下身框" then
    configs = Config.Avatar.Leg
  elseif BagUI.mType == "礼物盒框" then
    configs = Config.Box
  elseif BagUI.mType == "宠物框" then
    configs = Config.Avatar.Pet
  end
  for i, item in pairs(item_list) do
    local item_ui
    BagUI.mItemGridView:addItem(
      function(parent)
        for _, cfg in ipairs(BagUI) do
          local skip
          if cfg.params.name ~= "单个道具底框" and cfg.params.parent ~= "单个道具底框" then
            skip = true
          end
          if cfg.params.name == "目前装备着的道具" and not item.mEquiped then
            skip = true
          end
          if not skip then
            local cfg_cpy = clone(cfg)
            cfg_cpy.params.align = cfg.params.align or "_lt"
            local is_item
            if cfg.params.name == "单个道具底框" then
              cfg_cpy.params.parent = parent
              is_item = true
            else
              cfg_cpy.params.parent = item_ui
              if cfg.params.name == "展示道具的名字" then
                cfg_cpy.params.text = item.mName or configs[item.mConfigIndex].mDefaceName
              end
            end
            cfg_cpy.params.name = cfg.params.name .. "/" .. tostring(i)
            local ui = CreateUI(cfg_cpy.params)
            if is_item then
              item_ui = ui
            end
            if cfg.params.name == "道具展示图" then
              if configs[item.mConfigIndex].mIcon then
                if configs[item.mConfigIndex].mIcon.mResource then
                  GetResourceImage(
                    configs[item.mConfigIndex].mIcon.mResource,
                    function(path, err)
                      ui.background = path
                    end
                  )
                else
                  ui.background = configs[item.mConfigIndex].mIcon.mFile
                end
              end
            else
              local background_res = cfg.params.background_res
              if BagUI.mItemIndex == i then
                background_res = cfg.params.background_res_on or background_res
              end
              if background_res then
                GetResourceImage(
                  background_res,
                  function(path, err)
                    ui.background = path
                  end
                )
              end
            end
          end
        end
      end
    )
    for _, cfg in ipairs(BagUI) do
      local cfg_cpy = clone(cfg)
      if cfg_cpy.params.name == "单个道具底框" then
        cfg_cpy.params.parent = item_ui
        cfg_cpy.params.x = 0
        cfg_cpy.params.y = 0
        cfg_cpy.params.type = "button"
        cfg_cpy.params.name = cfg.params.name .. "/" .. tostring(i) .. "/button"
        cfg_cpy.params.background = ""
        local ui = CreateUI(cfg_cpy.params)
        ui.onclick = function()
          BagUI.onClickItem(i)
        end
        break
      end
    end
  end

  if BagUI.mAvatarEntity then
    BagUI.mMiniScene:removeEntity(BagUI.mAvatarEntity)
    BagUI.mAvatarEntity:SetDead(true)
    BagUI.mAvatarEntity = nil
  end

  local power_addition = 1
  local speed_addition = 1
  local jump_addition = 1
  local price_addition = 1

  local item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == "头部框" then
      item_list = list.mItems
      break
    end
  end
  local equiped_head = Config.Avatar.Head[1]
  for _, item in pairs(item_list) do
    if item.mEquiped then
      equiped_head = Config.Avatar.Head[item.mConfigIndex]
      break
    end
  end
  if BagUI.mEquipAvatar.mHead then
    equiped_head = Config.Avatar.Head[item_list[BagUI.mEquipAvatar.mHead].mConfigIndex]
  end
  power_addition = power_addition * (equiped_head.mPowerAddition or 1)
  speed_addition = speed_addition * (equiped_head.mSpeed or 1)
  jump_addition = jump_addition * (equiped_head.mJump or 1)
  price_addition = price_addition * (equiped_head.mOreValue or 1)

  BagUI.mAvatarEntity =
    CreateNPC({bx = 0, by = 0, bz = 0, item_id = 10062, can_random_move = false, mDisableSync = true})
  BagUI.mAvatarEntity._super.SetMainAssetPath(BagUI.mAvatarEntity, "")
  BagUI.mAvatarEntity._super.SetMainAssetPath(BagUI.mAvatarEntity, equiped_head.mModel.mFiles[1])
  if equiped_head.mTexture and equiped_head.mTexture.mFiles[1] then
    SetReplaceableTexture(BagUI.mAvatarEntity, equiped_head.mTexture.mFiles[1])
  end
  BagUI.mAvatarEntity:SetPosition(0, -0.5, 0)
  BagUI.mAvatarEntity:SetFacing(0.8)
  BagUI.mMiniScene:addEntity(BagUI.mAvatarEntity)

  item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == "上身框" then
      item_list = list.mItems
      break
    end
  end
  local equiped_body = Config.Avatar.Body[1]
  for _, item in pairs(item_list) do
    if item.mEquiped then
      equiped_body = Config.Avatar.Body[item.mConfigIndex]
      break
    end
  end
  if BagUI.mEquipAvatar.mBody then
    equiped_body = Config.Avatar.Body[item_list[BagUI.mEquipAvatar.mBody].mConfigIndex]
  end
  if equiped_body.mModel then
    if equiped_body.mModel.mFiles then
      for k, file in pairs(equiped_body.mModel.mFiles) do
        if equiped_body.mTexture then
          AddCustomAvatarComponent(file, BagUI.mAvatarEntity, equiped_body.mTexture.mFiles[k])
        else
          AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
        end
      end
    end
    if equiped_body.mModel.mResources then
      for k, res in pairs(equiped_body.mModel.mResources) do
        GetResourceModel(
          res,
          function(path, err)
            AddCustomAvatarComponent(path, BagUI.mAvatarEntity)
          end
        )
      end
    end
  end
  power_addition = power_addition * (equiped_body.mPowerAddition or 1)
  speed_addition = speed_addition * (equiped_body.mSpeed or 1)
  jump_addition = jump_addition * (equiped_body.mJump or 1)
  price_addition = price_addition * (equiped_body.mOreValue or 1)

  item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == "下身框" then
      item_list = list.mItems
      break
    end
  end
  local equiped_leg = Config.Avatar.Leg[1]
  for _, item in pairs(item_list) do
    if item.mEquiped then
      equiped_leg = Config.Avatar.Leg[item.mConfigIndex]
      break
    end
  end
  if BagUI.mEquipAvatar.mLeg then
    equiped_leg = Config.Avatar.Leg[item_list[BagUI.mEquipAvatar.mLeg].mConfigIndex]
  end
  if equiped_leg.mModel then
    if equiped_leg.mModel.mFiles then
      for k, file in pairs(equiped_leg.mModel.mFiles) do
        if equiped_leg.mTexture then
          AddCustomAvatarComponent(file, BagUI.mAvatarEntity, equiped_leg.mTexture.mFiles[k])
        else
          AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
        end
      end
    end
    if equiped_leg.mModel.mResources then
      for _, res in pairs(equiped_leg.mModel.mResources) do
        GetResourceModel(
          res,
          function(path, err)
            AddCustomAvatarComponent(path, BagUI.mAvatarEntity)
          end
        )
      end
    end
  end
  power_addition = power_addition * (equiped_leg.mPowerAddition or 1)
  speed_addition = speed_addition * (equiped_leg.mSpeed or 1)
  jump_addition = jump_addition * (equiped_leg.mJump or 1)
  price_addition = price_addition * (equiped_leg.mOreValue or 1)

  item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == "宠物框" then
      item_list = list.mItems
      break
    end
  end
  local equiped_pet = nil
  local equiped_pet_item = nil
  for _, item in pairs(item_list) do
    if item.mEquiped then
      equiped_pet = Config.Avatar.Pet[item.mConfigIndex]
      equiped_pet_item = item
      break
    end
  end
  if BagUI.mEquipAvatar.mPet then
    equiped_pet = Config.Avatar.Pet[item_list[BagUI.mEquipAvatar.mPet].mConfigIndex]
    equiped_pet_item = item_list[BagUI.mEquipAvatar.mPet]
  end
  if equiped_pet and equiped_pet.mModel then
    if equiped_pet.mTexture then
      if equiped_pet.mTexture.mFile then
        if equiped_pet.mModel.mFile then
          AddAttachment(equiped_pet.mModel.mFile, 29, BagUI.mAvatarEntity, nil, equiped_pet.mTexture.mFile)
        end
        if equiped_pet.mModel.mResource then
          GetResourceModel(
            equiped_pet.mModel.mResource,
            function(path, err)
              AddAttachment(path, 29, BagUI.mAvatarEntity, nil, equiped_pet.mTexture.mFile)
            end
          )
        end
      elseif equiped_pet.mTexture.mResource then
        GetResourceImage(
          equiped_pet.mTexture.mResource,
          function(path, err)
            if equiped_pet.mModel.mFile then
              AddAttachment(equiped_pet.mModel.mFile, 29, BagUI.mAvatarEntity, nil, path)
            end
            if equiped_pet.mModel.mResource then
              GetResourceModel(
                equiped_pet.mModel.mResource,
                function(path, err)
                  AddAttachment(path, 29, BagUI.mAvatarEntity, nil, path)
                end
              )
            end
          end
        )
      end
    else
      if equiped_pet.mModel.mFile then
        AddAttachment(equiped_pet.mModel.mFile, 29, BagUI.mAvatarEntity)
      end
      if equiped_pet.mModel.mResource then
        GetResourceModel(
          equiped_pet.mModel.mResource,
          function(path, err)
            AddAttachment(path, 29, BagUI.mAvatarEntity)
          end
        )
      end
    end
    local pet_buffs = GlobalFunction.parsePetRGB(equiped_pet_item.mRGB)
    local additions = GlobalFunction.getPetLevelAddition(equiped_pet_item.mLevel)
    if pet_buffs["挖掘效率"] then
      power_addition = power_addition * additions["挖掘效率"][pet_buffs["挖掘效率"]]
    end
    if pet_buffs["移动速度"] then
      speed_addition = speed_addition * additions["移动速度"][pet_buffs["移动速度"]]
    end
    if pet_buffs["跳跃"] then
      jump_addition = jump_addition * additions["跳跃"][pet_buffs["跳跃"]]
    end
    if pet_buffs["矿石价值"] then
      price_addition = price_addition * additions["矿石价值"][pet_buffs["矿石价值"]]
    end
  end

  local equiped_hand = Config.Avatar.Hand[1]
  for _, file in pairs(equiped_hand.mModel.mFiles) do
    AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
  end

  local equiped_foot = Config.Avatar.Foot[1]
  for _, file in pairs(equiped_foot.mModel.mFiles) do
    AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
  end

  local equiped_eye = Config.Avatar.Eye[1]
  SetReplaceableTexture(BagUI.mAvatarEntity, equiped_eye.mTexture.mFile, 3)

  local equiped_mouth = Config.Avatar.Mouth[1]
  SetReplaceableTexture(BagUI.mAvatarEntity, equiped_mouth.mTexture.mFile, 4)

  item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == "工具框" then
      item_list = list.mItems
      break
    end
  end
  local equiped_tool = Config.Tool[1]
  for _, item in pairs(item_list) do
    if item.mEquiped then
      equiped_tool = Config.Tool[item.mConfigIndex]
      break
    end
  end
  if BagUI.mEquipTool then
    equiped_tool = Config.Tool[item_list[BagUI.mEquipTool].mConfigIndex]
  end
  if equiped_tool.mModel then
    if equiped_tool.mModel.mFiles then
      for _, file in pairs(equiped_tool.mModel.mFiles) do
        AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
      end
    end
    if equiped_tool.mModel.mResources then
      for _, res in pairs(equiped_tool.mModel.mResources) do
        GetResourceModel(
          res,
          function(path, err)
            AddCustomAvatarComponent(path, BagUI.mAvatarEntity)
          end
        )
      end
    end
  end
  if string.find(equiped_tool.mName, "镐子") then
    BagUI.mAvatarEntity:SetAnimation(171)
  elseif string.find(equiped_tool.mName, "手枪") then
    BagUI.mAvatarEntity:SetAnimation(185)
  elseif string.find(equiped_tool.mName, "斧子") then
    BagUI.mAvatarEntity:SetAnimation(175)
  elseif string.find(equiped_tool.mName, "冲锋枪") then
    BagUI.mAvatarEntity:SetAnimation(189)
  elseif string.find(equiped_tool.mName, "剑") then
    BagUI.mAvatarEntity:SetAnimation(171)
  end

  item_list = {}
  for _, list in pairs(BagUI.mBag) do
    if list.mType == "背包框" then
      item_list = list.mItems
      break
    end
  end
  local equiped_bag = Config.Bag[1]
  for _, item in pairs(item_list) do
    if item.mEquiped then
      equiped_bag = Config.Bag[item.mConfigIndex]
      break
    end
  end
  if BagUI.mEquipBag then
    equiped_bag = Config.Bag[item_list[BagUI.mEquipBag].mConfigIndex]
  end
  if equiped_bag.mModel then
    if equiped_bag.mModel.mFiles then
      for _, file in pairs(equiped_bag.mModel.mFiles) do
        AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
      end
    end
    if equiped_bag.mModel.mResources then
      for _, res in pairs(equiped_bag.mModel.mResources) do
        GetResourceModel(
          res,
          function(path, err)
            AddCustomAvatarComponent(path, BagUI.mAvatarEntity)
          end
        )
      end
    end
  end

  price_addition = price_addition * (1 + BagUI.mBag.mRelifeTime / 100)

  local unused_keys = {}
  if equiped_head.mUnuseds then
    for _, unused in pairs(equiped_head.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_tool.mUnuseds then
    for _, unused in pairs(equiped_tool.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_bag.mUnuseds then
    for _, unused in pairs(equiped_bag.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_body.mUnuseds then
    for _, unused in pairs(equiped_body.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_leg.mUnuseds then
    for _, unused in pairs(equiped_leg.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_hand.mUnuseds then
    for _, unused in pairs(equiped_hand.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_foot.mUnuseds then
    for _, unused in pairs(equiped_foot.mUnuseds) do
      unused_keys[unused.mKey] = true
    end
  end
  if equiped_head.mOptionals then
    for _, optional in pairs(equiped_head.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end
  if equiped_tool.mOptionals then
    for _, optional in pairs(equiped_tool.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end
  if equiped_bag.mOptionals then
    for _, optional in pairs(equiped_bag.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end
  if equiped_body.mOptionals then
    for _, optional in pairs(equiped_body.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end
  if equiped_leg.mOptionals then
    for _, optional in pairs(equiped_leg.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end
  if equiped_hand.mOptionals then
    for _, optional in pairs(equiped_hand.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end
  if equiped_foot.mOptionals then
    for _, optional in pairs(equiped_foot.mOptionals) do
      if not unused_keys[optional.mKey] then
        for k, file in pairs(optional.mModel.mFiles) do
          if optional.mTexture then
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity, optional.mTexture.mFiles[k])
          else
            AddCustomAvatarComponent(file, BagUI.mAvatarEntity)
          end
        end
      end
    end
  end

  BagUI.mUIs["挖掘效率的值"].text = tostring(math.floor(equiped_tool.mBuff["挖掘力量"] * power_addition))
  BagUI.mUIs["挖掘速度的值"].text = tostring(equiped_tool.mBuff["挖掘速度"])
  BagUI.mUIs["背包容量的值"].text = tostring(equiped_bag.mBuff["背包容量"])
  BagUI.mUIs["当前跳跃加成总和"].text = "X " .. tostring(jump_addition * 100) .. "%"
  BagUI.mUIs["当前速度加成总和"].text = "X " .. tostring(speed_addition * 100) .. "%"
  BagUI.mUIs["当前挖掘效率加成总和"].text = "X " .. tostring(power_addition * 100) .. "%"
  BagUI.mUIs["当前矿石价值加成总和"].text = "X " .. tostring(price_addition * 100) .. "%"

  if BagUI.mItemIndex then
    local item_list = {}
    for _, list in pairs(BagUI.mBag) do
      if list.mType == BagUI.mType then
        item_list = list.mItems
        break
      end
    end
    local item = item_list[BagUI.mItemIndex]

    local config
    for _, cfg in ipairs(BagUI) do
      if cfg.params.name == "装备按钮" then
        config = cfg.params
        break
      end
    end
    local res, res_on
    if BagUI.mType == "工具框" or BagUI.mType == "背包框" then
      res = {hash = "FjjQF3tR_dOXmyn21F5X1INdM7eE", pid = "43488", ext = "png"}
      res_on = {hash = "FkunaW31FT8xiSM0th8sqpsJpB6f", pid = "43491", ext = "png"}
      BagUI.mUIs["详情按钮"].visible = true
    elseif BagUI.mType == "头部框" or BagUI.mType == "上身框" or BagUI.mType == "下身框" then
      res = {hash = "FjjQF3tR_dOXmyn21F5X1INdM7eE", pid = "43488", ext = "png"}
      res_on = {hash = "FjiuCGYbMkH7JThZABRxrtzTs93z", pid = "43489", ext = "png"}
      BagUI.mUIs["详情按钮"].visible = true
    elseif BagUI.mType == "礼物盒框" then
      res = {hash = "Fg3tlQHFgxEHN3AB2RDKDjgNZM-a", pid = "43494", ext = "png"}
      res_on = {hash = "Fg3tlQHFgxEHN3AB2RDKDjgNZM-a", pid = "43494", ext = "png"}
    elseif BagUI.mType == "宠物框" then
      res = {hash = "FokBnixyw7K0cIKO7VF0RN9U_lWC", pid = "43492", ext = "png"}
      res_on = {hash = "FuH8rKKz3bWOeAcsolrbFnmBsUeW", pid = "43493", ext = "png"}
      BagUI.mUIs["详情按钮"].visible = true
      BagUI.mUIs["放生按钮"].visible = true
    end
    if item.mEquiped then
      GetResourceImage(
        res_on,
        function(path, err)
          BagUI.mUIs["装备按钮"].visible = true
          BagUI.mUIs["装备按钮"].background = path
        end
      )
    else
      GetResourceImage(
        res,
        function(path, err)
          BagUI.mUIs["装备按钮"].visible = true
          BagUI.mUIs["装备按钮"].background = path
        end
      )
    end
  else
    BagUI.mUIs["详情按钮"].visible = false
    BagUI.mUIs["放生按钮"].visible = false
    BagUI.mUIs["装备按钮"].visible = false
  end
end

function BagUI.onClickType(type)
  if BagUI.mType then
    local config
    for _, cfg in ipairs(BagUI) do
      if cfg.params.name == BagUI.mType then
        config = cfg.params
        break
      end
    end
    GetResourceImage(
      config.background_res,
      function(path, err)
        BagUI.mUIs[BagUI.mType].background = path
      end
    )
  end
  BagUI.mType = type
  local config
  for _, cfg in ipairs(BagUI) do
    if cfg.params.name == BagUI.mType then
      config = cfg.params
      break
    end
  end
  GetResourceImage(
    config.background_res_on,
    function(path, err)
      BagUI.mUIs[BagUI.mType].background = path
    end
  )

  BagUI.mItemIndex = nil
  BagUI.refresh()
end

function BagUI.onClickItem(index)
  BagUI.mItemIndex = index

  if BagUI.mType == "工具框" then
    BagUI.mEquipTool = BagUI.mItemIndex
  elseif BagUI.mType == "背包框" then
    BagUI.mEquipBag = BagUI.mItemIndex
  elseif BagUI.mType == "头部框" then
    BagUI.mEquipAvatar.mHead = BagUI.mItemIndex
  elseif BagUI.mType == "上身框" then
    BagUI.mEquipAvatar.mBody = BagUI.mItemIndex
  elseif BagUI.mType == "下身框" then
    BagUI.mEquipAvatar.mLeg = BagUI.mItemIndex
  elseif BagUI.mType == "礼物盒框" then
  elseif BagUI.mType == "宠物框" then
    BagUI.mEquipAvatar.mPet = BagUI.mItemIndex
  end

  BagUI.refresh()
end
