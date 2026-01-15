-- UIState.lua
local UIState = {}

UIState.STATES = {
    BOOT = "BOOT",
    CHOOSE_PATH = "CHOOSE_PATH",
    GUILD_PICK = "GUILD_PICK",
    TUTORIAL_MOVEMENT = "TUTORIAL_MOVEMENT",
    TUTORIAL_COMBAT = "TUTORIAL_COMBAT",
    CITY = "CITY",
}

-- Simple helper: is state in list
function UIState.Is(state, a)
    return state == a
end

return UIState
