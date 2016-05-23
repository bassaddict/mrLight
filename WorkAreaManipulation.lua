WorkAreaManipulation = {};

function WorkAreaManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations);
end;

function WorkAreaManipulation:load(xmlFile)

	self.setWorkingWidth = WorkAreaManipulation.setWorkingWidth;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	self.workingWidth = 0;
	local workingWidth = getXMLFloat(xmlFile, "vehicle.workAreas#mrlWidth");
	local minWidth = getXMLFloat(xmlFile, "vehicle.workAreas#mrlMinWidth");
	local maxWidth = getXMLFloat(xmlFile, "vehicle.workAreas#mrlMaxWidth");
	local stepSize = getXMLFloat(xmlFile, "vehicle.workAreas#mrlStepSize");
	
	if workingWidth ~= nil and minWidth ~= nil and maxWidth ~= nil and stepSize ~= nil then
		self.workingWidth = workingWidth;
		self.minWorkingWidth = minWidth;
		self.maxWorkingWidth = maxWidth;
		self.workingWidthStepSize = stepSize;
		
		self:setWorkingWidth(self.workingWidth, self.workingWidthStepSize, "ABSOLUTE");
	end;
	
	local totalCharge = 0;
    local i = 0;
    while true do
        local key = string.format("vehicle.groundReferenceNodes.groundReferenceNode(%d)", i);
        if not hasXMLProperty(xmlFile, key) then
            break;
        end;
		local groundReferenceNode = {threshold = 0, chargeValue = 1};
		local mrlOrigNode = getXMLInt(xmlFile, key.."#mrlOrigNode");
		if mrlOrigNode ~= nil then
			groundReferenceNode = self.groundReferenceNodes[mrlOrigNode];
			--print("used existing refNode");
		end;
		groundReferenceNode.node = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#index")), groundReferenceNode.node);
		groundReferenceNode.threshold = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#threshold"), groundReferenceNode.threshold);
		groundReferenceNode.chargeValue = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#chargeValue"), groundReferenceNode.chargeValue);
		groundReferenceNode.normalizeChargeValue = Utils.getNoNil(getXMLBool(xmlFile, key .. "#mrlNormalizeChargeValue"), true);
        totalCharge = totalCharge + groundReferenceNode.chargeValue;
		
		if mrlOrigNode == nil then
			table.insert(self.groundReferenceNodes, groundReferenceNode);
			--print("added new refNode");
		end;
        i = i + 1;
    end;
	
	-- normalize chargeValues
    for _, refNode in pairs(self.groundReferenceNodes) do
		if refNode.normalizeChargeValue then
			refNode.chargeValue = refNode.chargeValue / totalCharge;
		end;
    end;
	
	local i = 0;
	while true do
        local key = string.format("vehicle.workAreas.workArea(%d)", i);
        if not hasXMLProperty(xmlFile, key) then
            break;
        end;
		local mrlOrigArea = getXMLInt(xmlFile, key.."#mrlOrigArea");
		if mrlOrigArea == nil then
			break;
		end;
		local workArea = self.workAreas[mrlOrigArea];
		
        local refNodeIndex = getXMLInt(xmlFile, key .."#refNodeIndex");
        if refNodeIndex ~= nil then
            if self.groundReferenceNodes[refNodeIndex+1] ~= nil then
                workArea.refNode = self.groundReferenceNodes[refNodeIndex+1];
            else
                print("Warning: Invalid GroundReferenceNode '"..refNodeIndex.."' ("..key..")! Indexing starts with 0");
            end;
        else
            if table.getn(self.groundReferenceNodes) == 1 then
                workArea.refNode = self.groundReferenceNodes[1];
            end;
        end;

        local areaTypeStr = getXMLString(xmlFile, key .."#type");
        if areaTypeStr == nil then
            workArea.type = WorkArea.AREATYPE_DEFAULT;
        else
            local areaType = WorkArea.areaTypeNameToInt[areaTypeStr];
            assert(areaType ~= nil, "Invalid workarea-type '"..areaTypeStr.."' ("..key..")");
            workArea.type = areaType;
        end;

        workArea.disableBackwards = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disableBackwards"), true);
		
		
		local startPos = Utils.getVectorNFromString(getXMLString(xmlFile, key.."#mrlStartPos"), 3);
		local widthPos = Utils.getVectorNFromString(getXMLString(xmlFile, key.."#mrlWidthPos"), 3);
		local heightPos = Utils.getVectorNFromString(getXMLString(xmlFile, key.."#mrlHeightPos"), 3);
		
		if startPos ~= nil then
			setTranslation(workArea.start, startPos[1], startPos[2], startPos[3]);
		end;
		if widthPos ~= nil then
			setTranslation(workArea.width, widthPos[1], widthPos[2], widthPos[3]);
		end;
		if heightPos ~= nil then
			setTranslation(workArea.height, heightPos[1], heightPos[2], heightPos[3]);
		end;
		
        i = i + 1;
    end;
	
	
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
	
	self.debugRenderWorkAreaManipulation = true;
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
	return BaseMission.VEHICLE_LOAD_OK;
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
end;

function WorkAreaManipulation:setWorkingWidth(currentWidth, step, action)
	--print("currentWidth: "..currentWidth..", step: "..step);
	local sx,sy,sz = getTranslation(self.workAreas[1].start);
	local wx,wy,wz = getTranslation(self.workAreas[1].width);
	local hx,hy,hz = getTranslation(self.workAreas[1].height);
	
	local doIncr = false;
	local doDecr = false;
	local actualStep = step;
	local actualWidth = currentWidth;
	if action == "ABSOLUTE" then
		--print("absolute -> start: "..self.workAreas[1].start..", width: "..self.workAreas[1].width..", height: "..self.workAreas[1].height);
		actualWidth = MrLightUtils.getWorkingWidth(self.workAreas, self.rootNode);
		actualStep = currentWidth-actualWidth;
		if actualStep < 0 then
			doDecr = true;
		else
			doIncr = true;
		end;
		actualStep = math.abs(actualStep);
	end;
	
	--print("actualWidth: "..actualWidth..", actualStep: "..actualStep);
	
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
	--print("factor: "..factor);
	setTranslation(self.workAreas[1].start, sx * factor, sy, sz);
	setTranslation(self.workAreas[1].width, wx * factor, wy, wz);
	setTranslation(self.workAreas[1].height, hx * factor, hy, hz);
end;

