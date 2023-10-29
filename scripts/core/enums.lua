local Mod = Isidoro
Mod.ENUMS = {}
local ENUMS = Mod.ENUMS

ENUMS.SFX = {
    TAUNT = Isaac.GetSoundIdByName("Isidoro Taunt"),
    PARRY = Isaac.GetSoundIdByName("Isidoro Parry"),
    GRABDASH = Isaac.GetSoundIdByName("Isidoro Grab Dash"),
    PUNCH = Isaac.GetSoundIdByName("Isidoro Punch"),
    PILEDRIVER_START = Isaac.GetSoundIdByName("Isidoro Piledriver Start"),
    PILEDRIVER_SLAM = Isaac.GetSoundIdByName("Isidoro Piledriver Slam"),
}

ENUMS.PLAYERS = {
    ISIDORO = Isaac.GetPlayerTypeByName("Isidoro", false),
}