function widget:DrawWorld()
	if spIsGUIHidden() then return end

	glDepthTest(false)

	local unitScale, countdown

	-- draw icon + countodown if there is an active self-d countdown going
	for unitID, unitDefID in pairs(activeSelfD) do
		if (spIsUnitAllied(unitID) or spec) and spIsUnitInView(unitID) then
			if spGetUnitTransporter(unitID) == nil then
				unitScale = unitConf[unitDefID]
				countdown = math.ceil(spGetUnitSelfDTime(unitID) / 2)
				if not drawLists[countdown] then
					drawLists[countdown] = gl.CreateList(DrawIcon, countdown)
				end
				glDrawListAtUnit(unitID, drawLists[countdown], false, unitScale, unitScale, unitScale)
			end
		end
	end

	-- draw just icon if there is a queued self-d command
	for unitID, unitDefID in pairs(queuedSelfD) do
		-- don't draw this if it also has an active countdown
		if activeSelfD[unitID] == nil and (spIsUnitAllied(unitID) or spec) and spIsUnitInView(unitID) then
			if spGetUnitTransporter(unitID) == nil then
				unitScale = unitConf[unitDefID]
				if not drawLists[0] then
					drawLists[0] = gl.CreateList(DrawIcon, 0)
				end
				glDrawListAtUnit(unitID, drawLists[0], true, unitScale, unitScale, unitScale)
			end
		end
	end

	glDepthTest(true)
end
