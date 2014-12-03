DrivableManipulation = {};

function DrivableManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations);
end;

function DrivableManipulation:load(xmlFile)
	self.collectMaxRpm = false;
	self.collected = false;
	self.collectedInput = "";
	self.firstUpdate = true;
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
				self.motor.torqueCurve.keyframes = {};
				local normRpmsT = Utils.splitString(" ", normRpms);
				local torquesT =  Utils.splitString(" ", torques);
				if #normRpmsT == #torquesT then
					self.motor.maxRpm = maxRpm;
					self.motor.torqueCurve.maxTime = maxRpm;
					for k,rpm in pairs(normRpmsT) do
						local e_time = rpm * maxRpm;
						local e_v = torquesT[k] * torqueScale;
						table.insert(self.motor.torqueCurve.keyframes, {time=e_time,v=e_v});
					end;
				else
					print("ERROR: not same length for 'normRpms' and 'torques' in vehicle "..tostring(MrLightUtils.vehicleConfigs[self.configFileName]));
				end;
			end;
			
			self.motor.maxForwardSpeed = maxSpeed / 3.6;
			self.motor.minForwardGearRatio = maxRpm / maxSpeed / (30 / math.pi / 3.6);
			self.fuelCapacity = fuelCapacity;
			self.fuelUsage = fuelUsage / (60*60*1000);
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
end;
