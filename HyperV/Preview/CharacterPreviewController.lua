--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local DisposableStore = require(script.Parent.Parent.Core.DisposableStore)
local Effects = require(script.Parent.CharacterPreviewEffects)
local Serializer = require(script.Parent.CharacterPreviewSerializer)
local CharacterPreviewState = require(script.Parent.CharacterPreviewState)
local CharacterPreviewView = require(script.Parent.CharacterPreviewView)

type CharacterPreviewConfig = Serializer.CharacterPreviewConfig

local DEFAULT_SIZE = Vector2.new(760, 560)

local CharacterPreviewController = {}
CharacterPreviewController.__index = CharacterPreviewController

local function deepClone(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local clone = {}
	for key, child in pairs(value) do
		clone[key] = deepClone(child)
	end
	return clone
end

local function deepEqual(left: any, right: any): boolean
	if type(left) ~= type(right) then
		return false
	end

	if type(left) ~= "table" then
		return left == right
	end

	for key, value in pairs(left) do
		if not deepEqual(value, right[key]) then
			return false
		end
	end

	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end

	return true
end

local function getVisualConfig(snapshot: CharacterPreviewConfig)
	return {
		transparency = snapshot.transparency,
		highlight = snapshot.highlight,
		trail = snapshot.trail,
		particles = snapshot.particles,
		forceField = snapshot.forceField,
		sound = snapshot.sound,
		charms = snapshot.charms,
	}
end

local function getLocalPlayer(): Player
	return Players.LocalPlayer
end

local function getUsableCharacter(player: Player): Model?
	local character = player.Character
	if character and character.Parent and character:IsA("Model") and character:FindFirstChildOfClass("Humanoid") then
		return character
	end

	local workspaceCharacter = Workspace:FindFirstChild(player.Name)
	if
		workspaceCharacter
		and workspaceCharacter:IsA("Model")
		and workspaceCharacter:FindFirstChildOfClass("Humanoid")
	then
		return workspaceCharacter
	end

	return nil
end

local function isCharacterReady(character: Model?): boolean
	if not character then
		return false
	end

	return character:FindFirstChildOfClass("Humanoid") ~= nil
		and character:FindFirstChild("HumanoidRootPart") ~= nil
		and character:FindFirstChild("Head") ~= nil
end

local function getWorldPoint(cf: CFrame, offset: Vector3): Vector3
	return (cf * CFrame.new(offset)).Position
end

local function getClassicFaceTexture(head: BasePart): string
	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("Decal") and (child.Name == "face" or child.Name == "Face") and child.Texture ~= "" then
			return child.Texture
		end
	end

	return "rbxasset://textures/face.png"
end

local function buildClassicPreviewHead(model: Model)
	local originalHead = model:FindFirstChild("Head")
	if not originalHead or not originalHead:IsA("BasePart") then
		return
	end

	local existing = model:FindFirstChild("PreviewClassicHead")
	if existing then
		existing:Destroy()
	end

	for _, child in ipairs(originalHead:GetChildren()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = 1
		elseif child:IsA("SurfaceAppearance") then
			child.Enabled = false
		end
	end

	originalHead.Transparency = 1
	originalHead.LocalTransparencyModifier = 0

	local classicHead = Instance.new("Part")
	classicHead.Name = "PreviewClassicHead"
	classicHead.Size = originalHead.Size
	classicHead.CFrame = originalHead.CFrame
	classicHead.Color = originalHead.Color
	classicHead.Material = Enum.Material.SmoothPlastic
	classicHead.TopSurface = Enum.SurfaceType.Smooth
	classicHead.BottomSurface = Enum.SurfaceType.Smooth
	classicHead.Anchored = true
	classicHead.CanCollide = false
	classicHead.CastShadow = false
	classicHead.Parent = model

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Parent = classicHead

	local face = Instance.new("Decal")
	face.Name = "Face"
	face.Face = Enum.NormalId.Front
	face.Texture = getClassicFaceTexture(originalHead)
	face.Parent = classicHead
end

function CharacterPreviewController.new(config, context)
	local self = setmetatable({}, CharacterPreviewController)
	self.id = config.Id or config.Name or "CharacterPreview"
	self.kind = "characterPreview"
	self.title = config.Title or "Character Preview"
	self._context = context
	self._config = config
	self._usesLiveCharacter = config.TargetCharacter == nil
	self._disposables = DisposableStore.new()
	self._effectCache = {}
	self._lastVisualConfig = nil
	self._rotationDragging = false
	self._lastPointer = nil
	self._targetCharacter = config.TargetCharacter
	self._lastLiveCharacter = nil
	self.previewCharacter = nil

	local window = context.app:createDetachedWindow({
		Id = self.id,
		Name = self.id,
		Title = self.title,
		Size = config.Size or DEFAULT_SIZE,
		Position = config.Position or context.defaultPreviewPosition,
		Parent = config.Parent,
		StackContent = false,
		OnCloseRequested = function()
			self:_cancel()
			return false
		end,
	})

	self.window = window
	self.view = window.view
	self.contentFrame = window.contentFrame
	self.state = CharacterPreviewState.new(config.InitialConfig)
	self._committedConfig = self.state:getConfig()

	self._view = CharacterPreviewView.new(window, context, {
		onPatch = function(patch)
			self.state:update(patch)
		end,
		onApply = function()
			self:_apply()
		end,
		onCancel = function()
			self:_cancel()
		end,
		onReset = function()
			self:reset()
		end,
		onResetView = function()
			local defaults = Serializer.getDefaults()
			self.state:update({
				orbit = {
					angle = defaults.orbit.angle,
					radius = defaults.orbit.radius,
					height = defaults.orbit.height,
				},
			})
		end,
	})

	self._disposables:add(self.state:subscribe(function(snapshot)
		self._view:setConfig(snapshot)
		local nextVisualConfig = getVisualConfig(snapshot)
		if not deepEqual(self._lastVisualConfig, nextVisualConfig) then
			self:_applyVisuals(snapshot)
			self._lastVisualConfig = deepClone(nextVisualConfig)
		end
		self:_updateCamera(snapshot)
		self:_updateProjectedEffects(snapshot)
	end))

	self._disposables:add(self._view.viewport.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self._rotationDragging = true
			self._lastPointer = input.Position
		end
	end))

	self._disposables:add(self._view.viewport.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self._rotationDragging = false
			self._lastPointer = nil
		end
	end))

	self._disposables:add(UserInputService.InputChanged:Connect(function(input)
		self._view:handleInputChanged(input)
		if
			self._rotationDragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			self:_onRotateMove(input.Position)
		end
	end))

	self._disposables:add(RunService.RenderStepped:Connect(function(deltaTime)
		self:_step(deltaTime)
	end))

	local player = getLocalPlayer()
	if self._usesLiveCharacter then
		self._targetCharacter = getUsableCharacter(player)
		self._lastLiveCharacter = self._targetCharacter
		self._disposables:add(player.CharacterAdded:Connect(function(character)
			self._targetCharacter = character
			self._lastLiveCharacter = character
			self:_rebuildPreviewCharacter()
			self._lastVisualConfig = nil
			self:_applyVisuals(self.state:getConfig())
		end))
		self._disposables:add(player.CharacterAppearanceLoaded:Connect(function(character)
			if not self._usesLiveCharacter then
				return
			end
			self._targetCharacter = character
			self._lastLiveCharacter = character
			self:_rebuildPreviewCharacter()
			self._lastVisualConfig = nil
			self:_applyVisuals(self.state:getConfig())
		end))
		self._disposables:add(player.CharacterRemoving:Connect(function(character)
			if self._targetCharacter == character then
				self._targetCharacter = nil
				self._lastLiveCharacter = nil
				self:_rebuildPreviewCharacter()
			end
		end))
	end

	self:_rebuildPreviewCharacter()
	local initialSnapshot = self.state:getConfig()
	self._view:setConfig(initialSnapshot)
	self:_applyVisuals(initialSnapshot)

	return self
end

function CharacterPreviewController:_refreshLiveCharacter(): boolean
	if not self._usesLiveCharacter then
		return false
	end

	local player = getLocalPlayer()
	local character = getUsableCharacter(player)
	if character ~= self._targetCharacter then
		self._targetCharacter = character
	end

	if character ~= self._lastLiveCharacter then
		self._lastLiveCharacter = character
		self:_rebuildPreviewCharacter()
		self._lastVisualConfig = nil
		self:_applyVisuals(self.state:getConfig())
		return true
	end

	if character and not self.previewCharacter then
		self:_rebuildPreviewCharacter()
		self._lastVisualConfig = nil
		self:_applyVisuals(self.state:getConfig())
		return self.previewCharacter ~= nil
	end

	return false
end

function CharacterPreviewController:_clearPreviewCharacter()
	if self.previewCharacter then
		self.previewCharacter:Destroy()
		self.previewCharacter = nil
	end

	for key, value in pairs(self._effectCache) do
		if key ~= "stage" and typeof(value) == "Instance" then
			value:Destroy()
			self._effectCache[key] = nil
		elseif key ~= "stage" and type(value) == "table" then
			for _, item in ipairs(value) do
				if typeof(item) == "Instance" then
					item:Destroy()
				end
			end
			self._effectCache[key] = nil
		end
	end
end

function CharacterPreviewController:_cloneCharacter(character: Model?): Model?
	if not character or not isCharacterReady(character) then
		return nil
	end

	local previousArchivable = character.Archivable
	character.Archivable = true
	local ok, clone = pcall(function()
		return character:Clone()
	end)
	character.Archivable = previousArchivable

	if not ok or not clone or not clone:IsA("Model") then
		return nil
	end

	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CastShadow = false
		end
	end

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	buildClassicPreviewHead(clone)

	local root = clone:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		clone.PrimaryPart = root
	end

	clone:PivotTo(CFrame.new(0, 0, 0))
	return clone
end

function CharacterPreviewController:_rebuildPreviewCharacter()
	self:_clearPreviewCharacter()

	local clone = self:_cloneCharacter(self._targetCharacter)
	if not clone then
		if self._targetCharacter and not isCharacterReady(self._targetCharacter) then
			self._view:setStatus("Character found, waiting for body parts...")
		else
			self._view:setStatus("Waiting for character model...")
		end
		return
	end

	Effects.ensurePreviewStage(self._view.worldModel, self._effectCache)
	clone.Parent = self._view.worldModel
	self.previewCharacter = clone
	self._view:setStatus(nil)
	self._lastVisualConfig = nil
end

function CharacterPreviewController:_getPivotPosition(): Vector3
	if not self.previewCharacter then
		return Vector3.zero
	end

	local root = self.previewCharacter:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end

	local cf = self.previewCharacter:GetBoundingBox()
	return cf.Position
end

function CharacterPreviewController:_getHealthText(): string
	if not self.previewCharacter then
		return "0 HP"
	end

	local humanoid = self.previewCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return "N/A"
	end

	return string.format("%d / %d HP", math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5))
end

function CharacterPreviewController:_getDistance(): number
	local currentCamera = Workspace.CurrentCamera
	if not currentCamera then
		return 0
	end

	return (currentCamera.CFrame.Position - self:_getPivotPosition()).Magnitude
end

function CharacterPreviewController:_projectBounds()
	if not self.previewCharacter then
		return nil
	end

	local camera = self._view.camera
	local boundingBox, size = self.previewCharacter:GetBoundingBox()
	local half = size * 0.5
	local corners = {
		getWorldPoint(boundingBox, Vector3.new(-half.X, -half.Y, -half.Z)),
		getWorldPoint(boundingBox, Vector3.new(-half.X, -half.Y, half.Z)),
		getWorldPoint(boundingBox, Vector3.new(-half.X, half.Y, -half.Z)),
		getWorldPoint(boundingBox, Vector3.new(-half.X, half.Y, half.Z)),
		getWorldPoint(boundingBox, Vector3.new(half.X, -half.Y, -half.Z)),
		getWorldPoint(boundingBox, Vector3.new(half.X, -half.Y, half.Z)),
		getWorldPoint(boundingBox, Vector3.new(half.X, half.Y, -half.Z)),
		getWorldPoint(boundingBox, Vector3.new(half.X, half.Y, half.Z)),
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local visible = false

	for _, corner in ipairs(corners) do
		local point, onScreen = camera:WorldToViewportPoint(corner)
		if onScreen then
			visible = true
			minX = math.min(minX, point.X)
			minY = math.min(minY, point.Y)
			maxX = math.max(maxX, point.X)
			maxY = math.max(maxY, point.Y)
		end
	end

	if not visible then
		return nil
	end

	return {
		minX = minX,
		minY = minY,
		width = math.max(1, maxX - minX),
		height = math.max(1, maxY - minY),
	}
end

function CharacterPreviewController:_applyVisuals(snapshot: CharacterPreviewConfig)
	if not self.previewCharacter then
		self._view:setStatus("Waiting for character model...")
		self._view.boxFrame.Visible = false
		self._view.infoLabel.Visible = false
		self._view.tracerFrame.Visible = false
		return
	end

	self._view:setStatus(nil)
	Effects.applyTransparency(self.previewCharacter, snapshot.transparency, self._effectCache)
	Effects.applyCharms(self.previewCharacter, snapshot.charms, self._effectCache, snapshot.transparency)
	Effects.applyHighlight(self.previewCharacter, snapshot.highlight, self._effectCache)
	Effects.applyTrail(self.previewCharacter, snapshot.trail, self._effectCache)
	Effects.applyParticles(self.previewCharacter, snapshot.particles, self._effectCache)
	Effects.applyForceField(self.previewCharacter, snapshot.forceField, self._effectCache)
	Effects.applySound(self.previewCharacter, snapshot.sound, self._effectCache)
end

function CharacterPreviewController:_updateProjectedEffects(snapshot: CharacterPreviewConfig)
	local bounds = self:_projectBounds()
	Effects.applyEspBox(self._view.viewportOverlay, self._view.boxFrame, bounds, snapshot.espBox)
	Effects.applyEspInfo(
		self._view.infoCard,
		self._view.infoLabel,
		bounds,
		snapshot.espInfo,
		if self._targetCharacter then self._targetCharacter.Name else "Character",
		self:_getDistance(),
		self:_getHealthText()
	)
	Effects.applyTracer(self._view.tracerFrame, bounds, self._view.viewportOverlay.AbsoluteSize, snapshot.tracer)
end

function CharacterPreviewController:_updateCamera(snapshot: CharacterPreviewConfig)
	local pivot = self:_getPivotPosition()
	local orbit = snapshot.orbit
	local radius = orbit.radius
	local height = orbit.height
	local lookTarget = pivot + Vector3.new(0, 1, 0)
	local baseVerticalOffset = 0

	if self.previewCharacter then
		local _, size = self.previewCharacter:GetBoundingBox()
		radius = math.max(radius, math.max(size.X, size.Z) * 1.15 + (size.Y * 0.55))
		baseVerticalOffset = size.Y * 0.18
		height = math.max(height, 0.35)
		lookTarget = pivot + Vector3.new(0, size.Y * 0.12, 0)
	end

	self._view.camera.FieldOfView = 40
	local x = radius * math.cos(orbit.angle)
	local z = radius * math.sin(orbit.angle)
	local cameraPosition = pivot + Vector3.new(x, baseVerticalOffset + height, z)
	self._view.camera.CFrame = CFrame.lookAt(cameraPosition, lookTarget)
end

function CharacterPreviewController:_step(deltaTime: number)
	if self._usesLiveCharacter and not self.previewCharacter then
		self:_refreshLiveCharacter()
	end

	local snapshot = self.state:getConfig()
	if snapshot.orbit.autoRotate and not self._rotationDragging then
		snapshot = self.state:update({
			orbit = {
				angle = snapshot.orbit.angle + (snapshot.orbit.speed * deltaTime),
			},
		})
	end

	self:_updateCamera(snapshot)
	if self.previewCharacter then
		Effects.applyTrail(self.previewCharacter, snapshot.trail, self._effectCache)
	end
	self:_updateProjectedEffects(snapshot)
end

function CharacterPreviewController:_onRotateMove(position: Vector3)
	if not self._lastPointer then
		self._lastPointer = position
		return
	end

	local delta = position - self._lastPointer
	self._lastPointer = position

	local snapshot = self.state:getConfig()
	self.state:update({
		orbit = {
			angle = snapshot.orbit.angle - (delta.X * 0.01),
			height = math.clamp(snapshot.orbit.height - (delta.Y * 0.005), 0.35, 2.4),
		},
	})
end

function CharacterPreviewController:_apply()
	local snapshot = self.state:getConfig()
	self._committedConfig = Serializer.snapshot(snapshot)
	if self._config.OnApply then
		self._config.OnApply(snapshot)
	end
	self:close()
end

function CharacterPreviewController:_cancel()
	self.state:setConfig(self._committedConfig)
	if self._config.OnCancel then
		self._config.OnCancel()
	end
	self:close()
end

function CharacterPreviewController:getPresetValue()
	return self.state:getConfig()
end

function CharacterPreviewController:applyPresetValue(value)
	self.state:setConfig(value)
	self._committedConfig = self.state:getConfig()
	self._lastVisualConfig = nil
end

function CharacterPreviewController:setConfig(config)
	self.state:setConfig(config)
	self._committedConfig = self.state:getConfig()
	self._lastVisualConfig = nil
end

function CharacterPreviewController:getConfig()
	return self.state:getConfig()
end

function CharacterPreviewController:reset()
	self.state:reset()
	self._lastVisualConfig = nil
end

function CharacterPreviewController:setTargetCharacter(model: Model?)
	self._usesLiveCharacter = model == nil
	self._targetCharacter = if model == nil then getUsableCharacter(getLocalPlayer()) else model
	self._lastLiveCharacter = self._targetCharacter
	self:_rebuildPreviewCharacter()
	self._lastVisualConfig = nil
	self:_applyVisuals(self.state:getConfig())
end

function CharacterPreviewController:applyTheme(theme, layout)
	self._context.theme = theme or self._context.theme
	self._context.layout = layout or self._context.layout
	self.window:applyTheme(self._context.theme)
	self._view:applyTheme(self._context.theme)
end

function CharacterPreviewController:open()
	self:_refreshLiveCharacter()
	self:_rebuildPreviewCharacter()
	self:_applyVisuals(self.state:getConfig())
	self.window:open()
end

function CharacterPreviewController:close()
	self.window:close()
end

function CharacterPreviewController:dispose()
	self._rotationDragging = false
	self._lastPointer = nil
	self:_clearPreviewCharacter()
	self._disposables:cleanup()
	self._view:dispose()
end

return CharacterPreviewController
