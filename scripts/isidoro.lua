local Mod = Isidoro
Mod.ISIDORO = {}
local ISIDORO = Mod.ISIDORO
local ENUMS = Mod.ENUMS
local FUNCTIONS = Mod.FUNCTIONS

local PLAYER_ISIDORO = ENUMS.PLAYERS.ISIDORO

ISIDORO.PARRY_WINDOW = 10

local PARRY_WINDOW = ISIDORO.PARRY_WINDOW

local uninterruptable_actions = {

}

function ISIDORO:GetIsidoroState(player)
    if not player:GetData().isi_data then
		player:GetData().isi_data = {
            Taunting = true,
			TauntTime = 0,
            LastPunchDirection = Vector.Zero,
		}
	end
	return player:GetData().isi_data
end

function ISIDORO:IsTaunting(player)
    local isiData = ISIDORO:GetIsidoroState(player)
    local sprite = player:GetSprite()
    return sprite:IsPlaying("TauntFX") or isiData.Taunting
end

function ISIDORO:ResetState(player)
    local isiData = ISIDORO:GetIsidoroState(player)

    player.ControlsEnabled = true
    isiData.TauntTime = 0
    isiData.Taunting = false
    player:ResetDamageCooldown()
end



-- assign costume
---@param player EntityPlayer
---@function
function ISIDORO:IsidoroInit(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    sprite:Load("gfx/characters/isidoro.anm2", true)
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ISIDORO.IsidoroInit)

---@param player EntityPlayer
---@function
function ISIDORO:IsidoroUpdate(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local data = player:GetData()
    local isiData = ISIDORO:GetIsidoroState(player)


    if player:GetMovementVector():Length() == 0 and not sprite:IsPlaying("IdleNormal") and player:IsExtraAnimationFinished() then
        ISIDORO:ResetState(player)
        player:PlayExtraAnimation("IdleNormal")
    elseif player:GetMovementVector():Length() > 0 and sprite:IsPlaying("IdleNormal") then
        player:StopExtraAnimation()
    end

    if sprite:IsPlaying("TauntFX") then
        if data.isi_overlay then
            data.isi_overlay:Render(Isaac.WorldToRenderPosition(player.Position))
        end

        if sprite:WasEventTriggered("Interruptable") then
            player.ControlsEnabled = true
        else
            player.ControlsEnabled = false
        end

    end

end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, ISIDORO.IsidoroUpdate, 0)


-----PARRY-----

---@param player EntityPlayer
---@function
function ISIDORO:Taunt(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local rng = player:GetDropRNG()
    local data = player:GetData()
    local isiData = ISIDORO:GetIsidoroState(player)

    if sprite:WasEventTriggered("Interruptable") then
        if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then --pre taunt
            isiData.Taunting = true
            isiData.TauntTime = 1

            Mod.Scheduler.Schedule(3, function() --taunt
                if not sprite:IsPlaying("Parry") then
                    player:PlayExtraAnimation("TauntFX", true)
                    SFXManager():Play(ENUMS.SFX.TAUNT)

                    local overlay = Sprite() --this game SUCKS so overlay animations dont work with player sprites so i have to do this instead
                    overlay:Load("gfx/characters/isidoro.anm2", true)
                    overlay:SetFrame("Taunt", rng:RandomInt(16))
                    player:GetData().isi_overlay = overlay

                end
            end)

        end
    end

    if isiData.TauntTime > 0 then
        player.ControlsEnabled = false
        isiData.TauntTime = isiData.TauntTime + 1
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ISIDORO.Taunt, 0)

---@param projectile EntityProjectile
---@param player EntityPlayer
---@function
function ISIDORO:DeflectProjectile(player, projectile)
	local playerPos = player.Position
    local projectilePos = projectile.Position

    projectile:ToProjectile():AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
    projectile.Velocity = projectile.Velocity * -1.5

	-- if math.abs(projectilePos.X - playerPos.X) > math.abs(projectilePos.Y - playerPos.Y) then
    --     projectile.Velocity = Vector(-projectile.Velocity.X, projectile.Velocity.Y)
	-- else
    --     projectile.Velocity = Vector(projectile.Velocity.X, -projectile.Velocity.Y)
	-- end
end

---@param projectile EntityProjectile
---@param collider EntityPlayer
---@function
function ISIDORO:ParryProjectile(projectile, collider)
    if not collider:ToPlayer() then return end

    local player = collider:ToPlayer()
    local isiData = ISIDORO:GetIsidoroState(player)

    if ISIDORO:IsTaunting(player) and isiData.TauntTime <= PARRY_WINDOW then
        player:PlayExtraAnimation("Parry", true)
        player:SetMinDamageCooldown(20)
        SFXManager():Play(ENUMS.SFX.PARRY, 1.4)
        SFXManager():Stop(ENUMS.SFX.TAUNT)

        for _, bullet in pairs(Isaac.FindInRadius(player.Position, 28, EntityPartition.BULLET)) do
			ISIDORO:DeflectProjectile(player, bullet)
		end

        return true
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, ISIDORO.ParryProjectile)



-----GRAB-----

--the next 3 functions are from epiphany https://steamcommunity.com/sharedfiles/filedetails/?id=3012430463
-- Custom implementation of GetAimDirection that doesn't reset between rooms.
-- Also accounts for Marked.
---@param player EntityPlayer
---@return Vector
---@function
function ISIDORO:GetAimDirection(player)
	local isMouseEnabled = Options.MouseControl
	local isiData = ISIDORO:GetIsidoroState(player)
	local aimVector = Vector.Zero

	if isMouseEnabled and Input.IsMouseBtnPressed(0) and player.ControllerIndex == 0 then -- 0 is left button
		local mousePos = Input.GetMousePosition(true)
		local direction = (mousePos - player.Position):Normalized()

		aimVector = direction
	end

	if not isMouseEnabled and player.ControllerIndex ~= 0 then -- they are using a controller
		local input = player:GetShootingJoystick()
		aimVector = input
	end

	if aimVector:Length() < 1e-3 then
		if player:AreOpposingShootDirectionsPressed() then
			aimVector = player:GetAimDirection()
		else
			aimVector = player:GetShootingJoystick()
		end
	end

	for _, mark in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TARGET)) do
		local parent = mark.SpawnerEntity and mark.SpawnerEntity:ToPlayer()
		if parent and FUNCTIONS:GetPlayerString(parent) == FUNCTIONS:GetPlayerString(player) then
			aimVector = (mark.Position - player.Position):Normalized()
			break
		end
	end

	if aimVector:Length() > 1e-3 then
		isiData.LastPunchDirection = aimVector
	end

	return aimVector
end

-- also from epiphany https://steamcommunity.com/sharedfiles/filedetails/?id=3012430463
---@param player EntityPlayer
---@return Vector
---@function
function ISIDORO:GetAttackDirection(player)
	local angle = ISIDORO:GetAimDirection(player):GetAngleDegrees()

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK) and not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then
		angle = ((angle + 45) // 90) * 90
	end

	return Vector.FromAngle(angle)
end


-- function from epiphany https://steamcommunity.com/sharedfiles/filedetails/?id=3012430463
---@param player EntityPlayer
---@param direction Vector?
---@param cooldown number? @Specifies a cooldown for the dash, fire delay
---@param dmg number? @Specifies the damage of the piledriver. If not specified, the player's damage will be used.
---@function
function ISIDORO:Grab(player, direction, cooldown, dmg)
	local isiData = ISIDORO:GetIsidoroState(player)

	-- multiply by 2 since player update runs 60 times a second while firerate works with 30 in mind
	cooldown = cooldown or (math.ceil(player.MaxFireDelay) * 2)

	local aimDirection = direction or ISIDORO:GetAttackDirection(player)


end


-- 		local angle = SAMSON:GetAimDirection(player):GetAngleDegrees()
-- 		angle = ((angle + 45) // 90) * 90

-- 		if angle == 0 then -- right
-- 			pos = pos + Vector(-offset.X, offset.Y)
-- 		elseif math.abs(angle) == 180 then -- left
-- 			pos = pos + Vector(offset.X, offset.Y)
-- 		else
-- 			pos = pos + Vector(0, offset.Y)
-- 		end