
local GoodsConfig = module();

GoodsConfig.GOAL_POINT = {
    -- ID
    ID = "GOAL_POINT",
    -- 物品标题
    title = "目标点",
    -- 物品描述
    description = "",
    -- 任务标题
    task_title = "达到目的地",
    -- 任务描述
    task_description = "",
}

GoodsConfig.TIAN_SHU_CAN_JUAN = {
    ID = "TIAN_SHU_CAN_JUAN",
    title = "天书残卷",
    task_title = "收集天书残卷",
}

GoodsConfig.CODE_LINE = {
    ID = "CODE_LINE",
    title = "代码行",
    task_title = "代码行数少于",
    task_description = nil,
    task_reverse_compare = true,
}

GoodsConfig.MAX_ALIVE_TIME = {
    ID = "MAX_ALIVE_TIME",
    title = "最长存活时间",
    task_title = "完成时间少于",
    task_reverse_compare = true,
}

GoodsConfig.ARROW = {
    ID = "ARROW",
    blood_peer = true,
    blood_peer_value = -20, 
}