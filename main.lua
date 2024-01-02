Isidoro = RegisterMod("Isidoro", 1)
local Mod = Isidoro

if not REPENTOGON then

    function Mod:RenderErrorText(player)
        if player:GetPlayerType() == Isaac.GetPlayerTypeByName("Isidoro") then

            Isaac.RenderText("[ISIDORO] THIS MOD REQUIRES REPENTOGON!", 100, 100 , 1, 0, 0, 1)
            Isaac.RenderText("REPENTOGON IS EITHER NOT INSTALLED", 100, 110, 1, 0, 0, 1)
            Isaac.RenderText("OR NOT INSTALLED CORRECTLY", 100, 120, 1, 0, 0, 1)
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Mod.RenderErrorText, 0)

    return
end

Mod.Scheduler = include("scripts/core/schedule_data")
include("scripts/core/enums")
include("scripts/core/util")
include("scripts/isidoro")