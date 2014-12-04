BalerManipulation = {};

function BalerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Baler, specializations);
end;

function BalerManipulation:load(xmlFile)	
	self.firstRun = true;
	self.secondRun = false;
	self.forceCapacityUpdate = false;
	self.lastFillType = Fillable.FILLTYPE_UNKNOWN;
	
	
	self.debugRender = false;
end;

function BalerManipulation:delete()
end;

function BalerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BalerManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function BalerManipulation:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local actualFillLevel = getXMLFloat(xmlFile, key.."#fillLevel");
	local actualFillType = getXMLString(xmlFile, key.."#fillType");
	
	if actualFillLevel ~= nil then
		self.actualFillLevel = actualFillLevel
	end;
	if actualFillType ~= nil then
		self.actualFillType = actualFillType;
	end;
	return BaseMission.VEHICLE_LOAD_OK;
end;

function BalerManipulation:getSaveAttributesAndNodes(nodeIdent)

end;

function BalerManipulation:update(dt)

	if self.secondRun then
		self.secondRun = false;
		self.forceCapacityUpdate = true;
	end;
	if self.firstRun then
		self.firstRun = false;
		self.secondRun = true;
	end;

	if (self.lastFillType ~= self.currentFillType and self.currentFillType ~= Fillable.FILLTYPE_UNKNOWN) or (self.forceCapacityUpdate and self.currentFillType ~= Fillable.FILLTYPE_UNKNOWN) then
		local bale = self.baleTypes[1];
		if bale.isRoundBale then
			local capacity = math.pi * (bale.diameter / 2)^2 * bale.width * 3000; --round bale, compacting factor 3, about 120kg per m3 for straw
			self:setCapacity(capacity);
			--print(" --> "..tostring(self.configFileName) .. " " .. tostring(Fillable.fillTypeIndexToDesc[self.currentFillType].massPerLiter));
		else
			local capacity = bale.width * bale.length * bale.height * 5500; --square bale, compacting factor 5.5, about 220kg per m3 for straw
			self:setCapacity(capacity);
		end;
		--print("capacity updated: " .. tostring(self.capacity));
	end;
	
	if self.forceCapacityUpdate then
		if self.actualFillLevel ~= nil and self.actualFillType ~= nil then
			local fillTypeInt = Fillable.fillTypeNameToInt[self.actualFillType];
			if fillTypeInt ~= nil then
				self:setFillLevel(self.actualFillLevel, fillTypeInt);
				--print("<-fillLevel fixed, fillLevel: " .. tostring(self.actualFillLevel) .. ", fillType: " .. tostring(self.actualFillType));
				--print("->fillLevel fixed, fillLevel: " .. tostring(self.fillLevel) .. ", fillType: " .. tostring(fillTypeIndexToDesc[self.currentFillType].name));
			end;
		end;
	end;
	
	self.forceCapacityUpdate = false;
	self.lastFillType = self.currentFillType;
end;

function BalerManipulation:draw()
	if self.debugRender then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.2f, capacity: %.2f, diam: %.2f, width: %.2f, height: %.2f, length: %.2f", Utils.getNoNil(self.fillLevel,0), self.capacity, self.baleTypes[1].diameter, self.baleTypes[1].width, self.baleTypes[1].height, self.baleTypes[1].length));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;
