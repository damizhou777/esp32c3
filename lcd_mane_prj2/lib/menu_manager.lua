local menu_manager = {}

-- 菜单结构
menu_manager.menu = {
    level = 1,
    index = 1,
    levels = {
        {
            title = "",  -- 主菜单不显示标题
            items = {
                {name = "Device Info", type = "submenu", target = 2},
                {name = "System Settings", type = "submenu", target = 3},
                {name = "Wireless", type = "submenu", target = 4},
                {name = "About", type = "action", action = "about"}
            }
        },
        {
            title = "DEVICE INFO", 
            items = {
                {name = "System Status", type = "action", action = "status"},
                {name = "Memory Info", type = "action", action = "memory"},
                {name = "Back", type = "back"}
            }
        },
        {
            title = "SYSTEM SETTINGS",
            items = {
                {name = "Reboot Device", type = "action", action = "reboot"},
                {name = "Back", type = "back"}
            }
        },
        {
            title = "WIRELESS",
            items = {
                {name = "WiFi Settings", type = "action", action = "wifi"},
                {name = "Bluetooth", type = "action", action = "bluetooth"},
                {name = "Back", type = "back"}
            }
        }
    }
}

-- 显示状态控制
menu_manager.display_state = {
    need_redraw = true
}

function menu_manager.init()
    log.info("menu", "menu manager initialized")
end

function menu_manager.set_need_redraw(state)
    menu_manager.display_state.need_redraw = state
end

function menu_manager.need_redraw()
    return menu_manager.display_state.need_redraw
end

function menu_manager.get_current_menu()
    return menu_manager.menu.levels[menu_manager.menu.level]
end

function menu_manager.get_current_index()
    return menu_manager.menu.index
end

function menu_manager.get_menu_structure()
    return menu_manager.menu
end

-- 处理所有菜单操作 - 修复第三级菜单问题
function menu_manager.handle_actions(joystick_state)
    local current = menu_manager.menu.levels[menu_manager.menu.level]
    local item = current.items[menu_manager.menu.index]
    local action_performed = false
    
    -- 上移
    if joystick_state.up and not joystick_state.last_up then
        log.info("menu", "UP pressed, current index:", menu_manager.menu.index)
        if menu_manager.menu.index > 1 then
            menu_manager.menu.index = menu_manager.menu.index - 1
            action_performed = true
        end
    end
    
    -- 下移
    if joystick_state.down and not joystick_state.last_down then
        log.info("menu", "DOWN pressed, current index:", menu_manager.menu.index)
        if menu_manager.menu.index < #current.items then
            menu_manager.menu.index = menu_manager.menu.index + 1
            action_performed = true
        end
    end
    
    -- 确认选择 (中键或右键)
    if (joystick_state.center and not joystick_state.last_center) or 
       (joystick_state.right and not joystick_state.last_right) then
        
        log.info("menu", "CONFIRM pressed, item type:", item.type, "action:", item.action)
        
        if item.type == "submenu" then
            log.info("menu", "Entering submenu from level", menu_manager.menu.level, "to level", item.target)
            menu_manager.menu.level = item.target
            menu_manager.menu.index = 1
            action_performed = true
            -- 返回特殊标记表示需要重绘
            return "menu_navigation"
            
        elseif item.type == "back" then
            log.info("menu", "Going back from level", menu_manager.menu.level)
            if menu_manager.menu.level > 1 then
                menu_manager.menu.level = menu_manager.menu.level - 1
                menu_manager.menu.index = 1
                action_performed = true
                return "menu_navigation"
            end
            
        elseif item.type == "action" then
            log.info("menu", "Executing action:", item.action)
            if item.action == "status" then
                local status_text = "CPU: ESP32C3" .. "\n" .. "LCD: ST7735" .. "\n" .. "System Running"
                return {"show_message", "SYSTEM STATUS", status_text}
            elseif item.action == "memory" then
                local mem = collectgarbage("count")
                local mem_text = "Memory: " .. string.format("%.1fKB", mem)
                return {"show_message", "MEMORY INFO", mem_text}
            elseif item.action == "wifi" then
                return "wifi_function"
            elseif item.action == "bluetooth" then
                return "bluetooth_function"
            elseif item.action == "reboot" then
                return "reboot_device"
            elseif item.action == "about" then
                local about_text = "ESP32C3 Board" .. "\n" .. "Joystick Menu" .. "\n" .. "Wireless Demo"
                return {"show_message", "ABOUT", about_text}
            end
        end
    end
    
    -- 返回 (左键)
    if joystick_state.left and not joystick_state.last_left then
        log.info("menu", "LEFT pressed, current level:", menu_manager.menu.level)
        if menu_manager.menu.level > 1 then
            menu_manager.menu.level = menu_manager.menu.level - 1
            menu_manager.menu.index = 1
            action_performed = true
            return "menu_navigation"
        end
    end
    
    -- 更新上次状态
    joystick_state.last_up = joystick_state.up
    joystick_state.last_down = joystick_state.down
    joystick_state.last_left = joystick_state.left
    joystick_state.last_right = joystick_state.right
    joystick_state.last_center = joystick_state.center
    
    -- 如果有普通菜单操作发生，返回true触发重绘
    return action_performed
end

return menu_manager