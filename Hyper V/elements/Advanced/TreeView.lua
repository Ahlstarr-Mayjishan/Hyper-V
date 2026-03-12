local VirtualList = require(script.Parent.VirtualList)

local TreeView = {}
TreeView.__index = TreeView

function TreeView.new(config, theme, utilities)
    local self = setmetatable({}, TreeView)

    self.Name = config.Name or "TreeView"
    self.Title = config.Title or "Tree View"
    self.Nodes = config.Nodes or {}
    self.Height = config.Height or 220
    self.ItemHeight = config.ItemHeight or 28
    self.Width = config.Width
    self.Parent = config.Parent
    self.Theme = theme
    self.Utilities = utilities
    self.OnSelect = config.OnSelect or config.Callback
    self.IndentWidth = config.IndentWidth or 14
    self.DefaultExpanded = config.DefaultExpanded == true

    self.Expanded = {}
    self.FlatRows = {}
    self.SelectedKey = nil
    self.SelectedNode = nil

    self:InitializeExpanded()
    self:Create()
    self:Refresh()
    return self
end

function TreeView:InitializeExpanded()
    if not self.DefaultExpanded then
        return
    end

    for _, node in ipairs(self.Nodes) do
        if node.Children and #node.Children > 0 then
            self.Expanded[node.Key or node.Name] = true
        end
    end
end

function TreeView:Create()
    self.VirtualList = VirtualList.new({
        Name = self.Name,
        Title = self.Title,
        Height = self.Height,
        Width = self.Width,
        ItemHeight = self.ItemHeight,
        Overscan = 4,
        Parent = self.Parent,
        Items = {},
        ResolveText = function(item)
            return item.Text
        end,
        RowRenderer = function(row, label, item, _, selected)
            row.BackgroundColor3 = selected and self.Theme.Accent or self.Theme.Default
            label.Position = UDim2.new(0, 8 + (item.Depth * self.IndentWidth), 0, 0)
            label.Size = UDim2.new(1, -(16 + (item.Depth * self.IndentWidth)), 1, 0)
            label.Text = item.Text
            label.TextColor3 = selected and Color3.new(1, 1, 1) or self.Theme.Text
        end,
        OnItemClick = function(item)
            self:HandleItemClick(item)
        end,
        OnItemSelect = function(item)
            self.SelectedKey = item.Key
            self.SelectedNode = item.Node
        end,
    }, self.Theme, self.Utilities)

    self.Container = self.VirtualList.Container
    self.ScrollFrame = self.VirtualList.ScrollFrame
end

function TreeView:BuildRow(node, depth)
    local key = node.Key or node.Name
    local hasChildren = node.Children and #node.Children > 0
    local expanded = self.Expanded[key] == true
    local prefix = hasChildren and (expanded and "[-] " or "[+] ") or "[ ] "

    return {
        Key = key,
        Node = node,
        Depth = depth,
        HasChildren = hasChildren,
        Expanded = expanded,
        Text = prefix .. tostring(node.Name or key),
    }
end

function TreeView:FlattenNodes()
    local rows = {}

    local function visit(nodes, depth)
        for _, node in ipairs(nodes or {}) do
            local row = self:BuildRow(node, depth)
            table.insert(rows, row)

            if row.HasChildren and row.Expanded then
                visit(node.Children, depth + 1)
            end
        end
    end

    visit(self.Nodes, 0)
    self.FlatRows = rows
    return rows
end

function TreeView:FindRowIndexByKey(key)
    for index, row in ipairs(self.FlatRows) do
        if row.Key == key then
            return index, row
        end
    end
end

function TreeView:Refresh()
    self:FlattenNodes()
    self.VirtualList:SetItems(self.FlatRows)

    if self.SelectedKey then
        local index, row = self:FindRowIndexByKey(self.SelectedKey)
        if index and row then
            self.SelectedNode = row.Node
            self.VirtualList:SetValue(index, true)
        else
            self.VirtualList:SetValue(nil, true)
        end
    else
        self.VirtualList:SetValue(nil, true)
    end
end

function TreeView:HandleItemClick(item)
    self.SelectedKey = item.Key
    self.SelectedNode = item.Node

    if item.HasChildren then
        self.Expanded[item.Key] = not self.Expanded[item.Key]
        self:Refresh()
    end

    if self.OnSelect then
        self.OnSelect(item.Node, item.Depth)
    end
end

function TreeView:SetNodes(nodes)
    self.Nodes = nodes or {}
    self.Expanded = {}
    self.SelectedKey = nil
    self.SelectedNode = nil
    self:InitializeExpanded()
    self:Refresh()
end

function TreeView:Expand(key)
    self.Expanded[key] = true
    self:Refresh()
end

function TreeView:Collapse(key)
    self.Expanded[key] = nil
    self:Refresh()
end

function TreeView:Toggle(key)
    self.Expanded[key] = not self.Expanded[key] or nil
    self:Refresh()
end

function TreeView:ExpandAll()
    local function visit(nodes)
        for _, node in ipairs(nodes or {}) do
            local key = node.Key or node.Name
            if node.Children and #node.Children > 0 then
                self.Expanded[key] = true
                visit(node.Children)
            end
        end
    end

    visit(self.Nodes)
    self:Refresh()
end

function TreeView:CollapseAll()
    self.Expanded = {}
    self:Refresh()
end

function TreeView:GetValue()
    return self.SelectedNode
end

function TreeView:GetSelectedKey()
    return self.SelectedKey
end

function TreeView:SetValue(nodeKey, silent)
    if not nodeKey then
        self.SelectedKey = nil
        self.SelectedNode = nil
        self:Refresh()
        return
    end

    local function findNode(nodes, ancestors)
        for _, node in ipairs(nodes or {}) do
            local key = node.Key or node.Name
            local nextAncestors = {}
            for _, ancestor in ipairs(ancestors) do
                table.insert(nextAncestors, ancestor)
            end
            table.insert(nextAncestors, key)

            if key == nodeKey or node.Name == nodeKey then
                return node, nextAncestors
            end

            local childNode, childAncestors = findNode(node.Children, nextAncestors)
            if childNode then
                return childNode, childAncestors
            end
        end
    end

    local node, ancestors = findNode(self.Nodes, {})
    if not node then
        return
    end

    for index = 1, math.max(#ancestors - 1, 0) do
        self.Expanded[ancestors[index]] = true
    end

    self.SelectedKey = node.Key or node.Name
    self.SelectedNode = node
    self:Refresh()

    if not silent and self.OnSelect then
        self.OnSelect(node)
    end
end

return TreeView
