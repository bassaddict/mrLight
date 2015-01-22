VehicleManipulation = {};

function VehicleManipulation.prerequisitesPresent(specializations)
    return true;
end;

function VehicleManipulation:load(xmlFile)
	self.firstRunVehicleManipulation = true;
	
	
	
		--local jointEntry = MrLightUtils.vehicleConfigs[self.configFileName]["attacherJoint"..tostring(i)];
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		for i,attacherJoint in ipairs(self.attacherJoints) do
			local jointNumber = "attacherJoint"..tostring(i);
			
			if MrLightUtils.vehicleConfigs[self.configFileName][jointNumber] ~= nil then
				local jointSettings = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName][jointNumber]);
				attacherJoint.minRotDistanceToGround = jointSettings[1];
				attacherJoint.minRotRotationOffset = math.rad(jointSettings[2]);
				attacherJoint.minRot[1] = math.rad(jointSettings[3]);
				attacherJoint.minRot2[1] = math.rad(jointSettings[4]);
				attacherJoint.maxRotDistanceToGround = jointSettings[5];
				attacherJoint.maxRotRotationOffset = math.rad(jointSettings[6]);
				attacherJoint.maxRot[1] = math.rad(jointSettings[7]);
				attacherJoint.maxRot2[1] = math.rad(jointSettings[8]);
				
				attacherJoint.bottomArm.translationNode = nil;
				attacherJoint.isFixed = true;
			end;
		end;
		
		--[[if MrLightUtils.vehicleConfigs[self.configFileName].wheelsSpring ~= nil then
			local wheelsSpringT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].wheelsSpring);
			if #wheelsSpringT == #self.wheels then
				for k,v in pairs(self.wheels) do
					v.spring = wheelsSpringT[k] * 10;
					
					
					local collisionMask = 255 - 4; -- all up to bit 8, except bit 2 which is set by the players kinematic object
					print(string.format("node %d, x %.4f, y %.4f, z %.4f, radius %.4f, suspTravel %.4f, radius %.4f, spring %.4f, damper %.4f, mass %.4f, collisionMask %d, wheelShape %d", v.node, v.netInfo.x, v.netInfo.y, v.netInfo.z, v.radius, v.suspTravel, v.radius, v.spring, v.damper, v.mass, collisionMask, v.wheelShape));
					--v.wheelShape = createWheelShape(v.node, v.netInfo.x, v.netInfo.y, v.netInfo.z, v.radius, v.suspTravel, v.radius, v.spring, v.damper, v.mass, collisionMask, v.wheelShape);
					
				end;
			else
				print("WARNING: number of wheelsSpring elements not equal number of wheels for vehicle "..self.configFileName);
			end;
		end;]]
	end;
	
	self.isDrivable = SpecializationUtil.hasSpecialization(Drivable, self.specializations);
	if self.isDrivable then
		self.moveLowerJointAxis1 = InputBinding.AXIS_MOVE_ATTACHERJOINT_LOWER1;
		self.moveLowerJointAxis2 = InputBinding.AXIS_MOVE_ATTACHERJOINT_LOWER2;
		self.moveUpperJointAxis1 = InputBinding.AXIS_MOVE_ATTACHERJOINT_UPPER1;
		self.moveUpperJointAxis2 = InputBinding.AXIS_MOVE_ATTACHERJOINT_UPPER2;
		self.isSelectable = true;
		self.attacherJointMovementLocked = true;
	end;
	
	self.counter = 100;
	self.debugLowerDistanceToGround = 0;
	self.debugUpperDistanceToGround = 1.5;
	self.debugVehicleManipulation = false;
	self.debugRenderVehicleManipulation = true;
end;

function VehicleManipulation:delete()
end;

function VehicleManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function VehicleManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function VehicleManipulation:update(dt)

	if self.firstRunVehicleManipulation then
		self.firstRunVehicleManipulation = false;
		--print("--VehicleManipulation first update "..self.configFileName);
		
		if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
			local numComponents = #self.components;
			if MrLightUtils.vehicleConfigs[self.configFileName].masses ~= nil then
				--print("--VehicleManipulation vehicle exists, masses exists, "..self.configFileName);
				if numComponents > 1 then
					local massesT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].masses);
					if #massesT == numComponents then
						for k,v in pairs(massesT) do
							--print("--VehicleManipulation set mass multiple components "..tostring(v));
							setMass(self.components[k].node, tonumber(v));
							--print("--mass: "..tostring(getMass(self.components[k].node)));
						end;
					else
						print("WARNING: number of masses in configFile not equals number of components for vehicle "..self.configFileName);
					end;
				elseif numComponents == 1 then
					--print("--VehicleManipulation set mass single component");
					setMass(self.rootNode, MrLightUtils.vehicleConfigs[self.configFileName].masses);
				end;
			end;
			
			if MrLightUtils.vehicleConfigs[self.configFileName].centerOfMass ~= nil then
				local comT = Utils.splitString(";", MrLightUtils.vehicleConfigs[self.configFileName].centerOfMass);
				if numComponents == # comT then
					for k,v in pairs(comT) do
						local x, y, z = Utils.getVectorFromString(v);
						setCenterOfMass(self.components[k].node, x, y, z);
					end;
				else
					print("WARNING: number of \"centerOfMass\" parts in configFile not equals number of components for vehicle "..self.configFileName);
				end;
			end;
			
		end;
	end;
	
	self.counter = self.counter - 1;
	if self.counter == 0 and self.debugVehicleManipulation then
		--[[if self.attacherJoints[1] ~= nil and self.attacherJoints[1].jointTransform ~= nil then
			local x,y,z = getWorldTranslation(self.attacherJoints[1].jointTransform);
			local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z);
			local dif = y - terrainHeight;
			print("dif: "..tostring(dif)..", vehicle: "..tostring(self.configFileName));
		end;]]
		
		local groundRaycastResult = {
			raycastCallback = function (self, transformId, x, y, z, distance)
				self.groundDistance = distance;
			end
		};
		
		for i, attacherJoint in ipairs(self.attacherJoints) do
			local trx, try, trz = getRotation(attacherJoint.jointTransform);
			setRotation(attacherJoint.jointTransform, unpack(attacherJoint.jointOrigRot));
			if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil and not attacherJoint.isFixed then
				local rx,ry,rz;
				if attacherJoint.rotationNode ~= nil then
					rx,ry,rz = getRotation(attacherJoint.rotationNode);
				end;
				local rx2,ry2,rz2;
				if attacherJoint.rotationNode2 ~= nil then
					rx2,ry2,rz2 = getRotation(attacherJoint.rotationNode2);
				end;
				local jointNumber = "attacherJoint"..tostring(i).."TODO";
				if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName][jointNumber] ~= nil then
					local jointMinMax = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName][jointNumber]);
					if attacherJoint.minRot[1] < attacherJoint.minRot2[1] then
						attacherJoint.minRot[1] = math.rad(jointMinMax[1]);
						attacherJoint.minRot2[1] = math.rad(-jointMinMax[1] - 8);
					else
						attacherJoint.minRot[1] = math.rad(jointMinMax[1]);
						attacherJoint.minRot2[1] = math.rad(-jointMinMax[1] + 8);
					end;
					attacherJoint.maxRot[1] = math.rad(jointMinMax[2]);
					attacherJoint.maxRot2[1] = math.rad(-jointMinMax[2]);
					attacherJoint.useTODO = true;
				end;
				
				--[[local offset = math.rad(0.05); --2 * math.pi / 360;
				local sign = 1;
				local pos = 1;
				local c = 0;
				if attacherJoint.maxRot[1] < attacherJoint.minRot[1] then sign = -1 else sign = 1 end;
				
				local minRotOrig = attacherJoint.minRot[1];
				local minRot2Orig = attacherJoint.minRot2[1];
				attacherJoint.minRotDistanceToGround = 0;
				-- set min rot
				--while attacherJoint.minRotDistanceToGround < 1 do
				while true do
					if attacherJoint.minRotDistanceToGround > 0.999 and attacherJoint.minRotDistanceToGround < 1.001 then
						print("break min in iteration: "..tostring(c));
						break;
					end;
					if attacherJoint.minRotDistanceToGround > 1 then pos = -1 else pos = 1 end;
					if attacherJoint.rotationNode ~= nil then
						attacherJoint.minRot[1] = minRotOrig - (pos * sign * c * offset);
						setRotation(attacherJoint.rotationNode, unpack(attacherJoint.minRot));
					end
					if attacherJoint.rotationNode2 ~= nil then
						attacherJoint.minRot2[1] = minRot2Orig + (pos * sign * c * offset);
						setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.minRot2));
					end
					local x,y,z = getWorldTranslation(attacherJoint.jointTransform);
					groundRaycastResult.groundDistance = 0;
					raycastClosest(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult);
					attacherJoint.minRotDistanceToGround = groundRaycastResult.groundDistance;
					c = c + 1;
				end;]]
				if attacherJoint.rotationNode ~= nil then
					setRotation(attacherJoint.rotationNode, unpack(attacherJoint.minRot));
				end;
				if attacherJoint.rotationNode2 ~= nil then
					setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.minRot2));
				end;
				local x,y,z = getWorldTranslation(attacherJoint.jointTransform);
				groundRaycastResult.groundDistance = 0;
				raycastClosest(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult);
				attacherJoint.minRotDistanceToGround = groundRaycastResult.groundDistance;
				
				local dx,dy,dz = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0);
				local angle = math.deg(math.acos(Utils.clamp(dy, -1, 1)));
				local dxx,dxy,dxz = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0);
				if dxy < 0 then
					angle = -angle;
				end;
				attacherJoint.minRotRotationOffset = math.rad(angle);
				
				
				--[[c = 0;
				local maxRotOrig = attacherJoint.maxRot[1];
				local maxRot2Orig = attacherJoint.maxRot2[1];
				attacherJoint.maxRotDistanceToGround = 10;
				-- set max rot
				--while attacherJoint.maxRotDistanceToGround > 0.7 do
				while true do
					if attacherJoint.maxRotDistanceToGround > 0.379 and attacherJoint.maxRotDistanceToGround < 0.381 then
						print("break max in iteration: "..tostring(c));
						break;
					end;
					if attacherJoint.maxRotDistanceToGround < 0.7 then pos = -1 else pos = 1 end;
					if attacherJoint.rotationNode ~= nil then
						attacherJoint.maxRot[1] = maxRotOrig + (pos * sign * c * offset);
						setRotation(attacherJoint.rotationNode, unpack(attacherJoint.maxRot));
					end
					if attacherJoint.rotationNode2 ~= nil then
						attacherJoint.maxRot2[1] = maxRot2Orig - (pos * sign * c * offset);
						setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.maxRot2));
					end
					local x,y,z = getWorldTranslation(attacherJoint.jointTransform);
					groundRaycastResult.groundDistance = 0;
					raycastClosest(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult);
					attacherJoint.maxRotDistanceToGround = groundRaycastResult.groundDistance;
					c = c + 1;
				end;]]
				if attacherJoint.useTODO == nil then
					local brx,bry,brz = getRotation(attacherJoint.bottomArm.rotationNode);
					attacherJoint.maxRot = {brx, bry, brz};
					attacherJoint.maxRot2 = {-brx, -bry, -brz};
				end;
				if attacherJoint.rotationNode ~= nil then
					setRotation(attacherJoint.rotationNode, unpack(attacherJoint.maxRot));
				end;
				if attacherJoint.rotationNode2 ~= nil then
					setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.maxRot2));
				end;
				local x,y,z = getWorldTranslation(attacherJoint.jointTransform);
				groundRaycastResult.groundDistance = 0;
				raycastClosest(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult);
				attacherJoint.maxRotDistanceToGround = groundRaycastResult.groundDistance;
				
				local dx,dy,dz = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0);
				local angle = math.deg(math.acos(Utils.clamp(dy, -1, 1)));
				local dxx,dxy,dxz = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0);
				if dxy < 0 then
					angle = -angle;
				end;
				attacherJoint.maxRotRotationOffset = math.rad(angle);

				-- reset rotations
				if attacherJoint.rotationNode ~= nil then
					setRotation(attacherJoint.rotationNode, rx,ry,rz);
				end;
				if attacherJoint.rotationNode2 ~= nil then
					setRotation(attacherJoint.rotationNode2, rx2,ry2,rz2);
				end;
				
				
				attacherJoint.bottomArm.translationNode = nil;
				
				
				print(string.format("joint %d for vehicle %s: %.3f %.2f %.2f %.2f %.3f %.2f %.2f %.2f", i, self.configFileName, 
				attacherJoint.minRotDistanceToGround, 
				math.deg(attacherJoint.minRotRotationOffset), 
				math.deg(attacherJoint.minRot[1]), 
				math.deg(attacherJoint.minRot2[1]), 
				attacherJoint.maxRotDistanceToGround, 
				math.deg(attacherJoint.maxRotRotationOffset),
				math.deg(attacherJoint.maxRot[1]), 
				math.deg(attacherJoint.maxRot2[1])));
			end;
			setRotation(attacherJoint.jointTransform, trx, try, trz);
		end;
		
		
		--[[for k,v in pairs(self.attacherJoints) do
			if v.bottomArm ~= nil then
				local difMinDist = 1;
				local difMaxDist = 0.7;
				local i = 0;
				local offset = math.rad(1); --2 * math.pi / 360;
				local sign = 1;
				if v.maxRot[1] < v.minRot[1] then sign = -1 else sign = 1 end;
				while difMinDist > 0.7 do --make sure lower distance to ground is 0.7 or smaller
					setRotation(v.rotationNode, (v.maxRot[1] + (sign * i * offset)), v.maxRot[2], v.maxRot[3]);
					local x,y,z = getWorldTranslation(v.jointTransform);
					local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z);
					difMinDist = y - terrainHeight;
					i = i + 1;
				end;
				v.maxRot[1] = v.maxRot[1] + (sign * i * offset);
				v.maxRotDistanceToGround = difMinDist;
				
				
				i = 0;
				while difMaxDist < 1 do --make sure upper distance to ground is 1 or bigger
					setRotation(v.rotationNode, (v.minRot[1] - (sign * i * offset)), v.minRot[2], v.minRot[3]);
					local x,y,z = getWorldTranslation(v.jointTransform);
					local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z);
					difMaxDist = y - terrainHeight;
					i = i + 1;
				end;
				v.minRot[1] = v.minRot[1] - (sign * i * offset);
				v.minRotDistanceToGround = difMaxDist;
				
			end;
		end;]]
	end;
	
	if (InputBinding.hasEvent(InputBinding.TOGGLE_AJ_LOCK)) then
		self.attacherJointMovementLocked = not self.attacherJointMovementLocked;
	end;
	
	if self:getIsActiveForInput(false) and self.isDrivable and not self.attacherJointMovementLocked then
		if self.selectedImplement ~= nil and self.selectedImplement.object ~= nil and self.attacherJoints[self.selectedImplement.jointDescIndex].bottomArm ~= nil then
			local moveU, _ = InputBinding.getInputAxis(self.moveUpperJointAxis2);
			local moveDeltaU = 0.05 / (1000 / dt); --0.05m/s
			if InputBinding.isAxisZero(moveU) then
				moveU, _ = InputBinding.getInputAxis(self.moveUpperJointAxis1);
				moveDeltaU = 0.25 / (1000 / dt); --0.25m/s
			end;
			
			local moveL, _ = InputBinding.getInputAxis(self.moveLowerJointAxis2);
			local moveDeltaL = 0.05 / (1000 / dt); --0.05m/s
			if InputBinding.isAxisZero(moveL) then
				moveL, _ = InputBinding.getInputAxis(self.moveLowerJointAxis1);
				moveDeltaL = 0.25 / (1000 / dt); --0.25m/s
			end;
			
			
			
			local aj = self.selectedImplement.object.attacherJoint;
			local ajs = self.attacherJoints[self.selectedImplement.jointDescIndex];
			
			aj.lowerDistanceToGround = math.max(math.min((aj.lowerDistanceToGround + (moveDeltaL * moveL)), aj.upperDistanceToGround), ajs.maxRotDistanceToGround);
			aj.upperDistanceToGround = math.min(math.max((aj.upperDistanceToGround + (moveDeltaU * moveU)), aj.lowerDistanceToGround), ajs.minRotDistanceToGround);
			self.debugLowerDistanceToGround = aj.lowerDistanceToGround;
			self.debugUpperDistanceToGround = aj.upperDistanceToGround;
			
			ajs.upperAlpha, ajs.lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(ajs, self.selectedImplement.object);
		else
			self.debugLowerDistanceToGround = 0;
			self.debugUpperDistanceToGround = 1.5
		end;
	end;
	
end;

function VehicleManipulation:draw()
	if self.debugRenderVehicleManipulation and self.isDrivable then
		--setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.45, 0.01, 0.01, string.format("low: %.3f, up: %.3f", self.debugLowerDistanceToGround, self.debugUpperDistanceToGround));
		--setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;

function VehicleManipulation:setAttacherJointRotation(joint, rotation)
	local jointNumber = tonumber(joint);
	local rotDeg = tonumber(rotation);
	if g_currentMission ~= nil and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.isServer then
		local self = g_currentMission.controlledVehicle;
		if self.attacherJoints ~= nil and self.attacherJoints[jointNumber] ~= nil and self.attacherJoints[jointNumber].bottomArm ~= nil then
			setRotation(self.attacherJoints[jointNumber].bottomArm.rotationNode, math.rad(rotDeg), 0, 0);
			self:setMovingToolDirty(self.attacherJoints[jointNumber].bottomArm.rotationNode);
		end;
	end;
end;

addConsoleCommand('setJointRot', 'set rotation for attacher joint', 'setAttacherJointRotation', VehicleManipulation);