-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "lcd_test"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- sys库是标配
_G.sys = require("sys")

-- 添加硬狗防止程序卡死
if wdt then
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end

-- 引脚定义
local LCD_SCK = 2    -- IO02
local LCD_SDA = 3    -- IO03  
local LCD_DC = 6     -- IO06
local LCD_CS = 7     -- IO07
local LCD_RES = 10   -- IO10
local LCD_BL = 11    -- IO11

-- 摇杆引脚
local UPKEY = 8      -- IO08 上
local DOWNKEY = 13   -- IO13 下
local LEFTKEY = 5    -- IO05 左
local RIGHTKEY = 9   -- IO09 右
local CENTER = 4     -- IO04 中

-- 初始化LCD屏幕
log.info("lcd", "init LCD")

spi_lcd = spi.deviceSetup(2, LCD_CS, 0, 0, 8, 10000000, spi.MSB, 1, 0)

-- 修正LCD初始化参数，消除白边
lcd.init("st7735", {
    port = "device",
    pin_dc = LCD_DC, 
    pin_pwr = LCD_BL, 
    pin_rst = LCD_RES,
    direction = 1,
    w = 160,
    h = 80,
    xoffset = 1,    -- 调整X偏移
    yoffset = 26    -- 调整Y偏移，消除顶部白线
}, spi_lcd)

log.info("lcd", "LCD initialized!")

-- 初始化摇杆GPIO
gpio.setup(UPKEY, nil, gpio.PULLUP)
gpio.setup(DOWNKEY, nil, gpio.PULLUP) 
gpio.setup(LEFTKEY, nil, gpio.PULLUP)
gpio.setup(RIGHTKEY, nil, gpio.PULLUP)
gpio.setup(CENTER, nil, gpio.PULLUP)

-- 摇杆状态
local joystick = {
    up = false, down = false, left = false, right = false, center = false,
    last_up = false, last_down = false, last_left = false, last_right = false, last_center = false
}

-- 显示状态控制
local display_state = {
    need_redraw = true  -- 是否需要重绘
}

-- 重置所有按键状态
function reset_joystick_state()
    joystick.up = false
    joystick.down = false
    joystick.left = false
    joystick.right = false
    joystick.center = false
    joystick.last_up = false
    joystick.last_down = false
    joystick.last_left = false
    joystick.last_right = false
    joystick.last_center = false
end

-- 读取摇杆状态
function read_joystick()
    joystick.up = (gpio.get(UPKEY) == 0)
    joystick.down = (gpio.get(DOWNKEY) == 0)
    joystick.left = (gpio.get(LEFTKEY) == 0)
    joystick.right = (gpio.get(RIGHTKEY) == 0)
    joystick.center = (gpio.get(CENTER) == 0)
end

-- 显示启动画面
function show_startup()
    lcd.clear()
    lcd.drawStr(40, 25, "JOYSTICK MENU")
    lcd.drawStr(25, 45, "ESP32C3 BOARD")
    lcd.drawStr(50, 65, "READY")
    sys.wait(2000)
    display_state.need_redraw = true
end

-- 显示消息 - 修正按键状态问题
function show_message(title, text)
    lcd.clear()
    lcd.drawStr(10, 15, title)
    
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    for i, line in ipairs(lines) do
        lcd.drawStr(10, 30 + (i-1)*12, line)
    end
    
    lcd.drawStr(30, 70, "Press OK to continue")
    
    -- 重置按键状态，避免之前的按键状态影响
    reset_joystick_state()
    
    -- 等待确认 - 添加延时避免快速退出
    local count = 0
    while count < 200 do
        read_joystick()
        -- 添加短暂延时，确保按键稳定
        sys.wait(20)
        read_joystick()
        
        if (joystick.center and not joystick.last_center) or 
           (joystick.right and not joystick.last_right) then
            -- 等待按键释放
            while joystick.center or joystick.right do
                read_joystick()
                sys.wait(20)
            end
            break
        end
        joystick.last_center = joystick.center
        joystick.last_right = joystick.right
        sys.wait(50)
        count = count + 1
    end
    
    -- 再次重置状态
    reset_joystick_state()
    display_state.need_redraw = true
end

-- WiFi功能 - 同样修正
function wifi_function()
    lcd.clear()
    lcd.drawStr(30, 15, "WiFi SETTINGS")
    lcd.drawStr(10, 30, "Status: Disabled")
    lcd.drawStr(10, 45, "SSID: ESP32C3_AP")
    lcd.drawStr(10, 60, "IP: 192.168.4.1")
    lcd.drawStr(20, 75, "Press OK to back")
    
    reset_joystick_state()
    
    local count = 0
    while count < 200 do
        read_joystick()
        sys.wait(20)
        read_joystick()
        
        if (joystick.center and not joystick.last_center) or 
           (joystick.right and not joystick.last_right) then
            while joystick.center or joystick.right do
                read_joystick()
                sys.wait(20)
            end
            break
        end
        joystick.last_center = joystick.center
        joystick.last_right = joystick.right
        sys.wait(50)
        count = count + 1
    end
    
    reset_joystick_state()
    display_state.need_redraw = true
end

-- 蓝牙功能 - 同样修正
function bluetooth_function()
    lcd.clear()
    lcd.drawStr(30, 15, "BLUETOOTH")
    lcd.drawStr(10, 30, "Status: Disabled")
    lcd.drawStr(10, 45, "Name: ESP32C3_BT")
    lcd.drawStr(10, 60, "Mode: Not Available")
    lcd.drawStr(20, 75, "Press OK to back")
    
    reset_joystick_state()
    
    local count = 0
    while count < 200 do
        read_joystick()
        sys.wait(20)
        read_joystick()
        
        if (joystick.center and not joystick.last_center) or 
           (joystick.right and not joystick.last_right) then
            while joystick.center or joystick.right do
                read_joystick()
                sys.wait(20)
            end
            break
        end
        joystick.last_center = joystick.center
        joystick.last_right = joystick.right
        sys.wait(50)
        count = count + 1
    end
    
    reset_joystick_state()
    display_state.need_redraw = true
end

-- 重启设备
function reboot_device()
    show_message("REBOOT", "Device restarting...")
    sys.wait(2000)
    rtos.reboot()
end


--[[
-- 绘制菜单 - 修正二级菜单标题位置
function draw_menu()
    lcd.clear()
    local menu = _G.menu_manager.get_menu_structure()
    local current = menu.levels[menu.level]
    
    -- 只在非主菜单时显示标题，向下调整位置
    if menu.level > 1 then
        lcd.drawStr(5, 10, current.title)
    end
    
    -- 显示菜单项 - 根据是否有标题调整起始位置
    local start_y = 10  -- 主菜单起始位置
    if menu.level > 1 then
        start_y = 25    -- 二级菜单从更低位置开始，为标题留出空间
    end
    
    for i = 1, #current.items do
        local y = start_y + (i-1) * 14
        if i == menu.index then
            lcd.drawStr(8, y, "> " .. current.items[i].name)
        else
            lcd.drawStr(8, y, "  " .. current.items[i].name)
        end
    end
    
    -- 显示操作提示
    lcd.drawStr(5, 75, "Up/Down OK:Select Back:Exit")
    
    display_state.need_redraw = false
end]]
-- 显示状态控制 - 增强版
local display_state = {
    need_redraw = true,
    full_redraw = true,      -- 是否需要完全重绘
    last_level = 0,          -- 上次菜单层级
    last_index = 0,          -- 上次选中项
    redraw_timer = 0         -- 重绘计时器
}

-- 绘制菜单 - 完整优化版本
function draw_menu()
    local menu = _G.menu_manager.get_menu_structure()
    local current = menu.levels[menu.level]
    
    -- 检查是否需要完全重绘
    local need_full_redraw = display_state.full_redraw or 
                            (menu.level ~= display_state.last_level)
    
    if need_full_redraw then
        lcd.clear()
        display_state.full_redraw = false
        display_state.last_level = menu.level
        
        -- 绘制标题（只在非主菜单时）
        if menu.level > 1 then
            lcd.drawStr(5, 10, current.title)
        end
        
        -- 绘制所有菜单项
        local start_y = 10
        if menu.level > 1 then
            start_y = 25
        end
        
        for i = 1, #current.items do
            local y = start_y + (i-1) * 14
            if i == menu.index then
                lcd.drawStr(8, y, "> " .. current.items[i].name)
            else
                lcd.drawStr(8, y, "  " .. current.items[i].name)
            end
        end
        
        -- 绘制操作提示
        lcd.drawStr(5, 75, "Up/Down OK:Select Back:Exit")
        
    else
        -- 部分重绘：只更新选中的菜单项
        if menu.index ~= display_state.last_index then
            local start_y = 10
            if menu.level > 1 then
                start_y = 25
            end
            
            -- 清除旧选中项
            if display_state.last_index > 0 and display_state.last_index <= #current.items then
                local old_y = start_y + (display_state.last_index-1) * 14
                lcd.drawRect(0, old_y-2, 160, 14, 0x0000, 0x0000)
                lcd.drawStr(8, old_y, "  " .. current.items[display_state.last_index].name)
            end
            
            -- 绘制新选中项
            local new_y = start_y + (menu.index-1) * 14
            lcd.drawRect(0, new_y-2, 160, 14, 0x0000, 0x0000)
            lcd.drawStr(8, new_y, "> " .. current.items[menu.index].name)
        end
    end
    
    display_state.last_index = menu.index
    display_state.need_redraw = false
end

-- 在返回菜单时标记需要完全重绘
function show_message(title, text)
    -- ... 原有代码不变 ...
    display_state.need_redraw = true
    display_state.full_redraw = true  -- 添加这一行
end

function wifi_function()
    -- ... 原有代码不变 ...
    display_state.need_redraw = true
    display_state.full_redraw = true  -- 添加这一行
end

function bluetooth_function()
    -- ... 原有代码不变 ...
    display_state.need_redraw = true
    display_state.full_redraw = true  -- 添加这一行
end

-- 处理菜单操作
function handle_menu_actions()
    local action_result = _G.menu_manager.handle_actions(joystick)
    
    -- 处理菜单操作返回的结果
    if action_result then
        if type(action_result) == "table" and action_result[1] == "show_message" then
            show_message(action_result[2], action_result[3])
        elseif action_result == "wifi_function" then
            wifi_function()
        elseif action_result == "bluetooth_function" then
            bluetooth_function()
        elseif action_result == "reboot_device" then
            reboot_device()
        else
            -- 普通菜单操作
            display_state.need_redraw = true
        end
    end
    
    return action_result ~= nil
end

-- 主任务
sys.taskInit(function()
    log.info("task", "system start")
    
    -- 尝试加载菜单管理器
    local status, err = pcall(function()
        _G.menu_manager = require("menu_manager")
    end)
    
    if not status then
        log.error("main", "Failed to load menu_manager:", err)
        show_message("ERROR", "Menu module\nnot found")
        sys.wait(3000)
        rtos.reboot()
    end
    
    -- 初始化菜单管理器
    _G.menu_manager.init()
    
    -- 显示启动画面
    show_startup()
    
    -- 主循环
    while true do
        -- 读取摇杆状态
        read_joystick()
        
        -- 处理所有菜单操作
        local action_performed = handle_menu_actions()
        
        -- 如果有动作发生，标记需要重绘
        if action_performed then
            display_state.need_redraw = true
        end
        
        -- 只有在需要重绘时才绘制屏幕
        if display_state.need_redraw then
            draw_menu()
        end
        
        -- 适当的延时，平衡响应性和性能
        sys.wait(50)
    end
end)

-- 用户代码已结束
sys.run()