local Mod = Isidoro
Mod.ISIDORO = {}
local ISIDORO = Mod.ISIDORO
ISIDORO.PLAYER_ISIDORO = Isaac.GetPlayerTypeByName("Isidoro")

local uninterruptable_actions = {

}

-- assign costume
function ISIDORO:IsidoroInit(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    sprite:Load("gfx/characters/isidoro.anm2", true)
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, ISIDORO.IsidoroInit)


function ISIDORO:IsidoroUpdate(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local data = player:GetData()


    if player:GetMovementVector():Length() == 0 and not sprite:IsPlaying("IdleNormal") and player:IsExtraAnimationFinished() then
        player:PlayExtraAnimation("IdleNormal")
        sprite:RemoveOverlay()
        player.ControlsEnabled = true
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

function ISIDORO:Parry(player)
    if player:GetPlayerType() ~= ISIDORO.PLAYER_ISIDORO then return end

    local sprite = player:GetSprite()
    local rng = player:GetDropRNG()
    local data = player:GetData()

    if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then
        player:PlayExtraAnimation("TauntFX", true)

        local overlay = Sprite() --this game SUCKS so overlay animations dont work with player sprites so i have to do this instead
        overlay:Load("gfx/characters/isidoro.anm2", true)
        overlay:SetFrame("Taunt", rng:RandomInt(16))
        data.isi_overlay = overlay

        player.ControlsEnabled = false
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ISIDORO.Parry, 0)
