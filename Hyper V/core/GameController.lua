--[[
    Hyper-V - Game Controller System
    Central hub quản lý tất cả keybinds, toggles, macros trong một nơi
]]

local GameController = {}
GameController.__index = GameController

-- Private state
local activeControllers = {}
local globalKeyHeld = {}
local defaultController = nil

local function normalizeBindingArgs(name, config, fallbackPrefix)
    if type(name) == "table" and config == nil then
        config = name
        name = config.Name or config.BindingName or config.Id or fallbackPrefix
    end

    config = config or {}
    name = name or config.Name or config.BindingName or config.Id or fallbackPrefix
    return tostring(name), config
end

function GameController.new(name)
    local self = setmetatable({}, GameController)
    
    self.Name = name or "GameController"
    self.Bindings = {}      -- {bindingName = {type, enabled, callback, keybind}}
    self.Toggles = {}       -- {toggleName = {enabled, callback}}
    self.Macros = {}        -- {macroName = {actions, callback}}
    self.HoldStates = {}    -- {holdName = {isHeld, callback}}
    self.Groups = {}       -- {groupName = {bindings}}
    self.Connections = {}   -- Luu cac ket noi
    
    -- Settings
    self.Priority = 0      -- So sanh khi trigger nhieu binding
    self.AllowOverlap = false -- Cho phep nhieu binding cung trigger
    
    -- State
    self.IsEnabled = true
    
    return self
end

-- ===== KEYBINDS =====

function GameController:BindKey(name, config)
    name, config = normalizeBindingArgs(name, config, "Keybind")
    -- Simple keybind
    self.Bindings[name] = {
        type = "key",
        key = config.Key or Enum.KeyCode.F,
        modifiers = config.Modifiers or {},
        callback = config.Callback,
        enabled = config.Enabled ~= false,
        description = config.Description or "",
        group = config.Group,
        priority = config.Priority or 0
    }
    
    if config.Group then
        self:AddToGroup(config.Group, name)
    end
    
    return self.Bindings[name]
end

function GameController:BindCombo(name, config)
    name, config = normalizeBindingArgs(name, config, "Combo")
    -- Combo keybind (Ctrl + F)
    self.Bindings[name] = {
        type = "combo",
        keys = config.Keys,
        callback = config.Callback,
        enabled = config.Enabled ~= false,
        description = config.Description or "",
        group = config.Group,
        priority = config.Priority or 0
    }
    
    if config.Group then
        self:AddToGroup(config.Group, name)
    end
    
    return self.Bindings[name]
end

function GameController:BindToggle(name, config)
    name, config = normalizeBindingArgs(name, config, "Toggle")
    -- Toggle: Press to on, press again to off
    self.Bindings[name] = {
        type = "toggle",
        key = config.Key or Enum.KeyCode.F,
        modifiers = config.Modifiers or {},
        state = config.Default or false,
        callback = config.Callback,
        enabled = config.Enabled ~= false,
        description = config.Description or "",
        group = config.Group,
        priority = config.Priority or 0
    }
    
    if config.Group then
        self:AddToGroup(config.Group, name)
    end
    
    return self.Bindings[name]
end

function GameController:BindHold(name, config)
    name, config = normalizeBindingArgs(name, config, "Hold")
    -- Hold: Active when key held, inactive when released
    self.Bindings[name] = {
        type = "hold",
        key = config.Key or Enum.KeyCode.F,
        modifiers = config.Modifiers or {},
        isHeld = false,
        callback = config.Callback,
        enabled = config.Enabled ~= false,
        description = config.Description or "",
        group = config.Group,
        priority = config.Priority or 0
    }
    
    if config.Group then
        self:AddToGroup(config.Group, name)
    end
    
    return self.Bindings[name]
end

-- ===== GROUPS =====

function GameController:CreateGroup(name, config)
    self.Groups[name] = {
        name = name,
        bindings = {},
        exclusive = config.Exclusive or false,  -- Chi 1 binding active trong group
        defaultEnabled = config.DefaultEnabled,
        switchCallback = config.OnSwitch  -- Called when switching in exclusive mode
    }
    return self.Groups[name]
end

function GameController:AddToGroup(groupName, bindingName)
    if not self.Groups[groupName] then
        self:CreateGroup(groupName, {})
    end
    table.insert(self.Groups[groupName].bindings, bindingName)
end

function GameController:EnableGroup(groupName)
    local group = self.Groups[groupName]
    if not group then return end
    
    for _, bindingName in ipairs(group.bindings) do
        if self.Bindings[bindingName] then
            self.Bindings[bindingName].enabled = true
        end
    end
end

function GameController:DisableGroup(groupName)
    local group = self.Groups[groupName]
    if not group then return end
    
    for _, bindingName in ipairs(group.bindings) do
        if self.Bindings[bindingName] then
            self.Bindings[bindingName].enabled = false
        end
    end
end

-- ===== TOGGLE STATE =====

function GameController:Toggle(name)
    local binding = self.Bindings[name]
    if not binding or binding.type ~= "toggle" then return end
    
    binding.state = not binding.state
    
    if binding.callback then
        binding.callback(binding.state)
    end
    
    return binding.state
end

function GameController:SetToggle(name, state)
    local binding = self.Bindings[name]
    if not binding or binding.type ~= "toggle" then return end
    
    binding.state = state
    
    if binding.callback then
        binding.callback(state)
    end
end

function GameController:GetToggle(name)
    local binding = self.Bindings[name]
    if not binding or binding.type ~= "toggle" then return nil end
    return binding.state
end

-- ===== ENABLE/DISABLE =====

function GameController:EnableBinding(name)
    if self.Bindings[name] then
        self.Bindings[name].enabled = true
    end
end

function GameController:DisableBinding(name)
    if self.Bindings[name] then
        self.Bindings[name].enabled = false
    end
end

function GameController:EnableAll()
    self.IsEnabled = true
    for name, _ in pairs(self.Bindings) do
        self.Bindings[name].enabled = true
    end
end

function GameController:DisableAll()
    self.IsEnabled = false
    for name, _ in pairs(self.Bindings) do
        self.Bindings[name].enabled = false
    end
end

-- ===== MACROS =====

function GameController:RegisterMacro(name, config)
    self.Macros[name] = {
        name = name,
        actions = config.Actions or {},
        callback = config.Callback,
        description = config.Description or "",
        enabled = config.Enabled ~= false
    }
    return self.Macros[name]
end

function GameController:PlayMacro(name)
    local macro = self.Macros[name]
    if not macro or not macro.enabled then return end
    
    if macro.callback then
        -- Callback se xu ly viec phat actions
        macro.callback("play", macro.actions)
    end
end

function GameController:StopMacro(name)
    local macro = self.Macros[name]
    if not macro then return end
    
    if macro.callback then
        macro.callback("stop", {})
    end
end

-- ===== ACTIVATION =====

function GameController:Start()
    local UserInputService = game:GetService("UserInputService")
    
    -- Input began
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.IsEnabled then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        
        local key = input.KeyCode
        globalKeyHeld[key] = true
        
        -- Check all bindings
        self:CheckBindings(key, true)
    end))
    
    -- Input ended
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        
        local key = input.KeyCode
        globalKeyHeld[key] = false
        
        -- Check hold bindings
        self:CheckHoldRelease(key)
    end))
    
    -- Focus lost - release all holds
    table.insert(self.Connections, UserInputService.WindowFocusReleased:Connect(function()
        self:ReleaseAllHolds()
    end))
    
    return self
end

function GameController:CheckBindings(key, isPressed)
    local triggered = {}
    
    for name, binding in pairs(self.Bindings) do
        if binding.enabled then
            local shouldTrigger = false
            
            if binding.type == "key" then
                shouldTrigger = self:CheckKeyMatch(key, binding.key, binding.modifiers)
            elseif binding.type == "combo" then
                shouldTrigger = self:CheckComboMatch(binding.keys)
            elseif binding.type == "toggle" then
                shouldTrigger = self:CheckKeyMatch(key, binding.key, binding.modifiers)
            elseif binding.type == "hold" then
                shouldTrigger = self:CheckKeyMatch(key, binding.key, binding.modifiers)
            end
            
            if shouldTrigger then
                table.insert(triggered, {
                    name = name,
                    binding = binding,
                    priority = binding.priority
                })
            end
        end
    end
    
    -- Sort by priority (highest first)
    table.sort(triggered, function(a, b)
        return a.priority > b.priority
    end)
    
    -- Execute triggers
    for _, trigger in ipairs(triggered) do
        local binding = trigger.binding
        local exclusiveGroup = binding.group and self.Groups[binding.group] 
            and self.Groups[binding.group].exclusive
        
        if exclusiveGroup then
            -- Disable other bindings in group first
            for _, otherName in ipairs(self.Groups[binding.group].bindings) do
                if otherName ~= trigger.name and self.Bindings[otherName] then
                    self.Bindings[otherName].enabled = false
                end
            end
        end
        
        if binding.type == "toggle" then
            self:Toggle(trigger.name)
        elseif binding.type == "hold" and isPressed then
            self:ActivateHold(trigger.name)
        elseif binding.type == "key" and isPressed and binding.callback then
            binding.callback()
        elseif binding.type == "combo" and isPressed and binding.callback then
            binding.callback()
        end
        
        if not self.AllowOverlap then
            break  -- Only trigger highest priority
        end
    end
end

function GameController:CheckKeyMatch(key, targetKey, modifiers)
    if key ~= targetKey then return false end
    
    -- Check modifiers
    local requiredModifiers = modifiers or {}
    for _, mod in ipairs(requiredModifiers) do
        if not globalKeyHeld[mod] then
            return false
        end
    end
    
    return true
end

function GameController:CheckComboMatch(keys)
    for _, key in ipairs(keys) do
        if not globalKeyHeld[key] then
            return false
        end
    end
    return #keys > 0
end

function GameController:ActivateHold(name)
    local binding = self.Bindings[name]
    if not binding or binding.type ~= "hold" then return end
    if binding.isHeld then return end
    
    binding.isHeld = true
    
    if binding.callback then
        binding.callback(true)
    end
end

function GameController:CheckHoldRelease(key)
    for name, binding in pairs(self.Bindings) do
        if binding.type == "hold" and binding.key == key and binding.isHeld then
            binding.isHeld = false
            if binding.callback then
                binding.callback(false)
            end
        end
    end
end

function GameController:ReleaseAllHolds()
    for name, binding in pairs(self.Bindings) do
        if binding.type == "hold" and binding.isHeld then
            binding.isHeld = false
            if binding.callback then
                binding.callback(false)
            end
        end
    end
end

-- ===== INFO =====

function GameController:GetBindings()
    local list = {}
    for name, binding in pairs(self.Bindings) do
        table.insert(list, {
            name = name,
            type = binding.type,
            enabled = binding.enabled,
            description = binding.description
        })
    end
    return list
end

function GameController:GetActiveBindings()
    local list = {}
    for name, binding in pairs(self.Bindings) do
        local isActive = false
        if binding.type == "toggle" then
            isActive = binding.state
        elseif binding.type == "hold" then
            isActive = binding.isHeld
        end
        if isActive then
            table.insert(list, name)
        end
    end
    return list
end

function GameController:GetBindingInfo(name)
    return self.Bindings[name]
end

-- ===== CLEANUP =====

function GameController:Destroy()
    -- Disconnect all
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}
    
    -- Clear bindings
    self.Bindings = {}
    self.Toggles = {}
    self.Macros = {}
    self.Groups = {}

    if self == defaultController then
        defaultController = nil
    end
end

-- ===== STATIC METHODS =====

function GameController:Get(name)
    if defaultController and defaultController.Name == (name or defaultController.Name) then
        return defaultController
    end

    if not defaultController then
        defaultController = GameController.new(name or "GameController")
        table.insert(activeControllers, defaultController)
    end

    return defaultController
end

function GameController:GetActiveControllers()
    return activeControllers
end

function GameController:Create(name)
    local controller = GameController.new(name)
    table.insert(activeControllers, controller)
    return controller
end

return GameController
