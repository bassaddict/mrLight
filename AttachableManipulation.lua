AttachableManipulation = {};

function AttachableManipulation.prerequisitesPresent(specializations)
    return true;
end;

function AttachableManipulation:load(xmlFile)
	--self.firstRunAttachableManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	local i=0;
	while true do
		local key = string.format("vehicle.inputAttacherJoints.inputAttacherJoint(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
            break;
        end
		local mrlOrigJointIndex = getXMLInt(xmlFile, key.. "#mrlOrigJointIndex");
        if mrlOrigJointIndex == nil then
			local inputAttacherJoint = {};
			if self:loadInputAttacherJoint(xmlFile, key, inputAttacherJoint) then
				table.insert(self.inputAttacherJoints, inputAttacherJoint);
			end;
		else
			self.inputAttacherJoints[mrlOrigJointIndex].lowerDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#lowerDistanceToGround"), self.inputAttacherJoints[mrlOrigJointIndex].lowerDistanceToGround);
			self.inputAttacherJoints[mrlOrigJointIndex].upperDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#upperDistanceToGround"), self.inputAttacherJoints[mrlOrigJointIndex].upperDistanceToGround);
			
			self.inputAttacherJoints[mrlOrigJointIndex].allowsJointTransLimitMovement = false;
			self.inputAttacherJoints[mrlOrigJointIndex].allowsJointTransLimitMovementMod = true;
			
			local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile,  key .. "#rotLimitScale"));
			self.inputAttacherJoints[mrlOrigJointIndex].rotLimitScale = { Utils.getNoNil(x, self.inputAttacherJoints[mrlOrigJointIndex].rotLimitScale[1]), Utils.getNoNil(y, self.inputAttacherJoints[mrlOrigJointIndex].rotLimitScale[2]), Utils.getNoNil(z, self.inputAttacherJoints[mrlOrigJointIndex].rotLimitScale[3]) };
		end;
		i = i + 1;
	end;
	
	
	local i = 0;
   while true do
       local key = string.format("vehicle.inputAttacherJoints.inputAttacherJoint(%d)", i);
       if not hasXMLProperty(xmlFile, key) then
           break;
       end

       local inputAttacherJoint = {};
       if self:loadInputAttacherJoint(xmlFile, key, inputAttacherJoint) then
           table.insert(self.inputAttacherJoints, inputAttacherJoint);
       end;

       i = i + 1;
   end;
	
	
	
	
	
	
	
	
	
	
	
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
	
	--self.debugRenderAttachableManipulation = false;
end;

function AttachableManipulation:delete()
end;

function AttachableManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AttachableManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function AttachableManipulation:update(dt)
end;

function AttachableManipulation:draw()
end;