local entitylib = {
	isAlive = false,
	character = {},
	List = {},
}

local playersService = game:GetService("Players")
local inputService = game:GetService("UserInputService")
local lplr = playersService.LocalPlayer
local gameCamera = workspace.CurrentCamera

local function getMousePosition()
	if inputService.TouchEnabled then
		return gameCamera.ViewportSize / 2
	end
	return inputService:GetMouseLocation()
end

entitylib.targetCheck = function(entity)
	if entity.NPC then return true end
	if not lplr.Team then return true end
	if not entity.Player or not entity.Player.Team then return true end
	if entity.Player.Team ~= lplr.Team then return true end
	return #entity.Player.Team:GetPlayers() == #playersService:GetPlayers()
end

entitylib.isVulnerable = function(entity)
	return entity.Health > 0 and not entity.Character:FindFirstChildWhichIsA("ForceField")
end

entitylib.EntityMouse = function(s)
	if not entitylib.isAlive then
		table.clear(s)
		return
	end
	local mouse = s.MouseOrigin or getMousePosition()
	local best, bestEnt = s.Range or 150, nil

	for _, entity in entitylib.List do
		if not s.Players and entity.Player then continue end
		if not s.NPCs and entity.NPC then continue end
		if not entity.Targetable then continue end
		if not entitylib.isVulnerable(entity) then continue end

		local part = entity[s.Part]
		if not part then continue end

		local position, vis = gameCamera:WorldToViewportPoint(part.Position)
		if not vis then continue end

		local mag = (mouse - Vector2.new(position.X, position.Y)).Magnitude
		if mag > best then continue end

		best = mag
		bestEnt = entity
	end

	table.clear(s)
	return bestEnt
end

entitylib.EntityPosition = function(s)
	if not entitylib.isAlive then
		table.clear(s)
		return
	end
	local origin = s.Origin or entitylib.character.RootPart.Position
	local best, bestEnt = s.Range or 150, nil

	for _, entity in entitylib.List do
		if not s.Players and entity.Player then continue end
		if not s.NPCs and entity.NPC then continue end
		if not entity.Targetable then continue end
		if not entitylib.isVulnerable(entity) then continue end

		local part = entity[s.Part]
		if not part then continue end

		local mag = (part.Position - origin).Magnitude
		if mag > best then continue end

		best = mag
		bestEnt = entity
	end

	table.clear(s)
	return bestEnt
end

entitylib.addEntity = function(char, plr)
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head") or root
	if not (hum and root) then return end

	local entity = {
		Character = char,
		Health = hum.Health,
		MaxHealth = hum.MaxHealth,
		Head = head,
		Humanoid = hum,
		HumanoidRootPart = root,
		RootPart = root,
		HipHeight = hum.HipHeight or 2,
		NPC = plr == nil,
		Player = plr,
		Targetable = true,
	}

	if plr == lplr then
		entitylib.character = entity
		entitylib.isAlive = true
	else
		entity.Targetable = entitylib.targetCheck(entity)
		table.insert(entitylib.List, entity)
	end
end

entitylib.removeEntity = function(char)
	if char == lplr.Character then
		entitylib.isAlive = false
		return
	end
	for i, e in ipairs(entitylib.List) do
		if e.Character == char then
			table.remove(entitylib.List, i)
			break
		end
	end
end

entitylib.start = function()
	for _, plr in playersService:GetPlayers() do
		if plr.Character then
			entitylib.addEntity(plr.Character, plr)
		end
		plr.CharacterAdded:Connect(function(c)
			entitylib.addEntity(c, plr)
		end)
		plr.CharacterRemoving:Connect(function(c)
			entitylib.removeEntity(c)
		end)
	end
	playersService.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(c)
			entitylib.addEntity(c, plr)
		end)
	end)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		gameCamera = workspace.CurrentCamera
	end)
end

entitylib.start()
return entitylib
