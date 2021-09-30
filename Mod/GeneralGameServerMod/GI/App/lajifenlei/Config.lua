
--[[
Title: Config
Author(s):  wxa
Date: 2021-06-01
Desc: 配置信息
use the lib:
]]

local Config = module();

local GARBAGE_CATEGORY_CHUYU = 0;         -- 厨余垃圾
local GARBAGE_CATEGORY_YOUHAI = 1;        -- 有害垃圾
local GARBAGE_CATEGORY_KEHUISHOU = 2;     -- 可回收垃圾
local GARBAGE_CATEGORY_QITA = 3;          -- 其它垃圾

Config.GARBAGE_CATEGORY = {
    CHUYU = GARBAGE_CATEGORY_CHUYU,
    YOUHAI = GARBAGE_CATEGORY_YOUHAI,
    KEHUISHOU = GARBAGE_CATEGORY_KEHUISHOU,
    QITA = GARBAGE_CATEGORY_QITA,
}
Config.GARBAGE_CATEGORY_SIZE = 4;

Config.TRASH_CFG = {
    [GARBAGE_CATEGORY_CHUYU] = {
        assetfile = "character/CC/keepwork/lajitong/lajitong_chuyu.x",
        name = "chuyu",
        label = "厨余垃圾箱",
    },
    [GARBAGE_CATEGORY_YOUHAI] = {
        assetfile = "character/CC/keepwork/lajitong/lajitong_youhai.x",
        name = "youhai",
        label = "有害垃圾箱",
    },
    [GARBAGE_CATEGORY_KEHUISHOU] = {
        assetfile = "character/CC/keepwork/lajitong/lajitong_kehuishou.x",
        name = "kehuishou",
        label = "可回收垃圾箱",
    },
    [GARBAGE_CATEGORY_QITA] = {
        assetfile = "character/CC/keepwork/lajitong/lajitong_qita.x",
        name = "其它",
        label = "其它垃圾箱",
    },
}

Config.CATEGORY_LIST = {
    {   
        name = "caiyezi",
        label = "菜叶子",
        assetfile = "character/CC/keepwork/laji/cy_caiyezi.x",
        category = GARBAGE_CATEGORY_CHUYU,
    },
    {   
        name = "canzhiluoye",
        label = "残枝落叶",
        assetfile = "character/CC/keepwork/laji/cy_canzhiluoye.x",
        category = GARBAGE_CATEGORY_CHUYU,
    },
    {   
        name = "dagu",
        label = "大骨",
        assetfile = "character/CC/keepwork/laji/cy_dagu.x",
        category = GARBAGE_CATEGORY_CHUYU,
    },
    {   
        name = "guohe",
        label = "果核",
        assetfile = "character/CC/keepwork/laji/cy_guohe.x",
        category = GARBAGE_CATEGORY_CHUYU,
    },
    {   
        name = "xiangjiaopi",
        label = "香蕉皮",
        assetfile = "character/CC/keepwork/laji/cy_xiangjiaopi.x",
        category = GARBAGE_CATEGORY_CHUYU,
    },

    {   
        name = "bolipin",
        label = "玻璃瓶",
        assetfile = "character/CC/keepwork/laji/khs_bolipin.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "hezi",
        label = "盒子",
        assetfile = "character/CC/keepwork/laji/khs_hezi.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "jylg",
        label = "卷状易拉罐",
        assetfile = "character/CC/keepwork/laji/khs_jylg.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "luomu",
        label = "螺母",
        assetfile = "character/CC/keepwork/laji/khs_luomu.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "luosi",
        label = "螺丝",
        assetfile = "character/CC/keepwork/laji/khs_luosi.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "ylg",
        label = "易拉罐",
        assetfile = "character/CC/keepwork/laji/khs_ylg.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "yugu",
        label = "鱼骨",
        assetfile = "character/CC/keepwork/laji/khs_yugu.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },
    {   
        name = "zhixiang",
        label = "纸箱",
        assetfile = "character/CC/keepwork/laji/khs_zhixiang.x",
        category = GARBAGE_CATEGORY_KEHUISHOU,
    },

    {   
        name = "fanhe",
        label = "饭盒",
        assetfile = "character/CC/keepwork/laji/qt_fanhe.x",
        category = GARBAGE_CATEGORY_QITA,
    },
    {   
        name = "taoci",
        label = "陶瓷",
        assetfile = "character/CC/keepwork/laji/qt_taoci.x",
        category = GARBAGE_CATEGORY_QITA,
    },
    {   
        name = "yantou",
        label = "烟头",
        assetfile = "character/CC/keepwork/laji/qt_yantou.x",
        category = GARBAGE_CATEGORY_QITA,
    },
    {   
        name = "zhijin",
        label = "纸巾",
        assetfile = "character/CC/keepwork/laji/qt_zhijin.x",
        category = GARBAGE_CATEGORY_QITA,
    },
    
    {   
        name = "dianchi",
        label = "电池",
        assetfile = "character/CC/keepwork/laji/yh_dianchi.x",
        category = GARBAGE_CATEGORY_YOUHAI,
    },
    {   
        name = "huazhuangpin",
        label = "化妆品",
        assetfile = "character/CC/keepwork/laji/yh_huazhuangpin.x",
        category = GARBAGE_CATEGORY_YOUHAI,
    },
    {   
        name = "yaopin",
        label = "药品",
        assetfile = "character/CC/keepwork/laji/yh_yaopin.x",
        category = GARBAGE_CATEGORY_YOUHAI,
    },
    {   
        name = "youqitong",
        label = "油漆桶",
        assetfile = "character/CC/keepwork/laji/yh_youqitong.x",
        category = GARBAGE_CATEGORY_YOUHAI,
    },
}

