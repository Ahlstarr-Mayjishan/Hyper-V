--[[
    HyperVAPI - API quản lý UI elements đã mark
    Singleton pattern để truy cập nhanh
]]

local HyperVAPI = {}
HyperVAPI.__index = HyperVAPI

-- Singleton
local instance = nil

function HyperVAPI.new()
    if instance then return instance end
    
    local self = setmetatable({}, HyperVAPI)
    
    -- Reference to HyperVMarker
    self.Marker = nil
    
    instance = self
    return self
end

function HyperVAPI:Get()
    if not instance then
        instance = HyperVAPI.new()
    end
    return instance
end

function HyperVAPI:SetMarker(marker)
    self.Marker = marker
end

-- ===== CORE OPERATIONS =====

function HyperVAPI:Destroy(instance: Instance): boolean
    if not instance then return false end
    
    -- Unmark from registry first
    if self.Marker then
        self.Marker:Unmark(instance)
    end
    
    -- Destroy instance
    local success, err = pcall(function()
        instance:Destroy()
    end)
    
    if not success then
        warn("[HyperVAPI] Destroy failed:", err)
        return false
    end
    
    return true
end

function HyperVAPI:Hide(instance: Instance): boolean
    if not instance then return false end
    
    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Visible = false
        elseif instance:IsA("LuaVMContainer") or instance:IsA("Frame") then
            -- For non-GuiObject instances, try to set some property
            instance.Visible = false
        end
    end)
    
    if not success then
        warn("[HyperVAPI] Hide failed:", err)
        return false
    end
    
    -- Touch to update last used
    if self.Marker then
        self.Marker:Touch(instance)
    end
    
    return true
end

function HyperVAPI:Show(instance: Instance): boolean
    if not instance then return false end
    
    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Visible = true
        else
            instance.Visible = true
        end
    end)
    
    if not success then
        warn("[HyperVAPI] Show failed:", err)
        return false
    end
    
    -- Touch to update last used
    if self.Marker then
        self.Marker:Touch(instance)
    end
    
    return true
end

function HyperVAPI:Enable(instance: Instance): boolean
    if not instance then return false end
    
    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Active = true
        end
        if instance:IsA("GuiButton") then
            instance.AutoButtonColor = true
        end
        if instance:IsA("TextBox") then
            instance.CaptureFocus = true
        end
        -- For other instances, set Enabled if available
        if instance.Enabled ~= nil then
            instance.Enabled = true
        end
    end)
    
    if not success then
        warn("[HyperVAPI] Enable failed:", err)
        return false
    end
    
    -- Touch to update last used
    if self.Marker then
        self.Marker:Touch(instance)
    end
    
    return true
end

function HyperVAPI:Disable(instance: Instance): boolean
    if not instance then return false end
    
    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Active = false
        end
        if instance:IsA("GuiButton") then
            instance.AutoButtonColor = false
        end
        if instance:IsA("TextBox") then
            instance:ReleaseFocus()
        end
        -- For other instances, set Enabled if available
        if instance.Enabled ~= nil then
            instance.Enabled = false
        end
    end)
    
    if not success then
        warn("[HyperVAPI] Disable failed:", err)
        return false
    end
    
    -- Touch to update last used
    if self.Marker then
        self.Marker:Touch(instance)
    end
    
    return true
end

-- ===== QUERY OPERATIONS =====

function HyperVAPI:IsVisible(instance: Instance): boolean?
    if not instance then return nil end
    
    local visible = false
    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            visible = instance.Visible
        else
            visible = instance.Visible
        end
    end)
    
    if not success then
        return nil
    end
    
    return visible
end

function HyperVAPI:IsEnabled(instance: Instance): boolean?
    if not instance then return nil end
    
    local enabled = true
    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            enabled = instance.Active
        end
        if instance.Enabled ~= nil then
            enabled = instance.Enabled
        end
    end)
    
    if not success then
        return nil
    end
    
    return enabled
end

function HyperVAPI:GetParent(instance: Instance): Instance?
    if not instance then return nil end
    
    local parent = nil
    local success, err = pcall(function()
        parent = instance.Parent
    end)
    
    if not success then
        return nil
    end
    
    return parent
end

-- ===== SETTER OPERATIONS =====

function HyperVAPI:SetVisible(instance: Instance, visible: boolean): boolean
    if visible then
        return self:Show(instance)
    else
        return self:Hide(instance)
    end
end

function HyperVAPI:SetEnabled(instance: Instance, enabled: boolean): boolean
    if enabled then
        return self:Enable(instance)
    else
        return self:Disable(instance)
    end
end

function HyperVAPI:SetParent(instance: Instance, parent: Instance): boolean
    if not instance or not parent then return false end
    
    local success, err = pcall(function()
        instance.Parent = parent
    end)
    
    if not success then
        warn("[HyperVAPI] SetParent failed:", err)
        return false
    end
    
    -- Touch to update last used
    if self.Marker then
        self.Marker:Touch(instance)
    end
    
    return true
end

-- ===== BATCH OPERATIONS =====

function HyperVAPI:DestroyByTag(tag: string): number
    if not self.Marker then return 0 end
    
    local entries = self.Marker:GetByTag(tag)
    local count = 0
    
    for _, entry in ipairs(entries) do
        if entry.Instance and self:Destroy(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVAPI:HideByTag(tag: string): number
    if not self.Marker then return 0 end
    
    local entries = self.Marker:GetByTag(tag)
    local count = 0
    
    for _, entry in ipairs(entries) do
        if entry.Instance and self:Hide(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVAPI:ShowByTag(tag: string): number
    if not self.Marker then return 0 end
    
    local entries = self.Marker:GetByTag(tag)
    local count = 0
    
    for _, entry in ipairs(entries) do
        if entry.Instance and self:Show(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVAPI:DisableByTag(tag: string): number
    if not self.Marker then return 0 end
    
    local entries = self.Marker:GetByTag(tag)
    local count = 0
    
    for _, entry in ipairs(entries) do
        if entry.Instance and self:Disable(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

function HyperVAPI:EnableByTag(tag: string): number
    if not self.Marker then return 0 end
    
    local entries = self.Marker:GetByTag(tag)
    local count = 0
    
    for _, entry in ipairs(entries) do
        if entry.Instance and self:Enable(entry.Instance) then
            count = count + 1
        end
    end
    
    return count
end

-- ===== FIND OPERATION =====

function HyperVAPI:FindFirstChild(instance: Instance, name: string, recursive: boolean?): Instance?
    if not instance then return nil end
    
    local child = nil
    local success, err = pcall(function()
        child = instance:FindFirstChild(name, recursive or false)
    end)
    
    if not success then
        return nil
    end
    
    return child
end

function HyperVAPI:GetDescendants(instance: Instance): {Instance}
    if not instance then return {} end
    
    local descendants = {}
    local success, err = pcall(function()
        descendants = instance:GetDescendants()
    end)
    
    if not success then
        return {}
    end
    
    return descendants
end

-- ===== UTILITY =====

function HyperVAPI:IsValid(instance: Instance): boolean
    if not instance then return false end
    
    local valid = false
    local success, err = pcall(function()
        valid = instance.Parent ~= nil
    end)
    
    return success and valid
end

function HyperVAPI:GetAttribute(instance: Instance, attribute: string): any
    if not instance then return nil end
    
    local value = nil
    local success, err = pcall(function()
        value = instance:GetAttribute(attribute)
    end)
    
    if not success then
        return nil
    end
    
    return value
end

function HyperVAPI:SetAttribute(instance: Instance, attribute: string, value: any): boolean
    if not instance then return false end

    local success, err = pcall(function()
        instance:SetAttribute(attribute, value)
    end)

    return success
end

-- ===== STATE MANAGEMENT =====

function HyperVAPI:GetState(instance: Instance): any?
    if not instance then return nil end
    return instance:GetAttribute("HyperV_State")
end

function HyperVAPI:SetState(instance: Instance, state: any): boolean
    if not instance then return false end
    return instance:SetAttribute("HyperV_State", state)
end

-- ===== REFRESH / RELOAD =====

function HyperVAPI:Refresh(instance: Instance): boolean
    if not instance then return false end

    -- Touch to update last used time
    if self.Marker then
        self.Marker:Touch(instance)
    end

    -- Emit refresh event
    local success, err = pcall(function()
        local refreshSignal = instance:GetAttribute("HyperV_OnRefresh")
        if refreshSignal and typeof(refreshSignal) == "function" then
            refreshSignal(instance)
        end
    end)

    return success
end

function HyperVAPI:Reload(instance: Instance): boolean
    if not instance then return false end

    if self.Marker then
        self.Marker:Touch(instance)
    end

    return true
end

-- ===== CLONE =====

function HyperVAPI:Clone(instance: Instance): Instance?
    if not instance then return nil end

    local cloned = nil
    local success, err = pcall(function()
        cloned = instance:Clone()
    end)

    if success and cloned then
        if self.Marker then
            local tag = instance:GetAttribute("RayfieldTag")
            self.Marker:Mark(cloned, tag)
        end
    end

    return cloned
end

-- ===== OPACITY =====

function HyperVAPI:GetOpacity(instance: Instance): number?
    if not instance then return nil end

    local opacity = nil
    pcall(function()
        if instance:IsA("GuiObject") then
            opacity = instance.BackgroundTransparency
            if opacity == 1 and (instance:IsA("TextLabel") or instance:IsA("TextButton")) then
                opacity = instance.TextTransparency
            end
        end
    end)

    return opacity or 1
end

function HyperVAPI:SetOpacity(instance: Instance, opacity: number): boolean
    if not instance then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.BackgroundTransparency = opacity
        end
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            instance.TextTransparency = opacity
        end
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            instance.ImageTransparency = opacity
        end
    end)

    return success
end

-- ===== POSITION / SIZE =====

function HyperVAPI:GetPosition(instance: Instance): UDim2?
    if not instance then return nil end

    local pos = nil
    pcall(function()
        if instance:IsA("GuiObject") then
            pos = instance.Position
        end
    end)

    return pos
end

function HyperVAPI:SetPosition(instance: Instance, position: UDim2): boolean
    if not instance then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Position = position
        end
    end)

    return success
end

function HyperVAPI:GetSize(instance: Instance): UDim2?
    if not instance then return nil end

    local size = nil
    pcall(function()
        if instance:IsA("GuiObject") then
            size = instance.Size
        end
    end)

    return size
end

function HyperVAPI:SetSize(instance: Instance, size: UDim2): boolean
    if not instance then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiObject") then
            instance.Size = size
        end
    end)

    return success
end

-- ===== TWEEN =====

function HyperVAPI:Tween(instance: Instance, property: string, target: any, duration: number): boolean
    if not instance then return false end

    local success, err = pcall(function()
        local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = {[property] = target}

        local tween = game:GetService("TweenService"):Create(instance, tweenInfo, goal)
        tween:Play()
    end)

    return success
end

function HyperVAPI:TweenPosition(instance: Instance, position: UDim2, duration: number): boolean
    if not instance then return false end

    local success = pcall(function()
        if instance:IsA("GuiObject") then
            local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local goal = {Position = position}

            local tween = game:GetService("TweenService"):Create(instance, tweenInfo, goal)
            tween:Play()
        end
    end)

    return success
end

function HyperVAPI:TweenSize(instance: Instance, size: UDim2, duration: number): boolean
    if not instance then return false end

    local success = pcall(function()
        if instance:IsA("GuiObject") then
            local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local goal = {Size = size}

            local tween = game:GetService("TweenService"):Create(instance, tweenInfo, goal)
            tween:Play()
        end
    end)

    return success
end

-- ===== EVENT HANDLERS =====

function HyperVAPI:OnClick(instance: Instance, callback: () -> ()): boolean
    if not instance then return false end

    local success, err = pcall(function()
        if instance:IsA("GuiButton") then
            instance.MouseButton1Click:Connect(callback)
        end
    end)

    return success
end

function HyperVAPI:OnHover(instance: Instance, onEnter: (() -> ())?, onLeave: (() -> ())?): boolean
    if not instance then return false end

    local success = pcall(function()
        if instance:IsA("GuiObject") then
            if onEnter then
                instance.MouseEnter:Connect(onEnter)
            end
            if onLeave then
                instance.MouseLeave:Connect(onLeave)
            end
        end
    end)

    return success
end

-- ===== PERSISTENCE =====

function HyperVAPI:SaveState(instance: Instance, key: string): boolean
    if not instance then return false end

    local state = {
        visible = instance.Visible,
        active = instance.Active,
        position = instance:IsA("GuiObject") and instance.Position or nil,
        size = instance:IsA("GuiObject") and instance.Size or nil,
    }

    return instance:SetAttribute("HyperV_SavedState_" .. key, state)
end

function HyperVAPI:LoadState(instance: Instance, key: string): boolean
    if not instance then return false end

    local state = instance:GetAttribute("HyperV_SavedState_" .. key)
    if not state then return false end

    local success = pcall(function()
        if state.visible ~= nil then
            instance.Visible = state.visible
        end
        if state.active ~= nil and instance:IsA("GuiObject") then
            instance.Active = state.active
        end
        if state.position and instance:IsA("GuiObject") then
            instance.Position = state.position
        end
        if state.size and instance:IsA("GuiObject") then
            instance.Size = state.size
        end
    end)

    return success
end

-- ===== Z-INDEX =====

function HyperVAPI:GetZIndex(instance: Instance): number?
    if not instance then return nil end

    local zIndex = nil
    pcall(function()
        if instance:IsA("GuiObject") then
            zIndex = instance.ZIndex
        end
    end)

    return zIndex
end

function HyperVAPI:SetZIndex(instance: Instance, zIndex: number): boolean
    if not instance then return false end

    local success = pcall(function()
        if instance:IsA("GuiObject") then
            instance.ZIndex = zIndex
        end
    end)

    return success
end

function HyperVAPI:BringToFront(instance: Instance): boolean
    if not instance then return false end

    local success = pcall(function()
        if instance:IsA("GuiObject") then
            local parent = instance.Parent
            if parent then
                instance.Parent = nil
                instance.Parent = parent
            end
        end
    end)

    return success
end

function HyperVAPI:SendToBack(instance: Instance): boolean
    if not instance then return false end

    local success = pcall(function()
        if instance:IsA("GuiObject") then
            local parent = instance.Parent
            if parent and parent:IsA("GuiObject") then
                local children = parent:GetChildren()
                local firstChild = nil
                for _, child in ipairs(children) do
                    if child:IsA("GuiObject") and child ~= instance then
                        firstChild = child
                        break
                    end
                end
                if firstChild then
                    instance.ZIndex = firstChild.ZIndex - 1
                end
            end
        end
    end)

    return success
end

-- ===== EVENT EMITTER =====

function HyperVAPI:Emit(instance: Instance, event: string, ...: any)
    if not instance then return end

    pcall(function()
        local listeners = instance:GetAttribute("HyperV_Listeners_" .. event)
        if listeners and type(listeners) == "table" then
            for _, callback in ipairs(listeners) do
                callback(...)
            end
        end
    end)
end

function HyperVAPI:On(instance: Instance, event: string, callback: (...any) -> ()): boolean
    if not instance then return false end

    local success = pcall(function()
        local attrName = "HyperV_Listeners_" .. event
        local listeners = instance:GetAttribute(attrName) or {}

        table.insert(listeners, callback)
        instance:SetAttribute(attrName, listeners)
    end)

    return success
end

function HyperVAPI:Off(instance: Instance, event: string)
    if not instance then return end

    pcall(function()
        instance:SetAttribute("HyperV_Listeners_" .. event, nil)
    end)
end

return HyperVAPI


