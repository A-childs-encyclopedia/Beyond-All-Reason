function widget:GetInfo()
	return {
		name	= "Camera Minimum Height",
		desc	= "Prevents you from zooming all the way to the ground, all the way to desired level - configurable in settings",
		author	= "Damgam",
		date	= "2022",
		license = "GNU GPL, v2 or later",
		layer	= -3,
		enabled	= true,
	}
end

local desiredLevel = Spring.GetConfigInt("MinimumCameraHeight", 350)
local optionRefresh = 0

function widget:Update()
    local camstate = Spring.GetCameraState()
    if (camstate.name == "ta" and camstate.height < desiredLevel) then
        camstate.height = desiredLevel
        Spring.SetCameraState(camstate, Spring.GetConfigFloat("CameraTransitionTime", 0))
    elseif (camstate.name == "spring" and camstate.dist < desiredLevel) then
        camstate.dist = desiredLevel
        Spring.SetCameraState(camstate, Spring.GetConfigFloat("CameraTransitionTime", 0))
    end

    optionRefresh = optionRefresh+1
    if optionRefresh > 30 then
        optionRefresh = 0
        desiredLevel = Spring.GetConfigInt("MinimumCameraHeight", 0)
    end
end
