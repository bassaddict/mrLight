TrailerManipulation = {};

function TrailerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Trailer, specializations);
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
		
		if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].capacity ~= nil then
			MrLightUtils.vehicleConfigs[self.configFileName].oldCapacity = self.capacity;
			--print("set cap");
			self:setCapacity(MrLightUtils.vehicleConfigs[self.configFileName].capacity);
			if self.capacity == MrLightUtils.vehicleConfigs[self.configFileName].oldCapacity then
				--print("set cap fix");
				self.capacity = MrLightUtils.vehicleConfigs[self.configFileName].capacity;
			end;
		end;
	
		-- start
		-- code by Stefan Geiger, deleting old fillVolume and creating a new one to fit the new capacity
		for _, fillVolume in pairs(self.fillVolumes) do
			if fillVolume.volume ~= nil then
				delete(fillVolume.volume)
				local maxPhysicalSurfaceAngle = math.rad(35);
				fillVolume.volume = createFillPlaneShape(fillVolume.baseNode, "fillPlane", self.capacity, fillVolume.maxDelta, fillVolume.maxSurfaceAngle, maxPhysicalSurfaceAngle, fillVolume.maxSubDivEdgeLength, fillVolume.allSidePlanes);
				link(fillVolume.baseNode, fillVolume.volume);
			end
		end
		local fillLevel = self.fillLevel;
		local fillType = self.currentFillType;
		self:setFillLevel(0, fillType, true)
		self:setFillLevel(fillLevel, fillType, true)
		-- end
		
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