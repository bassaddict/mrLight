FillableManipulation = {};

function FillableManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Fillable, specializations);
end;

function FillableManipulation:load(xmlFile)
	self.firstRunFillableManipulation = true;
	
	for part in string.gfind(self.configFileName, "/%w+") do
		self.configFileNameClean = string.sub(part, 2);
		--[[print(" --> part: "..part);
		local no, _ = string.find(part, ".", 1, true)
		if no ~= nil then
			print(" --> no: "..no);
			self.configFileNameClean = string.sub(part, 2, no-1);
			print(self.configFileNameClean);
			break;
		end;]]
	end;
	--print(self.configFileNameClean);
	
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].capacities ~= nil then
		self.myCapacities = Utils.getNoNil(getXMLString(xmlFile, "vehicle.capacities"), {});
		self.myCapacities = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].capacities);
	
		if #self.myCapacities == 0 then
			self.myCapacities[1] = self.capacity;
		end;
		self.fillVolumesInfo = {}
		for k=1, MrLightUtils.numFillableClasses do
			local capacity = 0;
			if self.myCapacities[k] ~= nil and self.myCapacities[k] ~= 0 and self.myCapacities[k] ~= "0" then
				capacity = tonumber(self.myCapacities[k]);
			end;
			local node;
			if self.configFileNameClean ~= nil then
				local path = MrLightUtils.modDir.."fillVolumes/"..self.configFileNameClean.."_"..k..".i3d";
				print(" --> path: "..path);
				if fileExists(path) then
					local i3dNode = Utils.loadSharedI3DFile(path, "", true, true);
					local linkNode = Utils.indexToObject(self.components, MrLightUtils.vehicleConfigs[self.configFileName].fillVolumesNode);
					
					local numChilds = getNumOfChildren(linkNode);
					local x,y,z = getTranslation(getChildAt(linkNode,0));
					local volumeNode = getChildAt(i3dNode,0);
					setTranslation(volumeNode, x,y,z);
					
					link(linkNode, volumeNode);
					delete(i3dNode);
					
					node = volumeNode;
					
					--print(" --> node: "..node);
				end;
			end;
			if node == nil and #self.fillVolumes ~= 0 then
				node = self.fillVolumes[1].baseNode;
			end;
			print(" --> node: "..node);
			self.fillVolumesInfo[k] = {capacity = capacity, baseNode = node};
			
		end;
	end;
	
	self.lastCurrentFillType = -1;
	
	self.debugRenderFillableManipulation = false;
end;

function FillableManipulation:delete()
end;

function FillableManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function FillableManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function FillableManipulation:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
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

function FillableManipulation:getSaveAttributesAndNodes(nodeIdent)

end;

function FillableManipulation:update(dt)

	if self.lastCurrentFillType ~= self.currentFillType and self.fillVolumesInfo~= nil and #self.fillVolumes ~= 0 then
		
		local fillableClass;
		if Fillable.fillTypeIndexToDesc[self.currentFillType] ~= nil then
			fillableClass = Fillable.fillTypeIndexToDesc[self.currentFillType].fillableClass;
		end;
		if fillableClass == nil then
			fillableClass = MrLightUtils.FILLABLE_CLASS_UNKNOWN;
		end;
		
		self:setCapacity(self.fillVolumesInfo[fillableClass].capacity);
		local volume;
		local baseNode;
		-- start
		-- code by Stefan Geiger, deleting old fillVolume and creating a new one to fit the new capacity
		for _, fillVolume in pairs(self.fillVolumes) do
			if fillVolume.volume ~= nil then
				delete(fillVolume.volume);
				local maxPhysicalSurfaceAngle = math.rad(35);
				fillVolume.baseNode = self.fillVolumesInfo[fillableClass].baseNode;
				fillVolume.maxDelta = 0.5;
				fillVolume.volume = createFillPlaneShape(fillVolume.baseNode, "fillPlane", self.capacity, fillVolume.maxDelta, fillVolume.maxSurfaceAngle, maxPhysicalSurfaceAngle, fillVolume.maxSubDivEdgeLength, fillVolume.allSidePlanes);
				link(fillVolume.baseNode, fillVolume.volume);
				baseNode = fillVolume.baseNode;
				volume = fillVolume.volume;
			end;
		end;
		for _,v in pairs(self.fillVolumeDeformers) do
			if volume ~= nil and baseNode ~= nil then
				v.baseNode = baseNode;
				v.volume = volume;
			end;
		end;
		
		local fillLevel = self.fillLevel;
		local fillType = self.currentFillType;
		self:setFillLevel(0, fillType, true);
		self:setFillLevel(fillLevel, fillType, true);
		-- end
		
		if self.actualFillLevel ~= nil and self.actualFillType ~= nil then
			local fillTypeInt = Fillable.fillTypeNameToInt[self.actualFillType];
			if fillTypeInt ~= nil then
				self:setFillLevel(self.actualFillLevel, fillTypeInt);
			end;
			self.actualFillLevel = nil;
			self.actualFillType = nil;
		end;
		self.lastCurrentFillType = self.currentFillType;
	end;
	
end;

function FillableManipulation:draw()
	if self.debugRenderFillableManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;