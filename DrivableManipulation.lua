DrivableManipulation = {};

function DrivableManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations);
end;

function DrivableManipulation:load(xmlFile)
	self.collectMaxRpm = false;
	self.collected = false;
	self.collectedInput = "";
	self.firstUpdate = true;
	
	self.debugRender = false;
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
	
	if self.firstUpdate then
		self.firstUpdate = false;
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
						print(k);
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
			
			
			--experiment:
			self.motor.lowBrakeForceScale = 0.1;
		end;
	end;
	
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
end;

function DrivableManipulation:draw()
	local rx, ry, rz = getWorldRotation(self.rootNode);
	local x, yCosValue, z = localDirectionToWorld(self.rootNode, 0, 1, 0);
	local dir = Utils.clamp(yCosValue, 0, 1);
	local deg_rx = math.acos(dir); --rx / (2 * math.pi) * 360;
	local deg_rx1 = math.deg(rx);
	local percent_rx = math.tan(deg_rx) * 100;
		setTextAlignment(RenderText.ALIGN_LEFT);
		renderText(0.6, 0.01, 0.01, string.format("rx: %.4f, ry: %.4f, rz: %.4f", rx, ry, rz));
		renderText(0.85, 0.01, 0.01, string.format("rad: %.3f, deg: %.3f, deg1: %.3f, percent: %.3f",rx, deg_rx, deg_rx1, percent_rx));
end;
