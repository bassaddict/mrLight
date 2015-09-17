BalerManipulation = {};

function BalerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Baler, specializations);
end;

function BalerManipulation:load(xmlFile)	
	self.firstRunBalerManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	self.mrlCompactingFactor = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.mrlCompactingFactor#value"), 3);
	
	self.lastFillType = Fillable.FILLTYPE_UNKNOWN;
	
	self.debugRenderBalerManipulation = false;
end;

function BalerManipulation:delete()
end;

function BalerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BalerManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function BalerManipulation:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	return BaseMission.VEHICLE_LOAD_OK;
end;

function BalerManipulation:getSaveAttributesAndNodes(nodeIdent)
	
end;

function BalerManipulation:update(dt)

	if self.firstRunBalerManipulation then
		self.firstRunBalerManipulation = false;
		--self.lastFillType = Fillable.FILLTYPE_UNKNOWN;
	end;

	if (self.lastFillType ~= self.currentFillType and self.currentFillType ~= Fillable.FILLTYPE_UNKNOWN) then
		local bale = self.baleTypes[1];
		if bale.isRoundBale then
			local capacity = math.pi * (bale.diameter / 2)^2 * bale.width * 1000 * self.mrlCompactingFactor; --round bale, compacting factor 3, about 120kg per m3 for straw
			self:setCapacity(capacity);
			--print(" --> "..tostring(self.configFileName) .. " " .. tostring(Fillable.fillTypeIndexToDesc[self.currentFillType].massPerLiter));
		else
			local capacity = bale.width * bale.length * bale.height * 1000 * self.mrlCompactingFactor; --square bale, compacting factor 4.5, about 180kg per m3 for straw
			self:setCapacity(capacity);
		end;
		--print("capacity updated: " .. tostring(self.capacity));
	end;
	
	self.lastFillType = self.currentFillType;
end;

function BalerManipulation:draw()
	if self.debugRenderBalerManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.2f, capacity: %.2f, diam: %.2f, width: %.2f, height: %.2f, length: %.2f", Utils.getNoNil(self.fillLevel,0), self.capacity, self.baleTypes[1].diameter, self.baleTypes[1].width, self.baleTypes[1].height, self.baleTypes[1].length));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;
