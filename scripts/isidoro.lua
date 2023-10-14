local Mod = Isidoro
Mod.ISIDORO = {}
local ISIDORO = Mod.ISIDORO
ISIDORO.PLAYER_ISIDORO = Isaac.GetPlayerTypeByName("Isidoro")
-- Mod.ENUMS.SOUNDS.TAUNT = Isaac.GetSoundIdByName("Isidoro Taunt") ill get to setting up enums later
-- Mod.ENUMS.SOUNDS.PARRY = Isaac.GetSoundIdByName("Isidoro Parry")
local TAUNTSOUND = Isaac.GetSoundIdByName("Isidoro Taunt")
local PARRYSOUND = Isaac.GetSoundIdByName("Isidoro Parry")

ISIDORO.PARRY_WINDOW = 12

local PARRY_WINDOW = ISIDORO.PARRY_WINDOW

local uninterruptable_actions = {

}

function ISIDORO:GetIsidoroState(player)
    if not player:GetData().isi_data then
		player:GetData().isi_data = {
			TauntTime = 0
		}
	end
	return player:GetData().isi_data
end

function ISIDORO:IsTaunting(player)
    local sprite = player:GetSprite()
    return sprite:IsPlaying("TauntFX")
end

function ISIDORO:ResetState(player)
    local isiData = ISIDORO:GetIsidoroState(player)

    player.ControlsEnabled = true
    isiData.TauntTime = 0
    player:ResetDamageCooldown()
end



-- assign costume
function ISIDORO:IsidoroInit(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    sprite:Load("gfx/characters/isidoro.anm2", true)
    ISIDORO:ResetState(player)
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ISIDORO.IsidoroInit)


function ISIDORO:IsidoroUpdate(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local data = player:GetData()
    -- local isiData = ISIDORO:GetIsidoroState(player)


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
    end

end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, ISIDORO.IsidoroUpdate, 0)


-----PARRY-----

function ISIDORO:Taunt(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local rng = player:GetDropRNG()
    local data = player:GetData()
    local isiData = ISIDORO:GetIsidoroState(player)

    if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then
        player:PlayExtraAnimation("TauntFX", true)
        SFXManager():Play(TAUNTSOUND)


        local overlay = Sprite() --this game SUCKS so overlay animations dont work with player sprites so i have to do this instead
        overlay:Load("gfx/characters/isidoro.anm2", true)
        overlay:SetFrame("Taunt", rng:RandomInt(16))
        data.isi_overlay = overlay

        player.ControlsEnabled = false
    end

    if isiData.TauntTime > 0 then
        player.ControlsEnabled = false
        isiData.TauntTime = isiData.TauntTime + 1
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ISIDORO.Taunt, 0)


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


function ISIDORO:ParryProjectile(projectile, collider)

    local player = collider:ToPlayer()
    local isiData = ISIDORO:GetIsidoroState(player)

    if ISIDORO:IsTaunting(player) and isiData.TauntTime <= PARRY_WINDOW then
        player:PlayExtraAnimation("Parry", true)
        player:SetMinDamageCooldown(20)
        SFXManager():Play(PARRYSOUND)

        for _, bullet in pairs(Isaac.FindInRadius(player.Position, 28, EntityPartition.BULLET)) do
			ISIDORO:DeflectProjectile(player, bullet)
		end

        return true
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, ISIDORO.ParryProjectile)