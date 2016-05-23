MotorizedManipulation = {};

function MotorizedManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Motorized, specializations);
end;

function MotorizedManipulation:load(xmlFile)
	
	self.toggleDifferentialLock = MotorizedManipulation.toggleDifferentialLock;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		--print(xmlPath);
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	self.fuelCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelCapacity"), self.fuelCapacity);
    local fuelUsage = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelUsage"), (self.fuelUsage * 60*60*1000));
    self.fuelUsage = fuelUsage / (60*60*1000); -- from l/h to l/ms
	
	local mrlMotorUpdate = getXMLBool(xmlFile, "vehicle.motor#mrlUpdate");
	
	if mrlMotorUpdate then
		self.motor = nil;
		--print("mrlMotorUpdate");
		local motorMinRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#minRpm"), 1000);
		local motorMaxRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#maxRpm"), 1800);
		
		local brakeForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#brakeForce"), 10);
		local lowBrakeForceScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#lowBrakeForceScale"), 0.1);
		local lowBrakeForceSpeedLimit = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#lowBrakeForceSpeedLimit"), 20)/3600;
		
		local maxForwardGearRatio = getXMLFloat(xmlFile, "vehicle.motor#maxForwardGearRatio");
		local minForwardGearRatio = getXMLFloat(xmlFile, "vehicle.motor#minForwardGearRatio");
		local maxBackwardGearRatio = getXMLFloat(xmlFile, "vehicle.motor#maxBackwardGearRatio");
		local minBackwardGearRatio = getXMLFloat(xmlFile, "vehicle.motor#minBackwardGearRatio");
		
		local maxForwardSpeed = getXMLFloat(xmlFile, "vehicle.motor#maxForwardSpeed");
		local maxBackwardSpeed = getXMLFloat(xmlFile, "vehicle.motor#maxBackwardSpeed");
		local minForwardSpeed = getXMLFloat(xmlFile, "vehicle.motor#mrlMinForwardSpeed");
		local minBackwardSpeed = getXMLFloat(xmlFile, "vehicle.motor#mrlMinBackwardSpeed");
		if maxForwardSpeed ~= nil then
			--minForwardGearRatio = motorMaxRpm / ((maxForwardSpeed * 30 / math.pi) / 3.6);
			maxForwardSpeed = maxForwardSpeed/3.6;
		else
			minForwardGearRatio = getXMLFloat(xmlFile, "vehicle.motor#minForwardGearRatio");
		end;
		
		if maxBackwardSpeed ~= nil then
			minBackwardGearRatio = motorMaxRpm / ((maxBackwardSpeed * 30 / math.pi) / 3.6);
			maxBackwardSpeed = maxBackwardSpeed/3.6;
		else
			minBackwardGearRatio = getXMLFloat(xmlFile, "vehicle.motor#minBackwardGearRatio");
		end;
		if minForwardSpeed ~= nil then
			maxForwardGearRatio = motorMaxRpm / ((minForwardSpeed * 30 / math.pi) / 3.6);
			minForwardSpeed = minForwardSpeed/3.6;
		else
			maxForwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#maxForwardGearRatio"), 130);
		end;
		if minBackwardSpeed ~= nil then
			maxBackwardGearRatio = motorMaxRpm / ((minBackwardSpeed * 30 / math.pi) / 3.6);
			minBackwardSpeed = minBackwardSpeed/3.6;
		else
			maxBackwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#maxBackwardGearRatio"), 130);
		end;
		
		
		
		local rpmFadeOutRange = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#rpmFadeOutRange"), 20);
		local torqueScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#torqueScale"), 1);
		
		local ptoRatedRatio = getXMLFloat(xmlFile, "vehicle.motor#mrlPtoRatedRatio");
		local baseRatio = 3;
		if ptoRatedRatio ~= nil then
			baseRatio = (motorMaxRpm * ptoRatedRatio) / 540; --general 540 PTO to reduce complexity
		end;
		local ptoMotorRpmRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#ptoMotorRpmRatio"), baseRatio);
		local maxTorque = 0;
		local torqueCurve = AnimCurve:new(linearInterpolator1);
		local torqueI = 0;
		while true do
			local key = string.format("vehicle.motor.torque(%d)", torqueI);
			local normRpm = getXMLFloat(xmlFile, key.."#normRpm");
			local rpm;
			if normRpm == nil then
				rpm = getXMLFloat(xmlFile, key.."#rpm");
			else
				rpm = normRpm * motorMaxRpm;
			end
			local torque = getXMLFloat(xmlFile, key.."#torque");
			if torque == nil or rpm == nil then
				break;
			end;
			torqueCurve:addKeyframe({v=torque*torqueScale, time = rpm});
			torqueI = torqueI +1;
			if torque*torqueScale > maxTorque then
				maxTorque = torque*torqueScale;
			end;
		end;
		self.motor = VehicleMotor:new(self, motorMinRpm, motorMaxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGearRatio, backwardGearRatio, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, rpmFadeOutRange, maxTorque);
		self.motor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit);
	end;
	
	
	-- update motor settings
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		local torqueScale = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].torqueScale, 1);
		local maxRpm = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].maxRpm, self.motor.maxRpm);
		local maxSpeed = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].maxSpeed, self.motor.maxForwardSpeed*3.6);
		local normRpms = MrLightUtils.vehicleConfigs[self.configFileName].normRpms;
		local torques = MrLightUtils.vehicleConfigs[self.configFileName].torques;
		local fuelCapacity = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].fuelCapacity, self.fuelCapacity);
		local fuelUsage = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].fuelUsage, self.fuelUsage*60*60*1000);
		
		
		self.motor.brakeForce = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].brakeForce, self.motor.brakeForce);
		
		
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
	self.numWheels = #self.wheels;
	self.wheelsGroundContactPos = {};
	for k,v in pairs(self.wheels) do
		local rx,_,_ = getRotation(v.driveNode);
		self.wheelsRot[k] = rx;
		local x,y,z = getWorldTranslation(v.driveNode);
		self.wheelsPos[k] = {x=x, y=y, z=z};
		local a, b, c = worldToLocal(v.node, getWorldTranslation(v.node));
		self.wheelsGroundContactPos[k] = {localToWorld(v.driveNode, a, b-v.node, c)}; --{localToWorld(v.driveNode, v.positionX, 0, v.positionZ)};
		
		v.rotPerSecond = 0;
		v.distPerSecond = 0;
		v.slip = 0;
		v.slipDisplay = 0;
	end;
	
	
	self.anglePercentVehicle = 0;
	self.anglePercentTerrain = 0;
	
	
	
	
	self.debugRenderMotorizedManipulation = true;
end;

function MotorizedManipulation:delete()
end;

function MotorizedManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function MotorizedManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function MotorizedManipulation:update(dt)
end;

function MotorizedManipulation:draw()
end;
