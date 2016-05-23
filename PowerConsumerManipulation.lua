PowerConsumerManipulation = {};

function PowerConsumerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PowerConsumer, specializations);
end;

function PowerConsumerManipulation:load(xmlFile)
	self.collectForce = false;
	self.collectPtoPower = false;
	self.collected = false;
	self.collectedInput = "";
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	if self.powerConsumer == nil then
		self.powerConsumer = {};
	end;
	
	self.powerConsumer.forceNode = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.powerConsumer#forceNode")), self.powerConsumer.forceNode);
	self.powerConsumer.forceDirNode = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.powerConsumer#forceDirNode")), Utils.getNoNil(self.powerConsumer.forceDirNode, self.powerConsumer.forceNode));
	
	self.powerConsumer.maxForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#maxForce"), self.powerConsumer.maxForce); -- kN
	self.powerConsumer.forceDir = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#forceDir"), self.powerConsumer.forceDir);
	self.powerConsumer.neededPtoPower = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#neededPtoPower"), self.powerConsumer.neededPtoPower); -- in kW at ptoRpm
	self.powerConsumer.ptoRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#ptoRpm"), self.powerConsumer.ptoRpm);
	
	self.powerConsumer.mrlBaseForce = getXMLFloat(xmlFile, "vehicle.powerConsumer#mrlBaseForce"); -- kN
	self.powerConsumer.mrlBaseForceFactor = getXMLFloat(xmlFile, "vehicle.powerConsumer#mrlBaseForceFactor");
	
	
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		if MrLightUtils.vehicleConfigs[self.configFileName].maxForce ~= nil then
			self.powerConsumer.forceNode = Utils.indexToObject(self.components, Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].forceNode, "0>"));
			self.powerConsumer.forceDirNode = Utils.indexToObject(self.components, Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].forceDirNode, "0>"));
		end;
		self.powerConsumer.ptoRpm = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].ptoRpm, self.powerConsumer.ptoRpm);
		self.powerConsumer.neededPtoPower = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].neededPtoPower, self.powerConsumer.neededPtoPower);
		self.powerConsumer.maxForce = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].maxForce, self.powerConsumer.maxForce);
		
		if MrLightUtils.vehicleConfigs[self.configFileName].groundReferenceNodes ~= nil then
			local refNodesInfoT = Utils.splitString(";", MrLightUtils.vehicleConfigs[self.configFileName].groundReferenceNodes);
			self.groundReferenceNodes = {};
			for _,refNodeInfo in pairs(refNodesInfoT) do
				local refNodeT = Utils.splitString(",", refNodeInfo);
				local refNodeIndex;
				local threshold;
				local workArea;
				if refNodeT[1] == "+" then
					refNodeIndex = createTransformGroup("refNodeIndex");
					link(Utils.indexToObject(self.components, refNodeT[2]), refNodeIndex);
					setTranslation(refNodeIndex, Utils.getVectorFromString(refNodeT[3]));
					threshold = tonumber(refNodeT[4]);
					workArea = tonumber(refNodeT[5]);
				else
					refNodeIndex = Utils.indexToObject(self.components, refNodeT[1]);
					threshold = tonumber(refNodeT[2]);
					workArea = tonumber(refNodeT[3]);
				end;
				table.insert(self.groundReferenceNodes, {node=refNodeIndex, threshold=threshold, isActive=true, chargeValue=(1/#refNodesInfoT)});
				if workArea > 0 then
					self.workAreas[workArea].refNode = self.groundReferenceNodes[#self.groundReferenceNodes];
				end;
			end;
			
			self.powerConsumer.forceNode = Utils.indexToObject(self.components, Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].forceNode, "0>"));
			self.powerConsumer.forceDirNode = Utils.indexToObject(self.components, Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].forceDirNode, "0>"));
		end;
	end;
	
	self.debugRenderPowerConsumerManipulation = false;
end;

function PowerConsumerManipulation:delete()
end;

function PowerConsumerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function PowerConsumerManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function PowerConsumerManipulation:update(dt)
end;

function PowerConsumerManipulation:draw()
end;





function PowerConsumer:update(dt)
    if self:getIsActive() and self.isServer then
        if self.powerConsumer.forceNode ~= nil and self.movingDirection == self.powerConsumer.forceDir then
            local multiplier = self:getPowerMultiplier();
            if multiplier ~= 0 then
			
				local force = 0;
				local frictionForce = self.lastSpeedReal * 1000 * getMass(self.powerConsumer.forceDirNode) / (dt/1000);
				local px,py,pz = getCenterOfMass(self.powerConsumer.forceNode);
				local str = "";
				
				if self.powerConsumer.mrlBaseForce ~= nil then
					local baseForceFactor = Utils.getNoNil(self.powerConsumer.mrlBaseForceFactor, 1);
					local lastSpeed = self.lastSpeedReal * 1000;
					force = -(self.powerConsumer.mrlBaseForce * baseForceFactor * (1 + 0.01 * lastSpeed^2)) * self.movingDirection * multiplier;
					--force = force * dt / 1000 / lastSpeed;
					local velX, velY, velZ = getLinearVelocity(self.powerConsumer.forceNode);
					addForce(self.powerConsumer.forceNode, velX*force, velY*force, velZ*force, px,py,pz, true);
					str = string.format("baseForce=%.2f baseForceFactor=%.2f -> force=%.2f", self.powerConsumer.mrlBaseForce, baseForceFactor, force);
				else
					force = -math.min(frictionForce, self.powerConsumer.maxForce)*self.movingDirection * multiplier;
					local x,y,z = localDirectionToWorld(self.powerConsumer.forceDirNode, 0, 0, force);
					addForce(self.powerConsumer.forceNode, x, y, z, px,py,pz, true);
					str = string.format("frictionForce=%.2f maxForce=%.2f -> force=%.2f", frictionForce, self.powerConsumer.maxForce, force);
				end;
				
                if Vehicle.debugRendering and self:getIsActiveForInput() then
                    renderText(0.7, 0.85, getCorrectTextSize(0.02), str);
                end
            end
        end
    end
end
