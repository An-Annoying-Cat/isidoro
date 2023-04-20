Isidoro = RegisterMod("Isidoro", 1)
local Mod = Isidoro

local PLAYER_ISIDORO = Isaac.GetPlayerTypeByName("Isidoro")


-- assign costume
function Mod:IsidoroInit(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    sprite:Load("gfx/characters/isidoro.anm2", true)
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Mod.IsidoroInit)


function Mod:IsidoroUpdate(player)
    if player:GetPlayerType() ~= PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    if player:GetMovementVector():Length() < 0.1 and not sprite:IsPlaying("IdleNormal") and player:IsExtraAnimationFinished() then
        player:PlayExtraAnimation("IdleNormal")
    elseif player:GetMovementVector():Length() > 0.1 and sprite:IsPlaying("IdleNormal") then
        player:StopExtraAnimation()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Mod.IsidoroUpdate)