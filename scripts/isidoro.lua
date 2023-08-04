local Mod = Isidoro
Mod.ISIDORO = {}
local ISIDORO = Mod.ISIDORO

ISIDORO.PLAYER_ISIDORO = Isaac.GetPlayerTypeByName("Isidoro")


-- assign costume
function ISIDORO:IsidoroInit(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    sprite:Load("gfx/characters/isidoro.anm2", true)
end
ISIDORO:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ISIDORO.IsidoroInit)


function ISIDORO:IsidoroUpdate(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    if player:GetMovementVector():Length() < 0.1 and not sprite:IsPlaying("IdleNormal") and player:IsExtraAnimationFinished() then
        player:PlayExtraAnimation("IdleNormal")
    elseif player:GetMovementVector():Length() > 0.1 and sprite:IsPlaying("IdleNormal") then
        player:StopExtraAnimation()
    end
end
ISIDORO:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, ISIDORO.IsidoroUpdate)