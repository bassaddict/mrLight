FillableManipulation = {};

function FillableManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Fillable, specializations);
end;

function FillableManipulation:load(xmlFile)
	self.firstRunFillableManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	self:setCapacity(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.capacity"), self.capacity));
	
	
	
	
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
	
	
	if self.fillTypes == nil then
		self.fillTypes = {};
		self.fillTypes[Fillable.FILLTYPE_UNKNOWN] = true;
	end;
	
    local fillTypes = getXMLString(xmlFile, "vehicle.fillTypes#fillTypes");
    if fillTypes ~= nil then
        local types = Utils.splitString(" ", fillTypes);
        for k,v in pairs(types) do
            local fillType = Fillable.fillTypeNameToInt[v];
            if fillType ~= nil then
                self.fillTypes[fillType] = true;
            else
                print("Warning: '"..self.configFileName.. "' has invalid fillType '"..v.."'.");
            end;
        end;
    end;
	local fruitTypes = getXMLString(xmlFile, "vehicle.fillTypes#fruitTypes");
    if fruitTypes ~= nil then
        local types = Utils.splitString(" ", fruitTypes);
        for k,v in pairs(types) do
            local fillType = Fillable.fillTypeNameToInt[v];
            if fillType ~= nil then
                self.fillTypes[fillType] = true;
            else
                print("Warning: '"..self.configFileName.. "' has invalid fillType '"..v.."'.");
            end;
        end;
    end;
	
	
	local key = "vehicle.mrlFillVolumes";
	if hasXMLProperty(xmlFile, key) then
		self.fillVolumesInfo = {}
		local i3dNode;
		local linkNode;
		local x,y,z;
		
		local baseFillVolumeNode = getXMLString(xmlFile, "vehicle.mrlFillVolumes#mrlBaseFillVolumeNode");
		local additionalFillVolumes = getXMLString(xmlFile, "vehicle.mrlFillVolumes#mrlAdditionalFillVolumes");
		local path;
		if additionalFillVolumes ~= nil then
			path = MrLightUtils.modDir..additionalFillVolumes;
			if fileExists(path) then
				i3dNode = Utils.loadSharedI3DFile(path, "", true, true);
				linkNode = Utils.indexToObject(self.components, baseFillVolumeNode);
				x,y,z = getTranslation(getChildAt(linkNode,0));
			end;
		end;

		local prerequisitesMet = (i3dNode ~= nil and linkNode ~= nil and x ~= nil and y ~= nil and z ~= nil);
		
		local node;
		local i = 0;
		while true do
			local key = string.format("vehicle.mrlFillVolumes.mrlFillVolume(%d)", i);
			if not hasXMLProperty(xmlFile, key) then
				break;
			end;
			local fillableClass = Utils.getNoNil(getXMLString(xmlFile, key.."#mrlClass"), "FILLABLE_CLASS_UNKNOWN");
			local capacity = Utils.getNoNil(getXMLFloat(xmlFile, key.."#mrlCapacity"), 0.0);
			local useOrigVolume = getXMLInt(xmlFile, key.."#mrlUseOrigVolume");
			local compressedCapacity = Utils.getNoNil(getXMLFloat(xmlFile, key.."#mrlCompressedCapacity"), capacity);
			local i3dNodeVolume = getXMLInt(xmlFile, key.."#mrlI3dNode");
			local maxDelta = Utils.getNoNil(getXMLFloat(xmlFile, key.."#mrlMaxDelta"), 1.0);
			
			if not useOrigVolume and i3dNodeVolume ~= nil and prerequisitesMet then
				local volumeNode = getChildAt(i3dNode,i3dNodeVolume);
				setTranslation(volumeNode, x,y,z);
				link(linkNode, volumeNode);
				node = volumeNode;
			else
				if #self.fillVolumes > 0 then
					node = self.fillVolumes[1].baseNode;
				end;
			end;
			
			local classIndex = MrLightUtils[fillableClass];
			self.fillVolumesInfo[classIndex] = {capacity = capacity, baseNode = node, maxDelta = maxDelta, compressedCapacity = compressedCapacity};
			self.compressedCapacity = compressedCapacity;
			
			i = i + 1;
		end;
		if i3dNode ~= nil then
			delete(i3dNode);
		end;
		
		
		for k=1, MrLightUtils.numFillableClasses do
			if self.fillVolumesInfo[k] == nil then
				local node;
				if #self.fillVolumes > 0 then
					node = self.fillVolumes[1].baseNode;
				end;
				self.fillVolumesInfo[k] = {capacity = 0, baseNode = node, maxDelta = 1.0, compressedCapacity = 0};
			end;
		end;

	end;
	
	
	
	
	
	
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].capacities ~= nil then
		--self.capacities = Utils.getNoNil(getXMLString(xmlFile, "vehicle.capacities"), {});
		self.capacities = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].capacities);
		self.compressedCapacity = MrLightUtils.vehicleConfigs[self.configFileName].compressedCapacity;
	
		if #self.capacities == 0 then
			self.capacities[1] = self.capacity;
		end;
		self.fillVolumesInfo = {}
		for k=1, MrLightUtils.numFillableClasses do
			local capacity = 0;
			if self.capacities[k] ~= nil and self.capacities[k] ~= 0 and self.capacities[k] ~= "0" then
				capacity = tonumber(self.capacities[k]);
			end;
			local node;
			if self.configFileNameClean ~= nil then
				local path = MrLightUtils.modDir.."fillVolumes/"..self.configFileNameClean.."_"..k..".i3d";
				--print(" --> path: "..path);
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
			if node == nil and #self.fillVolumes > 0 then
				node = self.fillVolumes[1].baseNode;
			end;
			--print(" --> node: "..node);
			self.fillVolumesInfo[k] = {capacity = capacity, baseNode = node, maxDelta = 1.0, compressedCapacity = self.compressedCapacity};
			
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
	local currentCapacity = getXMLFloat(xmlFile, key.."#currentCapacity");
	local actualFillLevel = getXMLFloat(xmlFile, key.."#fillLevel");
	local actualFillType = getXMLString(xmlFile, key.."#fillType");
	
	if currentCapacity ~= nil then
		self:setCapacity(currentCapacity);
	end;
	if actualFillLevel ~= nil then
		self.actualFillLevel = actualFillLevel
	end;
	if actualFillType ~= nil then
		self.actualFillType = actualFillType;
	end;
	return BaseMission.VEHICLE_LOAD_OK;
end;

function FillableManipulation:getSaveAttributesAndNodes(nodeIdent)
	local attributes = 'currentCapacity="'..self.capacity..'"';
	return attributes, nil;
end;

function FillableManipulation:update(dt)

	if self.actualFillLevel ~= nil and self.actualFillType ~= nil then
		local fillTypeInt = Fillable.fillTypeNameToInt[self.actualFillType];
		if fillTypeInt ~= nil then
			self:setFillLevel(self.actualFillLevel, fillTypeInt);
		end;
		self.actualFillLevel = nil;
		self.actualFillType = nil;
		--print(self.configFileNameClean);
	end;
	
	if not self.firstRunFillableManipulation and self.lastCurrentFillType ~= self.currentFillType and self.fillVolumesInfo~= nil and #self.fillVolumes > 0 then
		--print(self.configFileNameClean);
		local fillableClass;
		--print(self.currentFillType);
		if Fillable.fillTypeIndexToDesc[self.currentFillType] ~= nil then
			fillableClass = Fillable.fillTypeIndexToDesc[self.currentFillType].fillableClass;
		end;
		if fillableClass == nil then
			--print("fillableClass UNKNOWN");
			fillableClass = MrLightUtils.FILLABLE_CLASS_UNKNOWN;
		end;
		
		self:setCapacity(self.fillVolumesInfo[fillableClass].capacity);
		if Fillable.fillTypeIndexToDesc[self.currentFillType] ~= nil then--if self.isTurnedOn then
			if string.find(Fillable.fillTypeIndexToDesc[self.currentFillType].name, "_windrow") then
				self:setCapacity(self.fillVolumesInfo[fillableClass].compressedCapacity);
			end;
		end;
		
		local volume;
		local baseNode;
		-- start
		-- code by Stefan Geiger, deleting old fillVolume and creating a new one to fit the new capacity
		for _, fillVolume in pairs(self.fillVolumes) do
			if fillVolume.volume ~= nil then
				delete(fillVolume.volume);
				local maxPhysicalSurfaceAngle = math.rad(35);
				fillVolume.baseNode = self.fillVolumesInfo[fillableClass].baseNode;
				fillVolume.maxDelta = self.fillVolumesInfo[fillableClass].maxDelta;
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
		
		self.lastCurrentFillType = self.currentFillType;
	end;
	
	if self.firstRunFillableManipulation then 
		self.firstRunFillableManipulation = false;
	end;
end;

function FillableManipulation:draw()
	if self.debugRenderFillableManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;