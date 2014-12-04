--print("--- work speed updates ---");


WorkSpeedUpdates = {};

function WorkSpeedUpdates.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations);
end;

function WorkSpeedUpdates:load(xmlFile)
	self.firstRunWorkSpeedUpdates = true;
end;

function WorkSpeedUpdates:delete()
end;

function WorkSpeedUpdates:mouseEvent(posX, posY, isDown, isUp, button)
end;

function WorkSpeedUpdates:keyEvent(unicode, sym, modifier, isDown)
end;

function WorkSpeedUpdates:update(dt)
	if self.firstRunWorkSpeedUpdates then
		self.firstRunWorkSpeedUpdates = false;
		if MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].speedLimit ~= nil then
			self.speedLimit = MrLightUtils.vehicleConfigs[self.configFileName].speedLimit * MrLightUtils.developSpeedFactor;
			--print(string.format("work speed updated, speed: %.1f, configFile: %s",self.speedLimit, self.configFileName));
		end;
	end;
end;

function WorkSpeedUpdates:draw()
end;
