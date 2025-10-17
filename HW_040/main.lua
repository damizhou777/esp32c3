-- main.lua
PROJECT = "testrotary"
VERSION = "1.0.0"

_G.sys = require("sys")
require "rotary"

-- 初始化旋转编码器
rotary_start()

-- 添加旋转事件处理
sys.subscribe("ROTARY_LEFT", function(count)
    log.info("主程序", "向左旋转，当前计数:", count)
    -- 在这里添加向左旋转的处理代码
end)

sys.subscribe("ROTARY_RIGHT", function(count)
    log.info("主程序", "向右旋转，当前计数:", count)
    -- 在这里添加向右旋转的处理代码
end)

sys.subscribe("ROTARY_CLICK", function()
    log.info("主程序", "按键按下")
    -- 在这里添加按键按下的处理代码
end)

-- 示例：每5秒显示一次当前计数
sys.timerLoopStart(function()
    log.info("主程序", "旋转编码器当前计数:", rotary_get_count())
end, 5000)

sys.run()