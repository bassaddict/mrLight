AttachableManipulation = {};

function AttachableManipulation.prerequisitesPresent(specializations)
    return true;
end;

function AttachableManipulation:load(xmlFile)
	self.firstRunAttachableManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		if MrLightUtils.vehicleConfigs[self.configFileName].lowerDistanceToGround ~= nil then
			self.inputAttacherJoints[1].lowerDistanceToGround = MrLightUtils.vehicleConfigs[self.configFileName].lowerDistanceToGround;
		end;
		if MrLightUtils.vehicleConfigs[self.configFileName].upperDistanceToGround ~= nil then
			self.inputAttacherJoints[1].upperDistanceToGround = MrLightUtils.vehicleConfigs[self.configFileName].upperDistanceToGround;
		end;
	end;
	
	self.debugRenderAttachableManipulation = false;
end;

function AttachableManipulation:delete()
end;

function AttachableManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AttachableManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function AttachableManipulation:update(dt)

	--if self.firstRunAttachableManipulation then
	--	self.firstRunAttachableManipulation = false;
	--end;
	
end;

function AttachableManipulation:draw()
	--if self.debugRenderAttachableManipulation then
		--setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		--setTextAlignment(RenderText.ALIGN_LEFT);
	--end;
end;