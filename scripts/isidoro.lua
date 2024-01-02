local Mod = Isidoro
Mod.ISIDORO = {}
local ISIDORO = Mod.ISIDORO
local ENUMS = Mod.ENUMS
local FUNCTIONS = Mod.FUNCTIONS

local PLAYER_ISIDORO = ENUMS.PLAYERS.ISIDORO

ISIDORO.PARRY_WINDOW = 10
ISIDORO.GRAB_MINIMUM = 10
ISIDORO.GRAB_MAXIMUM = 20

local PARRY_WINDOW = ISIDORO.PARRY_WINDOW
local GRAB_MINIMUM = ISIDORO.GRAB_MINIMUM
local GRAB_MAXIMUM = ISIDORO.GRAB_MAXIMUM

--todo parry window is 8 frames in pt
--todo fix piledriver
--todo finish repentogon transfer

---@param player EntityPlayer
---@function
function ISIDORO:GetIsidoroState(player)
    if not player:GetData().isi_data then
		player:GetData().isi_data = {
            Taunting = true,
			TauntTime = 0,
            LastDashDirection = Vector.Zero,
            DashVelocity = Vector.Zero,
            GrabTimeRemaining = 0,
            StoredVelocity = Vector.Zero,
            PiledriveTime = 0,
            PiledrivenEnemyHash = nil,
            PiledrivenEnemyCollisionClass = nil
		}
	end
	return player:GetData().isi_data
end

---@param player EntityPlayer
---@function
function ISIDORO:IsTaunting(player)
    local isiData = ISIDORO:GetIsidoroState(player)
    local sprite = player:GetSprite()
    return sprite:IsPlaying("TauntFX") or isiData.Taunting
end

---@param player EntityPlayer
---@function
function ISIDORO:IsShooting(player)
    return ISIDORO:GetAimDirection(player):Length() > 1e-3
end

-- when players are doing an attack animation, even if they arent holding the button
---@param player EntityPlayer
---@function
function ISIDORO:IsAttacking(player)
    local sprite = player:GetSprite()
    return sprite:IsPlaying("GrabLoopRight") or sprite:IsPlaying("GrabLoopDown") or sprite:IsPlaying("GrabLoopLeft") or sprite:IsPlaying("GrabLoopUp")
end

---@param player EntityPlayer
---@function
function ISIDORO:IsPiledriving(player)
    local sprite = player:GetSprite()
    return sprite:IsPlaying("PiledriverLeap") or sprite:IsPlaying("PiledriverLand")
end

---@param player EntityPlayer
---@function
function ISIDORO:ResetState(player)
    local isiData = ISIDORO:GetIsidoroState(player)

    player.ControlsEnabled = true
    isiData.TauntTime = 0
    isiData.Taunting = false
    isiData.GrabTimeRemaining = 0
    player:StopExtraAnimation()
    player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
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
function ISIDORO:IsidoroRender(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local data = player:GetData()
    local isiData = ISIDORO:GetIsidoroState(player)

    if player:GetDamageCooldown() % 5 == 2 then
        player:SetColor(Color(0, 0, 0, 0), 2, 200, false, false)
    end


    if player:GetMovementVector():Length() == 0 and (not sprite:IsPlaying("IdleNormal") or not sprite:IsFinished("IdleNormal"))
    and player:IsExtraAnimationFinished() and not ISIDORO:IsAttacking(player) and not ISIDORO:IsPiledriving(player) then

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
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, ISIDORO.IsidoroRender, 0)


---@param player EntityPlayer
---@function
function ISIDORO:IsidoroUpdate(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local data = player:GetData()
    local isiData = ISIDORO:GetIsidoroState(player)

    if sprite:WasEventTriggered("Interruptable") then
        if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then --pre taunt
            ISIDORO:Taunt(player)
        end
    end

    if isiData.TauntTime > 0 then
        player.ControlsEnabled = false
        isiData.TauntTime = isiData.TauntTime + 1
    end



    if ISIDORO:IsShooting(player) and not player:HasEntityFlags(EntityFlag.FLAG_FEAR) --dash grab
    and not ISIDORO:IsAttacking(player) and isiData.GrabTimeRemaining == 0 and player.FireDelay <= 0
    and not ISIDORO:IsPiledriving(player) then
        ISIDORO:Grab(player)

    elseif ISIDORO:IsAttacking(player) and isiData.GrabTimeRemaining > 0 then --keeping the dashing at a consistant speed
        player.Velocity = isiData.DashVelocity + (player:GetMovementVector() * 2)

    elseif ISIDORO:IsAttacking(player) and isiData.GrabTimeRemaining == 0 then --let go of button before hitting something
        player:StopExtraAnimation()
        ISIDORO:ResetState(player)
        player.FireDelay = player.MaxFireDelay
    end

    if ISIDORO:IsAttacking(player) and player:CollidesWithGrid() then
        player:StopExtraAnimation()
        ISIDORO:ResetState(player)
    end

    if isiData.GrabTimeRemaining > 0 then
        isiData.GrabTimeRemaining = isiData.GrabTimeRemaining - 1
    end


    if isiData.PiledriveTime > 0 then
        isiData.PiledriveTime = isiData.PiledriveTime + 1
    end

    -- if ISIDORO:IsPiledriving(player) then
    --     player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    -- end

end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ISIDORO.IsidoroUpdate, 0)


--todo use the input callback so hes technically moving in the direction while dashing
--todo use the the damage countdown argument in a take damage function to make a buffer

-----PARRY-----

---@param player EntityPlayer
---@function
function ISIDORO:Taunt(player)
    local sprite = player:GetSprite()
    local rng = player:GetDropRNG()
    local isiData = ISIDORO:GetIsidoroState(player)

    isiData.Taunting = true
    isiData.TauntTime = 1

    Mod.Scheduler.Schedule(3, function() --taunt
        if not sprite:IsPlaying("Parry") then
            player:PlayExtraAnimation("TauntFX")
            SFXManager():Play(ENUMS.SFX.TAUNT)

            local overlay = Sprite() --this game SUCKS so overlay animations dont work with player sprites so i have to do this instead
            overlay:Load("gfx/characters/isidoro.anm2", true)
            overlay:SetFrame("Taunt", rng:RandomInt(16))
            player:GetData().isi_overlay = overlay

        end
    end)
end

---@param projectile Entity
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

    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local isiData = ISIDORO:GetIsidoroState(player)

    if ISIDORO:IsTaunting(player) and isiData.TauntTime <= PARRY_WINDOW then
        player:PlayExtraAnimation("Parry")
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

--the next 2 functions and a bit of the 3rd are from epiphany https://steamcommunity.com/sharedfiles/filedetails/?id=3012430463
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
		isiData.LastDashDirection = aimVector
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

---@param player EntityPlayer
---@function
function ISIDORO:Grab(player)
	local isiData = ISIDORO:GetIsidoroState(player)

	-- multiply by 2 since player update runs 60 times a second while firerate works with 30 in mind
	-- cooldown = cooldown or (math.ceil(player.MaxFireDelay) * 2)

	local aimDirection = ISIDORO:GetAttackDirection(player)
    local aimAngle = aimDirection:GetAngleDegrees()
    local vector = FUNCTIONS:VectorMin(FUNCTIONS:VectorMax(aimDirection * 8, aimDirection * player.TearRange / 40), aimDirection * 10) --speed scales with range

    player.Velocity = vector

    isiData.DashVelocity = vector
    isiData.GrabTimeRemaining = GRAB_MINIMUM + math.min(GRAB_MAXIMUM, FUNCTIONS.Round(vector:Length()))

    if aimAngle >= -45 and aimAngle <= 45 then --right
        player:PlayExtraAnimation("GrabStartRight")
        player:QueueExtraAnimation("GrabLoopRight")
    elseif aimAngle >= 45 and aimAngle <= 135 then --down
        player:PlayExtraAnimation("GrabStartDown")
        player:QueueExtraAnimation("GrabLoopDown")
    elseif aimAngle >= -135 and aimAngle <= -45 then --up
        player:PlayExtraAnimation("GrabStartUp")
        player:QueueExtraAnimation("GrabLoopUp")
    else --left
        player:PlayExtraAnimation("GrabStartLeft")
        player:QueueExtraAnimation("GrabLoopLeft")
    end

    SFXManager():Play(ENUMS.SFX.GRABDASH, .8)

end

---@param player EntityPlayer
---@param collider Entity
---@function
function ISIDORO:GrabCollision(player, collider)
    if not collider:ToNPC() then return end
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local npc = collider:ToNPC()

    local isiData = ISIDORO:GetIsidoroState(player)

    if ISIDORO:IsPiledriving(player) then
        return false
    end
    if ISIDORO:IsAttacking(player) and isiData.GrabTimeRemaining > 0 then
        if npc:IsBoss() or npc.Mass == 100 or npc:IsInvincible() or not npc:IsVulnerableEnemy() then  -- enemies with mass 100 are stationary
            ISIDORO:Punch(player, npc)
        else
            ISIDORO:Piledriver(player, npc)
        end

        return true
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, ISIDORO.GrabCollision)

---@param player EntityPlayer
---@param npc EntityNPC
---@function
function ISIDORO:Punch(player, npc)
    local isiData = ISIDORO:GetIsidoroState(player)

    local aimAngle = player.Velocity:GetAngleDegrees()

    if aimAngle >= -45 and aimAngle <= 45 then --right
        player:PlayExtraAnimation("BossPunchRight")
    elseif aimAngle >= 45 and aimAngle <= 135 then --down
        player:PlayExtraAnimation("BossPunchDown")
    elseif aimAngle >= -135 and aimAngle <= -45 then --up
        player:PlayExtraAnimation("BossPunchUp")
    else --left
        player:PlayExtraAnimation("BossPunchLeft")
    end

    player:ResetDamageCooldown()
    player:SetMinDamageCooldown(20)
    player.Velocity = -player.Velocity:Resized(10)
    player.FireDelay = player.MaxFireDelay

    npc:TakeDamage(player.Damage * 4, 0, EntityRef(player), 0)
    SFXManager():Play(ENUMS.SFX.PUNCH, 1.6)

    -- enemies with mass 100 are stationary
    if npc.Mass < 100 and not npc:IsInvincible() then
        npc:AddVelocity(isiData.DashVelocity * 1.5 * (100 - npc.Mass) * .04)
        npc:AddEntityFlags(EntityFlag.FLAG_KNOCKED_BACK | EntityFlag.FLAG_APPLY_IMPACT_DAMAGE)
    end

end



---@param player EntityPlayer
---@param npc EntityNPC
---@function
function ISIDORO:Piledriver(player, npc)
    local isiData = ISIDORO:GetIsidoroState(player)
    local sprite = player:GetSprite()

    sprite:Play("PiledriverLeap")
    SFXManager():Stop(ENUMS.SFX.GRABDASH)
    SFXManager():Play(ENUMS.SFX.PILEDRIVER_START, 2.7)
    isiData.PiledriveTime = 1

    npc:GetData().isi_piledriver = FUNCTIONS:GetPlayerNumber(player)
    npc:GetData().isi_piledriverHash = player
    isiData.PiledrivenEnemyHash = npc

    isiData.PiledrivenEnemyCollisionClass = npc.EntityCollisionClass
    player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

    player:ResetDamageCooldown()
    player:SetMinDamageCooldown(4)
    player.CollisionDamage = 4

    npc:AddEntityFlags(EntityFlag.FLAG_NO_SPRITE_UPDATE)

    return true

end

local piledriver_null_layer_position = {
    [0] = 15,
    [1] = 8,
    [2] = 0,
    [3] = -8,
    [4] = -15,
    [5] = -8,
    [6] = 0,
    [7] = 8,
}

function ISIDORO:PiledriveReciever(npc)
    local data = npc:GetData()
    if data.isi_piledriver then
        local player = Game():GetPlayer(data.isi_piledriver)

        if GetPtrHash(player) == GetPtrHash(data.isi_piledriverHash) then --todo move this to the player render callback
            local isiData = ISIDORO:GetIsidoroState(player)
            local x = isiData.PiledriveTime
            local frame = player:GetSprite():GetFrame()
            npc.Position = player.Position

            npc.SpriteOffset = Vector(piledriver_null_layer_position[frame] or 0, (x/5) * (x - (player.ShotSpeed * 40)))
            player.SpriteOffset = Vector(0, (x/5) * (x - (player.ShotSpeed * 40)))

            if frame == 1 or frame == 2 or frame == 3 then
                player.DepthOffset = npc.DepthOffset - 20
            else
                player.DepthOffset = npc.DepthOffset + 20
            end

            if player.SpriteOffset.Y > 0 then
                data.isi_piledriver = nil

                player.SpriteOffset = Vector.Zero
                npc.SpriteOffset = Vector.Zero
                player.DepthOffset = 0

                player:PlayExtraAnimation("PiledriverLand")
                SFXManager():Play(ENUMS.SFX.PILEDRIVER_SLAM, 1.8)

                npc:TakeDamage(player.Damage * 4, 0, EntityRef(player), 0)
                npc:AddVelocity(player:GetMovementVector():Resized(20))
                npc:AddEntityFlags(EntityFlag.FLAG_KNOCKED_BACK | EntityFlag.FLAG_APPLY_IMPACT_DAMAGE)
                npc:ClearEntityFlags(EntityFlag.FLAG_NO_SPRITE_UPDATE)

                player:ResetDamageCooldown()
                player:SetMinDamageCooldown(30)

                npc.EntityCollisionClass = isiData.PiledrivenEnemyCollisionClass
                player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

                isiData.PiledrivenEnemyHash = nil
                isiData.PiledrivenEnemyCollisionClass = nil
                isiData.PiledriveTime = 0
            end

            return true
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, ISIDORO.PiledriveReciever)