DrivableManipulation = {};

function DrivableManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations);
end;

function DrivableManipulation:load(xmlFile)
	self.collectMaxRpm = false;
	self.collected = false;
	self.collectedInput = "";
	--self.firstRunDrivableManipulation = true;
	
	self.toggleDifferentialLock = DrivableManipulation.toggleDifferentialLock;
	
	
	
	-- update motor settings
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		local torqueScale = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].torqueScale, 1);
		local maxRpm = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].maxRpm, self.motor.maxRpm);
		local maxSpeed = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].maxSpeed, self.motor.maxForwardSpeed*3.6);
		local normRpms = MrLightUtils.vehicleConfigs[self.configFileName].normRpms;
		local torques = MrLightUtils.vehicleConfigs[self.configFileName].torques;
		local fuelCapacity = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].fuelCapacity, self.fuelCapacity);
		local fuelUsage = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].fuelUsage, self.fuelUsage*60*60*1000);
		
		if normRpms ~= nil and torques ~= nil then
			--self.motor.torqueCurve.keyframes = {};
			local normRpmsT = Utils.splitString(" ", normRpms);
			local torquesT =  Utils.splitString(" ", torques);
			
			
			if self.debugRender then
				print(string.format("normRpms: %s, torques: %s", normRpms, torques));
				for k,v in pairs(normRpmsT) do
					print(string.format("k: %d, v: %s", k, v));
				end;
			end;
			
			
			if #normRpmsT == #torquesT and #normRpmsT == #self.motor.torqueCurve.keyframes then
				self.motor.maxRpm = maxRpm;
				self.motor.torqueCurve.maxTime = maxRpm;
				for k,rpm in pairs(normRpmsT) do
					--print(k);
					local e_time = rpm * maxRpm;
					local e_v = torquesT[k] * torqueScale;
					self.motor.torqueCurve.keyframes[k].time = e_time;
					self.motor.torqueCurve.keyframes[k].v = e_v;
					--table.insert(self.motor.torqueCurve.keyframes, {time=e_time,v=e_v});
				end;
			else
				print("ERROR: not same length for 'normRpms' and 'torques' in vehicle "..self.configFileName);
				print(string.format(" --> #normRpmsT: %d, #torquesT: %d, #keyframes: %d", #normRpmsT, #torquesT, #self.motor.torqueCurve.keyframes));
			end;
		end;
		
		self.cruiseControl.maxSpeed = maxSpeed;
		self.cruiseControl.speed = maxSpeed;
		self.cruiseControl.speedSent = maxSpeed;
		self.motor.maxForwardSpeed = maxSpeed / 3.6;
		self.motor.minForwardGearRatio = maxRpm / maxSpeed / (30 / math.pi / 3.6);
		self.fuelCapacity = fuelCapacity;
		self.fuelUsage = fuelUsage / (60*60*1000);
		
		--self.motor.maxForwardGearRatio = 750;
		
		
		--experiment:
		self.motor.lowBrakeForceScale = 0.1;
	end;
	
	
	-- incline display
	self.frontInclineNode = createTransformGroup("front");
	self.backInclineNode = createTransformGroup("back");
	link(self.rootNode, self.frontInclineNode);
	link(self.rootNode, self.backInclineNode);
	setTranslation(self.frontInclineNode, 0, 0, 1);
	setTranslation(self.backInclineNode, 0, 0, -1);
	
	
	
	-- slip
	self.slip = 0;
	self.isDiffLocked = false;
	self.diffBak = {};
	for k,v in pairs(self.differentials) do
		self.diffBak[k] = {};
		self.diffBak[k].torqueRatio = v.torqueRatio;
		self.diffBak[k].maxSpeedRatio = v.maxSpeedRatio;
	end;
	--print("diff backup done");
	
	self.wheelsRot = {};
	self.wheelsPos = {};
	for k,v in pairs(self.wheels) do
		local rx,_,_ = getRotation(v.driveNode);
		self.wheelsRot[k] = rx;
		local x,y,z = getWorldTranslation(v.driveNode);
		self.wheelsPos[k] = {x=x, y=y, z=z};
		
		--v.frictionScale = 5;
		
		v.rotPerSecond = 0;
		v.distPerSecond = 0;
		v.slip = 0;
		v.slipDisplay = 0;
	end;
	
	self.anglePercentVehicle = 0;
	self.anglePercentTerrain = 0;
	
	
	
	
	self.debugRenderDrivableManipulation = true;
end;

function DrivableManipulation:delete()
end;

function DrivableManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DrivableManipulation:keyEvent(unicode, sym, modifier, isDown)
	if self.collectMaxRpm then
		if isDown then
			if sym == 13 then
				self.collected = true;
				--print("enter");
			--elseif unicode == 46 or (unicode >= 48 and unicode <= 57) then
			elseif unicode >= 48 and unicode <= 57 then
				self.collectedInput = self.collectedInput .. string.char(unicode);
				--print("number: " .. tostring(unicode));
			else
				print("other char pressed: " .. tostring(sym));
			end;
		end;
	end;
end;

function DrivableManipulation:update(dt)
	
	--if self.firstRunDrivableManipulation then
	--	self.firstRunDrivableManipulation = false;
	--end;
	
	if (InputBinding.hasEvent(InputBinding.SETMAXRPM)) then --and not self.collectPtoPower then
		self.collectMaxRpm = true;
		--print("force pressed");
	end;
	if self.collected then
		local newValue = tonumber(self.collectedInput);
		if self.collectMaxRpm then
			self.motor.maxRpm = Utils.getNoNil(newValue, self.motor.maxRpm);
			local keyFramesNo = #self.motor.torqueCurve.keyframes;
			self.motor.torqueCurve.keyframes[keyFramesNo].time = self.motor.maxRpm;
			self.motor.torqueCurve.maxTime = self.motor.maxRpm;
			
			self.motor.maxForwardSpeed = self.motor.maxRpm / self.motor.minForwardGearRatio / 2.653;
			
			self.collectMaxRpm = false;
			print("new maxRpm value: " .. tostring(Utils.getNoNil(newValue, self.motor.maxRpm)));
		--elseif self.collectPtoPower then
		--	self.powerConsumer.neededPtoPower = Utils.getNoNil(newValue, self.powerConsumer.neededPtoPower);
		--	self.collectPtoPower = false;
		--	print("new PTO power value: " .. tostring(Utils.getNoNil(newValue, self.powerConsumer.neededPtoPower)));
		end;
		self.collected = false;
		self.collectedInput = "";
	end;
	
	
	if self.slip > 0.15 and not self.isDiffLocked then
		--print("todo lock diff");
		self:toggleDifferentialLock();
	elseif self.slip <= 0.10 and self.isDiffLocked then
		--print("todo unlock diff");
		self:toggleDifferentialLock();
	end;
	--print("self.slip: "..tostring(self.slip)..", self.isDiffLocked: "..tostring(self.isDiffLocked));
	
	
	
	
	for k,v in pairs(self.wheels) do
		local lastRot = self.wheelsRot[k];
		local rx,_,_ = getRotation(v.driveNode);
		self.wheelsRot[k] = rx;
		local tempRot = rx - lastRot;
		if self.movingDirection >= 0 and tempRot < 0 then
			tempRot = (2 * math.pi) + tempRot;
		elseif self.movingDirection < 0 and tempRot > 0 then
			tempRot = (-2 * math.pi) + tempRot;
		end;
		
		v.rotPerSecond = (tempRot / (2 * math.pi)) * (1000 / dt);
		--v.rotPerSecond = ((rx - lastRot) / 2 * math.pi) * (1000 / dt);
		
		
		local lastPos = self.wheelsPos[k];
		local x,y,z = getWorldTranslation(v.driveNode);
		self.wheelsPos[k] = {x=x, y=y, z=z};
		v.distPerSecond = Utils.vector3Length(x-lastPos.x, y-lastPos.y, z-lastPos.z) * (1000 / dt);
		
		v.slip = 1 - (v.distPerSecond / (math.abs(v.rotPerSecond) * (v.radius * 2 * math.pi)));
		if v.rotPerSecond == 0 then v.slip = 0 end;
		v.slipDisplay = (v.slipDisplay * 0.95) + (v.slip * 0.05);
		self.slip = self.slip + v.slipDisplay;
	end;
	self.slip = self.slip / #self.wheels;
	
	
	
	
	local fx, fy, fz = getWorldTranslation(self.frontInclineNode);
	local bx, by, bz = getWorldTranslation(self.backInclineNode);
	local tfy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, fy, fz);
	local tby = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, bx, by, bz);
	local dist = Utils.vector3Length(fx-bx, tfy-tby, fz-bz);
	local heightDifVehicle = fy - by;
	local heightDifTerrain = tfy - tby;
	--print(string.format("fy: %.3f, by: %.3f, heightDif: %.3f", fy, by, heightDif));
	self.anglePercentVehicle = 100 / math.sqrt(4 - math.pow(heightDifVehicle, 2)) * heightDifVehicle;
	self.anglePercentTerrain = 100 / math.sqrt(math.pow(dist, 2) - math.pow(heightDifTerrain, 2)) * heightDifTerrain;
	
end;

function DrivableManipulation:toggleDifferentialLock()
	--print("toggle diff");
	if self.isDiffLocked then
		for k,v in pairs(self.differentials) do
			--print(string.format("before -- dif: %d, torque: %.2f, speed: %.2f", k, v.torqueRatio, v.maxSpeedRatio));
			updateDifferential(self.rootNode, k, self.diffBak[k].torqueRatio, self.diffBak[k].maxSpeedRatio);
			--print(string.format("after -- dif: %d, torque: %.2f, speed: %.2f", k, v.torqueRatio, v.maxSpeedRatio));
			--v.torqueRatio = self.diffBak[k].torqueRatio;
			--v.maxSpeedRatio = self.diffBak[k].maxSpeedRatio;
		end;
	elseif not self.isDiffLocked then
		for k,v in pairs(self.differentials) do
			--print(string.format("before -- dif: %d, torque: %.2f, speed: %.2f", k, v.torqueRatio, v.maxSpeedRatio));
			updateDifferential(self.rootNode, k, 0.5, 1);
			--print(string.format("after -- dif: %d, torque: %.2f, speed: %.2f", k, v.torqueRatio, v.maxSpeedRatio));
			--v.torqueRatio = 0.5;
			--v.maxSpeedRatio = 1;
		end;
	end;
	self.isDiffLocked = not self.isDiffLocked;
end;

function DrivableManipulation:draw()
	if self.debugRenderDrivableManipulation then
		setTextAlignment(RenderText.ALIGN_LEFT);
		renderText(0.85, 0.01, 0.012, string.format("incline V: %.3f, incline T: %.3f", self.anglePercentVehicle, self.anglePercentTerrain));
		setTextAlignment(RenderText.ALIGN_RIGHT);
		
		local i = 0;
		for k,v in pairs(self.wheels) do
			i = i + 0.01;
			--local engineSlip = getWheelShapeSlip(self.rootNode, k);
			renderText(0.8, i, 0.012, string.format("r/s: %02.2f, m/s: %02.2f, slip: %02.2f, slipDisplay: %02.2f,", v.rotPerSecond, v.distPerSecond, v.slip*100, v.slipDisplay*100));
		end;
	end;
	setTextAlignment(RenderText.ALIGN_LEFT);
end;
