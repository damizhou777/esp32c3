-- rotary.lua (简化版本，移除时间防抖)
local rtos_bsp = rtos.bsp()

function pinx()
    if rtos_bsp == "ESP32C3" then
        return 2, 3, 10
    elseif rtos_bsp == "AIR105" then
        return pin.PC09, pin.PA10, pin.PA00
    elseif rtos_bsp == "EC718P" then
        return 12, 13, 14
    else
        log.info("rotary", "请根据实际开发板定义引脚")
        return 255, 255, 255
    end
end

local clk_pin, dt_pin, sw_pin = pinx()
local last_clk_state, last_sw_state
local rotary_count = 0

-- 引脚初始化
local function pins_init()
    gpio.setup(clk_pin, gpio.INPUT, gpio.PULLUP)
    gpio.setup(dt_pin, gpio.INPUT, gpio.PULLUP)
    gpio.setup(sw_pin, gpio.INPUT, gpio.PULLUP)
    
    last_clk_state = gpio.get(clk_pin)
    last_sw_state = gpio.get(sw_pin)
end

-- 简化的旋转检测
local function check_rotary()
    local current_clk = gpio.get(clk_pin)
    local current_dt = gpio.get(dt_pin)
    
    if current_clk ~= last_clk_state then
        if current_clk == 0 then  -- CLK下降沿
            if current_dt == 1 then
                -- 顺时针旋转
                rotary_count = rotary_count + 1
                log.info("旋转编码器", "向右旋转", "计数:", rotary_count)
                sys.publish("ROTARY_RIGHT", rotary_count)
            else
                -- 逆时针旋转
                rotary_count = rotary_count - 1
                log.info("旋转编码器", "向左旋转", "计数:", rotary_count)
                sys.publish("ROTARY_LEFT", rotary_count)
            end
        end
        last_clk_state = current_clk
    end
end

-- 简化的按键检测
local function check_button()
    local current_sw = gpio.get(sw_pin)
    
    if current_sw ~= last_sw_state and current_sw == 0 then
        log.info("旋转编码器", "按键按下")
        sys.publish("ROTARY_CLICK")
        last_sw_state = current_sw
    elseif current_sw ~= last_sw_state then
        last_sw_state = current_sw
    end
end

-- 主检测循环
local function detection_loop()
    check_rotary()
    check_button()
end

function rotary_start()
    log.info("旋转编码器", "初始化开始")
    log.info("引脚配置", "CLK:", clk_pin, "DT:", dt_pin, "SW:", sw_pin)
    
    pins_init()
    sys.timerLoopStart(detection_loop, 5)
    log.info("旋转编码器", "初始化完成")
end

function rotary_get_count()
    return rotary_count
end

function rotary_reset_count()
    rotary_count = 0
    return rotary_count
end

return _M