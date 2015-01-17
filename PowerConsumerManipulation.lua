PowerConsumerManipulation = {};

function PowerConsumerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PowerConsumer, specializations);
end;

function PowerConsumerManipulation:load(xmlFile)
	self.collectForce = false;
	self.collectPtoPower = false;
	self.collected = false;
	self.collectedInput = "";
	
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		self.powerConsumer.forceNode = Utils.indexToObject(self.components, Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].forceNode, "0>"));
		self.powerConsumer.forceDirNode = Utils.indexToObject(self.components, Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].forceDirNode, "0>"));
		self.powerConsumer.ptoRpm = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].ptoRpm, self.powerConsumer.ptoRpm);
		self.powerConsumer.neededPtoPower = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].neededPtoPower, self.powerConsumer.neededPtoPower);
		self.powerConsumer.maxForce = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].maxForce, self.powerConsumer.maxForce);
	end;
	
	self.debugRenderPowerConsumerManipulation = false;
end;

function PowerConsumerManipulation:delete()
end;

function PowerConsumerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function PowerConsumerManipulation:keyEvent(unicode, sym, modifier, isDown)
	if self.collectForce or self.collectPtoPower then
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

function PowerConsumerManipulation:update(dt)
	if (InputBinding.hasEvent(InputBinding.SETFORCE)) and not self.collectPtoPower then
		self.collectForce = true;
		--print("force pressed");
	elseif (InputBinding.hasEvent(InputBinding.SETPTOPOWER)) and not self.collectForce then
		self.collectPtoPower = true;
		--print("PTO power pressed");
	end;
	if self.collected then
		local newValue = tonumber(self.collectedInput);
		if self.collectForce then
			self.powerConsumer.maxForce = Utils.getNoNil(newValue, self.powerConsumer.maxForce);
			self.collectForce = false;
			print("new force value: " .. tostring(Utils.getNoNil(newValue, self.powerConsumer.maxForce)));
		elseif self.collectPtoPower then
			self.powerConsumer.neededPtoPower = Utils.getNoNil(newValue, self.powerConsumer.neededPtoPower);
			self.collectPtoPower = false;
			print("new PTO power value: " .. tostring(Utils.getNoNil(newValue, self.powerConsumer.neededPtoPower)));
		end;
		self.collected = false;
		self.collectedInput = "";
	end;
	
	--if ... then
	--	local powerMultiplier = getPowerMultiplier();
	--	local ptoRpm = getPtoRpm();
	--	local consumedPtoTorque = getConsumedPtoTorque();
	--end;
end;

function PowerConsumerManipulation:draw()
	if self.debugRenderPowerConsumerManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, lastFillLevel: %.4f, currentSeed: %d, isFilling: %s", self.fillLevel, self.myLastFillLevel, self.currentSeed, tostring(self.isFilling)));
		--renderText(0.99, 0.78, 0.018, string.format("fillDelta: %.4f",self.deltaFill));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;
