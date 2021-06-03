-- 人物属性说明
-- power: 一次成功挖掘能获取的最大数量， grade：能挖掘的矿物等级, speed：挖掘的速度, carryAmount: 携带矿的数量, carryMoney：待出售的矿物总价 , capacity：背包最大可携带的数量
local ProtectedData = require("ProtectedData")

local version = 0.2 -- 当前游戏版本
local minVersion = 0.1 -- 最低版本要求限制，主要用于限制存档

local Player = GetPlayer()
local isServer = (Player.name == "__MP__admin")
local cameraMode = 0
local cameradist_default_mode_0, cameradist_default_mode_1 = 3, 10
local cameradist = cameradist_default_mode_0
local keyPressed = {}
local GUI = require("GUI")
local Repository = require("Repository")
local Particle = require("Particle")
local homeX, homeY, homeZ = ConvertToBlockIndex(GetHomePosition())
local mousePressing_left
local selectBlockColor = {right = 0, wrong = 3}
local canQuickMove = true
local playerScaling = 0.45
local Server = {
    playerInfo = {},
    npcs = {},
    blockData = {},
    blockData_temp = {},
    miningTime = {},
    version = version,
    minVersion = minVersion,
    currentBGM = nil
}
local Client = {players = {}, npcs = {}, blockData = {}, playerInfo = ProtectedData:new(GetSavedData() or {}, 1), miningInfo = {},currentBGM = nil}
local PublicFunction = {}
function PublicFunction.getBagItemList(bag, bagType)
    for _, items in pairs(bag) do
        if items.mType == bagType then
            return items
        end
    end
end
local defaultPlayerInfo = {
    toolGrade = 1,
    bagGrade = 1,
    carryAmount = 0,
    carryMoney = 0,
    capacity = 10,
    money = 0,
    blockMined = 0,
    version = Server.version,
    purchased = {tool = {[1] = true}, bag = {[1] = true}}
}
local rankName = {
    [0] = "刨土工",
    [100] = "挖沙工",
    [500] = "采石工",
    [2000] = "初级矿工",
    [10000] = "中级矿工",
    [50000] = "高级矿工",
    [300000] = "矿场监工",
    [500000] = "矿场主任",
    [1000000] = "地质勘察者",
    [2000000] = "考古专家",
    [5000000] = "家里有矿",
    [55000000] = "石油王子",
    [250000000] = "富可敌国",
    [1000000000] = "头号砖家",
    [10000000000] = "突破天际",
}
local grade = {
    toolGrade = {
        [1] = {price = 0, speed = 1, power = 1},
        -- [1] = {price = 0, speed = 100000, power = 1000000},
        [2] = {price = 25, speed = 2, power = 2},
        [3] = {price = 75, speed = 2, power = 3},
        [4] = {price = 250, speed = 3, power = 5},
        [5] = {price = 600, speed = 5, power = 7},
        [6] = {price = 2000, speed = 5, power = 10},
        [7] = {price = 3500, speed = 6, power = 12},
        [8] = {price = 6000, speed = 6, power = 15},
        [9] = {price = 8500, speed = 10, power = 18},
        [10] = {price = 12000, speed = 12, power = 18},
        [11] = {price = 32000, speed = 8, power = 30},
        [12] = {price = 78000, speed = 12, power = 40},
        [13] = {price = 100000, speed = 12, power = 60},
        [14] = {price = 120000, speed = 15, power = 50},
        [15] = {price = 400000, speed = 20, power = 60},
        [16] = {price = 500000, speed = 30, power = 50},
        [17] = {price = 600000, speed = 30, power = 75},
        [18] = {price = 800000, speed = 40, power = 100},
        [19] = {price = 1000000, speed = 50, power = 125},
        [20] = {price = 2000000, speed = 75, power = 150},
        [21] = {price = 2500000, speed = 100, power = 200},
        [22] = {price = 3500000, speed = 200, power = 150},
        [23] = {price = 5000000, speed = 200, power = 300},
        [24] = {price = 8000000, speed = 175, power = 450},
        [25] = {price = 12500000, speed = 250, power = 600},
        [26] = {price = 20000000, speed = 300, power = 1000},
        [27] = {price = 30000000, speed = 400, power = 1000},
        [28] = {price = 50000000, speed = 300, power = 2000},
        [29] = {price = 75000000, speed = 350, power = 2000},
        [30] = {price = 100000000, speed = 350, power = 2500},
        [31] = {price = 200000000, speed = 400, power = 3000},
        [32] = {price = 500000000, speed = 500, power = 3500},
        [33] = {price = 1500000000, speed = 550, power = 5000},
        [34] = {price = 3000000000, speed = 580, power = 6000},
        [35] = {price = 6000000000, speed = 600, power = 8000},
        [36] = {price = 11111111111, speed = 620, power = 12000},
        [37] = {price = 23333333333, speed = 680, power = 17000},
        [38] = {price = 40000000000, speed = 730, power = 23000},
        [39] = {price = 80000000000, speed = 780, power = 29000},
        [40] = {price = 233333333333, speed = 850, power = 35000},
        [41] = {price = 555555555555, speed = 900, power = 45000},
        [42] = {price = 999999999999, speed = 1000, power = 50000},
        [43] = {price = 2555555555555, speed = 2500, power = 10000},
        [44] = {price = 5555555555555, speed = 1100, power = 60000},
        [45] = {price = 9999999999999, speed = 1200, power = 70000},
        -- [42] = {price = 9, speed = 9000, power = 18000000},
    },
    bagGrade = {
        [1] = {price = 0, capacity = 10},
        -- [1] = {price = 0, capacity = 100000000},
        [2] = {price = 20, capacity = 20},
        [3] = {price = 300, capacity = 40},
        [4] = {price = 1000, capacity = 75},
        [5] = {price = 3500, capacity = 100},
        [6] = {price = 5000, capacity = 200},
        [7] = {price = 7500, capacity = 350},
        [8] = {price = 15000, capacity = 500},
        [9] = {price = 25000, capacity = 1000},
        [10] = {price = 35000, capacity = 1500},
        [11] = {price = 72000, capacity = 2000},
        [12] = {price = 150000, capacity = 2500},
        [13] = {price = 200000, capacity = 3000},
        [14] = {price = 300000, capacity = 5000},
        [15] = {price = 450000, capacity = 7500},
        [16] = {price = 700000, capacity = 9000},
        [17] = {price = 1200000, capacity = 10000},
        [18] = {price = 1800000, capacity = 13000},
        [19] = {price = 2400000, capacity = 20000},
        [20] = {price = 5500000, capacity = 25000},
        [21] = {price = 8000000, capacity = 35000},
        [22] = {price = 15000000, capacity = 50000},
        [23] = {price = 30000000, capacity = 80000},
        [24] = {price = 50000000, capacity = 100000},
        [25] = {price = 100000000, capacity = 150000},
        [26] = {price = 250000000, capacity = 300000},
        [27] = {price = 500000000, capacity = 500000},
        [28] = {price = 800000000, capacity = 700000},
        [29] = {price = 1000000000, capacity = 1000000},
        [30] = {price = 1500000000, capacity = 1200000},
        [31] = {price = 2500000000, capacity = 1600000},
        [32] = {price = 5000000000, capacity = 2500000},
        [33] = {price = 10000000000, capacity = 3000000},
        [34] = {price = 20000000000, capacity = 3600000},
        [35] = {price = 40000000000, capacity = 4200000},
        [36] = {price = 80000000000, capacity = 6000000},
        [37] = {price = 125000000000, capacity = 7500000},
        [38] = {price = 200000000000, capacity = 9000000},
        [39] = {price = 400000000000, capacity = 12000000},
        [40] = {price = 800000000000, capacity = 15000000},
        [41] = {price = 2000000000000, capacity = 20000000},
        [42] = {price = 8000000000000, capacity = 30000000},
        -- [42] = {price = 8, capacity = 300000000},
    }
}
local miningBlock = {
    normal = {
        [1] = {id = 2218, name = "草皮", color = "116 205 50", defaultAmount = 1, grade = 1, price = 1, miningSpeed = 1},
        [2] = {id = 55, name = "泥土", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
        [5] = {id = 51, name = "沙子", color = "111 105 73", defaultAmount = 5, grade = 2, price = 3, miningSpeed = 2},
        [15] = {id = 12, name = "砂砾", color = "87 82 74", defaultAmount = 20, grade = 2, price = 4, miningSpeed = 3},
        [30] = {id = 58, name = "圆石", color = "50 50 50", defaultAmount = 50, grade = 3, price = 5, miningSpeed = 5},
        [50] = {id = 60, name = "裂石", color = "123 103 59", defaultAmount = 125, grade = 4, price = 6, miningSpeed = 10},
        [75] = {id = 77, name = "波纹石", color = "8 103 111", defaultAmount = 250, grade = 5, price = 7, miningSpeed = 20},
        [100] = {
            id = 146,
            name = "火山岩",
            color = "80 38 29",
            defaultAmount = 500,
            grade = 6,
            price = 8,
            miningSpeed = 30
        },
        [125] = {
            id = 150,
            name = "黑红石",
            color = "82 20 0",
            defaultAmount = 1000,
            grade = 7,
            price = 9,
            miningSpeed = 50
        },
        [150] = {
            id = 2056,
            name = "地狱石",
            color = "0 54 9",
            defaultAmount = 2000,
            grade = 8,
            price = 10,
            miningSpeed = 75
        },
        [175] = {
            id = 2077,
            name = "红花石",
            color = "136 78 106",
            defaultAmount = 5000,
            grade = 9,
            price = 15,
            miningSpeed = 200
        },
        [190] = {
            id = 2076,
            name = "紫花石",
            color = "83 14 60",
            defaultAmount = 10000,
            grade = 10,
            price = 20,
            miningSpeed = 300
        }
    },
    special = {
        {
            id = 125,
            name = "煤矿石",
            grade = 1,
            color = "5 5 5",
            defaultAmount = 5,
            price = 10,
            miningSpeed = 5,
            minDepth = 1,
            maxDepth = 14,
            probability = 1
        },
        {
            id = 151,
            name = "灵魂沙",
            grade = 2,
            color = "60 36 26",
            defaultAmount = 1,
            price = 100,
            miningSpeed = 10,
            minDepth = 5,
            maxDepth = 29,
            probability = 0.5
        },
        {
            id = 124,
            name = "铁矿石",
            grade = 2,
            color = "75 67 44",
            defaultAmount = 5,
            price = 35,
            miningSpeed = 15,
            minDepth = 10,
            maxDepth = 99,
            probability = 0.75
        },
        {
            id = 143,
            name = "铁块",
            grade = 3,
            color = "57 57 57",
            defaultAmount = 1,
            price = 2000,
            miningSpeed = 20,
            minDepth = 20,
            maxDepth = 99,
            probability = 0.3
        },
        {
            id = 16,
            name = "能量矿石",
            grade = 4,
            color = "110 28 19",
            defaultAmount = 10,
            price = 150,
            miningSpeed = 25,
            minDepth = 15,
            maxDepth = 99,
            probability = 0.8
        },
        {
            id = 18,
            name = "金矿石",
            grade = 5,
            color = "149 118 36",
            defaultAmount = 10,
            price = 200,
            miningSpeed = 30,
            minDepth = 20,
            maxDepth = 99,
            probability = 0.5
        },
        {
            id = 158,
            name = "石英矿石",
            grade = 6,
            color = "130 155 168",
            defaultAmount = 10,
            price = 300,
            miningSpeed = 35,
            minDepth = 30,
            maxDepth = 99,
            probability = 0.75
        },
        {
            id = 130,
            name = "青金石矿石",
            grade = 6,
            color = "2 15 97",
            defaultAmount = 30,
            price = 350,
            miningSpeed = 35,
            minDepth = 40,
            maxDepth = 99,
            probability = 0.4
        },
        {
            id = 87,
            name = "萤石矿石",
            grade = 7,
            color = "224 21 201",
            defaultAmount = 25,
            price = 500,
            miningSpeed = 50,
            minDepth = 50,
            maxDepth = 150,
            probability = 0.5
        },
        {
            id = 147,
            name = "钻石矿石",
            grade = 7,
            color = "59 150 166",
            defaultAmount = 10,
            price = 2000,
            miningSpeed = 100,
            minDepth = 50,
            maxDepth = 200,
            probability = 0.1
        },
        {
            id = 142,
            name = "金块",
            grade = 8,
            color = "175 123 39",
            defaultAmount = 1,
            price = 10000,
            miningSpeed = 100,
            minDepth = 100,
            maxDepth = 200,
            probability = 0.25
        },
        {
            id = 155,
            name = "远古化石",
            grade = 10,
            color = "209 204 198",
            defaultAmount = 1,
            price = 15000,
            miningSpeed = 250,
            minDepth = 31,
            maxDepth = 150,
            probability = 1
        },
        {
            id = 2,
            name = "绿宝石矿石",
            grade = 10,
            color = "164 227 257",
            defaultAmount = 20,
            price = 750,
            miningSpeed = 200,
            minDepth = 100,
            maxDepth = 200,
            probability = 0.2
        },
        {
            id = 148,
            name = "钻石块",
            grade = 12,
            color = "75 217 231",
            defaultAmount = 1,
            price = 30000,
            miningSpeed = 500,
            minDepth = 40,
            maxDepth = 200,
            probability = 0.1
        },
        {
            id = 156,
            name = "绿宝石块",
            grade = 12,
            color = "164 227 257",
            defaultAmount = 1,
            price = 50000,
            miningSpeed = 750,
            minDepth = 100,
            maxDepth = 200,
            probability = 0.05
        },
        {
            id = 2103,
            name = "金刚石",
            grade = 30,
            color = "99 99 99",
            defaultAmount = 1,
            price = 500000,
            miningSpeed = 5000,
            minDepth = 180,
            maxDepth = 200,
            probability = 0.01
        },
        {
            id = 2105,
            name = "国家宝藏",
            grade = 1,
            color = "143 13 13",
            defaultAmount = 1,
            price = 500000,
            miningSpeed = 50,
            minDepth = 10,
            maxDepth = 100,
            probability = 0.001
        },
        -- {
        --     id = 75,
        --     name = "水",
        --     grade = 1,
        --     color = "50 90 116",
        --     defaultAmount = 1,
        --     price = 0,
        --     miningSpeed = 50,
        --     minDepth = 100,
        --     maxDepth = 200,
        --     probability = 0.1
        -- },
        {
            id = 2216,
            name = "红宝石块",
            grade = 15,
            color = "174 23 63",
            defaultAmount = 1,
            price = 100000,
            miningSpeed = 2000,
            minDepth = 100,
            maxDepth = 200,
            probability = 0.05
        }
    }
}
-- 这里是月球
local ExtMiningBlocks={
    {
        normal = {
            [1] = {id = 2284, name = "宇宙封印", color = "116 205 50", defaultAmount = 15000, grade = 40, price = 1, miningSpeed = 10000000},
            [11] = {id = 2261, name = "宇宙紫色方块", color = "138 85 174", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [21] = {id = 2260, name = "宇宙蓝色方块", color = "51 125 193", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [31] = {id = 2259, name = "宇宙青色方块", color = "42 160 187", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [41] = {id = 2258, name = "宇宙碧色方块", color = "37 156 111", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [51] = {id = 2257, name = "宇宙深绿色方块", color = "43 146 37", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [61] = {id = 2256, name = "宇宙绿色方块", color = "101 170 23", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [71] = {id = 2255, name = "宇宙草绿色方块", color = "133 164 25", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [81] = {id = 2254, name = "宇宙黄色方块", color = "192 165 0", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [91] = {id = 2253, name = "宇宙金色方块", color = "191 140 0", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [101] = {id = 2252, name = "宇宙桔色方块", color = "192 102 0", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [111] = {id = 2251, name = "宇宙粉色方块", color = "241 125 125", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [121] = {id = 2248, name = "宇宙肉色方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [131] = {id = 2249, name = "宇宙棕色方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [141] = {id = 2247, name = "宇宙奶油色方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [151] = {id = 2102, name = "宇宙红色方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [161] = {id = 2246, name = "宇宙白色方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [171] = {id = 2250, name = "宇宙灰色方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [181] = {id = 2245, name = "宇宙水泥方块", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
            [191] = {id = 2065, name = "e@$&#^@^!", color = "93 54 34", defaultAmount = 2, grade = 1, price = 2, miningSpeed = 1},
        },
        special = {
            {
                id = 125,
                name = "煤矿石",
                grade = 1,
                color = "5 5 5",
                defaultAmount = 5,
                price = 10,
                miningSpeed = 5,
                minDepth = 1,
                maxDepth = 14,
                probability = 1
            },
            {
                id = 151,
                name = "灵魂沙",
                grade = 2,
                color = "60 36 26",
                defaultAmount = 1,
                price = 100,
                miningSpeed = 10,
                minDepth = 5,
                maxDepth = 29,
                probability = 0.5
            },
            {
                id = 124,
                name = "铁矿石",
                grade = 2,
                color = "75 67 44",
                defaultAmount = 5,
                price = 35,
                miningSpeed = 15,
                minDepth = 10,
                maxDepth = 99,
                probability = 0.75
            },
            {
                id = 143,
                name = "铁块",
                grade = 3,
                color = "57 57 57",
                defaultAmount = 1,
                price = 2000,
                miningSpeed = 20,
                minDepth = 25,
                maxDepth = 99,
                probability = 0.3
            },
            {
                id = 16,
                name = "能量矿石",
                grade = 4,
                color = "110 28 19",
                defaultAmount = 10,
                price = 150,
                miningSpeed = 25,
                minDepth = 10,
                maxDepth = 99,
                probability = 0.8
            },
            {
                id = 18,
                name = "金矿石",
                grade = 5,
                color = "149 118 36",
                defaultAmount = 10,
                price = 200,
                miningSpeed = 30,
                minDepth = 25,
                maxDepth = 99,
                probability = 0.5
            },
            {
                id = 158,
                name = "石英矿石",
                grade = 6,
                color = "130 155 168",
                defaultAmount = 10,
                price = 300,
                miningSpeed = 35,
                minDepth = 10,
                maxDepth = 99,
                probability = 0.75
            },
            {
                id = 130,
                name = "青金石矿石",
                grade = 6,
                color = "2 15 97",
                defaultAmount = 30,
                price = 350,
                miningSpeed = 35,
                minDepth = 40,
                maxDepth = 99,
                probability = 0.4
            },
            {
                id = 87,
                name = "萤石矿石",
                grade = 7,
                color = "224 21 201",
                defaultAmount = 25,
                price = 500,
                miningSpeed = 50,
                minDepth = 50,
                maxDepth = 150,
                probability = 0.5
            },
            {
                id = 147,
                name = "钻石矿石",
                grade = 7,
                color = "59 150 166",
                defaultAmount = 10,
                price = 2000,
                miningSpeed = 100,
                minDepth = 50,
                maxDepth = 200,
                probability = 0.1
            },
            {
                id = 142,
                name = "金块",
                grade = 8,
                color = "175 123 39",
                defaultAmount = 1,
                price = 10000,
                miningSpeed = 100,
                minDepth = 100,
                maxDepth = 200,
                probability = 0.25
            },
            {
                id = 155,
                name = "远古化石",
                grade = 10,
                color = "209 204 198",
                defaultAmount = 1,
                price = 15000,
                miningSpeed = 250,
                minDepth = 31,
                maxDepth = 150,
                probability = 1
            },
            {
                id = 2,
                name = "绿宝石矿石",
                grade = 10,
                color = "164 227 257",
                defaultAmount = 20,
                price = 750,
                miningSpeed = 200,
                minDepth = 100,
                maxDepth = 200,
                probability = 0.2
            },
            {
                id = 148,
                name = "钻石块",
                grade = 12,
                color = "75 217 231",
                defaultAmount = 1,
                price = 30000,
                miningSpeed = 500,
                minDepth = 40,
                maxDepth = 200,
                probability = 0.1
            },
            {
                id = 156,
                name = "绿宝石块",
                grade = 12,
                color = "164 227 257",
                defaultAmount = 1,
                price = 50000,
                miningSpeed = 750,
                minDepth = 100,
                maxDepth = 200,
                probability = 0.05
            },
            {
                id = 2103,
                name = "金刚石",
                grade = 30,
                color = "99 99 99",
                defaultAmount = 1,
                price = 500000,
                miningSpeed = 10000,
                minDepth = 180,
                maxDepth = 200,
                probability = 0.01
            },
            {
                id = 2105,
                name = "国家宝藏",
                grade = 1,
                color = "143 13 13",
                defaultAmount = 1,
                price = 500000,
                miningSpeed = 50,
                minDepth = 10,
                maxDepth = 100,
                probability = 0.001
            },
            -- {
            --     id = 75,
            --     name = "水",
            --     grade = 1,
            --     color = "50 90 116",
            --     defaultAmount = 1,
            --     price = 0,
            --     miningSpeed = 50,
            --     minDepth = 100,
            --     maxDepth = 200,
            --     probability = 0.1
            -- },
            {
                id = 2216,
                name = "红宝石块",
                grade = 15,
                color = "174 23 63",
                defaultAmount = 1,
                price = 100000,
                miningSpeed = 2000,
                minDepth = 100,
                maxDepth = 200,
                probability = 0.05
            }
        }
    },
-- 这里是二号矿
    {
        normal = {
            [1] = {id=155,name="远古化石",color="209 204 198",defaultAmount=1,grade=10,price=15000,miningSpeed=250},
            [2] = {id=150,name="黑红石",color="82 20 0",defaultAmount=1000,grade=7,price=9,miningSpeed=50},
            [4] = {id=2056,name="地狱石",color="0 5 49",defaultAmount=2000,grade=8,price=10,miningSpeed=75},
            [6] = {id=2114,name="黑色遗迹砖",color="50 58 68",defaultAmount=7000,grade=31,price=15,miningSpeed=300},
            [31] = {id=68,name="褪色遗迹砖",color="136 126 88",defaultAmount=10000,grade=32,price=20,miningSpeed=325},
            [56] = {id=70,name="赤色遗迹砖",color="189 57 32",defaultAmount=15000,grade=33,price=21,miningSpeed=375},
            [81] = {id=2111,name="粉色遗迹砖",color="244 78 111",defaultAmount=25000,grade=34,price=22,miningSpeed=450},
            [106] = {id=2115,name="橘色遗迹砖",color="190 91 40",defaultAmount=35000,grade=35,price=23,miningSpeed=550},
            [131] = {id=2113,name="黄色遗迹砖",color="255 228 155",defaultAmount=50000,grade=36,price=24,miningSpeed=650},
            [161] = {id=2117,name="绿色遗迹砖",color="19 123 104",defaultAmount=75000,grade=37,price=25,miningSpeed=800},
            [181] = {id=2116,name="蓝色遗迹砖",color="51 115 225",defaultAmount=125000,grade=38,price=26,miningSpeed=1000},
            [191] = {id=2118,name="白色遗迹砖",color="150 150 150",defaultAmount=150000,grade=39,price=27,miningSpeed=1500},
            },
        special = {
            {
                id = 125,
                name = "煤矿石",
                grade = 1,
                color = "5 5 5",
                defaultAmount = 5,
                price = 10,
                miningSpeed = 5,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.1
            },
            {
                id = 151,
                name = "灵魂沙",
                grade = 2,
                color = "60 36 26",
                defaultAmount = 1,
                price = 100,
                miningSpeed = 10,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 124,
                name = "铁矿石",
                grade = 2,
                color = "75 67 44",
                defaultAmount = 5,
                price = 35,
                miningSpeed = 15,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.075
            },
            {
                id = 143,
                name = "铁块",
                grade = 3,
                color = "57 57 57",
                defaultAmount = 1,
                price = 2000,
                miningSpeed = 20,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.03
            },
            {
                id = 16,
                name = "能量矿石",
                grade = 4,
                color = "110 28 19",
                defaultAmount = 10,
                price = 150,
                miningSpeed = 25,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.08
            },
            {
                id = 18,
                name = "金矿石",
                grade = 5,
                color = "149 118 36",
                defaultAmount = 10,
                price = 200,
                miningSpeed = 30,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 158,
                name = "石英矿石",
                grade = 6,
                color = "130 155 168",
                defaultAmount = 10,
                price = 300,
                miningSpeed = 35,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.075
            },
            {
                id = 130,
                name = "青金石矿石",
                grade = 6,
                color = "2 15 97",
                defaultAmount = 30,
                price = 350,
                miningSpeed = 35,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.04
            },
            {
                id = 87,
                name = "萤石矿石",
                grade = 7,
                color = "224 21 201",
                defaultAmount = 25,
                price = 500,
                miningSpeed = 50,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 147,
                name = "钻石矿石",
                grade = 7,
                color = "59 150 166",
                defaultAmount = 10,
                price = 2000,
                miningSpeed = 100,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.01
            },
            {
                id = 142,
                name = "金块",
                grade = 8,
                color = "175 123 39",
                defaultAmount = 1,
                price = 10000,
                miningSpeed = 100,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.025
            },
            {
                id = 2,
                name = "绿宝石矿石",
                grade = 10,
                color = "164 227 257",
                defaultAmount = 20,
                price = 750,
                miningSpeed = 200,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.02
            },
            {
                id = 148,
                name = "钻石块",
                grade = 12,
                color = "75 217 231",
                defaultAmount = 1,
                price = 30000,
                miningSpeed = 500,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.01
            },
            {
                id = 156,
                name = "绿宝石块",
                grade = 12,
                color = "164 227 257",
                defaultAmount = 1,
                price = 50000,
                miningSpeed = 750,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 2103,
                name = "金刚石",
                grade = 30,
                color = "99 99 99",
                defaultAmount = 1,
                price = 500000,
                miningSpeed = 10000,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.01
            },
            {
                id = 2105,
                name = "国家宝藏",
                grade = 1,
                color = "10 58 68",
                defaultAmount = 1,
                price = 500000,
                miningSpeed = 50,
                minDepth = 191,
                maxDepth = 200,
                probability = 0.01
            },
            {
                id = 2216,
                name = "红宝石块",
                grade = 15,
                color = "174 23 63",
                defaultAmount = 1,
                price = 100000,
                miningSpeed = 2000,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 2123,
                name = "黑色遗迹碎砖",
                grade = 31,
                color = "50 68 68",
                defaultAmount = 1750,
                price = 13,
                miningSpeed = 300,
                minDepth = 6,
                maxDepth = 30,
                probability = 1
            },
            {
                id = 2132,
                name = "黑色遗迹苔砖",
                grade = 31,
                color = "50 68 68",
                defaultAmount = 30000,
                price = 17,
                miningSpeed = 300,
                minDepth = 6,
                maxDepth = 30,
                probability = 1
            },
            {
                id = 66,
                name = "褐色遗迹碎砖",
                grade = 32,
                color = "136 126 88",
                defaultAmount = 2500,
                price = 18,
                miningSpeed = 325,
                minDepth = 31,
                maxDepth = 55,
                probability = 1
            },
            {
                id = 69,
                name = "褐色遗迹苔砖",
                grade = 32,
                color = "136 126 88",
                defaultAmount = 40000,
                price = 22,
                miningSpeed = 325,
                minDepth = 31,
                maxDepth = 55,
                probability = 1
            },
            {
                id = 2119,
                name = "赤色遗迹碎砖",
                grade = 33,
                color = "189 57 32",
                defaultAmount = 3750,
                price = 19,
                miningSpeed = 350,
                minDepth = 56,
                maxDepth = 80,
                probability = 1
            },
            {
                id = 2128,
                name = "赤色遗迹苔砖",
                grade = 33,
                color = "189 57 32",
                defaultAmount = 60000,
                price = 23,
                miningSpeed = 350,
                minDepth = 56,
                maxDepth = 80,
                probability = 1
            },
            {
                id = 2120,
                name = "粉色遗迹碎砖",
                grade = 34,
                color = "244 78 111",
                defaultAmount = 6250,
                price = 20,
                miningSpeed = 380,
                minDepth = 81,
                maxDepth = 105,
                probability = 1
            },
            {
                id = 2129,
                name = "粉色遗迹苔砖",
                grade = 34,
                color = "244 78 111",
                defaultAmount = 100000,
                price = 24,
                miningSpeed = 380,
                minDepth = 81,
                maxDepth = 105,
                probability = 1
            },
            {
                id = 2124,
                name = "橘色遗迹碎砖",
                grade = 35,
                color = "190 91 40",
                defaultAmount = 8750,
                price = 21,
                miningSpeed = 400,
                minDepth = 106,
                maxDepth = 130,
                probability = 1
            },
            {
                id = 2133,
                name = "橘色遗迹苔砖",
                grade = 35,
                color = "190 91 40",
                defaultAmount = 140000,
                price = 25,
                miningSpeed = 400,
                minDepth = 106,
                maxDepth = 130,
                probability = 1
            },
            {
                id = 2122,
                name = "黄色遗迹碎砖",
                grade = 36,
                color = "255 228 155",
                defaultAmount = 12500,
                price = 22,
                miningSpeed = 425,
                minDepth = 131,
                maxDepth = 160,
                probability = 1
            },
            {
                id = 2131,
                name = "黄色遗迹苔砖",
                grade = 36,
                color = "255 228 155",
                defaultAmount = 200000,
                price = 26,
                miningSpeed = 425,
                minDepth = 131,
                maxDepth = 160,
                probability = 1
            },
            {
                id = 2126,
                name = "绿色遗迹碎砖",
                grade = 37,
                color = "19 123 104",
                defaultAmount = 18750,
                price = 23,
                miningSpeed = 450,
                minDepth = 161,
                maxDepth = 180,
                probability = 1
            },
            {
                id = 2135,
                name = "绿色遗迹苔砖",
                grade = 37,
                color = "19 123 104",
                defaultAmount = 300000,
                price = 27,
                miningSpeed = 450,
                minDepth = 161,
                maxDepth = 180,
                probability = 1
            },
            {
                id = 2125,
                name = "蓝色遗迹碎砖",
                grade = 38,
                color = "51 115 225",
                defaultAmount = 18750,
                price = 24,
                miningSpeed = 500,
                minDepth = 181,
                maxDepth = 190,
                probability = 1
            },
            {
                id = 2134,
                name = "蓝色遗迹苔砖",
                grade = 38,
                color = "51 115 225",
                defaultAmount = 500000,
                price = 28,
                miningSpeed = 500,
                minDepth = 181,
                maxDepth = 190,
                probability = 1
            },
            {
                id = 2127,
                name = "白色遗迹碎砖",
                grade = 39,
                color = "150 150 150",
                defaultAmount = 37500,
                price = 25,
                miningSpeed = 600,
                minDepth = 191,
                maxDepth = 200,
                probability = 1
            },
            {
                id = 2136,
                name = "白色遗迹苔砖",
                grade = 39,
                color = "150 150 150",
                defaultAmount = 600000,
                price = 29,
                miningSpeed = 600,
                minDepth = 191,
                maxDepth = 200,
                probability = 1
            },
            {
                id = 220,
                name = "邪恶雕像",
                grade = 31,
                color = "170 70 16",
                defaultAmount = 5000,
                price = 50,
                miningSpeed = 1500,
                minDepth = 101,
                maxDepth = 200,
                probability = 0.1
            },
            {
                id = 2049,
                name = "高达尼姆合金",
                grade = 35,
                color = "100 100 100",
                defaultAmount = 1,
                price = 2333333,
                miningSpeed = 10000,
                minDepth = 101,
                maxDepth = 199,
                probability = 0.1
            },
            {
                id = 2319,
                name = "宇宙合金Z",
                grade = 37,
                color = "200 150 50",
                defaultAmount = 1,
                price = 7650000,
                miningSpeed = 30000,
                minDepth = 121,
                maxDepth = 190,
                probability = 0.02
            },
            {
                id = 157,
                name = "盖塔石",
                grade = 36,
                color = "61 184 195",
                defaultAmount = 1,
                price = 5252525,
                miningSpeed = 20000,
                minDepth = 111,
                maxDepth = 190,
                probability = 0.05
            },
            {
                id = 8,
                name = "贤者之石",
                grade = 38,
                color = "100 100 100",
                defaultAmount = 1,
                price = 20000000,
                miningSpeed = 40000,
                minDepth = 161,
                maxDepth = 200,
                probability = 0.01
            },
            {
                id = 170,
                name = "大贤者之石",
                grade = 39,
                color = "200 150 50",
                defaultAmount = 1,
                price = 150000000,
                miningSpeed = 50000,
                minDepth = 171,
                maxDepth = 200,
                probability = 0.005
            },
            {
                id = 89,
                name = "真贤者之石",
                grade = 41,
                color = "61 184 195",
                defaultAmount = 1,
                price = 987654321,
                miningSpeed = 250000,
                minDepth = 191,
                maxDepth = 200,
                probability = 0.001
            },
        }
    },
    {
        normal = {
            [1] = {id=146,name="火山岩",color="80 38 29",defaultAmount=500,grade=6,price=8,miningSpeed=30},
            [2] = {id=150,name="黑红石",color="82 20 0",defaultAmount=1000,grade=7,price=9,miningSpeed=50},
            [4] = {id=2056,name="地狱石",color="0 5 49",defaultAmount=2000,grade=8,price=10,miningSpeed=75},
            [6] = {id=2114,name="黑色遗迹砖",color="50 58 68",defaultAmount=7000,grade=31,price=15,miningSpeed=300},
            [31] = {id=68,name="褪色遗迹砖",color="136 126 88",defaultAmount=10000,grade=32,price=20,miningSpeed=325},
            [56] = {id=70,name="赤色遗迹砖",color="189 57 32",defaultAmount=15000,grade=33,price=21,miningSpeed=375},
            [81] = {id=2111,name="粉色遗迹砖",color="244 78 111",defaultAmount=25000,grade=34,price=22,miningSpeed=450},
            [106] = {id=2115,name="橘色遗迹砖",color="190 91 40",defaultAmount=35000,grade=35,price=23,miningSpeed=550},
            [131] = {id=2113,name="黄色遗迹砖",color="255 228 155",defaultAmount=50000,grade=36,price=24,miningSpeed=650},
            [161] = {id=2117,name="绿色遗迹砖",color="19 123 104",defaultAmount=75000,grade=37,price=25,miningSpeed=800},
            [181] = {id=2116,name="蓝色遗迹砖",color="51 115 225",defaultAmount=125000,grade=38,price=26,miningSpeed=1000},
            [191] = {id=2118,name="白色遗迹砖",color="150 150 150",defaultAmount=150000,grade=39,price=27,miningSpeed=1500},
            },
        special = {
            {
                id = 125,
                name = "煤矿石",
                grade = 1,
                color = "5 5 5",
                defaultAmount = 5,
                price = 10,
                miningSpeed = 5,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.1
            },
            {
                id = 151,
                name = "灵魂沙",
                grade = 2,
                color = "60 36 26",
                defaultAmount = 1,
                price = 100,
                miningSpeed = 10,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 124,
                name = "铁矿石",
                grade = 2,
                color = "75 67 44",
                defaultAmount = 5,
                price = 35,
                miningSpeed = 15,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.075
            },
            {
                id = 143,
                name = "铁块",
                grade = 3,
                color = "57 57 57",
                defaultAmount = 1,
                price = 2000,
                miningSpeed = 20,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.03
            },
            {
                id = 16,
                name = "能量矿石",
                grade = 4,
                color = "110 28 19",
                defaultAmount = 10,
                price = 150,
                miningSpeed = 25,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.08
            },
            {
                id = 18,
                name = "金矿石",
                grade = 5,
                color = "149 118 36",
                defaultAmount = 10,
                price = 200,
                miningSpeed = 30,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.05
            },
            {
                id = 158,
                name = "石英矿石",
                grade = 6,
                color = "130 155 168",
                defaultAmount = 10,
                price = 300,
                miningSpeed = 35,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.075
            },
            {
                id = 130,
                name = "青金石矿石",
                grade = 6,
                color = "2 15 97",
                defaultAmount = 30,
                price = 350,
                miningSpeed = 35,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.04
            },
            {
                id = 87,
                name = "萤石矿石",
                grade = 7,
                color = "224 21 201",
                defaultAmount = 25,
                price = 500,
                miningSpeed = 50,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.1
            },
            {
                id = 147,
                name = "钻石矿石",
                grade = 7,
                color = "59 150 166",
                defaultAmount = 10,
                price = 2000,
                miningSpeed = 100,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.01
            },
            {
                id = 142,
                name = "金块",
                grade = 8,
                color = "175 123 39",
                defaultAmount = 1,
                price = 10000,
                miningSpeed = 100,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.025
            },
            {
                id = 155,
                name = "远古化石",
                grade = 10,
                color = "209 204 198",
                defaultAmount = 1,
                price = 15000,
                miningSpeed = 250,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.1
            },
            {
                id = 2,
                name = "绿宝石矿石",
                grade = 10,
                color = "164 227 257",
                defaultAmount = 20,
                price = 750,
                miningSpeed = 200,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.02
            },
            {
                id = 148,
                name = "钻石块",
                grade = 12,
                color = "75 217 231",
                defaultAmount = 1,
                price = 30000,
                miningSpeed = 500,
                minDepth = 1,
                maxDepth = 100,
                probability = 0.01
            },
            {
                id = 156,
                name = "绿宝石块",
                grade = 12,
                color = "164 227 257",
                defaultAmount = 1,
                price = 50000,
                miningSpeed = 750,
                minDepth = 6,
                maxDepth = 150,
                probability = 0.1
            },
            {
                id = 2103,
                name = "金刚石",
                grade = 30,
                color = "99 99 99",
                defaultAmount = 1,
                price = 500000,
                miningSpeed = 10000,
                minDepth = 6,
                maxDepth = 200,
                probability = 0.05
            },
            {
                id = 2105,
                name = "国家宝藏",
                grade = 1,
                color = "10 58 68",
                defaultAmount = 1,
                price = 500000,
                miningSpeed = 50,
                minDepth = 6,
                maxDepth = 200,
                probability = 0.05
            },
            {
                id = 2216,
                name = "红宝石块",
                grade = 15,
                color = "174 23 63",
                defaultAmount = 1,
                price = 100000,
                miningSpeed = 2000,
                minDepth = 6,
                maxDepth = 200,
                probability = 0.1
            },
            {
                id = 2123,
                name = "黑色遗迹碎砖",
                grade = 31,
                color = "50 68 68",
                defaultAmount = 1750,
                price = 13,
                miningSpeed = 300,
                minDepth = 6,
                maxDepth = 30,
                probability = 1
            },
            {
                id = 2132,
                name = "黑色遗迹苔砖",
                grade = 31,
                color = "50 68 68",
                defaultAmount = 30000,
                price = 17,
                miningSpeed = 300,
                minDepth = 6,
                maxDepth = 30,
                probability = 1
            },
            {
                id = 66,
                name = "褐色遗迹碎砖",
                grade = 32,
                color = "136 126 88",
                defaultAmount = 2500,
                price = 18,
                miningSpeed = 325,
                minDepth = 31,
                maxDepth = 55,
                probability = 1
            },
            {
                id = 69,
                name = "褐色遗迹苔砖",
                grade = 32,
                color = "136 126 88",
                defaultAmount = 40000,
                price = 22,
                miningSpeed = 325,
                minDepth = 31,
                maxDepth = 55,
                probability = 1
            },
            {
                id = 2119,
                name = "赤色遗迹碎砖",
                grade = 33,
                color = "189 57 32",
                defaultAmount = 3750,
                price = 19,
                miningSpeed = 350,
                minDepth = 56,
                maxDepth = 80,
                probability = 1
            },
            {
                id = 2128,
                name = "赤色遗迹苔砖",
                grade = 33,
                color = "189 57 32",
                defaultAmount = 60000,
                price = 23,
                miningSpeed = 350,
                minDepth = 56,
                maxDepth = 80,
                probability = 1
            },
            {
                id = 2120,
                name = "粉色遗迹碎砖",
                grade = 34,
                color = "244 78 111",
                defaultAmount = 6250,
                price = 20,
                miningSpeed = 380,
                minDepth = 81,
                maxDepth = 105,
                probability = 1
            },
            {
                id = 2129,
                name = "粉色遗迹苔砖",
                grade = 34,
                color = "244 78 111",
                defaultAmount = 100000,
                price = 24,
                miningSpeed = 380,
                minDepth = 81,
                maxDepth = 105,
                probability = 1
            },
            {
                id = 2124,
                name = "橘色遗迹碎砖",
                grade = 35,
                color = "190 91 40",
                defaultAmount = 8750,
                price = 21,
                miningSpeed = 400,
                minDepth = 106,
                maxDepth = 130,
                probability = 1
            },
            {
                id = 2133,
                name = "橘色遗迹苔砖",
                grade = 35,
                color = "190 91 40",
                defaultAmount = 140000,
                price = 25,
                miningSpeed = 400,
                minDepth = 106,
                maxDepth = 130,
                probability = 1
            },
            {
                id = 2122,
                name = "黄色遗迹碎砖",
                grade = 36,
                color = "255 228 155",
                defaultAmount = 12500,
                price = 22,
                miningSpeed = 425,
                minDepth = 131,
                maxDepth = 160,
                probability = 1
            },
            {
                id = 2131,
                name = "黄色遗迹苔砖",
                grade = 36,
                color = "255 228 155",
                defaultAmount = 200000,
                price = 26,
                miningSpeed = 425,
                minDepth = 131,
                maxDepth = 160,
                probability = 1
            },
            {
                id = 2126,
                name = "绿色遗迹碎砖",
                grade = 37,
                color = "19 123 104",
                defaultAmount = 18750,
                price = 23,
                miningSpeed = 450,
                minDepth = 161,
                maxDepth = 180,
                probability = 1
            },
            {
                id = 2135,
                name = "绿色遗迹苔砖",
                grade = 37,
                color = "19 123 104",
                defaultAmount = 300000,
                price = 27,
                miningSpeed = 450,
                minDepth = 161,
                maxDepth = 180,
                probability = 1
            },
            {
                id = 2125,
                name = "蓝色遗迹碎砖",
                grade = 38,
                color = "51 115 225",
                defaultAmount = 18750,
                price = 24,
                miningSpeed = 500,
                minDepth = 181,
                maxDepth = 190,
                probability = 1
            },
            {
                id = 2134,
                name = "蓝色遗迹苔砖",
                grade = 38,
                color = "51 115 225",
                defaultAmount = 500000,
                price = 28,
                miningSpeed = 500,
                minDepth = 181,
                maxDepth = 190,
                probability = 1
            },
            {
                id = 2127,
                name = "白色遗迹碎砖",
                grade = 39,
                color = "150 150 150",
                defaultAmount = 37500,
                price = 25,
                miningSpeed = 600,
                minDepth = 191,
                maxDepth = 200,
                probability = 1
            },
            {
                id = 2136,
                name = "白色遗迹苔砖",
                grade = 39,
                color = "150 150 150",
                defaultAmount = 600000,
                price = 29,
                miningSpeed = 600,
                minDepth = 191,
                maxDepth = 200,
                probability = 1
            },
            {
                id = 220,
                name = "邪恶雕像",
                grade = 31,
                color = "170 70 16",
                defaultAmount = 5000,
                price = 50,
                miningSpeed = 1500,
                minDepth = 101,
                maxDepth = 200,
                probability = 0.1
            },
            {
                id = 2049,
                name = "高达尼姆合金",
                grade = 35,
                color = "100 100 100",
                defaultAmount = 1,
                price = 2333333,
                miningSpeed = 10000,
                minDepth = 101,
                maxDepth = 199,
                probability = 0.1
            },
            {
                id = 2319,
                name = "宇宙合金Z",
                grade = 37,
                color = "200 150 50",
                defaultAmount = 1,
                price = 7650000,
                miningSpeed = 30000,
                minDepth = 121,
                maxDepth = 190,
                probability = 0.02
            },
            {
                id = 157,
                name = "盖塔石",
                grade = 36,
                color = "61 184 195",
                defaultAmount = 1,
                price = 5252525,
                miningSpeed = 20000,
                minDepth = 111,
                maxDepth = 190,
                probability = 0.05
            },
            {
                id = 8,
                name = "贤者之石",
                grade = 38,
                color = "100 100 100",
                defaultAmount = 1,
                price = 20000000,
                miningSpeed = 40000,
                minDepth = 161,
                maxDepth = 200,
                probability = 0.01
            },
            {
                id = 170,
                name = "大贤者之石",
                grade = 39,
                color = "200 150 50",
                defaultAmount = 1,
                price = 150000000,
                miningSpeed = 50000,
                minDepth = 171,
                maxDepth = 200,
                probability = 0.005
            },
            {
                id = 89,
                name = "真贤者之石",
                grade = 41,
                color = "61 184 195",
                defaultAmount = 1,
                price = 987654321,
                miningSpeed = 250000,
                minDepth = 191,
                maxDepth = 200,
                probability = 0.001
            },
        }
    }
}
local broadcastBlocks = {
    89,170,2103,2105
}

local ExtMaps = {{startPoint = {x = 17189, y = 201, z = 19350}, width = 26},{startPoint = {x = 17908, y = 201, z = 16982}, width = 25},{startPoint = {x = 19480, y = 201, z = 19232}, width = 10}}

local Router = require("Router")

local function showMoneyUI(text)
    get = get or 0
    Client.showUi("UI_addMoney")
    local UI_addMoney = Client.getUi("UI_addMoney")
    UI_addMoney.text = text
    UI_addMoney.y = UI_addMoney._y
    UI_addMoney.font_color = UI_addMoney._font_color
    local loopTime = 20
    local totalTime = 1500
    local count = 0
    Timer(
        loopTime,
        function(t)
            count = count + loopTime
            if not Client then
                t:stop()
                return
            end
            if count >= totalTime then
                t:stop()
                Client.hideUi("UI_addMoney")
                return
            end
            UI_addMoney.y = UI_addMoney.y - 1
            UI_addMoney.font_color = UI_addMoney._font_color .. " " .. math.ceil(255 - 255 * count / totalTime)
        end
    )
end

local npc = {
    ["npc_reclaim"] = {
        spawnAtStart = true,
        x = 19209,
        y = 202,
        z = 19198,
        facing = 3.14,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FhdMPJOwIQdvgOKwXoqEzYEyCj6Q",pid="52395",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "矿石回收商人",
        onclick = function(entity)
            local playerInfo = Client.playerInfo
            if playerInfo.carryMoney > 0 then
                Router.send(
                    "sell",
                    {id = GetPlayerId()},
                    function(msg) -- msg.get:获得的钱
                        -- Client.showUi("UI_addMoney")
                        -- local UI_addMoney = Client.getUi("UI_addMoney")
                        -- UI_addMoney.text = "+ " .. (PublicFunction.convertNumber(msg.get) or "0") .. "￥"
                        -- UI_addMoney.y = UI_addMoney._y
                        -- UI_addMoney.font_color = UI_addMoney._font_color
                        -- local loopTime = 20
                        -- local totalTime = 1500
                        -- local count = 0
                        -- Timer(
                        --     loopTime,
                        --     function(t)
                        --         count = count + loopTime
                        --         if not Client then
                        --             t:stop()
                        --             return
                        --         end
                        --         if count >= totalTime then
                        --             t:stop()
                        --             Client.hideUi("UI_addMoney")
                        --             return
                        --         end
                        --         UI_addMoney.y = UI_addMoney.y - 1
                        --         UI_addMoney.font_color =
                        --             UI_addMoney._font_color .. " " .. math.ceil(255 - 255 * count / totalTime)
                        --     end
                        -- )
                        showMoneyUI("+ " .. (PublicFunction.convertNumber(msg.get) or "0") .. "￥")
                    end
                )
            else
                MessageBox("背包为空，请挖到矿石再来找我吧！")
            end
        end,
        update = function(entity)
        end
    },
    ["npc_upgrade_tool"] = {
        spawnAtStart = true,
        x = 19195,
        y = 202,
        z = 19202,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "矿镐商店",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_upgrade_bag"] = {
        spawnAtStart = true,
        x = 19205,
        y = 202,
        z = 19202,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "背包商店",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_surprise"] = {
        spawnAtStart = true,
        x = 19192,
        y = 202,
        z = 19196,
        facing = 0,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "宝箱商店",
        onclick = function(entity)
            MiniStoreUI.show()
        end,
        update = function(entity)
        end
    },
    ["npc_tunnel2"] = {
        spawnAtStart = true,
        x = 19201,
        y = 202,
        z = 19150,
        facing = 0,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "月球矿区管理员",
        onclick = function(entity)
                local function moonText()
                    if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >49 then
                        -- return "全太阳系首家线上矿场招工啦！\n"
                        return "虽然我们成功地发现了位于月面的矿区，但目前没有任何工具可以挖开那里\n"
                    else
                        return "抱歉！我们这边需要【逃亡】阅历丰富的老矿工！\n你的【逃亡次数】不足50次\n多和老司机【逃跑】，增加阅历后再来吧！"
                    end
                end

            Tunnel.show({mOnClickOK=function()
                if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >19 then
                    Router.send("quickMove", {id = GetPlayerId(), quickMovePos = {x = ExtMaps[1].startPoint.x - 59, y = ExtMaps[1].startPoint.y + 5, z = ExtMaps[1].startPoint.z + 43}})
                end
            end,mText = moonText()})
        end,
        update = function(entity)
        end
    },
    ["npc_tunnel2to1"] = {
        spawnAtStart = true,
        x = 17925,
        y = 205,
        z = 16993,
        facing = 3.14,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "大监工孟姜女",
        onclick = function(entity)
                local function moonText()
                    if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >999 then
                        -- return "全太阳系首家线上矿场招工啦！\n"
                        return "虽然我们成功地发现了位于月面的矿区，但目前没有任何工具可以挖开那里\n"
                    else
                        return "欢迎来到秦始皇陵！\n什么！？造房子？看来你还没搞清情况？\n你已经被安排来挖掘始皇墓了！\n想回去！？那是不可能的啦！快点干活吧！"
                    end
                end

            Tunnel.show({mOnClickOK=function()
                if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >999 then
                    Router.send("quickMove", {id = GetPlayerId(), quickMovePos = {x = ExtMaps[1].startPoint.x - 59, y = ExtMaps[1].startPoint.y + 5, z = ExtMaps[1].startPoint.z + 43}})
                end
            end,mText = moonText()})
        end,
        update = function(entity)
        end
    },
    -- ["npc_tunnel3"] = {
    --     spawnAtStart = true,
    --     x = 19232,
    --     y = 202,
    --     z = 19161,
    --     facing = 2.335,
    --     item_id = 30002,
    --     scaling = 0.5,
    --     model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
    --     effectiveRange = 5,
    --     dummy = true,
    --     displayName = "招工专员",
    --     onclick = function(entity)
    --         local function moonText()
    --                 if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >0 then
    --                     return "包吃包住钱多事少的矿场哪里找？错过这个村就没这个店啦！\n放心吧，这里绝不是黑砖窑，说不定还能挖到巨神像"
    --                 else
    --                     return "我们这边需要【逃亡】阅历丰富的老矿工\n你的【逃亡】经历为0怎么行呢？增加阅历后再来吧！"
    --                 end
    --             end

    --         Tunnel.show({mOnClickOK=function()
    --             if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >0 then
    --                 Router.send("quickMove", {id = GetPlayerId(), quickMovePos = {x = ExtMaps[2].startPoint.x + 44, y = ExtMaps[2].startPoint.y + 10, z = ExtMaps[2].startPoint.z - 6}})
    --             end
    --         end,mText = moonText()})
    --     end,
    --     update = function(entity)
    --     end
    -- },
    ["npc_tunnel3"] = {
        spawnAtStart = true,
        x = 19232,
        y = 202,
        z = 19161,
        facing = 2.335,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FkrNNy37L1mTg_31quIlozDSGx8S",pid="49642",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "孟姜女",
        onclick = function(entity)
            local function moonText()
                    if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >0 then
                        return "包吃包住钱多事少的差事哪里找？错过这个村就没这个店啦！\n放心吧，这里绝不是黑砖窑，大家一起盖房子！\n真的，大家一起盖房子，放心吧，快点来吧！"
                    else
                        return "我们这边需要【逃亡】阅历丰富的老矿工\n你的【逃亡】经历为0怎么行呢？增加阅历后再来吧！"
                    end
                end

            Tunnel.show({mOnClickOK=function()
                if Client.playerInfo.mVersion_0_2.mRelifeTime and Client.playerInfo.mVersion_0_2.mRelifeTime >0 then
                    Router.send("quickMove", {id = GetPlayerId(), quickMovePos = {x = ExtMaps[2].startPoint.x + 12, y = ExtMaps[2].startPoint.y + 5, z = ExtMaps[2].startPoint.z + 9}})
                end
            end,mText = moonText()})
        end,
        update = function(entity)
        end
    },
    ["npc_rebirth"] = {
        spawnAtStart = true,
        x = 19220,
        y = 207,
        z = 19172,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FnvudG4Bhg_AXrphTWtodlCwJ5k4",pid="52396",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "老司机",
        onclick = function(entity)
            IngameUI[3].params.onclick()
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool1"] = {
        spawnAtStart = true,
        x = 19194,
        y = 202,
        z = 19203,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FqGcBCD45M-aqosWgEyAxNOww2oE",pid="426231",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+42魔仙棒",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool2"] = {
        spawnAtStart = true,
        x = 19195,
        y = 202,
        z = 19203,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="Fp9rnWRWFzXWEgWcWMFQfUyVgPZj",pid="426222",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+43MBA篮球板",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool3"] = {
        spawnAtStart = true,
        x = 19196,
        y = 202,
        z = 19203,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FpQ3z4KAZKMm8fZPAFxNJ2YFFWTj",pid="426229",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+27红色冲锋枪",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool4"] = {
        spawnAtStart = true,
        x = 19196,
        y = 202,
        z = 19202,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FoGMtqCOVHgYSYei7Z-EBexUd-zc",pid="426228",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+35平底锅",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool5"] = {
        spawnAtStart = true,
        x = 19194,
        y = 202,
        z = 19202,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FoAeztjTQXubIt4UYiPsm8vWCc3x",pid="426227",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+42大宝剑",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool6"] = {
        spawnAtStart = true,
        x = 19194,
        y = 202,
        z = 19201,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FqDfs1Y1VS8VKyQaZ1QK_1cs5MWH",pid="426225",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+39炼狱神棍",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool7"] = {
        spawnAtStart = true,
        x = 19195,
        y = 202,
        z = 19201,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="FlMby30iLZh6Zsie9tWLZf-9Dm6v",pid="49876",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+32钻石镐子",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_tool8"] = {
        spawnAtStart = true,
        x = 19196,
        y = 202,
        z = 19201,
        facing = 1.57,
        item_id = 30002,
        scaling = 0.5,
        model = {hash="Fs9cyArf901-h2CRDRq93ElwdUHL",pid="426223",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+38圣堂神叉",
        onclick = function(entity)
            Client.initShopUi("tool")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag1"] = {
        spawnAtStart = true,
        x = 19204,
        y = 201.2,
        z = 19202.8,
        facing = 1.66,
        item_id = 30002,
        scaling = 1,
        model = {hash="FrWLqzbtnGm0CyilWMQC-hLYpn-Q",pid="426312",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+38电热油汀",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag2"] = {
        spawnAtStart = true,
        x = 19205,
        y = 201.2,
        z = 19203.2,
        facing = 4.68,
        item_id = 30002,
        scaling = 1,
        model = {hash="Fs7KL6IIHdYbaWezrIppVjBFPyll",pid="426310",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+37电冰柜",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag3"] = {
        spawnAtStart = true,
        x = 19206.1,
        y = 201.05,
        z = 19203.5,
        facing = 5,
        item_id = 30002,
        scaling = 1,
        model = {hash="Fu_V6EeAGr6usoy03qbyerkPrhJQ",pid="426309",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+36光波炉",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag4"] = {
        spawnAtStart = true,
        x = 19205.6,
        y = 201.3,
        z = 19202.1,
        facing = 3.07,
        item_id = 30002,
        scaling = 1,
        model = {hash="FmOAPY1vCYCRpW_zSn4mWr2nE0Ll",pid="426313",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+39主机箱",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag5"] = {
        spawnAtStart = true,
        x = 19204.1,
        y = 201.05,
        z = 19202.5,
        facing = 5,
        item_id = 30002,
        scaling = 1,
        model = {hash="FitbN4KGW7fv8N0FbESK4f_oWZNO",pid="426308",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+34微波炉",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag6"] = {
        spawnAtStart = true,
        x = 19204,
        y = 201.05,
        z = 19201.5,
        facing = 5,
        item_id = 30002,
        scaling = 1,
        model = {hash="Frmk3w1x51Pi1o1EbiWIclaIz8o7",pid="426315",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+41诺贝尔背包",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag7"] = {
        spawnAtStart = true,
        x = 19205,
        y = 201.05,
        z = 19201.5,
        facing = 5,
        item_id = 30002,
        scaling = 1,
        model = {hash="FooS05R9tMxIiBhEaGMUxLGHoKF8",pid="426306",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+32科技大背包",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
    ["npc_accessories_bag8"] = {
        spawnAtStart = true,
        x = 19206,
        y = 201.27,
        z = 19201.5,
        facing = 5,
        item_id = 30002,
        scaling = 0.8,
        model = {hash="Fg5JqpJAxPQE6wAtsW5PlM7NaX7y",pid="426316",ext="fbx",},
        effectiveRange = 5,
        dummy = true,
        displayName = "+42世界背包",
        onclick = function(entity)
            Client.initShopUi("bag")
        end,
        update = function(entity)
        end
    },
}

local itemId = {
    tool = {
        [1] = {id = 40500, name = "矿镐"},
        [2] = {id = 100, name = "火把"}
    }
}
local mainMap = {startPoint = {x = 19198, y = 201, z = 19176}, width = 10}

-- 外网keepwork服资源~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- local uiRes = {
-- 	background_1 = {hash="FpKKiBPaJLCyM5-JDMlBgoqWuLcV",pid="1295",ext="png",}, -- 左侧UI背景（蓝条）
-- 	background_2 = {hash="FpKKiBPaJLCyM5-JDMlBgoqWuLcV",pid="1295",ext="png",}, -- 传送按钮背景
-- 	background_3 = {hash="Fs_LiV_0DICfgEc69wE5uk3iG7s6",pid="1296",ext="png",},-- 商店UI背景
-- 	icon_money = {hash="Fj7IIHK0FAaJhSVWR8iN63cfJTDE",pid="1591",ext="png",},
-- 	icon_bag = {hash="FtQGxlxhxe9eNxhxa4SgdfWoJYE1",pid="1298",ext="png",},
-- 	icon_grade = {hash="Fl3MvvWonEuR3H8HPvPHe34ng89E",pid="1299",ext="png",},
-- 	icon_strength = {hash="FhgtATyixwSg2P2mPatsyEaeMgE7",pid="1300",ext="png",},
-- 	icon_tool = {hash="FgyPysiQp5IApPwdiK1X6Daw-6FE",pid="1301",ext="png",},
-- 	button_close = {hash="Fjycp49eOZVOYBXy81g3xOFVfhn2",pid="1302",ext="png",},
-- 	button_shop_yellow = {hash="Fh0geuFJYg8PlOLMtP4QWudexvhp",pid="1303",ext="png",},
-- 	button_shop_green = {hash="FpArwgfQsa5xeWXFf7XtsuRTSoOK",pid="1304",ext="png",},
-- 	button_left = {hash="FhbLWPEZqHROxcJb5I-G_5gvESQQ",pid="1305",ext="png",},
-- 	button_right = {hash="Fgk5RuHiM_pzzi7LKKcqjLjmDgES",pid="1306",ext="png",},
-- }
-- 外网keepwork服资源~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 腾讯1服资源~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local uiRes = {
    background_1 = {hash = "FpKKiBPaJLCyM5-JDMlBgoqWuLcV", pid = "19", ext = "png"}, -- 左侧UI背景（蓝条）
    background_2 = {hash = "FglRfgd6Mrbqy4YzlOWE4gNxZY41", pid = "21", ext = "png"}, -- 传送按钮背景
    background_3 = {hash = "Fs_LiV_0DICfgEc69wE5uk3iG7s6", pid = "23", ext = "png"}, -- 商店UI背景
    icon_money = {hash = "Fj7IIHK0FAaJhSVWR8iN63cfJTDE", pid = "24", ext = "png"},
    icon_bag = {hash = "FtQGxlxhxe9eNxhxa4SgdfWoJYE1", pid = "26", ext = "png"},
    icon_grade = {hash = "Fl3MvvWonEuR3H8HPvPHe34ng89E", pid = "27", ext = "png"},
    icon_strength = {hash = "FhgtATyixwSg2P2mPatsyEaeMgE7", pid = "29", ext = "png"},
    icon_tool = {hash = "FgyPysiQp5IApPwdiK1X6Daw-6FE", pid = "30", ext = "png"},
    button_close = {hash = "Fjycp49eOZVOYBXy81g3xOFVfhn2", pid = "33", ext = "png"},
    button_shop_yellow = {hash = "Fh0geuFJYg8PlOLMtP4QWudexvhp", pid = "35", ext = "png"},
    button_shop_green = {hash = "FpArwgfQsa5xeWXFf7XtsuRTSoOK", pid = "36", ext = "png"},
    button_left = {hash = "FhbLWPEZqHROxcJb5I-G_5gvESQQ", pid = "38", ext = "png"},
    button_right = {hash = "Fgk5RuHiM_pzzi7LKKcqjLjmDgES", pid = "37", ext = "png"}
}
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local gameUi = {
    -- 鼠标所指方块信息
    {
        ui_name = "UI_blockInfo",
        type = "Text",
        align = "_ctb",
        text = function()
            if not Client then
                return
            end
            local name, color, info, infoColor = Client.getBlockInfoUiText()
            return info or ""
        end,
        font_size = 40,
        y = -90,
        x = 0,
        font_bold = true,
        height = 50,
        width = 1000,
        text_format = 5,
        text_border = true,
        font_color = function()
            if not Client then
                return
            end
            local name, color, info, infoColor = Client.getBlockInfoUiText()
            return color or "255 255 0"
        end,
        background_color = "255 255 0",
        visible = false
    },
    -- 挖掘方块-名称+等级
    {
        ui_name = "UI_blockName",
        type = "Text",
        align = "_ctb",
        text_border = true,
        text = function()
            if not Client then
                return
            end
            local name, color, info, infoColor = Client.getBlockInfoUiText()
            return name or ""
        end,
        font_size = 40,
        y = -192,
        x = 0,
        font_bold = true,
        height = 50,
        width = 500,
        text_format = 1,
        font_color = function()
            if not Client then
                return
            end
            local name, color, info, infoColor = Client.getBlockInfoUiText()
            return color or "255 255 0"
        end,
        background_color = "255 255 0",
        visible = false
    },
    -- 挖掘进度条-背景
    {
        ui_name = "UI_miningProgress_background",
        type = "Picture",
        align = "_ctb",
        y = -140,
        x = 0,
        height = 50,
        width = 450,
        visible = false,
        background_color = "255 255 255 128"
    },
    -- 挖掘进度条
    {
        ui_name = "UI_miningProgress",
        type = "Picture",
        align = "_ctb",
        y = -142,
        x = 0,
        height = 46,
        width = 10,
        background_color = function()
            if not Client then
                return
            end
            local name, color, info, infoColor = Client.getBlockInfoUiText()
            return color
        end,
        visible = false
    },
    -- 挖掘方块-icon
    {
        ui_name = "UI_miningProgress_icon",
        type = "Picture",
        background = function()
            if not Client then
                return
            end
            local name, color, info, infoColor, id = Client.getBlockInfoUiText()
            if not id or id == 0 then
                return ""
            end
            return CreateItemStack(id):GetIcon()
        end,
        align = "_ctb",
        y = -140,
        x = 0,
        height = 50,
        width = 50,
        visible = true
    },
    -- 当前深度
    {
        ui_name = "UI_depth",
        type = "Text",
        align = "_ctt",
        shadow = false,
        text = function()
            local x, y, z = Player:GetBlockPos()
            local depth = mainMap.startPoint.y + 1 - y
            if depth <= 0 then
                depth = "地表"
            end
            if version > 0.1 then
                return tostring(depth)
            end
            return "当前深度:" .. depth
        end,
        font_size = 40,
        font_bold = true,
        y = 5,
        x = 110,
        height = 50,
        width = 500,
        text_format = 2,
        font_color = "255 255 255",
        background_color = "255 255 0",
        visible = true
    },
    -- 金钱-背景
    {
        ui_name = "UI_info_money_background",
        background = uiRes.background_1,
        type = "Picture",
        align = "_lb",
        y = -189,
        x = 10,
        height = 60,
        width = 300,
        background_color = "255 255 255 200",
        visible = true
    },
    -- 金钱-icon
    {
        ui_name = "UI_info_money_icon",
        background = uiRes.icon_money,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_money_background", "y") - 5
        end,
        x = 15,
        height = 50,
        width = 50,
        visible = true
    },
    -- 金钱-text
    {
        ui_name = "UI_info_money_text",
        type = "Text",
        align = "_lb",
        shadow = false,
        text = function()
            if not Client then
                return
            end
            local playerInfo = Client.playerInfo
            if --[[not next(playerInfo)]]playerInfo:empty() then
                return
            end
            return PublicFunction.convertNumber(playerInfo.money)
        end,
        font_size = 35,
        y = function()
            return Client.getUiValue("UI_info_money_background", "y") - 3
        end,
        x = 33,
        height = 50,
        width = 300,
        text_format = 1,
        font_bold = true,
        font_color = "255 255 255",
        visible = true
    },
    -- 获得金钱效果
    {
        ui_name = "UI_addMoney",
        type = "Text",
        align = "_ct",
        text = "+500￥",
        font_size = 100,
        font_bold = true,
        y = -50,
        _y = -50,
        x = 0,
        height = 120,
        width = 1200,
        text_format = 1,
        font_color = "255 255 0",
        _font_color = "255 255 0",
        background_color = "255 255 0",
        visible = false
    },
    -- 背包-背景
    {
        ui_name = "UI_info_bag_background",
        background = uiRes.background_1,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_money_background", "y") + 60
        end,
        x = 10,
        height = 60,
        width = 300,
        background_color = "255 255 255 200",
        visible = true
    },
    -- 背包-icon
    {
        ui_name = "UI_info_bag_icon",
        background = uiRes.icon_bag,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_bag_background", "y") - 5
        end,
        x = 15,
        height = 50,
        width = 50,
        visible = true
    },
    -- 背包-text
    {
        ui_name = "UI_info_bag_text",
        type = "Text",
        align = "_lb",
        shadow = false,
        text = function()
            if not Client then
                return
            end
            local playerInfo = Client.playerInfo
            if --[[not next(playerInfo)]]playerInfo:empty() then
                return
            end
            return (playerInfo.carryAmount or 0) .. "/" .. (playerInfo.capacity or 0)
        end,
        font_size = 35,
        y = function()
            return Client.getUiValue("UI_info_bag_background", "y") - 3
        end,
        x = 35,
        height = 50,
        width = 300,
        text_format = 1,
        font_bold = true,
        font_color = function()
            if not Client then
                return
            end
            local playerInfo = Client.playerInfo
            if --[[not next(playerInfo)]]playerInfo:empty() then
                return
            end
            if (playerInfo.carryAmount or 0) < (playerInfo.capacity or 0) then
                return "255 255 255"
            else
                return "255 0 0"
            end
        end,
        visible = true
    },
    -- 等级-背景
    {
        ui_name = "UI_info_grade_background",
        background = uiRes.background_1,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_money_background", "y") + 120
        end,
        x = 10,
        height = 60,
        width = 300,
        background_color = "255 255 255 200",
        visible = true
    },
    -- 等级-icon
    {
        ui_name = "UI_info_grade_icon",
        background = uiRes.icon_grade,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_grade_background", "y") - 5
        end,
        x = 12,
        height = 45,
        width = 55,
        visible = true
    },
    -- 等级-text
    {
        ui_name = "UI_info_grade_text",
        type = "Text",
        align = "_lb",
        shadow = false,
        text = function()
            if not Client then
                return
            end
            local playerInfo = Client.playerInfo
            if --[[not next(playerInfo)]]playerInfo:empty() then
                return
            end
            return "矿镐等级:" .. (playerInfo.toolGrade or "?")
        end,
        font_size = 30,
        y = function()
            return Client.getUiValue("UI_info_grade_background", "y") + 1
        end,
        x = 20,
        height = 50,
        width = 300,
        text_format = 1,
        font_bold = true,
        font_color = "255 255 255",
        visible = true
    },
    -- 效率-背景
    {
        ui_name = "UI_info_strength_background",
        background = uiRes.background_1,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_money_background", "y") + 180
        end,
        x = 10,
        height = 60,
        width = 300,
        background_color = "255 255 255 200",
        visible = true
    },
    -- 效率-icon
    {
        ui_name = "UI_info_strength_icon",
        background = uiRes.icon_strength,
        type = "Picture",
        align = "_lb",
        y = function()
            return Client.getUiValue("UI_info_strength_background", "y") - 5
        end,
        x = 15,
        height = 50,
        width = 60,
        visible = true
    },
    -- 效率-text
    {
        ui_name = "UI_info_speed_text",
        type = "Text",
        align = "_lb",
        shadow = false,
        text = function()
            if not Client then
                return
            end
            local playerInfo = Client.playerInfo
            if --[[not next(playerInfo)]]playerInfo:empty() then
                return
            end
            return "挖掘效率:" .. Client.getMiningPower()
        end,
        font_size = 30,
        y = function()
            return Client.getUiValue("UI_info_strength_background", "y") + 1
        end,
        x = 20,
        height = 50,
        width = 300,
        text_format = 1,
        font_bold = true,
        font_color = "255 255 255",
        visible = true
    },
    -- 回到地面传送按钮
    {
        ui_name = "UI_moveToHome",
        type = "Button",
        shadow = false,
        background = uiRes.background_2,
        text = "传送至地表",
        font_color = "255 255 255",
        font_bold = true,
        font_size = 30,
        align = "_ctt",
        x = 450,
        y = 5,
        width = 160,
        height = 50,
        onclick = function()
            mousePressing_left = false
            if canQuickMove then
                MessageBox(
                    "是否快速移动回到地表？",
                    function()
                        canQuickMove = false
                        Router.send("quickMove", {id = GetPlayerId(), quickMovePos = {x = homeX, y = homeY, z = homeZ}})
                        Delay(
                            10 * 1000,
                            function()
                                canQuickMove = true
                            end
                        )
                    end
                )
            else
                MessageBox("快速移动功能冷却中，请等待10秒。")
            end
        end,
        visible = true,
        background_color = "255 255 255"
    },
    -- 快捷键tip
    {
        ui_name = "UI_info_speed_text",
        type = "Text",
        align = "_ctt",
        text = "(快捷键T)",
        font_size = 20,
        y = 50,
        x = 556,
        height = 25,
        width = 300,
        text_format = 0,
        font_color = "255 255 255 150",
        visible = true
    },
    -- 排行榜-tip
    {
        ui_name = "UI_rankingList_tip",
        type = "Text",
        align = "_rt",
        text = "(按tab显示/隐藏排行榜)",
        font_size = 18,
        y = function()
            return Client.getUiValue("UI_rankingList_text", "y") - 35
        end,
        x = function()
            return Client.getUiValue("UI_rankingList_text", "x") - 81
        end,
        height = 500,
        width = 200,
        text_format = 0,
        font_color = "255 255 255 100",
        visible = true
    },
    -- 排行榜-文字
    {
        ui_name = "UI_rankingList_text",
        type = "Text",
        align = "rt",
        text = "玩家名      挖掘方块     金钱",
        font_size = 18,
        y = 100,
        x = -50,
        height = 500,
        width = 300,
        text_format = 0,
        font_color = "255 255 255",
        visible = true
    },
    -- 排行榜-玩家名
    {
        ui_name = "UI_rankingList_name",
        type = "Text",
        align = "_rt",
        text = "",
        font_size = 18,
        y = function()
            return Client.getUiValue("UI_rankingList_text", "y") + 30
        end,
        x = -265,
        height = 500,
        width = 100,
        text_format = 0,
        font_color = "255 255 255 150",
        font_bold = true,
        visible = true
    },
    -- 排行榜-挖方块数
    {
        ui_name = "UI_rankingList_blockMined",
        type = "Text",
        align = "_rt",
        text = "",
        font_size = 18,
        y = function()
            return Client.getUiValue("UI_rankingList_name", "y")
        end,
        x = function()
            return Client.getUiValue("UI_rankingList_name", "x") + 105
        end,
        height = 500,
        width = 100,
        text_format = 0,
        font_color = "255 255 255 150",
        font_bold = true,
        visible = true
    },
    -- 排行榜-金钱
    {
        ui_name = "UI_rankingList_money",
        type = "Text",
        align = "_rt",
        text = "",
        font_size = 18,
        y = function()
            return Client.getUiValue("UI_rankingList_name", "y")
        end,
        x = function()
            return Client.getUiValue("UI_rankingList_name", "x") + 308
        end,
        height = 500,
        width = 200,
        text_format = 0,
        font_color = "255 255 255 150",
        font_bold = true,
        visible = true
    },
    -- help-tip
    {
        ui_name = "UI_help_tip",
        type = "Text",
        align = "_lt",
        text = "(按H打开教程)",
        font_size = 20,
        y = 5,
        x = 5,
        height = 25,
        width = 200,
        text_format = 0,
        font_color = "255 255 255 100",
        visible = true
    },
    -- help
    {
        ui_name = "UI_help",
        type = "Button",
        text = "《淘金者井下作业安全生产劳动手册》\n\n1、按住鼠标左键挖掘，挖到的矿物会到背包中，把矿石带到我矿场主的面前，会帮助自动折算成金币。\n2、金币可以用来在商店购买提升挖矿效率的和装下更多矿石的背包，以及礼物盒。\n3、礼物盒中随机放入了各种服装，有闲钱了的时候请务必尝试一下\n4、所处位置越深可挖到的矿物价值越高，点击右下角的深度按钮可快速回到地表，键盘快捷键【T】。\n5、可使用ctrl+鼠标滚轮调整镜头距离。光线较暗时，放置火把照亮周围。\n6、逃跑到外面的世界，将会获得一定数量的卡车币。如果重新回来，矿场主提高矿石回收价格。\n7、每过一段时间，矿井会发生一次塌方，届时将强制撤离\n（点击任意位置关闭教程）",
        font_color = "255 255 255",
        font_bold = true,
        font_size = 40,
        align = "_lt",
        x = 0,
        y = 0,
        width = function()
            local width, height = GetScreenSize()
            return width or 1920
        end,
        height = function()
            local width, height = GetScreenSize()
            return height or 1080
        end,
        onclick = function()
            Client.hideUi("UI_help")
        end,
        visible = true,
        background_color = "255 255 255"
    },
    -- 商店UI-背景(工具、背包共用)
    {
        ui_name = "UI_shop",
        background = uiRes.background_3,
        type = "Picture",
        align = "_ct",
        y = 100,
        x = 0,
        width = 960,
        height = 560,
        visible = false,
        shopType = "tool",
        -- zorder = 10,
        selectedIndex = 1
    },
    -- 商店UI-关闭
    {
        ui_name = "UI_shop_close",
        type = "Button",
        background = uiRes.button_close,
        align = "_ct",
        x = function()
            local x = Client.getUiValue("UI_shop", "width")
            return x / 2 - Client.getUiValue("UI_shop_close", "width") - 855
        end,
        y = function()
            local y = Client.getUiValue("UI_shop", "height")
            return -y / 2 + Client.getUiValue("UI_shop_close", "height") +95
        end,
        width = 50,
        height = 50,
        onclick = function()
            EnableAutoCamera(true)
            Client.setUiValue("UI_shop", "visible", false)
        end,
        visible = function()
            return Client.getUiValue("UI_shop", "visible")
        end,
        background_color = "255 255 255",
        -- zorder = 10
    },
    -- 商店UI-标题
    {
        ui_name = "UI_shop_title",
        type = "Text",
        align = "_ct",
        text_border = true,
        text = function()
            local text = ""
            if not Client then
                return
            end
            local shopType = Client.getUiValue("UI_shop", "shopType")
            if shopType == "tool" then
                text = "工具商店"
            elseif shopType == "bag" then
                text = "背包商店"
            end
            return text
        end,
        font_size = 40,
        y = function()
            local y = Client.getUiValue("UI_shop", "height")
            return -y / 2 + Client.getUiValue("UI_shop_title", "height") +100
        end,
        x = 0,
        height = 50,
        width = 400,
        font_bold = true,
        text_format = 1,
        font_color = "255 255 255",
        visible = function()
            return Client.getUiValue("UI_shop", "visible")
        end
    },
    -- 商店UI-升级物品icon
    {
        ui_name = "UI_shop_icon",
        background = function()
            if not Client then
                return
            end
            local shopType = Client.getUiValue("UI_shop", "shopType")
            local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
            if shopType == "tool" then
                GetResourceImage(
                    Config.Tool[selectedIndex].mIcon.mResource,
                    function(path, err)
                        Config.Tool[selectedIndex].mIcon.mFile = path
                    end
                )
                return Config.Tool[selectedIndex].mIcon.mFile or uiRes.icon_tool
            elseif shopType == "bag" then
                GetResourceImage(
                    Config.Bag[selectedIndex].mIcon.mResource,
                    function(path, err)
                        Config.Bag[selectedIndex].mIcon.mFile = path
                    end
                )
                return Config.Bag[selectedIndex].mIcon.mFile or uiRes.icon_bag
            end
        end,
        type = "Picture",
        align = "_ct",
        y = function()
            local y = Client.getUiValue("UI_shop", "height")
            return -y / 2 + 300
        end,
        x = 0,
        height = 200,
        width = 200,
        visible = function()
            return Client.getUiValue("UI_shop", "visible")
        end
    },
    -- 商店UI-升级物品描述
    {
        ui_name = "UI_shop_desc",
        type = "Text",
        align = "_ct",
        text_border = true,
        text = function()
            local text = ""
            if not Client then
                return
            end
            local shopType = Client.getUiValue("UI_shop", "shopType")
            local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
            if shopType == "tool" then
                text =
                    text ..
                    "等级：" ..
                        selectedIndex ..
                            "\n挖掘效率：" ..
                                grade.toolGrade[selectedIndex].power ..
                                    "\n挖掘速度：" .. grade.toolGrade[selectedIndex].speed
            elseif shopType == "bag" then
                text = text .. "等级：" .. selectedIndex .. "\n背包容量：" .. grade.bagGrade[selectedIndex].capacity
            end
            return text
        end,
        font_size = 35,
        y = function()
            local y = Client.getUiValue("UI_shop", "height")
            return -y / 2 + 480
        end,
        x = 0,
        height = 150,
        width = 400,
        font_bold = true,
        text_format = 1,
        font_color = "255 255 255",
        visible = function()
            return Client.getUiValue("UI_shop", "visible")
        end
    },
    -- 商店UI-底部按钮
    {
        ui_name = "UI_shop_button",
        type = "Button",
        background = function()
            if not Client then
                return
            end
            if
                (Client.getUiValue("UI_shop_button", "text") or "") == "点击装备" or
                    (Client.getUiValue("UI_shop_button", "text") or "") == "已装备"
             then
                return uiRes.button_shop_green
            else
                return uiRes.button_shop_yellow
            end
        end,
        align = "_ct",
        x = 0,
        text = function()
            local text = ""
            if not Client then
                return
            end
            local playerInfo = Client.playerInfo or {}
            if not playerInfo.purchased then
                return
            end
            local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
            local shopType = Client.getUiValue("UI_shop", "shopType")
            if shopType == "tool" then
                if playerInfo.toolGrade == selectedIndex then
                    text = "已装备"
                elseif playerInfo.purchased.tool[selectedIndex] then
                    text = "点击装备"
                else
                    text = PublicFunction.convertNumber(grade.toolGrade[selectedIndex].price) .. "￥"
                end
            elseif shopType == "bag" then
                if playerInfo.bagGrade == selectedIndex then
                    text = "已装备"
                elseif playerInfo.purchased.bag[selectedIndex] then
                    text = "点击装备"
                else
                    text = PublicFunction.convertNumber(grade.bagGrade[selectedIndex].price) .. "￥"
                end
            end
            return text
        end,
        font_size = 35,
        font_bold = true,
        font_color = "255 255 255",
        y = function()
            local y = Client.getUiValue("UI_shop", "height")
            return y / 2 - Client.getUiValue("UI_shop_button", "height") + 120
        end,
        width = 350,
        height = 70,
        onclick = function()
            local state = Client.getUiValue("UI_shop_button", "text")
            if state == "已装备" then -- 按钮无效
            elseif state == "点击装备" then -- 装备
                local playerInfo = Client.playerInfo or {}
                local shopType = Client.getUiValue("UI_shop", "shopType")
                local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
                local selectedItem = Client.getSelectedItem()
                if shopType == "bag" and (playerInfo.carryAmount or 0) > (selectedItem.capacity or 0) then
                    MessageBox("当前携带矿物太多，请先去出售！")
                    return
                end
                Router.send("equip", {id = GetPlayerId(), itemType = shopType, grade = selectedIndex})
            else -- 购买
                local shopType = Client.getUiValue("UI_shop", "shopType")
                local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
                local selectedItem = Client.getSelectedItem()
                local playerInfo = Client.playerInfo or {}
                if not selectedItem then
                    return
                else
                    if Client.playerInfo.money >= selectedItem.price then
                        Router.send("buy", {id = GetPlayerId(), shopType = shopType, grade = selectedIndex})
                        showMoneyUI("- " .. (PublicFunction.convertNumber(selectedItem.price) or "0") .. "￥")
                    else
                        MessageBox("金钱不足，继续努力挖矿吧！")
                    end
                end
            end
        end,
        visible = function()
            return Client.getUiValue("UI_shop", "visible")
        end,
        background_color = "255 255 0"
    },
    -- 商店UI-上一页
    {
        ui_name = "UI_shop_button_left",
        type = "Button",
        background = uiRes.button_left,
        align = "_ct",
        x = function()
            local x = Client.getUiValue("UI_shop", "width")
            return -x / 2 + Client.getUiValue("UI_shop_button_left", "width")
        end,
        y = 100,
        width = 86,
        height = 100,
        onclick = function()
            local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
            Client.setUiValue("UI_shop", "selectedIndex", selectedIndex - 1)
        end,
        visible = function()
            if not Client then
                return false
            end
            if not Client.getUiValue("UI_shop", "visible") then
                return false
            else
                local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
                local shopType = Client.getUiValue("UI_shop", "shopType")
                if shopType == "tool" then
                    if grade.toolGrade[selectedIndex - 1] then
                        return true
                    else
                        return false
                    end
                elseif shopType == "bag" then
                    if grade.bagGrade[selectedIndex - 1] then
                        return true
                    else
                        return false
                    end
                end
            end
            return false
        end
    },
    -- 商店UI-下一页
    {
        ui_name = "UI_shop_button_right",
        type = "Button",
        background = uiRes.button_right,
        align = "_ct",
        x = function()
            local x = Client.getUiValue("UI_shop", "width")
            return x / 2 - Client.getUiValue("UI_shop_button_right", "width")
        end,
        y = 100,
        width = 86,
        height = 100,
        onclick = function()
            local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
            Client.setUiValue("UI_shop", "selectedIndex", selectedIndex + 1)
        end,
        visible = function()
            if not Client then
                return false
            end
            if not Client.getUiValue("UI_shop", "visible") then
                return false
            else
                local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
                local shopType = Client.getUiValue("UI_shop", "shopType")
                if shopType == "tool" then
                    if grade.toolGrade[selectedIndex + 1] then
                        return true
                    else
                        return false
                    end
                elseif shopType == "bag" then
                    if grade.bagGrade[selectedIndex + 1] then
                        return true
                    else
                        return false
                    end
                end
            end
            return false
        end
    }
}

function CopyLuaTable(t)
    local function copy(t, res)
        for k, v in pairs(t) do
            if type(v) ~= "table" then
                res[k] = v
            else
                res[k] = {}
                copy(v, res[k])
            end
        end
    end
    local res = {}
    copy(t, res)
    return res
end

function main()
    --cmd("/shader 4")
    if isServer then
        Server.main()
    end
    Client.init()
end

function clear()
    Player:SetSpeedScale(1)
    Player:SetScaling(1)
    if Client.mGravity then
        Player:SetGravity(Client.mGravity)
    end
    CameraZoomInOut(10)
    SetPermission("toggleFly", true)
    SetPermission("edit", true)
    SetPermission("teleport", true)
    if isServer and Server then
        Server.destroyNpc("all")
        Router.broadcast("clear", {})
    end
    Server = nil

    BagUI.close()
    DiscardUI.close()
    if Client.mCloseAvatarPlayers then
        for player_id, _ in pairs(Client.mCloseAvatarPlayers) do
            local entity = GetEntityById(player_id)
            if entity then
                PublicFunction.openAvatar(entity)
            end
        end
        Client.mCloseAvatarPlayers = nil
    end
end

function update()
    if not Server or not Client then
        return
    end
    if isServer then
        Server.checkPlayerList()
        Server.broadcastBlockData()
        Server.update_npc()
    end

    Client.setNpcDisplayName()

    local check = Client.canMine()
    if mousePressing_left then
        if type(check) == "string" then
            tip(check, {channel = "miningError", color = "ff0000"})
        elseif type(check) == "table" then
            --tip("",{channel = "miningError", color = "ff0000"})
            Client.startMining()
        end
    end

    Client.checkNPC()
    Client.updateUI()
    Client.updateToolAvatar()
    BlockEffect.update()
end

function Server.update_npc()
    for k, v in pairs(Server.npcs or {}) do
        if npc[k].update then
            local entity = Server.getNpc(k)
            if entity then
                npc[k].update(entity)
            end
        end
    end
end

function Server.broadcastBlockData()
    if next(Server.blockData_temp) then
        Router.broadcast("setBlockData", {dataTb = Server.blockData_temp})
        Server.blockData_temp = {}
    end
end

function Server.checkPlayerList()
    allEntities = GetAllEntities()
    for k, v in pairs(Server.playerInfo or {}) do
        if not Server.isInRoom(GetEntityById(k)) and v.onLine then
            -- 玩家离开 playerLeave
            Server.playerInfo[k].onLine = false
        end
    end
end

function Server.isInRoom(playerEntity)
    allEntities = GetAllEntities()
    for k, v in pairs(allEntities) do
        if v:GetType() == "PlayerMP" then
            if v == playerEntity then
                return true
            end
        end
    end
    return false
end

function handleInput(event)
    if not Client then
        return
    end
    if event.event_type == "keyPressEvent" then
        keyPressed[event.keyname] = true
        if event.keyname == "DIK_T" then
            mousePressing_left = false
            if canQuickMove then
                MessageBox(
                    "是否快速移动回到地表？",
                    function()
                        canQuickMove = false
                        Router.send("quickMove", {id = GetPlayerId(), quickMovePos = {x = homeX, y = homeY, z = homeZ}})
                        Delay(
                            10 * 1000,
                            function()
                                canQuickMove = true
                            end
                        )
                    end
                )
            else
                MessageBox("快速移动功能冷却中，请等待10秒。")
            end
        elseif event.keyname == "DIK_TAB" then
            -- elseif event.keyname == "DIK_N" then
            -- 	echotable(Server.blockData)
            Client.showOrHideRankingListUi()
        elseif event.keyname == "DIK_H" then
            local UI_help = Client.getUi("UI_help")
            UI_help.visible = not UI_help.visible
        elseif event.keyname == "DIK_F5" then
            if cameraMode == 0 then
                cameraMode = 1
                cameradist = cameradist_default_mode_1
                SetCameraMode(cameraMode)
                CameraZoomInOut(cameradist)
            else
                cameraMode = 0
                cameradist = cameradist_default_mode_0
                SetCameraMode(cameraMode)
                CameraZoomInOut(cameradist)
            end
            return true
        end
    elseif event.event_type == "keyReleaseEvent" then
        keyPressed[event.keyname] = nil
    end
    if event.event_type == "mouseMoveEvent" then
        local isShowBlockInfoUi
        local pick = Pick()
        local x, y, z = pick.blockX, pick.blockY, pick.blockZ
        if x then
            if PublicFunction.getBlockInfoById(GetBlockId(x, y, z)) then
                isShowBlockInfoUi = true
            end
        end

        if isShowBlockInfoUi then
            Client.blockInfoUi("open")
        else
            Client.blockInfoUi("close")
        end
    end

    if event.event_type == "mouseWheelEvent" and event.ctrl_pressed then
        if event.mouse_wheel == 1 then -- up
            cameradist = cameradist * 0.9
            if cameradist <= 1 then
                cameradist = 1
            end
        elseif event.mouse_wheel == -1 then -- down
            cameradist = cameradist * 1.1
            if cameradist >= 10 then
                cameradist = 10
            end
        end
        CameraZoomInOut(cameradist)
        return true
    end

    if event.event_type == "mousePressEvent"then
        if event.mouse_button == "left" or event.mouse_button == "right" then
            local pick = Pick()
            if event.mouse_button == "left" then
                mousePressing_left = true
                if Client.clickNpc(pick.entity) then
                    mousePressing_left = false
                    return
                end
            end
            if pick.blockX then
                local tx,ty,tz = pick.blockX,pick.blockY,pick.blockZ
                Delay(500,function (t)
                    local function isMusicButton(x,y,z)
                        for k,v in pairs(Config.PlayMusic.buttons) do
                            local l = v.location
                            if l[1] == x and l[2] == y and l[3] == z then
                                return true
                            end
                        end
                        return false
                    end
                    local id,data = GetBlockFull(tx,ty,tz)
                    if id == 105 and data and data > 8 then
                        local b = isMusicButton(tx,ty,tz)
                        if b then
                            Router.send("OrderMusic",{mID = GetPlayerId()})
                        end
                    end
                end)
            end
        end
    end

    if event.event_type == "mouseReleaseEvent" and event.mouse_button == "left" then
        mousePressing_left = false
    end

    if event.event_type == "mouseReleaseEvent" and event.mouse_button == "right" then
        local pick = Pick()
        local x, y, z, side = pick.blockX, pick.blockY, pick.blockZ, pick.side
        if not x then
            return
        end
        if not PublicFunction.getBlockInfoById(GetBlockId(x, y, z)) then
            return
        end
        if GetItemStackInHand() == itemId.tool[2].id and y < mainMap.startPoint.y then -- 放火把
            local torchData = {
                [5] = {x = 0, y = 1, z = 0, data = 5},
                [4] = {x = 0, y = -1, z = 0, data = 6},
                [3] = {x = 0, y = 0, z = 1, data = 2},
                [2] = {x = 0, y = 0, z = -1, data = 4},
                [1] = {x = 1, y = 0, z = 0, data = 3},
                [0] = {x = -1, y = 0, z = 0, data = 1}
            }
            local data = torchData[side]
            local x_new, y_new, z_new = x + data.x, y + data.y, z + data.z
            if GetBlockId(x_new, y_new, z_new) == 0 then
                SetBlock(x_new, y_new, z_new, itemId.tool[2].id, data.data)
            end
        end
    end
end

function Client.initShopUi(shopType)
    if not Client then
        return
    end
    local playerInfo = Client.playerInfo
    local selectedIndex = 1
    if shopType == "tool" then
        selectedIndex = playerInfo.toolGrade
        if grade.toolGrade[selectedIndex + 1] and not playerInfo.purchased.tool[selectedIndex + 1] then
            selectedIndex = selectedIndex + 1
        end
    elseif shopType == "bag" then
        selectedIndex = playerInfo.bagGrade
        if grade.bagGrade[selectedIndex + 1] and not playerInfo.purchased.bag[selectedIndex + 1] then
            selectedIndex = selectedIndex + 1
        end
    end
    EnableAutoCamera(false)
    Client.setUiValue("UI_shop", "visible", true)
    Client.setUiValue("UI_shop", "shopType", shopType)
    Client.setUiValue("UI_shop", "selectedIndex", selectedIndex)
end

function Client.getSelectedItem()
    if not Client then
        return
    end
    local shopType = Client.getUiValue("UI_shop", "shopType")
    local selectedIndex = Client.getUiValue("UI_shop", "selectedIndex")
    if shopType == "tool" then
        return grade.toolGrade[selectedIndex]
    elseif shopType == "bag" then
        return grade.bagGrade[selectedIndex]
    end
end

function PublicFunction.getRankName(blockMined)
    local name = ""
    local temp = 0
    for k, v in pairs(rankName) do
        if blockMined >= k and k >= temp then
            name = v
            temp = k
        end
    end
    return name
end

function Client.getMiningSpeed()
    if not Client.playerInfo.toolGrade then
        return 0
    end
    return grade.toolGrade[Client.playerInfo.toolGrade].speed
end

function Client.getMiningPower()
    return PublicFunction.getMiningPower(Client.playerInfo)
end

function Client.canMine()
    local pick = Pick()
    local x, y, z = pick.blockX, pick.blockY, pick.blockZ
    if not x or y > 201 then
        return false
    end
    local blockInfo = PublicFunction.getBlockInfoById(GetBlockId(x, y, z))
    local playerInfo = Client.playerInfo
    if blockInfo --[[GetItemStackInHand() == itemId.tool[1].id]] and not GetItemStackInHand() then
        local xx, yy, zz = Player:GetBlockPos()
        local dist = math.sqrt((xx - x) ^ 2 + (yy - y) ^ 2 + (zz - z) ^ 2)
        if dist < 3.5 then
            if blockInfo.grade <= (playerInfo.toolGrade or 0) then
                Client.showSelectBlock(x, y, z, selectBlockColor.right)
                return blockInfo
            else
                Client.showSelectBlock(x, y, z, selectBlockColor.wrong)
                return "矿镐等级不足，请升级矿镐。"
            end
        else -- 距离远，不让挖
            Client.showSelectBlock(x, y, z, selectBlockColor.wrong)
            Client.endMining()
            return "距离过远，请靠近挖掘"
        end
    else
        Client.hideSelectBlock()
    end
end

function Client.startMining()
    if Client.miningInfo.timer then
        return
    end
    local pick = Pick()
    local x, y, z = pick.blockX, pick.blockY, pick.blockZ
    if not x then
        return
    end
    Client.miningInfo = {
        x = x,
        y = y,
        z = z,
        progress = 0,
        blockInfo = PublicFunction.getBlockInfoById(GetBlockId(x, y, z))
    }
    Client.miningInfo.timer = {}
    local loopTime = 40
    Timer(
        loopTime,
        function(t)
            if not Client then
                return
            end
            if not Client.isMoving() then
                --cmd("/anim 233")
                local anim = 233
                if string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "镐子") then
                    anim = 171
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "棍") then
                    anim = 251
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "水") then
                    anim = 185
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "神叉") then
                    anim = 171
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "熨斗") then
                    anim = 171
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "诺贝尔") then
                    anim = 251
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "风筒") then
                    anim = 185
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "平底锅") then
                    anim = 171
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "键盘") then
                    anim = 251
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "手枪") then
                    anim = 185
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "斧子") then
                    anim = 175
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "冲锋枪") then
                    anim = 189
                elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "剑") then
                    anim = 251
                end
                if Client.mAnimation ~= anim then
                    Client.mAnimation = anim
                    cmd("/anim " .. tostring(Client.mAnimation))
                    Player:GetInnerObject():SetField("UpperAnimID", -1)
                end
            end
            Client.miningInfo.timer = t
            if GetItemStackInHand() --[[~= itemId.tool[1].id]] then
                Client.endMining()
                return
            end

            if not Server then
                Client.endMining()
                return
            end
            local x, y, z = Client.miningInfo.x, Client.miningInfo.y, Client.miningInfo.z
            local pick = Pick()
            if not pick.blockX then
                Client.endMining()
                return
            end
            if pick.blockX ~= x or pick.blockY ~= y or pick.blockZ ~= z then
                Client.endMining()
                return
            end
            if not mousePressing_left then
                Client.endMining()
                return
            end
            if GetBlockId(x, y, z) == 0 then
                Client.endMining()
                return
            end

            if Client.miningInfo.progress >= 1 then
                Client.endMining()
                local playerInfo = Client.playerInfo
                if playerInfo.carryAmount < playerInfo.capacity then
                    Router.send("mineBlock", {id = GetPlayerId(), pos = {x = x, y = y, z = z}})
                else
                    MessageBox("背包已满，按【T】键回到地表出售携带的矿石，或升级你的背包。")
                    mousePressing_left = false
                end
                return
            end

            local add = Client.getMiningSpeed() * loopTime / 1000 / Client.miningInfo.blockInfo.miningSpeed
            if add >= loopTime / 250 then
                add = loopTime / 250
            end
            Client.miningInfo.progress = Client.miningInfo.progress + add
            local UI_miningProgress = Client.getUi("UI_miningProgress")
            UI_miningProgress.width =
                10 + math.floor((Client.getUi("UI_miningProgress_background").width - 10) * Client.miningInfo.progress)
            if UI_miningProgress.width >= Client.getUi("UI_miningProgress_background").width - 4 then
                UI_miningProgress.width = Client.getUi("UI_miningProgress_background").width - 4
            end
        end
    )
end

function Client.endMining()
    if Client.miningInfo.timer then
        if Client.miningInfo.timer.stop then
            local UI_miningProgress = Client.getUi("UI_miningProgress")
            UI_miningProgress.width = 10
            Client.miningInfo.timer:stop()
            Client.miningInfo.timer = nil
            --cmd("/anim 0")
            Client.mAnimation = nil
            Client.playStandAnimation()
        end
    end
end

function Client.showSelectBlock(x, y, z, color)
    Client.hideSelectBlock()
    createSelectBlocks({{x, y, z}}, color)
end

function Client.hideSelectBlock()
    for k, v in pairs(selectBlockColor) do
        destroyAllSelectBlocks(v)
    end
end

function Client.clickNpc(entity)
    if entity then
        local x, y, z = Player:GetBlockPos()
        local xx, yy, zz = entity:GetBlockPos()
        local dist = math.sqrt((x - xx) ^ 2 + (y - yy) ^ 2 + (z - zz) ^ 2)

        for k, v in pairs(Client.npcs or {}) do
            if v.id == entity.entityId then
                if npc[k].onclick and dist <= (npc[k].effectiveRange or 99999) then
                    npc[k].onclick(entity)
                end
                return true
            end
        end
    end
end

function PublicFunction.convertNumber(number)
    if type(number) ~= "number" then
        return ""
    end
    local temp = {}
    local s = string.format("%.0f",number)
    while string.len(s) > 4 do
        table.insert(temp, string.sub(s, -4))
        s = string.sub(s, 1, string.len(s) - 4)
    end
    for i = #temp, 1, -1 do
        s = s .. "," .. temp[i]
    end
    return s
end

function PublicFunction.getMiningTime(toolMiningSpeed, blockMiningSpeed)
    local time
    time = blockMiningSpeed / toolMiningSpeed
    if (time or 0) < 0.25 then
        time = 0.25
    end
    return time
end

function PublicFunction.computePrice(blockInfo, count, playerInfo)
    local version_0_2 = playerInfo.mVersion_0_2 or {}
    local addition = 1
    if version_0_2.mBag and version_0_2.mAvatarInfo then
        for k, v in version_0_2.mAvatarInfo:pairs() do
            local bag_type = PublicFunction.mapAvatarTypeToBagType(k)
            local avatar_type = PublicFunction.mapAvatarTypeToConfigType(k)
            local check = version_0_2.mBag[bag_type] and Config.Avatar[avatar_type] and version_0_2.mBag[bag_type].mItems[v] and Config.Avatar[avatar_type][version_0_2.mBag[bag_type].mItems[v].mConfigIndex]
            if check then
                addition =
                    addition *
                    (Config.Avatar[avatar_type][version_0_2.mBag[bag_type].mItems[v].mConfigIndex].mOreValue or 1)
                if k == "mPet" then
                    local item = version_0_2.mBag[bag_type].mItems[v]
                    local buffs = GlobalFunction.parsePetRGB(item.mRGB)
                    local additions = GlobalFunction.getPetLevelAddition(item.mLevel)
                    if buffs["矿石价值"] then
                        addition = addition * additions["矿石价值"][buffs["矿石价值"]]
                    end
                end
            else
                echotable("devilwalk:PublicFunction.computePrice:")
                echotable(version_0_2)
            end
        end
    end
    local ret = math.floor(blockInfo.price * count * (1 + (version_0_2.mRelifeTime or 0) / 100) * addition)
    return ret
end

function PublicFunction.updateVersion_0_2(playerInfo)
    for i, level in pairs(grade.toolGrade) do
        Config.Tool[i].mBuff = Config.Tool[i].mBuff or {}
        Config.Tool[i].mBuff["挖掘力量"] = grade.toolGrade[i].power
        Config.Tool[i].mBuff["挖掘速度"] = grade.toolGrade[i].speed
    end
    for i, level in pairs(grade.bagGrade) do
        Config.Bag[i].mBuff = Config.Bag[i].mBuff or {}
        Config.Bag[i].mBuff["背包容量"] = grade.bagGrade[i].capacity
    end

    playerInfo.mVersion_0_2 = playerInfo.mVersion_0_2 or {}
    local version_0_2 = playerInfo.mVersion_0_2
    version_0_2.mBag =
        version_0_2.mBag or
        {
            ["工具框"] = {mType = "工具框", mItems = {}},
            ["背包框"] = {mType = "背包框", mItems = {}},
            ["头部框"] = {mType = "头部框", mItems = {}},
            ["上身框"] = {mType = "上身框", mItems = {}},
            ["下身框"] = {mType = "下身框", mItems = {}},
            ["礼物盒框"] = {mType = "礼物盒框", mItems = {}, mLuckies = {}},
            ["宠物框"] = {mType = "宠物框", mItems = {}}
        }
    if playerInfo.purchased and playerInfo.purchased.tool then
        local tool_list = version_0_2.mBag["工具框"]
        for i, level in playerInfo.purchased.tool:pairs() do
            tool_list.mItems[i] = {mConfigIndex = i, mEquiped = playerInfo.toolGrade == i}
        end
    end

    if playerInfo.purchased and playerInfo.purchased.bag then
        local bag_list = version_0_2.mBag["背包框"]
        for i, level in playerInfo.purchased.bag:pairs() do
            bag_list.mItems[i] = {mConfigIndex = i, mEquiped = playerInfo.bagGrade == i}
        end
    end
end

function PublicFunction.getMiningPower(playerInfo)
    if not playerInfo.toolGrade then
        return 0
    end
    local addition = 1
    local version_0_2 = playerInfo.mVersion_0_2 or {}
    if version_0_2.mBag and version_0_2.mAvatarInfo then
        for k, v in version_0_2.mAvatarInfo:pairs() do
            local bag_type = PublicFunction.mapAvatarTypeToBagType(k)
            local avatar_type = PublicFunction.mapAvatarTypeToConfigType(k)
            local check = version_0_2.mBag[bag_type] and Config.Avatar[avatar_type] and version_0_2.mBag[bag_type].mItems[v] and Config.Avatar[avatar_type][version_0_2.mBag[bag_type].mItems[v].mConfigIndex]
            if check then
                addition =
                    addition *
                    (Config.Avatar[avatar_type][version_0_2.mBag[bag_type].mItems[v].mConfigIndex].mPowerAddition or 1)
                if k == "mPet" then
                    local item = version_0_2.mBag[bag_type].mItems[v]
                    local buffs = GlobalFunction.parsePetRGB(item.mRGB)
                    local additions = GlobalFunction.getPetLevelAddition(item.mLevel)
                    if buffs["挖掘效率"] then
                        addition = addition * additions["挖掘效率"][buffs["挖掘效率"]]
                    end
                end
            else
                echotable("devilwalk:PublicFunction.getMiningPower:")
                echotable(version_0_2)
            end
        end
    end
    return math.floor(grade.toolGrade[playerInfo.toolGrade].power * addition)
end

function Client.getBlockInfoUiText()
    local text = ""
    local pick = Pick()
    local color = "255 255 0"
    local blockId
    local blockName
    local blockColor = "255 255 0"
    local x, y, z = pick.blockX, pick.blockY, pick.blockZ
    if pick.blockX then
        Client.lastPick = Client.lastPick or {}

        blockId = GetBlockId(x, y, z)
        local blockInfo = PublicFunction.getBlockInfoById(blockId)
        if not blockInfo then
            return ""
        end
        -- text = text..blockInfo.name.."】 "
        blockName = blockInfo.name
        text = text .. "等级:" .. blockInfo.grade .. ""
        blockColor = blockInfo.color or blockColor
        local blockData = Client.getBlockData(x, y, z)
        blockName = blockName .. " - "
        if not blockData then
            blockName = blockName .. blockInfo.defaultAmount
            if x ~= Client.lastPick.x or y ~= Client.lastPick.y or z ~= Client.lastPick.z then -- 无数据，向服务器请求
                Router.send("getBlockData", {id = GetPlayerId(), pos = {x = x, y = y, z = z}})
            end
        else
            blockName = blockName .. blockData.amount
        end
        local tPrice = string.format("%.0f",blockInfo.price)
        text = text .. "   回收单价:" .. tPrice
        Client.lastPick = {x = x, y = y, z = z}

        local playerInfo = Client.playerInfo
        if playerInfo then
            if (playerInfo.toolGrade or 0) < blockInfo.grade then
                color = "255 0 0"
            end
        end
    end

    return blockName, blockColor, text, color, blockId
end

function Client.getBlockData(x, y, z)
    return Client.blockData[x .. "," .. y .. "," .. z]
end

function Client.blockInfoUi(order)
    if order == "open" then
        Client.showUi("UI_blockInfo")
        Client.showUi("UI_miningProgress_background")
        Client.showUi("UI_miningProgress")
        Client.showUi("UI_miningProgress_icon")
        Client.showUi("UI_blockName")
    elseif order == "close" then
        Client.hideUi("UI_blockInfo")
        Client.hideUi("UI_miningProgress_background")
        Client.hideUi("UI_miningProgress")
        Client.hideUi("UI_miningProgress_icon")
        Client.hideUi("UI_blockName")
    end
end

function Client.isMoving()
    if
        keyPressed["DIK_A"] or keyPressed["DIK_SPACE"] or keyPressed["DIK_W"] or keyPressed["DIK_S"] or
            keyPressed["DIK_D"] or
            keyPressed["DIK_LEFT"] or
            keyPressed["DIK_RIGHT"] or
            keyPressed["DIK_UP"] or
            keyPressed["DIK_DOWN"]
     then
        return true
    end
end

function Client.playStandAnimation()
    local anim = 0
    if string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "镐子") then
    elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "手枪") then
        anim = 181
    elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "斧子") then
        anim = 172
    elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "冲锋枪") then
        anim = 190
    elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "剑") then
    elseif string.find(Config.Tool[Client.playerInfo.toolGrade].mName, "水") then
        anim = 190

    end
    Client.mAnimation = anim
    cmd("/anim " .. tostring(Client.mAnimation))
    Player:GetInnerObject():SetField("UpperAnimID", Client.mAnimation)
end

function Server.main()
    Server.gaming = true
    Server.initMiningArea()
    Server.destroyNpc("all")
    Server.createNpc("all")
    Server.updateRankingList()
end

function Server.resetMiningArea()
    tip("矿区发生了安全事故，已抢修完毕，大家可以继续开采了。", {}, true)
    for k, v in pairs(Server.playerInfo) do
        if v.onLine then
            Router.send("quickMove", {id = k, quickMovePos = {x = homeX, y = homeY, z = homeZ}})
        end
    end
    Server.initMiningArea()
end

function Server.initMiningArea()
    local x, y, z, width = mainMap.startPoint.x, mainMap.startPoint.y, mainMap.startPoint.z, mainMap.width

    -- for i=x-100,x+100 do
    -- 	for j=z-100,z+100 do
    -- 		SetBlock(i,y,j,123)
    -- 		SetBlock(i,0,j,123)
    -- 	end
    -- end
    --
    -- for i=x-100,x+100 do
    -- 	for j=0,y do
    -- 		SetBlock(i,j,z-100,123)
    -- 		SetBlock(i,j,z+100,123)
    -- 	end
    -- end
    --
    -- for i=z-100,z+100 do
    -- 	for j=0,y do
    -- 		SetBlock(x-100,j,i,123)
    -- 		SetBlock(x+100,j,i,123)
    -- 	end
    -- end
    Server.blockData = {}
    for i = x, x + width - 1 do
        for j = z, z + width - 1 do
            Server.generateBlock_normal(i, y, j)
        end
    end

    local resetTime = 20 -- 分钟
    Delay(
        resetTime * 60 * 1000,
        function()
            if not Server then
                return
            end
            Server.resetMiningArea()
        end
    )

    ----------------------------------------------ext map---------------------------------------------------
    for _,map in pairs(ExtMaps) do
        local x, y, z, width = map.startPoint.x, map.startPoint.y, map.startPoint.z, map.width
        for i = x, x + width - 1 do
            for j = z, z + width - 1 do
                Server.generateBlock_normal(i, y, j)
            end
        end
    end
end

function Server.generateBlock_around(x, y, z)
    for i = x - 1, x + 1 do
        for j = y - 1, y + 1 do
            for k = z - 1, z + 1 do
                if (i == x and j == y) or (i == x and k == z) or (j == y and k == z) then -- 只生成最多5个，看不到的方块不生产
                    if not Server.getBlockData(i, j, k) and j < mainMap.startPoint.y then
                        local depth = mainMap.startPoint.y + 1 - j
                        local probability = 0.15 + 0.15 * depth / 200
                        if math.random() <= probability then
                            Server.generateBlock_special(i, j, k)
                        else
                            Server.generateBlock_normal(i, j, k)
                        end
                    end
                end
            end
        end
    end
end

function Server.generateBlock_special(x, y, z) -- 生成特殊方块，尝试1000次
    local mining_block = miningBlock
    for k,map in pairs(ExtMaps) do
        if map.startPoint.x - 150 <= x and map.startPoint.x + 150 >= x
        and map.startPoint.z - 150 <= z and map.startPoint.z + 150 >= z
        then
            mining_block = ExtMiningBlocks[k]
        end
    end



    local depth = mainMap.startPoint.y + 1 - y
    local count = 0
    local temp = {}
    local info
    for k, v in pairs(mining_block.special) do
        if v.minDepth <= depth and v.maxDepth >= depth then
            table.insert(temp, v)
        end
    end

    if next(temp) then
        while count < 1000 do
            local randomInfo = temp[math.random(#temp)]
            if math.random() <= randomInfo.probability then
                Server.generateBlock_main(x, y, z, randomInfo)
                return
            end

            count = count + 1
        end
    else
        Server.generateBlock_normal(x, y, z)
    end
    Server.generateBlock_normal(x, y, z)
end

function Server.generateBlock_normal(x, y, z) -- 根据深度，寻找生成的方块
    local mining_block = miningBlock
    for k,map in pairs(ExtMaps) do
        if map.startPoint.x - 150 <= x and map.startPoint.x + 150 >= x
        and map.startPoint.z - 150 <= z and map.startPoint.z + 150 >= z
        then
            mining_block = ExtMiningBlocks[k]
        end
    end



    local depth = mainMap.startPoint.y + 1 - y
    local info
    local depth_temp = 0
    for k, v in pairs(mining_block.normal) do
        if depth >= k and depth_temp < k then
            info = v
            depth_temp = k
        end
    end

    if info then
        Server.generateBlock_main(x, y, z, info)
    end
end

function Server.generateBlock_main(x, y, z, info)
    if GetBlockId(x, y, z) == 123 or  GetBlockId(x, y, z) ==17 or y < 1 then
        return
    end

    SetBlock(x, y, z, info.id)
    Server.blockData[x .. "," .. y .. "," .. z] = {amount = info.defaultAmount}
    Server.rareBlockShowTip(x,y,z,info.id) --稀有矿出现广播

    table.insert(
        Server.blockData_temp,
        {pos = {x = x, y = y, z = z}, data = Server.blockData[x .. "," .. y .. "," .. z]}
    )
end

function Server.getBlockData(x, y, z) -- 返回nil表示该位置未生成过方块
    return Server.blockData[x .. "," .. y .. "," .. z]
end
function Server.rareBlockShowTip(x,y,z,bId)
    if Server.isBroadcastBlock(bId) then
        Timer(120*1000,function (t)
            local b = Server.getBlockData(x,y,z)
            if not first then
                first = true
            else
                if b and b.amount >0 and GetBlockId(x,y,z) == bId then
                    local info = PublicFunction.getBlockInfoById(GetBlockId(x, y, z))
                    tip("稀有矿的【"..info.name.."】已经出现，但是似乎还没人注意到！", {channel = "rareBlockshow"},true)
                else
                    t:stop()
                end
            end
        end)
    end
end
function Server.rareBlockGetTip(playerName,bId)
    if Server.isBroadcastBlock(bId) then
        local info = PublicFunction.getBlockInfoById(bId)
        tip("恭喜 "..playerName.." 获得稀有矿【"..info.name.."】",{channel = "rareBlockDig"},true)
    end

end
function Server.isBroadcastBlock(id)
    for _,blockId in pairs(broadcastBlocks) do
        if id == blockId then
            return true
        end
    end
    return false
end
function Server.boxBroadcast(playerId,playerName,boxName,presentName)
    tip("恭喜 "..playerName.." 打开了【"..boxName.."】并获得了【"..presentName.."】",{channel = playerId.."openBox"},true)
end
function Server.rankNameUpgradeTip(playerId,playerName,newRankName)
    tip("恭喜 "..playerName.." 被提拔为【"..newRankName.."】",{channel = playerId.."rankUpgrade"},true)
end
function Server.playMusicTip(playerId,playerName,musicName)
    tip(playerName.."点播了一首《"..musicName.."》",{channel = playerId.."music"},true)
end
function Server.mineBlock(x, y, z, playerId)
    local block = Server.getBlockData(x, y, z)
    if not block then
        return
    end
    local playerInfo = Server.playerInfo[playerId]
    local power --[[grade.toolGrade[playerInfo.toolGrade].power]] = PublicFunction.getMiningPower(playerInfo)
    local blockInfo = PublicFunction.getBlockInfoById(GetBlockId(x, y, z))
    if not blockInfo then
        return
    end
    -- check grade
    if playerInfo.toolGrade < blockInfo.grade then
        Router.sendto(
            playerId,
            "msg",
            {type = "tip", data = {color = "ff0000"}, msg = "grade error, maybe you cheated :)"}
        )
        return
    end
    -- checkTime
    -- local miningTime = PublicFunction.getMiningTime(grade.toolGrade[playerInfo.toolGrade].speed, blockInfo.miningSpeed)
    -- if (Server.miningTime[playerId] or 0) + miningTime*0.75 < os.clock() then
    -- 	Server.miningTime[playerId] = os.clock()
    -- else
    -- 	Router.sendto(playerId, "msg", {type = "tip", data = {color = "ff0000"}, msg = "time error, maybe you cheated :)"})
    -- 	return
    -- end
    local currentAmount = block.amount
    local blockId = GetBlockId(x, y, z)
    local result = {}
    if block.amount > 0 then
        --CreateBlockPieces(blockId, x,y,z, (power - 0.5)/10)
        block.amount = block.amount - power
        if block.amount <= 0 then
            Server.rareBlockGetTip(playerInfo.name,GetBlockId(x, y, z))
            SetBlock(x, y, z, 0)
            Server.generateBlock_around(x, y, z)
            if block.amount < 0 then
                result.amount = currentAmount
                block.amount = 0
            else
                result.amount = power
            end
        else
            result.amount = power
        end

        if result.amount > 0 then -- 挖成功，向客户端返回结果
            if playerInfo.capacity > playerInfo.carryAmount then
                local get
                local currentAmount = playerInfo.carryAmount
                playerInfo.carryAmount = playerInfo.carryAmount + result.amount
                if playerInfo.carryAmount <= playerInfo.capacity then
                    get = result.amount
                else
                    playerInfo.carryAmount = playerInfo.capacity
                    get = playerInfo.capacity - currentAmount
                end
                local lastRankName = PublicFunction.getRankName(playerInfo.blockMined)
                playerInfo.blockMined = playerInfo.blockMined + get
                local currentRankName = PublicFunction.getRankName(playerInfo.blockMined)
                -- 称号变化广播
                if lastRankName ~= currentRankName then
                    Server.rankNameUpgradeTip(playerId,playerInfo.name,currentRankName)
                end
                playerInfo.carryMoney = playerInfo.carryMoney + PublicFunction.computePrice(blockInfo, get, playerInfo)
                if
                    playerInfo.mVersion_0_2 and playerInfo.mVersion_0_2.mAvatarInfo and
                        playerInfo.mVersion_0_2.mAvatarInfo.mPet
                 then
                    local item = playerInfo.mVersion_0_2.mBag["宠物框"].mItems[playerInfo.mVersion_0_2.mAvatarInfo.mPet]
                    if item and item.mLevel < 10 then
                        local cfg = Config.Avatar.Pet[item.mConfigIndex]
                        for i = 1, 3 do
                            if cfg.mLevelUp[item.mLevel + 1][i].mBlockID == blockId then
                                item.mExp[i] =
                                    math.min((item.mExp[i] or 0) + get, cfg.mLevelUp[item.mLevel + 1][i].mCount)
                            end
                        end
                        local level_up = true
                        for i = 1, 3 do
                            if item.mExp[i] ~= cfg.mLevelUp[item.mLevel + 1][i].mCount then
                                level_up = false
                            end
                        end
                        if level_up then
                            item.mExp = {0, 0, 0}
                            item.mLevel = item.mLevel + 1
                            Router.sendto(playerId, "PetLevelUp")
                        end
                    end
                end
                Router.sendto(playerId, "setPlayerInfo", {playerInfo = playerInfo:clone()})
                local _x, _y, _z = ConvertToRealPosition(x, y, z)
                Router.broadcast(
                    "blockParticle",
                    {id = blockId, count = get, fromPos = {x = _x, y = _y, z = _z}, playerId = playerId}
                )
            end
        end

        table.insert(
            Server.blockData_temp,
            {pos = {x = x, y = y, z = z}, data = Server.blockData[x .. "," .. y .. "," .. z]}
        )
    -- 待广播数据
    end
end

function Server.updateRankingList()
    local loopTime = 500
    Timer(
        loopTime,
        function(t)
            if not Server then
                t:stop()
                return
            end
            if next(Server.playerInfo or {}) then
                local rankingList = {}
                for k, v in pairs(Server.playerInfo) do
                    if v.onLine then
                        local player = GetEntityById(k)
                        if player then
                            relife_time = 0
                            if v.mVersion_0_2 then
                                relife_time = v.mVersion_0_2.mRelifeTime or 0
                            end
                            table.insert(
                                rankingList,
                                {
                                    name = player.nickname,
                                    id = k,
                                    blockMined = v.blockMined,
                                    money = v.money,
                                    mRelifeTime = relife_time
                                }
                            )
                        end
                    end
                end
                table.sort(
                    rankingList,
                    function(a, b)
                        return a.blockMined > b.blockMined
                    end
                )
                Router.broadcast("refreshRankingList", {rankingList = rankingList})
            end
        end
    )
end

function Server.getNpc(npcName)
    if Server.npcs[npcName] then
        return GetEntityById(Server.npcs[npcName].id)
    end
end

function Server.createNpc(npcName)
    if not Server.gaming then
        return
    end
    local function _createNpc(name, x, y, z, item_id, scaling, facing, dummy, model, displayName, onCreate)
        local entity = Server.getNpc(name)
        if entity then
            entity:Destroy()
        end

        entity =
            CreateNPC(
            {
                bx = x,
                by = y,
                bz = z,
                item_id = item_id,
                facing = facing,
                displayName = displayName,
                can_random_move = false
            },
            nil
        )
        if math.floor(x) < x or math.floor(y) < y or math.floor(z) < z then
          local floatx,floaty,floatz = (x-math.floor(x)),(y-math.floor(y)),(z-math.floor(z))
          local rx,ry,rz = ConvertToRealPosition(math.floor(x),math.floor(y),math.floor(z))
          rx = rx + floatx
          ry = ry + floaty
          rz = rz + floatz
          entity:SetPosition(rx,ry,rz)
        end
        -- if displayName then
        -- 	entity:ShowHeadOnDisplay(true)
        -- end
        if scaling then
            entity:SetScaling(scaling)
        end

        if dummy then
            entity:SetStaticBlocker(true);
            entity:SetGravity(0)
            -- entity:SetDummy(true)
        end
        if model then
            entity:setModelFromResource(model)
        end
        if onCreate then
            onCreate(entity)
        end
        Server.npcs[name] = {id = entity.entityId, displayName = displayName}
    end

    if npcName == "all" then
        for k, v in pairs(npc) do
            if v.spawnAtStart then
                _createNpc(
                    k,
                    v.x,
                    v.y,
                    v.z,
                    v.item_id,
                    v.scaling,
                    v.facing,
                    v.dummy,
                    v.model,
                    v.displayName,
                    v.onCreate
                )
            end
        end
    else
        if npc[npcName] then
            local create = npc[npcName]
            _createNpc(
                npcName,
                create.x,
                create.y,
                create.z,
                create.item_id,
                create.scaling,
                create.facing,
                create.dummy,
                create.model,
                create.displayName,
                create.onCreate
            )
        end
    end
    Router.broadcast("refreshNpcList", {npcs = Server.npcs})
end

function Server.destroyNpc(npcName)
    if npcName == "all" then
        -- debug -----------------------------------------------
        for k, v in pairs(Server.npcs) do
            local npc = GetEntityById(v.id)
            if npc then
                npc:Destroy()
            end
        end

        -- debug -----------------------------------------------
        local allEntities = GetAllEntities()
        for k, v in pairs(allEntities) do
            if v:GetType() == "EntityNPCOnline" then
                v:Destroy()
            end
        end
    else
        if Server.npcs[npcName] then
            local entity = GetEntityById(Server.npcs[npcName].id)
            if entity then
                entity:Destroy()
            end
        end
    end
end

function Client.init()
    Player:SetSpeedScale(0)
    EnableWalkUpBlock(false)
    SetPermission("toggleFly", false)
    SetPermission("edit", false)
    SetPermission("teleport", false)
    SetPermission("clickEntity",false)
    if Config.mDebug then
        Client.playerInfo.money = 99999999999999
        Client.playerInfo.blockMined = 10000000000
        Client.playerInfo.mVersion_0_2 = {}
        Client.playerInfo.mVersion_0_2.mBag = {
            ["工具框"] = {mType = "工具框", mItems = {}},
            ["背包框"] = {mType = "背包框", mItems = {}},
            ["头部框"] = {mType = "头部框", mItems = {}},
            ["上身框"] = {mType = "上身框", mItems = {}},
            ["下身框"] = {mType = "下身框", mItems = {}},
            ["礼物盒框"] = {mType = "礼物盒框", mItems = {}, mLuckies = {}},
            ["宠物框"] = {mType = "宠物框", mItems = {}}
        }
        for i=1,#Config.Avatar.Body do
            Client.playerInfo.mVersion_0_2.mBag["头部框"].mItems[i] = {mConfigIndex = i}
        end
        for i=1,#Config.Avatar.Body do
            Client.playerInfo.mVersion_0_2.mBag["上身框"].mItems[i] = {mConfigIndex = i}
        end
        for i=1,#Config.Avatar.Leg do
            Client.playerInfo.mVersion_0_2.mBag["下身框"].mItems[i] = {mConfigIndex = i}
        end
        Client.playerInfo.mVersion_0_2.mBag["宠物框"].mItems[1] = {
            mConfigIndex = 1,
            mRGB = {math.random(0, 255), math.random(0, 255), math.random(0, 255)},
            mLevel = 9,
            mExp = {0, 0, 0}
        }
    end
    PublicFunction.updateVersion_0_2(Client.playerInfo)
    Client.initUi()
    Router.send(
        "join",
        {id = GetPlayerId(), SavedData = GetSavedData() or {}},
        function(suc)
            if suc then
                for k, v in pairs(suc.npcs) do
                    Client.npcs[k] = {}
                    for kk, vv in pairs(v) do
                        Client.npcs[k][kk] = vv
                    end
                end
                --Repository.setItem(GetPlayerId(), "inventory", 1, itemId.tool[1].id, 1)
                Repository.setItem(GetPlayerId(), "inventory", 1, 0, 0)
                Repository.setItem(GetPlayerId(), "inventory", 2, itemId.tool[2].id, 1)
                --Client.initUi()
                Player:SetSpeedScale(1.5)
                Player:SetScaling(playerScaling)
                CameraZoomInOut(cameradist_default_mode_0)
            end
        end
    )
end

function Client.initUi()
    for i = 1, #gameUi do
        if
            gameUi[i].ui_name ~= "UI_moveToHome" and gameUi[i].ui_name ~= "UI_rankingList_text" and
                gameUi[i].ui_name ~= "UI_rankingList_tip" and
                gameUi[i].ui_name ~= "UI_rankingList_name" and
                gameUi[i].ui_name ~= "UI_rankingList_blockMined" and
                gameUi[i].ui_name ~= "UI_rankingList_money" and
                gameUi[i].ui_name ~= "UI_info_money_background" and
                gameUi[i].ui_name ~= "UI_info_money_icon" and
                gameUi[i].ui_name ~= "UI_info_money_text" and
                gameUi[i].ui_name ~= "UI_info_bag_background" and
                gameUi[i].ui_name ~= "UI_info_bag_icon" and
                gameUi[i].ui_name ~= "UI_info_bag_text" and
                gameUi[i].ui_name ~= "UI_info_strength_background" and
                gameUi[i].ui_name ~= "UI_info_strength_icon" and
                gameUi[i].ui_name ~= "UI_info_speed_text" and
                gameUi[i].ui_name ~= "UI_info_grade_background" and
                gameUi[i].ui_name ~= "UI_info_grade_icon" and
                gameUi[i].ui_name ~= "UI_info_grade_text" and
                gameUi[i].ui_name ~= "UI_depth"
         then
            GUI.UI(gameUi[i])
        end
    end

    IngameUI[2].params.onclick = function()
        if not BagUI.mUIs then
            local bag = --[[CopyLuaTable(Client.playerInfo.mVersion_0_2.mBag)]]ProtectedData.unserialize(Client.playerInfo.mVersion_0_2.mBag:clone(),1)
            bag.mRelifeTime = Client.playerInfo.mVersion_0_2.mRelifeTime or 0
            BagUI.show(bag)
        else
            BagUI.close()
        end
    end
    IngameUI[19].params.onclick = Client.getUi("UI_moveToHome").onclick
    IngameUI[16].params.onclick = function()
        Client.getUi("UI_help").visible = not Client.getUi("UI_help").visible
    end
    IngameUI[3].params.onclick = function()
        Rebirth1UI[3].params.onclick = function()
            if Client.playerInfo.blockMined < 5000000 then
                MessageBox("你的等级不足,请至少挖满500000块砖，成为【富可敌国】的矿工再来吧！")
                return
            end
            if Client.playerInfo.money < 10000000 then
                MessageBox("你的金钱不足，请至少准备1000万再来找我！")
                return
            end
            local overflow
            if Client.playerInfo.money < 509999999 then
                overflow = 0
            elseif Client.playerInfo.money < 510000000 then
                overflow = 50
            elseif Client.playerInfo.money < 1010000000 then
                overflow = 60
            elseif Client.playerInfo.money < 10010000000 then
                overflow = 70
            elseif Client.playerInfo.money < 100010000000 then
                overflow = 80
            elseif Client.playerInfo.money < 1000010000000 then
                overflow = 90
            else
                overflow = 100
            end
            local scalar
            if Client.playerInfo.money < 110000000 then
                scalar = 1
            elseif Client.playerInfo.money < 210000000 then
                scalar = 1.1
            elseif Client.playerInfo.money < 310000000 then
                scalar = 1.2
            elseif Client.playerInfo.money < 410000000 then
                scalar = 1.3
            elseif Client.playerInfo.money < 510000000 then
                scalar = 1.4
            else
                scalar = 0.00000000001
                -- scalar = 1
            end
            local truck_money = math.ceil(math.ceil((Client.playerInfo.money - 10000000) / 10000000) * scalar + overflow)
            Rebirth1UI.close()
            Rebirth2UI[3].params.onclick = function()
                Rebirth2UI.close()
            end
            Rebirth2UI.mOnClose = function()
                Rebirth3UI[4].params.text =
                    "很不幸，又被抓回黑煤窑了。但在这次逃亡的路上\13\
                幸运地获得了" .. tostring(truck_money) .. "枚卡车币"
                local version_0_2 = Client.playerInfo.mVersion_0_2 or {}
                Rebirth3UI[5].params.text = "第" .. tostring(version_0_2.mRelifeTime or 0) .. "次"
                Rebirth3UI.show()
                Router.send("Escape", {mID = GetPlayerId(), mTruckMoney = truck_money})
            end
            Rebirth2UI.show(truck_money)
        end
        Rebirth1UI.show()
    end
    IngameUI.show()
    MiniStoreUI[11].params.onclick = function()
        local can_buy
        local version_0_2 = Client.playerInfo.mVersion_0_2 or {}
        if Config.Box[MiniStoreUI.mItemIndex].mPrice.mType == "卡车币" then
            can_buy = (version_0_2.mTruckMoney or 0) >= Config.Box[MiniStoreUI.mItemIndex].mPrice.mValue
            showMoneyUI(
                "- " .. (PublicFunction.convertNumber(Config.Box[MiniStoreUI.mItemIndex].mPrice.mValue) or "0") .. "卡车币"
            )
        elseif Config.Box[MiniStoreUI.mItemIndex].mPrice.mType == "金币" then
            can_buy = Client.playerInfo.money >= Config.Box[MiniStoreUI.mItemIndex].mPrice.mValue
            showMoneyUI(
                "- " .. (PublicFunction.convertNumber(Config.Box[MiniStoreUI.mItemIndex].mPrice.mValue) or "0") .. "￥"
            )
        end
        if can_buy then
            Router.send("BuyBox", {mID = GetPlayerId(), mConfigIndex = MiniStoreUI.mItemIndex})
        else
            MessageBox("金钱不足，继续努力挖矿吧！")
        end
    end
end

function Client.getUi(name)
    if "UI_rankingList_text" == name then
        return IngameUI.mUIs["排行榜框"]
    elseif "UI_rankingList_name" == name then
        return IngameUI.mUIs["玩家名"]
    elseif "UI_rankingList_blockMined" == name then
        return IngameUI.mUIs["排行榜挖方块数"]
    elseif "UI_rankingList_money" == name then
        return IngameUI.mUIs["排行榜金钱"]
    end
    for i = 1, #gameUi do
        if gameUi[i].ui_name == name then
            return gameUi[i]
        end
    end
    return {}
end

function Client.getUiValue(ui_name, key)
    local ui = Client.getUi(ui_name)
    if type(ui[key]) == "function" then
        return ui[key]()
    end
    return ui[key]
end

function Client.setUiValue(ui_name, key, value)
    local ui = Client.getUi(ui_name)
    if ui then
        ui[key] = value
    end
end

function Client.showUi(name)
    local ui = Client.getUi(name)
    if ui then
        ui.visible = true
    end
end

function Client.hideUi(name)
    local ui = Client.getUi(name)
    if ui then
        ui.visible = false
    end
end

function Client.showOrHideRankingListUi()
    local UI_rankingList_text = Client.getUi("UI_rankingList_text")
    local UI_rankingList_name = Client.getUi("UI_rankingList_name")
    local UI_rankingList_blockMined = Client.getUi("UI_rankingList_blockMined")
    local UI_rankingList_money = Client.getUi("UI_rankingList_money")
    if UI_rankingList_text.visible then
        Client.hideUi("UI_rankingList_text")
        Client.hideUi("UI_rankingList_name")
        Client.hideUi("UI_rankingList_blockMined")
        Client.hideUi("UI_rankingList_money")
    else
        Client.showUi("UI_rankingList_text")
        Client.showUi("UI_rankingList_name")
        Client.showUi("UI_rankingList_blockMined")
        Client.showUi("UI_rankingList_money")
    end
end

function PublicFunction.getBlockInfoById(id)
    for k, v in pairs(miningBlock) do
        for kk, vv in pairs(v) do
            if id == vv.id then
                return vv
            end
        end
    end

    for _,mining_block in pairs(ExtMiningBlocks) do
        for k, v in pairs(mining_block) do
            for kk, vv in pairs(v) do
                if id == vv.id then
                    return vv
                end
            end
        end
    end
end

function Client.setNpcDisplayName()
    local allEntities = GetAllEntities()
    for k, v in pairs(allEntities) do
        if v:GetType() == "EntityNPCOnline" then
            for kk, vv in pairs(Client.npcs) do
                if vv.id == v.entityId and vv.displayName then
                    if not v._displayNameMark then
                        v._displayNameMark = true
                        SetEntityHeadOnText(v.entityId, vv.displayName, "255 255 0")
                    end
                end
            end
        elseif v:GetType() == "PlayerMP" or v:GetType() == "Player" then
            if v:GetScaling() ~= playerScaling then
                v:SetScaling(playerScaling)
            end
        end
    end
end

function Client.showTip(data, msg)
    cmd(
        string.format(
            "/tip -color #%s -duration %s -%s %s",
            data.color or "ffff00",
            data.duration or 5000,
            data.channel or math.random(9999),
            tostring(msg)
        )
    )
end

function Client.blockParticle(id, count, fromPos, playerId)
    local maxCount = 50
    if count > maxCount then
        count = maxCount
    end
    local speed = 4
    local time = 0.2
    local timeCount = 0
    local dimension_max = 0.4
    local dimension_min = 0.2
    local dimension = dimension_max - (dimension_max - dimension_min) * (count / maxCount)

    local function _particle(count)
        local player = GetEntityById(playerId)
        local px, py, pz
        if player then
            local x, y, z = Player:GetPosition()
            px, py, pz = player:GetPosition()
            py = py + 0.25

            local dist = math.sqrt((x - px) ^ 2 + (y - py) ^ 2 + (z - pz) ^ 2)
            if dist >= 30 then
                return
            end
        else
            return
        end

        local tempFromPos = {
            x = fromPos.x + 0.5 - math.random(),
            y = fromPos.y + 0.5 - math.random(),
            z = fromPos.z + 0.5 - math.random()
        }
        local dist = math.sqrt((px - tempFromPos.x) ^ 2 + (py - tempFromPos.y) ^ 2 + (pz - tempFromPos.z) ^ 2)
        local randomSpeed = speed + (0.5 - math.random(1))
        local p = Particle:new(tempFromPos.x, tempFromPos.y, tempFromPos.z)
        p.width = dimension
        p.height = dimension
        p.quota = 1
        p.emitter_quota = 1
        p.life = dist / randomSpeed
        p.texture = CreateItemStack(id):GetIcon()
        p.emitter = {
            emission_rate = 100,
            velocity = randomSpeed,
            direction = {px - tempFromPos.x, py - tempFromPos.y, pz - tempFromPos.z},
            time_to_live = dist / randomSpeed,
            color = {1, 1, 1, 0.75}
        }
        p.affector = {
            type = "Custom",
            init_particle = function(p)
            end,
            update_particle = function(ps)
                for i, p in ipairs(ps) do
                end
            end
        }

        Delay(
            dist / randomSpeed * 1000,
            function()
                if playerId == GetPlayerId() then
                    -- play sound here
                    if count or 0 <= 10 then
                        cmd("/sound " .. (count or 0) .. " TS/pop.ogg")
                    else
                        cmd("/sound " .. math.random(10) .. " TS/pop.ogg")
                    end
                end
            end
        )
    end

    _particle(1)

    if count > 1 then
        local loopTime = math.floor(time * 1000 / (count - 1))
        Timer(
            loopTime,
            function(t)
                timeCount = timeCount + loopTime
                if not Client then
                    t:stop()
                    return
                end
                if timeCount >= time * 1000 then
                    t:stop()
                end

                _particle(timeCount / loopTime + 1)
            end
        )
    end
end

function PublicFunction.mapAvatarTypeToBagType(t)
    if t == "mHead" then
        return "头部框"
    elseif t == "mBody" then
        return "上身框"
    elseif t == "mLeg" then
        return "下身框"
    elseif t == "mPet" then
        return "宠物框"
    else
        echotable("devilwalk:PublicFunction.mapAvatarTypeToBagType:t:" .. t)
    end
end

function PublicFunction.mapAvatarTypeToConfigType(t)
    if t == "mHead" then
        return "Head"
    elseif t == "mBody" then
        return "Body"
    elseif t == "mLeg" then
        return "Leg"
    elseif t == "mPet" then
        return "Pet"
    else
        echotable("devilwalk:PublicFunction.mapAvatarTypeToConfigType:t:" .. t)
    end
end

function PublicFunction.getUpdateAvatarInfo(playerInfo)
    local ret = {}
    ret.mTool = playerInfo.toolGrade
    ret.mBag = playerInfo.bagGrade
    if playerInfo.mVersion_0_2 and playerInfo.mVersion_0_2.mAvatarInfo then
        playerInfo.mVersion_0_2.mAvatarInfo:foreach(function(k,v)
            local bag_type = PublicFunction.mapAvatarTypeToBagType(k)
            local check = playerInfo.mVersion_0_2.mBag[bag_type] and playerInfo.mVersion_0_2.mBag[bag_type].mItems[v]
            if check then
                ret[k] = playerInfo.mVersion_0_2.mBag[bag_type].mItems[v].mConfigIndex
            else
                echotable("PublicFunction.getUpdateAvatarInfo:")
                echotable(playerInfo.mVersion_0_2)
            end
        end)
    end
    return ret
end

function PublicFunction.updateAvatar(avatarInfo, playerID)
    playerID = playerID or GetPlayerId()
    if not GetEntityById(playerID) then
        return
    end
    local avatar_info = avatarInfo
    local tool, bag, head, body, leg, hand, foot, pet = 1, 1, 1, 1, 1, 1, 1, nil
    if avatar_info and avatar_info.mTool then
        tool = avatar_info.mTool
    end
    if avatar_info and avatar_info.mBag then
        bag = avatar_info.mBag
    end
    if avatar_info and avatar_info.mHead then
        head = avatar_info.mHead
    end
    if avatar_info and avatar_info.mHead then
        head = avatar_info.mHead
    end
    if avatar_info and avatar_info.mBody then
        body = avatar_info.mBody
    end
    if avatar_info and avatar_info.mLeg then
        leg = avatar_info.mLeg
    end
    if avatar_info and avatar_info.mHand then
        hand = avatar_info.mHand
    end
    if avatar_info and avatar_info.mFoot then
        foot = avatar_info.mFoot
    end
    if avatar_info and avatar_info.mPet then
        pet = avatar_info.mPet
    end
    local entity_player = GetEntityById(playerID)
    PublicFunction.closeAvatar(entity_player)
    Client.mCloseAvatarPlayers = Client.mCloseAvatarPlayers or {}
    Client.mCloseAvatarPlayers[playerID] = true
    entity_player:SetMainAssetPath("")
    entity_player:SetMainAssetPath(Config.Avatar.Head[head].mModel.mFiles[1])
    if Config.Avatar.Head[head].mTexture and Config.Avatar.Head[head].mTexture.mFiles[1] then
        SetReplaceableTexture(entity_player, Config.Avatar.Head[head].mTexture.mFiles[1])
    end
    entity_player.mCustomAvatarComponents = {}
    for k, file in pairs(Config.Avatar.Head[head].mModel.mFiles) do
        if k ~= 1 then
            if Config.Avatar.Head[head].mTexture then
                entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                    AddCustomAvatarComponent(file, entity_player, Config.Avatar.Head[head].mTexture.mFiles[k])
            else
                entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                    AddCustomAvatarComponent(file, entity_player)
            end
        end
    end
    for k, file in pairs(Config.Tool[tool].mModel.mFiles) do
        entity_player.mToolAvatars = entity_player.mToolAvatars or {}
        if Config.Tool[tool].mTexture then
            entity_player.mToolAvatars[#entity_player.mToolAvatars + 1] =
                AddCustomAvatarComponent(file, entity_player, Config.Tool[tool].mTexture.mFiles[k])
        else
            entity_player.mToolAvatars[#entity_player.mToolAvatars + 1] = AddCustomAvatarComponent(file, entity_player)
        end
    end
    for k, file in pairs(Config.Bag[bag].mModel.mFiles) do
        if Config.Bag[bag].mTexture then
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player, Config.Bag[bag].mTexture.mFiles[k])
        else
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player)
        end
    end
    for k, file in pairs(Config.Avatar.Body[body].mModel.mFiles) do
        if Config.Avatar.Body[body].mTexture then
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player, Config.Avatar.Body[body].mTexture.mFiles[k])
        else
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player)
        end
    end
    for k, file in pairs(Config.Avatar.Leg[leg].mModel.mFiles) do
        if Config.Avatar.Leg[leg].mTexture then
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player, Config.Avatar.Leg[leg].mTexture.mFiles[k])
        else
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player)
        end
    end
    for k, file in pairs(Config.Avatar.Hand[hand].mModel.mFiles) do
        if Config.Avatar.Hand[hand].mTexture then
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player, Config.Avatar.Hand[hand].mTexture.mFiles[k])
        else
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player)
        end
    end
    for k, file in pairs(Config.Avatar.Foot[foot].mModel.mFiles) do
        if Config.Avatar.Foot[foot].mTexture then
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player, Config.Avatar.Foot[foot].mTexture.mFiles[k])
        else
            entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                AddCustomAvatarComponent(file, entity_player)
        end
    end
    SetReplaceableTexture(entity_player, Config.Avatar.Eye[1].mTexture.mFile, 3)
    SetReplaceableTexture(entity_player, Config.Avatar.Mouth[1].mTexture.mFile, 4)

    local unused_keys = {}
    if Config.Avatar.Head[head].mUnuseds then
        for _,unused in pairs(Config.Avatar.Head[head].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Tool[tool].mUnuseds then
        for _,unused in pairs(Config.Tool[tool].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Bag[bag].mUnuseds then
        for _,unused in pairs(Config.Bag[bag].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Avatar.Body[body].mUnuseds then
        for _,unused in pairs(Config.Avatar.Body[body].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Avatar.Leg[leg].mUnuseds then
        for _,unused in pairs(Config.Avatar.Leg[leg].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Avatar.Hand[hand].mUnuseds then
        for _,unused in pairs(Config.Avatar.Hand[hand].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Avatar.Foot[foot].mUnuseds then
        for _,unused in pairs(Config.Avatar.Foot[foot].mUnuseds) do
            unused_keys[unused.mKey] = true
        end
    end
    if Config.Avatar.Head[head].mOptionals then
        for _,optional in pairs(Config.Avatar.Head[head].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end
    if Config.Tool[tool].mOptionals then
        for _,optional in pairs(Config.Tool[tool].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end
    if Config.Bag[bag].mOptionals then
        for _,optional in pairs(Config.Bag[bag].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end
    if Config.Avatar.Body[body].mOptionals then
        for _,optional in pairs(Config.Avatar.Body[body].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end
    if Config.Avatar.Leg[leg].mOptionals then
        for _,optional in pairs(Config.Avatar.Leg[leg].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end
    if Config.Avatar.Hand[hand].mOptionals then
        for _,optional in pairs(Config.Avatar.Hand[hand].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end
    if Config.Avatar.Foot[foot].mOptionals then
        for _,optional in pairs(Config.Avatar.Foot[foot].mOptionals) do
            if not unused_keys[optional.mKey] then
                for k,file in pairs(optional.mModel.mFiles) do
                    if optional.mTexture then
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player, optional.mTexture.mFiles[k])
                    else
                        entity_player.mCustomAvatarComponents[#entity_player.mCustomAvatarComponents + 1] =
                            AddCustomAvatarComponent(file, entity_player)
                    end
                end
            end
        end
    end

    if pet then
        local equiped = Config.Avatar.Pet[pet]
        if equiped and equiped.mModel then
            if equiped and equiped.mTexture then
                if equiped.mTexture.mFile then
                    if equiped.mModel.mFile then
                        AddAttachment(equiped.mModel.mFile, 29, entity_player, nil, equiped.mTexture.mFile)
                    end
                    if equiped.mModel.mResource then
                        GetResourceModel(
                            equiped.mModel.mResource,
                            function(path, err)
                                AddAttachment(path, 29, entity_player, nil, equiped.mTexture.mFile)
                            end
                        )
                    end
                elseif equiped.mTexture.mResource then
                    GetResourceImage(
                        equiped.mTexture.mResource,
                        function(path, err)
                            if equiped.mModel.mFile then
                                AddAttachment(equiped.mModel.mFile, 29, entity_player, nil, path)
                            end
                            if equiped.mModel.mResource then
                                GetResourceModel(
                                    equiped.mModel.mResource,
                                    function(path, err)
                                        AddAttachment(path, 29, entity_player, nil, path)
                                    end
                                )
                            end
                        end
                    )
                end
            else
                if equiped.mModel.mFile then
                    AddAttachment(equiped.mModel.mFile, 29, entity_player)
                end
                if equiped.mModel.mResource then
                    GetResourceModel(
                        equiped.mModel.mResource,
                        function(path, err)
                            AddAttachment(path, 29, entity_player)
                        end
                    )
                end
            end
        end
        entity_player.mHasPet = true
    end
end

function PublicFunction.closeAvatar(entity)
    if entity.mCustomAvatarComponents then
        for _, model in pairs(entity.mCustomAvatarComponents) do
            RemoveCustomAvatarComponent(model)
        end
    end
    entity.mCustomAvatarComponents = nil
    if entity.mToolAvatars then
        for _, model in pairs(entity.mToolAvatars) do
            RemoveCustomAvatarComponent(model)
        end
    end
    entity.mToolAvatars = nil
    if entity.mHasPet then
        RemoveAttachment(29, entity)
    end
    entity.mHasPet = nil
    CloseAvatar(entity)
end

function PublicFunction.openAvatar(entity)
    PublicFunction.closeAvatar(entity)
    OpenAvatar(entity)
end

function Client.checkNPC()
    if Client.playerInfo.carryMoney and Client.playerInfo.carryMoney > 0 then
        local x, y, z = GetPlayer():GetBlockPos()
        if y == npc.npc_reclaim.y and math.abs(x - npc.npc_reclaim.x) < 3 and math.abs(z - npc.npc_reclaim.z) < 3 then
            npc.npc_reclaim:onclick()
        end
    end
end

function Client.updateUI()
    if IngameUI.mUIs then
        IngameUI.mUIs["显示掘进层数"].text = Client.getUi("UI_depth").text()
        IngameUI.mUIs["金钱数值"].text = Client.getUi("UI_info_money_text").text()
        IngameUI.mUIs["背包显示的数值"].text = Client.getUi("UI_info_bag_text").text()
        local version_0_2 = Client.playerInfo.mVersion_0_2 or {}
        IngameUI.mUIs["卡车币数量"].text = tostring(version_0_2.mTruckMoney or 0)
        IngameUI.mUIs["效率数值"].text = Client.getUi("UI_info_grade_text").text()
    end
    Rebirth2UI.update()
end

function Client.updateToolAvatar()
    local entity = GetPlayer()
    if GetItemStackInHand() then
        if entity.mToolAvatars then
            for _, model in pairs(entity.mToolAvatars) do
                RemoveCustomAvatarComponent(model)
            end
        end
        entity.mToolAvatars = nil
    elseif Client.playerInfo.toolGrade and not entity.mToolAvatars then
        entity.mToolAvatars = {}
        for _, file in pairs(Config.Tool[Client.playerInfo.toolGrade].mModel.mFiles) do
            entity.mToolAvatars[#entity.mToolAvatars + 1] = AddCustomAvatarComponent(file, entity)
        end
    end
end

function tip(msg, data, isBroadcast)
    if isBroadcast then
        Router.broadcast("msg", {type = "tip", msg = msg, data = data or {}})
    else
        Client.showTip((data or {}), msg)
    end
end

Router.receive(
    "msg",
    function(msg) -- client
        if msg.type == "tip" then
            Client.showTip(msg.data, msg.msg)
        elseif msg.type == "msg" then
            MessageBox(msg.msg)
        end
    end
)

Router.receive(
    "join",
    function(msg, res)
        local player = GetEntityById(msg.id)
        for k, v in pairs(Server.playerInfo) do
            if v.name == player.nickname then
                Server.playerInfo[msg.id] = --[[CopyLuaTable(v)]]v
                v = nil
            end
        end
        local SavedData = ProtectedData:new(msg.SavedData or {},1)
        if --[[next(SavedData)]]not SavedData:empty() then
            if (SavedData.version or 0) >= Server.minVersion then
                Server.playerInfo[msg.id] = ProtectedData:new(CopyLuaTable(msg.SavedData), 1)
            else
                Server.playerInfo[msg.id] = ProtectedData:new(CopyLuaTable(defaultPlayerInfo), 1)
            end
        else
            Server.playerInfo[msg.id] = ProtectedData:new(CopyLuaTable(defaultPlayerInfo), 1)
        end
        Server.playerInfo[msg.id].capacity = grade.bagGrade[Server.playerInfo[msg.id].bagGrade].capacity
        Server.playerInfo[msg.id].name = player.nickname
        Server.playerInfo[msg.id].onLine = true
        res:send({npcs = Server.npcs})
        PublicFunction.updateVersion_0_2(Server.playerInfo[msg.id])
        Router.sendto(msg.id, "setPlayerInfo", {playerInfo = Server.playerInfo[msg.id]:clone()})
        --Router.send("quickMove", {id = msg.id, quickMovePos = {x = homeX, y = homeY, z = homeZ}})
        for id,info in pairs(Server.playerInfo) do
            Router.broadcast(
                "UpdateAvatar",
                {mID = id, mAvatarInfo = PublicFunction.getUpdateAvatarInfo(info)}
            )
        end
    end
)

Router.receive(
    "mineBlock",
    function(msg)
        local player = GetEntityById(msg.id)
        local x, y, z = msg.pos.x, msg.pos.y, msg.pos.z
        if GetBlockId(x, y, z) ~= 0 then
            Server.mineBlock(x, y, z, msg.id)
        end
    end
)

Router.receive(
    "clear",
    function()
        EnableAutoCamera(true)
        Client = nil
        if not isServer then
            clear()
        end
    end
)

Router.receive(
    "getBlockData",
    function(msg) -- client to server
        local x, y, z = msg.pos.x, msg.pos.y, msg.pos.z
        count = count or 0
        count = count + 1
        local blockData = Server.getBlockData(x, y, z)
        if blockData then
            local temp = {{pos = {x = x, y = y, z = z}, data = blockData}}
            Router.sendto(msg.id, "setBlockData", {dataTb = temp})
        end
    end
)

Router.receive(
    "setPlayerInfo",
    function(msg) -- server to client
        if not Client then
            return
        end
        local protected_data = ProtectedData:new(msg.playerInfo or {},1)
        protected_data:foreach(function(k,v)
            Client.playerInfo[k] = v
        end)
        -- for k, v in pairs(msg.playerInfo or {}) do
        --     Client.playerInfo[k] = v
        -- end

        if Client.playerInfo.mVersion_0_2 and Client.playerInfo.mVersion_0_2.mAvatarInfo then
            local speed_addition = 1
            local jump_addition = 1
            for k, v in Client.playerInfo.mVersion_0_2.mAvatarInfo:pairs() do
                local bag_type = PublicFunction.mapAvatarTypeToBagType(k)
                local check = Client.playerInfo.mVersion_0_2.mBag[bag_type] and Client.playerInfo.mVersion_0_2.mBag[bag_type].mItems[v] and Config.Avatar[PublicFunction.mapAvatarTypeToConfigType(k)]
                if check then
                    local cfg =
                        Config.Avatar[PublicFunction.mapAvatarTypeToConfigType(k)][
                        Client.playerInfo.mVersion_0_2.mBag[bag_type].mItems[v].mConfigIndex
                    ]
                    speed_addition = speed_addition * (cfg.mSpeed or 1)
                    jump_addition = jump_addition * (cfg.mJump or 1)
                    if k == "mPet" then
                        local item = Client.playerInfo.mVersion_0_2.mBag[bag_type].mItems[v]
                        local buffs = GlobalFunction.parsePetRGB(item.mRGB)
                        local additions = GlobalFunction.getPetLevelAddition(item.mLevel)
                        if buffs["移动速度"] then
                            speed_addition = speed_addition * additions["移动速度"][buffs["移动速度"]]
                        end
                        if buffs["跳跃"] then
                            jump_addition = jump_addition * additions["跳跃"][buffs["跳跃"]]
                        end
                    end
                end
            end
            Player:SetSpeedScale(1.3+ 0.2 * speed_addition)
            Client.mGravity = Client.mGravity or 9.81
            Player:SetGravity(1+(Client.mGravity-1) / (jump_addition*0.9))
        end
    end
)

Router.receive(
    "setBlockData",
    function(msg) -- server to client
        if not Client then
            return
        end
        local dataTb = msg.dataTb or {}
        for i = 1, #dataTb do
            local x, y, z = dataTb[i].pos.x, dataTb[i].pos.y, dataTb[i].pos.z
            Client.blockData[x .. "," .. y .. "," .. z] = {}
            for k, v in pairs(dataTb[i].data) do
                Client.blockData[x .. "," .. y .. "," .. z][k] = v
            end
        end
    end
)

Router.receive(
    "quickMove",
    function(msg) -- clint to server
        local player = GetEntityById(msg.id)
        if player and msg.quickMovePos then
            player:TeleportToBlockPos(msg.quickMovePos.x, msg.quickMovePos.y + 2, msg.quickMovePos.z)
        end
    end
)

Router.receive(
    "sell",
    function(msg, res) -- clint to server
        local playerInfo = Server.playerInfo[msg.id]
        if playerInfo.carryMoney > 0 then
            res:send({get = playerInfo.carryMoney})
            --Router.sendto(msg.id, "msg", {type = "tip", msg = "出售成功。", data = {color = "ffff00"}})
            playerInfo.money = playerInfo.money + playerInfo.carryMoney
            playerInfo.carryMoney = 0
            playerInfo.carryAmount = 0
            Router.sendto(msg.id, "setPlayerInfo", {playerInfo = playerInfo:clone()})
        end
    end
)

-- Router.send("buy", {id = GetPlayerId(), shopType = shopType, grade = selectedIndex})
Router.receive(
    "buy",
    function(msg)
        local playerInfo = Server.playerInfo[msg.id]
        local type = msg.shopType
        local itemGrade = msg.grade
        local item
        if type == "tool" then
            item = grade.toolGrade[itemGrade]
            if item then
                if playerInfo.purchased.tool[itemGrade] then
                    return
                end
            else
                return
            end
        elseif type == "bag" then
            item = grade.bagGrade[itemGrade]
            if item then
                if playerInfo.purchased.bag[itemGrade] then
                    return
                end
            else
                return
            end
        end
        if not item then
            return
        end
        if playerInfo.money >= item.price then
            playerInfo.money = playerInfo.money - item.price
            playerInfo.purchased[type][itemGrade] = true
            if type == "tool" then
                playerInfo.toolGrade = itemGrade
            elseif type == "bag" then
                playerInfo.capacity = item.capacity
                playerInfo.bagGrade = itemGrade
            end
            PublicFunction.updateVersion_0_2(playerInfo)
            Router.sendto(msg.id, "setPlayerInfo", {playerInfo = playerInfo:clone()})
            Router.broadcast(
                "UpdateAvatar",
                {mID = msg.id, mAvatarInfo = PublicFunction.getUpdateAvatarInfo(Server.playerInfo[msg.id])}
            )
        end
    end
)

Router.receive(
    "equip",
    function(msg)
        local playerInfo = Server.playerInfo[msg.id]
        local type = msg.itemType
        local itemGrade = msg.grade
        local item
        if type == "tool" then
            item = grade.toolGrade[itemGrade]
        elseif type == "bag" then
            item = grade.bagGrade[itemGrade]
        end
        if not item then
            return
        end
        if playerInfo.purchased[type][itemGrade] then
            if type == "tool" then
                playerInfo.toolGrade = itemGrade
            elseif type == "bag" then
                playerInfo.capacity = item.capacity
                playerInfo.bagGrade = itemGrade
            end
            PublicFunction.updateVersion_0_2(playerInfo)
            Router.sendto(msg.id, "setPlayerInfo", {playerInfo = playerInfo:clone()})
            Router.broadcast(
                "UpdateAvatar",
                {mID = msg.id, mAvatarInfo = PublicFunction.getUpdateAvatarInfo(playerInfo)}
            )
        end
    end
)

Router.receive(
    "refreshNpcList",
    function(msg) -- client
        if not Client then
            return
        end
        for k, v in pairs(msg.npcs) do
            Client.npcs[k] = {}
            for kk, vv in pairs(v) do
                Client.npcs[k][kk] = vv
            end
        end
    end
)

Router.receive(
    "refreshRankingList",
    function(msg) -- client
        if not Client then
            return
        end
        local rankingList = CopyLuaTable(msg.rankingList)
        local UI_rankingList_name = Client.getUi("UI_rankingList_name")
        UI_rankingList_name.text = ""
        local UI_rankingList_blockMined = Client.getUi("UI_rankingList_blockMined")
        UI_rankingList_blockMined.text = ""
        local UI_rankingList_money = Client.getUi("UI_rankingList_money")
        UI_rankingList_money.text = ""
        for i = 1, #rankingList do
            local player = GetEntityById(rankingList[i].id)
            if player and player.nickname then
                SetEntityHeadOnText(
                    rankingList[i].id,
                    "[" .. PublicFunction.getRankName(rankingList[i].blockMined) .. "]" .. player.nickname,
                    "0 255 0"
                )
            end
            UI_rankingList_name.text = UI_rankingList_name.text .. i .. " ["..PublicFunction.getRankName(rankingList[i].blockMined).."]"..rankingList[i].name .. "\n"
            UI_rankingList_blockMined.text =
                UI_rankingList_blockMined.text .. PublicFunction.convertNumber(rankingList[i].blockMined) .. "\n"
            UI_rankingList_money.text =
                UI_rankingList_money.text .. PublicFunction.convertNumber(rankingList[i].money) .. "\n"
        end

        local ui_rankinglist_escape = IngameUI.mUIs["排行榜逃亡次数"]
        ui_rankinglist_escape.text = ""
        for i = 1, #rankingList do
            ui_rankinglist_escape.text = ui_rankinglist_escape.text .. (rankingList[i].mRelifeTime or 0) .. "\n"
        end
    end
)

Router.receive(
    "blockParticle",
    function(msg) -- client
        if not Client then
            return
        end
        Client.blockParticle(msg.id, msg.count, msg.fromPos, msg.playerId)
    end
)

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

Router.receive(
    "Escape",
    function(msg)
        local playerInfo = Server.playerInfo[msg.mID]
        for k, v in pairs(defaultPlayerInfo) do
            playerInfo[k] = clone(v)
        end
        playerInfo.mVersion_0_2 = playerInfo.mVersion_0_2 or {}
        playerInfo.mVersion_0_2.mTruckMoney = playerInfo.mVersion_0_2.mTruckMoney or 0
        playerInfo.mVersion_0_2.mTruckMoney = playerInfo.mVersion_0_2.mTruckMoney + msg.mTruckMoney
        playerInfo.mVersion_0_2.mRelifeTime = (playerInfo.mVersion_0_2.mRelifeTime or 0) + 1
        if playerInfo.mVersion_0_2 then
            playerInfo.mVersion_0_2.mAvatarInfo = nil
            if playerInfo.mVersion_0_2.mBag then
                playerInfo.mVersion_0_2.mBag["工具框"] = {mType = "工具框", mItems = {}}
                playerInfo.mVersion_0_2.mBag["背包框"] = {mType = "背包框", mItems = {}}
                local bag = playerInfo.mVersion_0_2.mBag["头部框"]
                if bag and bag.mItems then
                    local index = 1
                    while index <= bag.mItems:size() do
                        local cfg = Config.Avatar.Head[bag.mItems[index].mConfigIndex]
                        if not cfg.mInherit then
                            bag.mItems:remove(index)
                        else
                            bag.mItems[index].mEquiped = nil
                            index = index + 1
                        end
                    end
                end
                local bag = playerInfo.mVersion_0_2.mBag["下身框"]
                if bag and bag.mItems then
                    local index = 1
                    while index <= bag.mItems:size() do
                        local cfg = Config.Avatar.Leg[bag.mItems[index].mConfigIndex]
                        if not cfg.mInherit then
                            bag.mItems:remove(index)
                        else
                            bag.mItems[index].mEquiped = nil
                            index = index + 1
                        end
                    end
                end
                local bag = playerInfo.mVersion_0_2.mBag["上身框"]
                if bag and bag.mItems then
                    local index = 1
                    while index <= bag.mItems:size() do
                        local cfg = Config.Avatar.Body[bag.mItems[index].mConfigIndex]
                        if not cfg.mInherit then
                            bag.mItems:remove(index)
                        else
                            bag.mItems[index].mEquiped = nil
                            index = index + 1
                        end
                    end
                end
                local bag = playerInfo.mVersion_0_2.mBag["宠物框"]
                if bag and bag.mItems then
                    for _,item in bag.mItems:pairs() do
                        item.mEquiped = nil
                    end
                end
            end
        end
        PublicFunction.updateVersion_0_2(playerInfo)
        Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
        Router.broadcast("UpdateAvatar", {mID = msg.mID, mAvatarInfo = PublicFunction.getUpdateAvatarInfo(playerInfo)})
    end
)

Router.receive(
    "UpdateAvatar",
    function(msg)
        PublicFunction.updateAvatar(msg.mAvatarInfo, msg.mID)
        if msg.mID == GetPlayerId() then
            Client.playStandAnimation()
        end
    end
)

Router.receive(
    "EquipAvatar",
    function(msg)
        local playerInfo = Server.playerInfo[msg.mID]
        for _, item in pairs(msg.mAvatarInfo) do
            playerInfo.mVersion_0_2.mAvatarInfo = playerInfo.mVersion_0_2.mAvatarInfo or {}
            local avatar_type
            if item.mType == "头部框" then
                avatar_type = "mHead"
            elseif item.mType == "上身框" then
                avatar_type = "mBody"
            elseif item.mType == "下身框" then
                avatar_type = "mLeg"
            elseif item.mType == "宠物框" then
                avatar_type = "mPet"
            end
            if playerInfo.mVersion_0_2.mAvatarInfo[avatar_type] and playerInfo.mVersion_0_2.mBag[item.mType].mItems[playerInfo.mVersion_0_2.mAvatarInfo[avatar_type]] then
                playerInfo.mVersion_0_2.mBag[item.mType].mItems[playerInfo.mVersion_0_2.mAvatarInfo[avatar_type]].mEquiped = nil
            end
            playerInfo.mVersion_0_2.mAvatarInfo[avatar_type] = item.mIndex
            if item.mIndex then
                playerInfo.mVersion_0_2.mBag[item.mType].mItems[item.mIndex].mEquiped = true
            end
        end
        Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
        Router.broadcast("UpdateAvatar", {mID = msg.mID, mAvatarInfo = PublicFunction.getUpdateAvatarInfo(playerInfo)})
    end
)

Router.receive(
    "OpenBox",
    function(msg)
        local playerInfo = Server.playerInfo[msg.mID]
        if not msg.mItem.mOwnered then
            playerInfo.mVersion_0_2.mBag[msg.mItem.mType].mItems[playerInfo.mVersion_0_2.mBag[msg.mItem.mType].mItems:size() + 1] = {
                mConfigIndex = msg.mItem.mConfigIndex,
                mRGB = msg.mItem.mRGB,
                mLevel = msg.mItem.mLevel,
                mExp = msg.mItem.mExp
            }
        end
        Server.boxBroadcast(msg.mID,playerInfo.name,msg.boxName,msg.presentName)
        playerInfo.mVersion_0_2.mBag["礼物盒框"].mItems:remove(msg.mBagItemIndex)
        Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
    end
)

Router.receive(
    "BuyBox",
    function(msg)
        local playerInfo = Server.playerInfo[msg.mID]
        local can_buy
        local version_0_2 = playerInfo.mVersion_0_2 or {}
        if Config.Box[msg.mConfigIndex].mPrice.mType == "卡车币" then
            can_buy = (version_0_2.mTruckMoney or 0) >= Config.Box[msg.mConfigIndex].mPrice.mValue
            if can_buy then
                version_0_2.mTruckMoney = version_0_2.mTruckMoney - Config.Box[msg.mConfigIndex].mPrice.mValue
            end
        elseif Config.Box[msg.mConfigIndex].mPrice.mType == "金币" then
            can_buy = playerInfo.money >= Config.Box[msg.mConfigIndex].mPrice.mValue
            if can_buy then
                playerInfo.money = playerInfo.money - Config.Box[msg.mConfigIndex].mPrice.mValue
            end
        end
        playerInfo.mVersion_0_2.mBag["礼物盒框"].mItems[playerInfo.mVersion_0_2.mBag["礼物盒框"].mItems:size() + 1] = {
            mConfigIndex = msg.mConfigIndex
        }
        Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
    end
)
Router.receive(
    "OrderMusic", --client to server
    function(msg)
        local orderFee = 100000
        local playerInfo = Server.playerInfo[msg.mID]
        local can_buy = playerInfo.money >= orderFee
        local function randomMusic()
            local tempMusic = CopyLuaTable(Config.PlayMusic.music)
            if Server.currentBGM then
                for i=#tempMusic,1,-1 do
                    local v = tempMusic[i]
                    if v.name == Server.currentBGM.name then
                        table.remove(tempMusic,i)
                        break
                    end
                end
            end
            return tempMusic[math.random(#tempMusic)]
        end
        if can_buy then
            playerInfo.money = playerInfo.money - orderFee
            Server.currentBGM  = randomMusic()
            Server.playMusicTip(msg.mID,playerInfo.name,Server.currentBGM.name)
            Router.broadcast("PlayMusic",{music = Server.currentBGM})
            Router.sendto(msg.mID, "moneyEffect", {cost = orderFee})
            Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
        else
            Router.sendto(msg.mID,"msg",{type = "tip", msg = "金币不足"..tostring(orderFee), data = {channel = "musicError", color = "ff0000"}})
        end
    end
)
Router.receive(
    "PlayMusic", --server to client
    function(msg)
        local music = msg.music
        local tempBGM = Client.currentBGM or {mid = 0}
        local tempId = tempBGM.mid + 1
        Client.currentBGM = msg.music
        Client.currentBGM.mid = tempId
        tip("即将播放《"..music.name.."》,下载中,请稍后...",{channel = "currentMusic"})
        cmd("/music stop")
        GetResourceAudio(music.resource,function (path)
            if Client.currentBGM.mid == tempId then
                cmd("/music "..path.." 0")
                tip("正在播放《"..music.name.."》...",{channel = "currentMusic"})
                Delay(music.time*1000,function (t)
                    if Client.currentBGM.mid == tempId then
                        cmd("/music stop")
                    end
                end)
            end
        end)
    end
)

Router.receive(
    "moneyEffect", --server to client
    function(msg)
            showMoneyUI(
                "- " .. (PublicFunction.convertNumber(msg.cost) or "0") .. "￥"
            )
    end
)
Router.receive(
    "RenamePet",
    function(msg)
        local playerInfo = Server.playerInfo[msg.mID]
        playerInfo.mVersion_0_2.mBag["宠物框"].mItems[msg.mBagItemIndex].mName = msg.mName
        Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
    end
)

Router.receive(
    "DiscardPet",
    function(msg)
        local playerInfo = Server.playerInfo[msg.mID]
        if playerInfo.mVersion_0_2.mAvatarInfo and playerInfo.mVersion_0_2.mAvatarInfo.mPet == msg.mBagItemIndex then
            playerInfo.mVersion_0_2.mAvatarInfo.mPet = nil
        end
        if playerInfo.mVersion_0_2.mAvatarInfo and playerInfo.mVersion_0_2.mAvatarInfo.mPet and playerInfo.mVersion_0_2.mAvatarInfo.mPet > msg.mBagItemIndex then
            playerInfo.mVersion_0_2.mAvatarInfo.mPet = playerInfo.mVersion_0_2.mAvatarInfo.mPet - 1
        end
        playerInfo.mVersion_0_2.mBag["宠物框"].mItems:remove(msg.mBagItemIndex)
        Router.sendto(msg.mID, "setPlayerInfo", {playerInfo = playerInfo:clone()})
        Router.broadcast("UpdateAvatar", {mID = msg.mID, mAvatarInfo = PublicFunction.getUpdateAvatarInfo(playerInfo)})
    end
)

Router.receive(
    "PetLevelUp",
    function(msg)
        showMoneyUI("Level Up")
    end
)

GlobalFunction = {}
function GlobalFunction.convertDecimalToBinary(value)
    local temp = {}
    for i = 1, 64 do
        temp[i] = 0
    end
    if value < 0 then
        temp[64] = 1
    end
    local index = 1
    while value ~= 0 do
        temp[index] = math.fmod(value, 2)
        value = math.floor(value / 2)
        index = index + 1
    end
    local ret = {}
    for i = 64, 1, -1 do
        ret[#ret + 1] = temp[i]
    end
    return ret
end

function GlobalFunction.convertBinaryToDecimal(value)
    local ret = 0
    for i = 1, 63 do
        ret = ret + GlobalFunction.getBinaryBit(value, i - 1) * math.pow(2, i - 1)
    end
    if value[1] == 1 then
        ret = -ret
    end
    return ret
end

--bit from 0
function GlobalFunction.getBinaryBit(value, bit)
    if bit > #value then
        return 0
    else
        return value[#value - bit]
    end
end

function GlobalFunction.xor(v1, v2)
    local b1 = GlobalFunction.convertDecimalToBinary(v1)
    local b2 = GlobalFunction.convertDecimalToBinary(v2)
    local ret = {}
    for i = 1, 64 do
        if b1[i] ~= b2[i] then
            ret[i] = 1
        else
            ret[i] = 0
        end
    end
    return GlobalFunction.convertBinaryToDecimal(ret)
end

function GlobalFunction.parsePetRGB(rgb)
    local b = GlobalFunction.convertDecimalToBinary(GlobalFunction.xor(GlobalFunction.xor(rgb[1], rgb[2]), rgb[3]))
    local ret = {}
    if GlobalFunction.getBinaryBit(b, 7) == 1 then
        ret["移动速度"] = GlobalFunction.getBinaryBit(b, 3) + 1
    end
    if GlobalFunction.getBinaryBit(b, 6) == 1 then
        ret["跳跃"] = GlobalFunction.getBinaryBit(b, 2) + 1
    end
    if GlobalFunction.getBinaryBit(b, 4) == 1 then
        ret["矿石价值"] = GlobalFunction.getBinaryBit(b, 1) + 1
    end
    if GlobalFunction.getBinaryBit(b, 5) == 1 then
        ret["挖掘效率"] = GlobalFunction.getBinaryBit(b, 0) + 1
    end
    return ret
end

function GlobalFunction.getPetLevelAddition(level)
    return {
        ["移动速度"] = {[1] = 1.01 + level * 0.1, [2] = 1.02 + level * 0.15},
        ["跳跃"] = {[1] = 1.01 + level * 0.1, [2] = 1.02 + level * 0.15},
        ["矿石价值"] = {[1] = 1.01 + level * 0.02, [2] = 1.02 + level * 0.05},
        ["挖掘效率"] = {[1] = 1.01 + level * 0.01, [2] = 1.02 + level * 0.02}
    }
end

function GlobalFunction.getMiningBlock(blockID)
    if blockID then
        for _, blocks in pairs(miningBlock) do
            for _, block in pairs(blocks) do
                if block.id == blockID then
                    return block
                end
            end
        end
        for _,mining_block in pairs(ExtMiningBlocks) do
            for k, v in pairs(mining_block) do
                for kk, vv in pairs(v) do
                    if blockID == vv.id then
                        return vv
                    end
                end
            end
        end
    end
end
