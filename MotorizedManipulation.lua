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
	
	self.fuelCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelCapacity"), 500);
    local fuelUsage = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelUsage"), 1);
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
	
	
	-- incline display
	--[[self.frontInclineNode = createTransformGroup("front");
	self.backInclineNode = createTransformGroup("back");
	link(self.rootNode, self.frontInclineNode);
	link(self.rootNode, self.backInclineNode);
	setTranslation(self.frontInclineNode, 0, 0, 1);
	setTranslation(self.backInclineNode, 0, 0, -1);]]
	
	
	
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
	--[[if self.collectMaxRpm then
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
	end;]]
end;

function MotorizedManipulation:update(dt)
	
	--if self.firstRunMotorizedManipulation then
	--	self.firstRunMotorizedManipulation = false;
	--end;
	
	--[[if (InputBinding.hasEvent(InputBinding.SETMAXRPM)) then --and not self.collectPtoPower then
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
	end;]]
	
	
	--[[
	if self.slip > 0.15 and not self.isDiffLocked then
		--print("todo lock diff");
		self:toggleDifferentialLock();
	elseif self.slip <= 0.10 and self.isDiffLocked then
		--print("todo unlock diff");
		self:toggleDifferentialLock();
	end;
	--print("self.slip: "..tostring(self.slip)..", self.isDiffLocked: "..tostring(self.isDiffLocked));
	
	
	
	self.slip = 0;
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
		--local a, b, c = getTranslation(v.driveNode)
		--local x1,y1,z1 = worldToLocal(v.driveNode, x, y, z);
		--print(x1, " ", y1, " ", z1);
		
		local a, b, c = worldToLocal(v.node, getWorldTranslation(v.driveNode));
		self.wheelsGroundContactPos[k] = {localToWorld(v.node, a, b-v.radius, c)};
		
	end;
	self.slip = self.slip / self.numWheels;
	]]
	
	
	
	--[[local fx, fy, fz = getWorldTranslation(self.frontInclineNode);
	local bx, by, bz = getWorldTranslation(self.backInclineNode);
	local tfy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, fy, fz);
	local tby = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, bx, by, bz);
	local dist = Utils.vector3Length(fx-bx, tfy-tby, fz-bz);
	local heightDifVehicle = fy - by;
	local heightDifTerrain = tfy - tby;
	--print(string.format("fy: %.3f, by: %.3f, heightDif: %.3f", fy, by, heightDif));
	self.anglePercentVehicle = 100 / math.sqrt(4 - math.pow(heightDifVehicle, 2)) * heightDifVehicle;
	self.anglePercentTerrain = 100 / math.sqrt(math.pow(dist, 2) - math.pow(heightDifTerrain, 2)) * heightDifTerrain;]]
	
	--[[
	local ax, ay, az = unpack(self.wheelsGroundContactPos[1]);
	--print(ax, " ", ay, " ", az);
	local bx, by, bz = unpack(self.wheelsGroundContactPos[2]);
	local cx, cy, cz = unpack(self.wheelsGroundContactPos[4]);
	
	--drawDebugLine(ax,ay,az,1,0,1,bx,by,bz,1,0,1); --,float r0,float g0,float b0,float x1,float y1,float z1,float r1,float g1,float b1)
	--drawDebugLine(bx,by,bz,1,1,1,cx,cy,cz,1,1,1); --float x0,float y0,float z0,float r0,float g0,float b0,float x1,float y1,float z1,float r1,float g1,float b1)
	
	local distLeftRight = Utils.vector3Length(ax-bx, ay-by, az-bz);
	local distFrontBack = Utils.vector3Length(bx-cx, by-cy, bz-cz);
	local yDifLeftRight = ay - by;
	local yDifFrontBack = by - cy;
	self.anglePercentLeftRight = 100 / math.sqrt(math.pow(distLeftRight, 2) - math.pow(yDifLeftRight, 2)) * yDifLeftRight;
	self.anglePercentFrontBack = 100 / math.sqrt(math.pow(distFrontBack, 2) - math.pow(yDifFrontBack, 2)) * yDifFrontBack;]]
end;

--[[
function MotorizedManipulation:toggleDifferentialLock()
	--print("toggle diff");
	if self.isDiffLocked then
		for k,v in pairs(self.differentials) do
			updateDifferential(self.rootNode, k, self.diffBak[k].torqueRatio, self.diffBak[k].maxSpeedRatio);
		end;
	elseif not self.isDiffLocked then
		for k,v in pairs(self.differentials) do
			updateDifferential(self.rootNode, k, 0.5, 1);
		end;
	end;
	self.isDiffLocked = not self.isDiffLocked;
end;]]

function MotorizedManipulation:draw()
	if self.debugRenderMotorizedManipulation then
		--[[
		setTextAlignment(RenderText.ALIGN_LEFT);
		renderText(0.85, 0.01, 0.012, string.format("slip: %.3f, incline X: %.3f, incline Z: %.3f", self.slip*100, self.anglePercentLeftRight, self.anglePercentFrontBack));
		setTextAlignment(RenderText.ALIGN_RIGHT);
		
		local i = 0;
		for k,v in pairs(self.wheels) do
			i = i + 0.01;
			--local engineSlip = getWheelShapeSlip(self.rootNode, k);
			renderText(0.8, i, 0.012, string.format("r/s: %02.2f, m/s: %02.2f, slip: %02.2f, slipDisplay: %02.2f,", v.rotPerSecond, v.distPerSecond, v.slip*100, v.slipDisplay*100));
		end;
		]]
	end;
	setTextAlignment(RenderText.ALIGN_LEFT);
end;
