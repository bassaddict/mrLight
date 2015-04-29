AttachableManipulation = {};

function AttachableManipulation.prerequisitesPresent(specializations)
    return true;
end;

function AttachableManipulation:load(xmlFile)
	--self.firstRunAttachableManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		if MrLightUtils.vehicleConfigs[self.configFileName].lowerDistanceToGround ~= nil then
			self.inputAttacherJoints[1].lowerDistanceToGround = MrLightUtils.vehicleConfigs[self.configFileName].lowerDistanceToGround;
		end;
		if MrLightUtils.vehicleConfigs[self.configFileName].upperDistanceToGround ~= nil then
			self.inputAttacherJoints[1].upperDistanceToGround = MrLightUtils.vehicleConfigs[self.configFileName].upperDistanceToGround;
		end;
		if MrLightUtils.vehicleConfigs[self.configFileName].rotLimitScale ~= nil then
			self.inputAttacherJoints[1].rotLimitScale = {Utils.getVectorFromString(MrLightUtils.vehicleConfigs[self.configFileName].rotLimitScale)};
		end;
		
		self.brakeForce = Utils.getNoNil(MrLightUtils.vehicleConfigs[self.configFileName].brakeForce, self.brakeForce);
	end;
	
	
	
	--[[self.collectLoderDist = false;
	self.collectUpperDist = false;
	self.collectedAM = false;
	self.collectedInputAM = "";
	
	
	for _,v in pairs(self.inputAttacherJoints) do
		v.transLimitScale = {0, 0, 0};
	end;]]
	
	
	
	--self.debugRenderAttachableManipulation = false;
end;

function AttachableManipulation:delete()
end;

function AttachableManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AttachableManipulation:keyEvent(unicode, sym, modifier, isDown)
	--[[if self.collectLowerDist or self.collectUpperDist then
		if isDown then
			if sym == 13 then
				self.collectedAM = true;
				--print("enter");
			--elseif unicode == 46 or (unicode >= 48 and unicode <= 57) then
			elseif unicode >= 48 and unicode <= 57 then
				self.collectedInputAM = self.collectedInputAM .. string.char(unicode);
				--print("number: " .. tostring(unicode));
			else
				print("other char pressed: " .. tostring(sym));
			end;
		end;
	end;]]
end;

function AttachableManipulation:update(dt)
	
	--[[if (InputBinding.hasEvent(InputBinding.SETLOWERDIST)) and not self.collectUpperDist then
		self.collectLowerDist = true;
		--print("force pressed");
	elseif (InputBinding.hasEvent(InputBinding.SETUPPERDIST)) and not self.collectLowerDist then
		self.collectUpperDist = true;
		--print("PTO power pressed");
	end;
	if self.collectedAM then
		local newValue = tonumber(self.collectedInputAM);
		if self.collectLowerDist then
			self.inputAttacherJoints[1].lowerDistanceToGround = Utils.getNoNil(newValue*0.01, self.inputAttacherJoints[1].lowerDistanceToGround);
			self.collectLowerDist = false;
			print("new lowerDist value: " .. tostring(self.inputAttacherJoints[1].lowerDistanceToGround));
		elseif self.collectUpperDist then
			self.inputAttacherJoints[1].upperDistanceToGround = Utils.getNoNil(newValue*0.01, self.inputAttacherJoints[1].upperDistanceToGround);
			self.collectUpperDist = false;
			print("new upperDist value: " .. tostring(self.inputAttacherJoints[1].upperDistanceToGround));
		end;
		self.collectedAM = false;
		self.collectedInputAM = "";
	end;
	
	
	--if self.firstRunAttachableManipulation then
	--	self.firstRunAttachableManipulation = false;
	--end;]]
	
end;

function AttachableManipulation:draw()
	--if self.debugRenderAttachableManipulation then
		--setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		--setTextAlignment(RenderText.ALIGN_LEFT);
	--end;
end;