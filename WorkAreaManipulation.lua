WorkAreaManipulation = {};

function WorkAreaManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations);
end;

function WorkAreaManipulation:load(xmlFile)

	self.setWorkingWidth = WorkAreaManipulation.setWorkingWidth;
	
	self.workingWidth = 0;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].workingWidths ~= nil then
		local wwT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].workingWidths);
		if #wwT == 4 then
			self.workingWidth = wwT[1];
			self.minWorkingWidth = wwT[2];
			self.maxWorkingWidth = wwT[3];
			self.workingWidthStepSize = wwT[4];
			
			self:setWorkingWidth(self.workingWidth, self.workingWidthStepSize, "ABSOLUTE");
		end;
	end;
	
	self.debugRenderWorkAreaManipulation = false;
end;

function WorkAreaManipulation:delete()
end;

function WorkAreaManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function WorkAreaManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function WorkAreaManipulation:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	if self.workingWidth ~= 0 then
		self.workingWidth = Utils.getNoNil(getXMLFloat(xmlFile, key.."#currentWorkingWidth"), self.workingWidth);
		self:setWorkingWidth(self.workingWidth, self.workingWidthStepSize, "ABSOLUTE");
	end;
end;

function WorkAreaManipulation:getSaveAttributesAndNodes(nodeIdent)
	local attributes = 'currentWorkingWidth="'..self.workingWidth..'"';
	return attributes, nil;
end;

function WorkAreaManipulation:update(dt)
	if self:getIsActiveForInput() and self.workingWidth ~= 0 then
		if InputBinding.hasEvent(InputBinding.WWPLUS) then
			self:setWorkingWidth(self.workingWidth, self.workingWidthStepSize, "INCREASE");
		elseif InputBinding.hasEvent(InputBinding.WWMINUS) then
			self:setWorkingWidth(self.workingWidth, self.workingWidthStepSize, "DECREASE");
		end;
	end;
end;

function WorkAreaManipulation:draw()
	if self.debugRenderWorkAreaManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, lastFillLevel: %.4f, currentSeed: %d, isFilling: %s", self.fillLevel, self.myLastFillLevel, self.currentSeed, tostring(self.isFilling)));
		--renderText(0.99, 0.78, 0.018, string.format("fillDelta: %.4f",self.deltaFill));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;

function WorkAreaManipulation:setWorkingWidth(currentWidth, step, action)
	print("currentWidth: "..currentWidth..", step: "..step);
	local sx,sy,sz = getTranslation(self.workAreas[1].start);
	local wx,wy,wz = getTranslation(self.workAreas[1].width);
	local hx,hy,hz = getTranslation(self.workAreas[1].height);
	
	local doIncr = false;
	local doDecr = false;
	local actualStep = step;
	local actualWidth = currentWidth;
	if action == "ABSOLUTE" then
		print("absolute -> start: "..self.workAreas[1].start..", width: "..self.workAreas[1].width..", height: "..self.workAreas[1].height);
		actualWidth = MrLightUtils.getWorkingWidth(self.workAreas, self.rootNode);
		actualStep = currentWidth-actualWidth;
		if actualStep < 0 then
			doDecr = true;
		else
			doIncr = true;
		end;
		actualStep = math.abs(actualStep);
	end;
	
	print("actualWidth: "..actualWidth..", actualStep: "..actualStep);
	
	local factor = 1;
	if action == "INCREASE" or doIncr then
		if (actualWidth + actualStep) < (self.maxWorkingWidth + 0.01) then
			factor = 1 + (actualStep / actualWidth);
			self.workingWidth = actualWidth + actualStep;
		end;
	elseif action == "DECREASE" or doDecr then
		if (actualWidth - actualStep) > (self.minWorkingWidth - 0.01) then
			factor = 1 - (actualStep / actualWidth);
			self.workingWidth = actualWidth - actualStep;
		end;
	end;
	print("factor: "..factor);
	setTranslation(self.workAreas[1].start, sx * factor, sy, sz);
	setTranslation(self.workAreas[1].width, wx * factor, wy, wz);
	setTranslation(self.workAreas[1].height, hx * factor, hy, hz);
end;

