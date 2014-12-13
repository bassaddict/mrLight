TrailerManipulation = {};

function TrailerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Fillable, specializations);
end;

function TrailerManipulation:load(xmlFile)
	self.firstRunTrailerManipulation = true;
	
	
	self.debugRenderTrailerManipulation = false;
end;

function TrailerManipulation:delete()
end;

function TrailerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function TrailerManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function TrailerManipulation:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
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

function TrailerManipulation:getSaveAttributesAndNodes(nodeIdent)

end;

function TrailerManipulation:update(dt)

	if self.firstRunTrailerManipulation then
		self.firstRunTrailerManipulation = false;
		
		if MrLightUtils ~= nil and MrLightUtils.trailers[self.configFileName] ~= nil then
			MrLightUtils.trailers[self.configFileName].oldCapacity = self.capacity;
			--print("set cap");
			self:setCapacity(MrLightUtils.trailers[self.configFileName].newCapacity);
			if self.capacity == MrLightUtils.trailers[self.configFileName].oldCapacity then
				--print("set cap fix");
				self.capacity = MrLightUtils.trailers[self.configFileName].newCapacity;
			end;
		end;
	
		--self:updateMeasurementNode();
		
		if self.actualFillLevel ~= nil and self.actualFillType ~= nil then
			local fillTypeInt = Fillable.fillTypeNameToInt[self.actualFillType];
			if fillTypeInt ~= nil then
				self:setFillLevel(self.actualFillLevel, fillTypeInt);
			end;
		end;
	end;
	
end;

function TrailerManipulation:draw()
	if self.debugRenderTrailerManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;