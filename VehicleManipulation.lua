VehicleManipulation = {};

function VehicleManipulation.prerequisitesPresent(specializations)
    return true;
end;

function VehicleManipulation:load(xmlFile)
	self.firstRunVehicleManipulation = true;
	
	local oldXmlFile = xmlFile;
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	self.realSpeedLimit = getXMLFloat(xmlFile, "vehicle.speedLimit#value");
	
	--print(self.configFileName);
	local numWheels = #self.wheels;
	for i=1, numWheels do
		local wheelnamei = string.format("vehicle.wheels.wheel(%d)", self.wheels[i].xmlIndex);
		local reloadWheel = getXMLBool(xmlFile, wheelnamei .. "#mrlReloadWheel");
		
		if reloadWheel then
			self:loadDynamicWheelDataFromXML(xmlFile, wheelnamei, self.wheels[i]);
		else
			self.wheels[i].frictionScale = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#frictionScale"), self.wheels[i].frictionScale);
			--print("    " .. tostring(self.wheels[i].frictionScale));
			self:updateWheelTireFriction(self.wheels[i]);
			--print("    " .. tostring(self.wheels[i].frictionScale));
		end;
	end;
	
	local updateSteering = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.wheels#mrlUpdateSteering"), false);
	
	local i = 0;
    while true do
        local wheelnamei = string.format("vehicle.wheels.wheel(%d)", i);
		local reloadWheel = getXMLBool(xmlFile, wheelnamei .. "#mrlReloadWheel");
		local newWheel = getXMLBool(xmlFile, wheelnamei .. "#mrlNewWheel");
		local checkWheel = getXMLString(xmlFile, wheelnamei .. "#frictionScale");
		if checkWheel == nil then
			break;
		end;
		
		if newWheel then
			local linkNode = Utils.indexToObject(self.components, getXMLString(xmlFile, wheelnamei .. "#mrlLinkNode"));
			local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, wheelnamei .. "#mrlNodePos"));
			local newNode = createTransformGroup("newWheel" .. i);
			link(linkNode, newNode);
			setTranslation(newNode, x, y, z);
			
			local wheel = {};
			wheel.repr = newNode;
			if wheel.repr == nil then
				print("Error: could not add new wheel " .. i);
			else
				wheel.driveNode = newNode;
				if wheel.driveNode == nil then
					wheel.driveNode = wheel.repr;
				end;
				wheel.isSynchronized = Utils.getNoNil(getXMLBool(xmlFile, wheelnamei .. "#isSynchronized"), true);
				--wheel.node = getParent(wheel.repr);
				-- look for top parent component node
				wheel.node = self:getParentComponent(wheel.repr);
				if wheel.node == 0 then
					print("Invalid wheel-repr. Needs to be a child of a collision");
				end;
				wheel.positionX, wheel.positionY, wheel.positionZ = localToLocal(wheel.repr, wheel.node, 0,0,0);
				wheel.startPositionX, wheel.startPositionY, wheel.startPositionZ = getTranslation(wheel.repr);
				wheel.dirtAmount = 0;
				wheel.lastColor = {0,0,0,0};
				wheel.contact = Vehicle.WHEEL_NO_CONTACT;
				wheel.steeringAngle = 0;
				wheel.hasGroundContact = false;
				wheel.hasHandbrake = true;
				-- try to load wheels from i3d
				local wheelFilename = getXMLString(xmlFile, wheelnamei .. "#wheelFilename");
				if wheelFilename ~= nil then
					wheel.wheelFilename = wheelFilename;
					wheelIndex = Utils.getNoNil(getXMLString(xmlFile, wheelnamei .. "#wheelIndex"), "0|0");
					local i3dNode = Utils.loadSharedI3DFile(wheelFilename, self.baseDirectory, false, false, false);
					if i3dNode ~= 0 then
						local loadedWheel = Utils.indexToObject(i3dNode, wheelIndex);
						link(wheel.driveNode, loadedWheel);
						delete(i3dNode);
					end;
				end;
				local vehicleNode = self.vehicleNodes[wheel.node];
				if vehicleNode ~= nil and vehicleNode.component ~= nil and vehicleNode.component.motorized == nil then
					vehicleNode.component.motorized = true;
					if lastMotorizedNode ~= nil then
						if self.isServer then
							addVehicleLink(lastMotorizedNode, vehicleNode.component.node);
						end
					end
					lastMotorizedNode = vehicleNode.component.node;
				end
				self:loadDynamicWheelDataFromXML(xmlFile, wheelnamei, wheel);
				wheel.width = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#width"), wheel.radius * 0.8);
				if g_currentMission.tyreTrackSystem ~= nil and Utils.getNoNil(getXMLBool(xmlFile, wheelnamei .. "#hasTyreTracks"), false) then
					wheel.tyreTrackIndex = g_currentMission.tyreTrackSystem:createTrack(wheel.width, Utils.getNoNil(getXMLInt(xmlFile, wheelnamei .. "#tyreTrackAtlasIndex"), 0));
				end
				wheel.xmlIndex = i;
				table.insert(self.wheels, wheel);
			end;
		elseif reloadWheel then
			self:loadDynamicWheelDataFromXML(xmlFile, wheelnamei, self.wheels[i+1]);
		else
			--print("    " .. tostring(self.wheels[i+1].frictionScale));
			self.wheels[i+1].frictionScale = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#frictionScale"), self.wheels[i+1].frictionScale);
			self:updateWheelTireFriction(self.wheels[i+1]);
			--print("    " .. tostring(self.wheels[i+1].frictionScale));
		end;
		
        i = i+1;
	end;
	if updateSteering then
		self:loadWheelsSteeringDataFromXML(xmlFile);
	else
		self:loadWheelsSteeringDataFromXML(oldXmlFile);
	end;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local numComponents = #self.components;
	self.componentMasses = {};
	for i=1, numComponents do
		local namei = string.format("vehicle.components.component%d", i);
		if not hasXMLProperty(xmlFile, namei) then
			break;
            --print("Warning: " .. namei .. " not found in '"..self.configFileName.."'");
        end;
		
		self.componentMasses[i] = getXMLFloat(xmlFile, namei .. "#mrlMass");
		
		local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, namei .. "#centerOfMass"));
        if x ~= nil and y ~= nil and z ~= nil then
            setCenterOfMass(self.components[i].node, x, y, z);
            self.components[i].centerOfMass = { x, y, z };
        end;
	end;
	
	local i=0;
	while true do
        local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i);
		local mrlType = getXMLString(xmlFile, baseName.."#mrlType");
		local mrlAddJoint = getXMLString(xmlFile, baseName.."#mrlAddJoint");
		if mrlType == nil and mrlAddJoint == nil then
			break;
		end;
        local mrlOrigJointIndex = getXMLInt(xmlFile, baseName.. "#mrlOrigJointIndex");
		local attacherJoint = self.attacherJoints[mrlOrigJointIndex];
		if mrlOrigJointIndex ~= nil and attacherJoint ~= nil then
			if mrlType == "3pt" then
				--minRot + maxRot
				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRot"));
				attacherJoint.maxRot = { math.rad(Utils.getNoNil(x, 0)), math.rad(Utils.getNoNil(y, 0)), math.rad(Utils.getNoNil(z, 0)) };

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#minRot"));
				attacherJoint.minRot = { math.rad(Utils.getNoNil(x, 0)), math.rad(Utils.getNoNil(y, 0)), math.rad(Utils.getNoNil(z, 0)) };
				
				--minRot2 + maxRot2
				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRot2"));
				attacherJoint.maxRot2 = { math.rad(Utils.getNoNil(x, 0)), math.rad(Utils.getNoNil(y, 0)), math.rad(Utils.getNoNil(z, 0)) };

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#minRot2"));
				attacherJoint.minRot2 = { math.rad(Utils.getNoNil(x, 0)), math.rad(Utils.getNoNil(y, 0)), math.rad(Utils.getNoNil(z, 0)) };
				
				--distance to ground + rotation offsets
				attacherJoint.maxRotDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#maxRotDistanceToGround"), 0.7);
				attacherJoint.minRotDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#minRotDistanceToGround"), 1.0);
				attacherJoint.maxRotRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#maxRotRotationOffset"), 0));
				attacherJoint.minRotRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#minRotRotationOffset"), 8));
				
				attacherJoint.bottomArm.translationNode = nil;
			elseif mrlType == "trailer" or mrlType == "trailerLow" then
				--rotation limit for trailer attacher joints
				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRotLimit"));
				attacherJoint.maxRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)));
				attacherJoint.maxRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)));
				attacherJoint.maxRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)));
			end;
		elseif mrlAddJoint then
			local index = getXMLString(xmlFile, baseName.. "#index");
			if index == nil then
				break;
			end;
			local object = Utils.indexToObject(self.components, index);
			if object ~= nil then
				local entry = {};
				entry.jointTransform = object;
				entry.jointOrigRot = { getRotation(entry.jointTransform) };
				entry.jointOrigTrans = { getTranslation(entry.jointTransform) };

				local jointTypeStr = getXMLString(xmlFile, baseName.. "#jointType");
				local jointType;
				if jointTypeStr ~= nil then
					jointType = Vehicle.jointTypeNameToInt[jointTypeStr];
					if jointType == nil then
						print("Warning: invalid jointType " .. jointTypeStr);
					end;
				end;
				if jointType == nil then
					jointType = Vehicle.JOINTTYPE_IMPLEMENT;
				end;
				entry.jointType = jointType;
				entry.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, baseName.."#allowsJointLimitMovement"), true);
				entry.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, baseName.."#allowsLowering"), true);

				if jointType == Vehicle.JOINTTYPE_TRAILER or jointType == Vehicle.JOINTTYPE_TRAILERLOW then
					entry.allowsLowering = false;
				end;

				self:loadPowerTakeoff(xmlFile, baseName, entry);

				entry.canTurnOnImplement = Utils.getNoNil(getXMLBool(xmlFile, baseName.."#canTurnOnImplement"), true);

				local rotationNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. "#rotationNode"));
				if rotationNode ~= nil then
					entry.rotationNode = rotationNode;
					local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRot"));
					entry.maxRot = { math.rad(Utils.getNoNil(x, 0)), math.rad(Utils.getNoNil(y, 0)), math.rad(Utils.getNoNil(z, 0)) };

					local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#minRot"));
					local rx,ry,rz = getRotation(rotationNode);
					entry.minRot = { Utils.getNoNilRad(x, rx), Utils.getNoNilRad(y, ry), Utils.getNoNilRad(z, rz) };

				end;
				local rotationNode2 = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. "#rotationNode2"));
				if rotationNode2 ~= nil then
					entry.rotationNode2 = rotationNode2;
					local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRot2"));
					entry.maxRot2 = { math.rad(Utils.getNoNil(x, 0)), math.rad(Utils.getNoNil(y, 0)), math.rad(Utils.getNoNil(z, 0)) };

					local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#minRot2"));
					local rx,ry,rz = getRotation(rotationNode2);
					entry.minRot2 = { Utils.getNoNilRad(x, rx), Utils.getNoNilRad(y, ry), Utils.getNoNilRad(z, rz) };
				end;
				entry.maxRotDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#maxRotDistanceToGround"), 0.7);
				entry.minRotDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#minRotDistanceToGround"), 1.0);
				entry.maxRotRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#maxRotRotationOffset"), 0));
				entry.minRotRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#minRotRotationOffset"), 8));


				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRotLimit"));
				entry.maxRotLimit = {};
				entry.maxRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)));
				entry.maxRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)));
				entry.maxRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)));

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#minRotLimit"));
				entry.minRotLimit = {};
				entry.minRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)));
				entry.minRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)));
				entry.minRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)));

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxTransLimit"));
				entry.maxTransLimit = {};
				entry.maxTransLimit[1] = math.abs(Utils.getNoNil(x, 0));
				entry.maxTransLimit[2] = math.abs(Utils.getNoNil(y, 0));
				entry.maxTransLimit[3] = math.abs(Utils.getNoNil(z, 0));

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#minTransLimit"));
				entry.minTransLimit = {};
				entry.minTransLimit[1] = math.abs(Utils.getNoNil(x, 0));
				entry.minTransLimit[2] = math.abs(Utils.getNoNil(y, 0));
				entry.minTransLimit[3] = math.abs(Utils.getNoNil(z, 0));

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#jointPositionOffset"));
				entry.jointPositionOffset = {};
				entry.jointPositionOffset[1] = Utils.getNoNil(x, 0);
				entry.jointPositionOffset[2] = Utils.getNoNil(y, 0);
				entry.jointPositionOffset[3] = Utils.getNoNil(z, 0);

				entry.transNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.."#transNode"));
				if entry.transNode ~= nil then
					entry.transNodeOrgTrans = {getTranslation(entry.transNode)};
					entry.transMinYHeight = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#transMinYHeight"), entry.jointOrigTrans[2]);
					entry.transMaxYHeight = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#transMaxYHeight"), entry.jointOrigTrans[2]);
				end;

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile,  baseName.."#rotLimitSpring"));
				local rotLimitSpring = { Utils.getNoNil(x, 0), Utils.getNoNil(y, 0), Utils.getNoNil(z, 0) };
				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile,  baseName.."#rotLimitDamping"));
				local rotLimitDamping = { Utils.getNoNil(x, 1), Utils.getNoNil(y, 1), Utils.getNoNil(z, 1) };
				entry.rotLimitSpring = rotLimitSpring;
				entry.rotLimitDamping = rotLimitDamping;

				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile,  baseName.."#transLimitSpring"));
				local transLimitSpring = { Utils.getNoNil(x, 0), Utils.getNoNil(y, 0), Utils.getNoNil(z, 0) };
				local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile,  baseName.."#transLimitDamping"));
				local transLimitDamping = { Utils.getNoNil(x, 1), Utils.getNoNil(y, 1), Utils.getNoNil(z, 1) };
				entry.transLimitSpring = transLimitSpring;
				entry.transLimitDamping = transLimitDamping;

				entry.moveTime = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#moveTime"), 0.5)*1000;

				entry.enableCollision = Utils.getNoNil(getXMLBool(xmlFile, baseName.."#enableCollision"), false);

				local topArmFilename = getXMLString(xmlFile, baseName.. ".topArm#filename");
				if topArmFilename ~= nil then
					local baseNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".topArm#baseNode"));
					if baseNode ~= nil then
						local i3dNode = Utils.loadSharedI3DFile(topArmFilename,self.baseDirectory, false, false, false);
						if i3dNode ~= 0 then
							local rootNode = getChildAt(i3dNode, 0);
							link(baseNode, rootNode);
							delete(i3dNode);
							setTranslation(rootNode, 0,0,0);
							local translationNode = getChildAt(rootNode, 0);
							local referenceNode = getChildAt(translationNode, 0);


							local topArm = {};
							topArm.rotationNode = rootNode;
							topArm.rotX, topArm.rotY, topArm.rotZ = 0,0,0;
							topArm.translationNode = translationNode;

							local _,_,referenceDistance = getTranslation(referenceNode);
							topArm.referenceDistance = referenceDistance;

							topArm.zScale = 1;
							local zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName.. ".topArm#zScale"), 1));
							if zScale < 0 then
								topArm.rotY = math.pi;
								setRotation(rootNode, topArm.rotX, topArm.rotY, topArm.rotZ);
							end

							if getNumOfChildren(rootNode) > 1 then
								topArm.scaleNode = getChildAt(rootNode, 1);
								local scaleReferenceNode = getChildAt(topArm.scaleNode, 0);
								local _,_,scaleReferenceDistance = getTranslation(scaleReferenceNode);
								topArm.scaleReferenceDistance = scaleReferenceDistance;
							end

							topArm.toggleVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseName.. ".topArm#toggleVisibility"), false);
							if topArm.toggleVisibility then
								setVisibility(topArm.rotationNode, false);
							end;

							entry.topArm = topArm;
						end
					end
				else
					local rotationNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".topArm#rotationNode"));
					local translationNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".topArm#translationNode"));
					local referenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".topArm#referenceNode"));
					if rotationNode ~= nil then
						local topArm = {};
						topArm.rotationNode = rotationNode;
						topArm.rotX, topArm.rotY, topArm.rotZ = getRotation(rotationNode);
						if translationNode ~= nil and referenceNode ~= nil then
							topArm.translationNode = translationNode;

							local x,y,z = getTranslation(translationNode);
							if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
								print("Warning: translation of topArm of attacherJoint "..i.." is not 0/0/0 in '"..self.configFileName.."'");
							end;
							local ax, ay, az = getWorldTranslation(referenceNode);
							local bx, by, bz = getWorldTranslation(translationNode);
							topArm.referenceDistance = Utils.vector3Length(ax-bx, ay-by, az-bz);
						end;
						topArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName.. ".topArm#zScale"), 1));
						topArm.toggleVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseName.. ".topArm#toggleVisibility"), false);
						if topArm.toggleVisibility then
							setVisibility(topArm.rotationNode, false);
						end;

						entry.topArm = topArm;
					end;
				end
				local rotationNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".bottomArm#rotationNode"));
				local translationNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".bottomArm#translationNode"));
				local referenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.. ".bottomArm#referenceNode"));
				if rotationNode ~= nil then
					local bottomArm = {};
					bottomArm.rotationNode = rotationNode;
					bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = getRotation(rotationNode);
					if translationNode ~= nil and referenceNode ~= nil then
						bottomArm.translationNode = translationNode;

						local x,y,z = getTranslation(translationNode);
						if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
							print("Warning: translation of bottomArm '"..getName(translationNode).."' of attacherJoint "..i.." is "..math.abs(x) .. "/" .. math.abs(y) .. "/" .. math.abs(z) .. "! Should be 0/0/0! ("..self.configFileName..")");
						end;
						local ax, ay, az = getWorldTranslation(referenceNode);
						local bx, by, bz = getWorldTranslation(translationNode);
						bottomArm.referenceDistance = Utils.vector3Length(ax-bx, ay-by, az-bz);
					end;
					bottomArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName.. ".bottomArm#zScale"), 1));
					entry.bottomArm = bottomArm;
				end;
				entry.rootNode = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, baseName.."#rootNode")), self.components[1].node);
				entry.jointIndex = 0;
				table.insert(self.attacherJoints, entry);
			end;
		end;
		if self.attacherJoints[i+1] ~= nil then
			self.attacherJoints[i+1].isFixed = Utils.getNoNil(getXMLBool(xmlFile, baseName.."#mrlIsFixed"), false);
		end;
		
        i = i + 1;
    end;
	
	local aiLeftMarkerPos = Utils.getVectorNFromString(getXMLString(xmlFile, "vehicle.aiLeftMarker#mrlPos"), 3);
	local aiRightMarkerPos = Utils.getVectorNFromString(getXMLString(xmlFile, "vehicle.aiRightMarker#mrlPos"), 3);
	local aiBackMarkerPos = Utils.getVectorNFromString(getXMLString(xmlFile, "vehicle.aiBackMarker#mrlPos"), 3);
	
	if self.aiLeftMarker ~= nil and aiLeftMarkerPos ~= nil then
		setTranslation(self.aiLeftMarker, aiLeftMarkerPos[1], aiLeftMarkerPos[2], aiLeftMarkerPos[3]);
	end;
	if self.aiRightMarker ~= nil and aiRightMarkerPos ~= nil then
		setTranslation(self.aiRightMarker, aiRightMarkerPos[1], aiRightMarkerPos[2], aiRightMarkerPos[3]);
	end;
	if self.aiBackMarker ~= nil and aiBackMarkerPos ~= nil then
		setTranslation(self.aiBackMarker, aiBackMarkerPos[1], aiBackMarkerPos[2], aiBackMarkerPos[3]);
	end;
	
	
	
	
	
	
	
	
	
	--print("configFileName: " .. self.configFileName);
	
	
		--local jointEntry = MrLightUtils.vehicleConfigs[self.configFileName]["attacherJoint"..tostring(i)];
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		for i,attacherJoint in ipairs(self.attacherJoints) do
			local jointNumber = "attacherJoint"..tostring(i);
			
			if MrLightUtils.vehicleConfigs[self.configFileName][jointNumber] ~= nil then
				if attacherJoint.jointType == Vehicle.JOINTTYPE_IMPLEMENT then
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
					attacherJoint.maxTransLimit = {0, 0.2, 0};
					attacherJoint.isFixed = true;
				elseif attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILERLOW or attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILER then
					local jointSettings = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName][jointNumber]);
					attacherJoint.maxRotLimit[1] = math.rad(jointSettings[1]);
					attacherJoint.maxRotLimit[2] = math.rad(jointSettings[2]);
					attacherJoint.maxRotLimit[3] = math.rad(jointSettings[3]);
				end;
			end;
		end;
		
		
	end;
	
	self.isDrivable = SpecializationUtil.hasSpecialization(Drivable, self.specializations);
	if self.isDrivable then
		self.moveLowerJointAxis1 = InputBinding.AXIS_MOVE_ATTACHERJOINT_LOWER1;
		self.moveLowerJointAxis2 = InputBinding.AXIS_MOVE_ATTACHERJOINT_LOWER2;
		self.moveUpperJointAxis1 = InputBinding.AXIS_MOVE_ATTACHERJOINT_UPPER1;
		self.moveUpperJointAxis2 = InputBinding.AXIS_MOVE_ATTACHERJOINT_UPPER2;
		--self.isSelectable = true;
		self.attacherJointMovementLocked = true;
	end;
	
	self.counter = 100;
	self.debugLowerDistanceToGround = 0;
	self.debugUpperDistanceToGround = 1.5;
	self.debugVehicleManipulation = true;
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
		if self.realSpeedLimit ~= nil then
			self.speedLimit = self.realSpeedLimit;
		end;
		
		if self.isServer then
			for i=1, #self.components do
				if self.componentMasses[i] ~= nil then
					setMass(self.components[i].node, self.componentMasses[i]);
				end;
			end;
		end;
		
		
		
		
		
		
		
		
		
		if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
			local numComponents = #self.components;
			if MrLightUtils.vehicleConfigs[self.configFileName].masses ~= nil then
				if numComponents > 1 then
					local massesT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].masses);
					if #massesT == numComponents then
						for k,v in pairs(massesT) do
							setMass(self.components[k].node, tonumber(v));
						end;
					else
						print("WARNING: number of masses in configFile not equals number of components for vehicle "..self.configFileName);
					end;
				elseif numComponents == 1 then
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
			
			if MrLightUtils.vehicleConfigs[self.configFileName].wheelsFrictionScale ~= nil then
				local wheelsFrictionScaleT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].wheelsFrictionScale);
				if #wheelsFrictionScaleT == #self.wheels then
					for k,v in pairs(self.wheels) do
						v.frictionScale = wheelsFrictionScaleT[k];
					end;
				end;
			end;
			
			if MrLightUtils.vehicleConfigs[self.configFileName].wheelsSpring ~= nil then
				local wheelsSpringT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].wheelsSpring);
				if #wheelsSpringT == #self.wheels then
					for k,v in pairs(self.wheels) do
						v.spring = wheelsSpringT[k] * 10;
						local widthBak = v.width;
						--print(widthBak);
						
						local collisionMask = 255 - 4; -- all up to bit 8, except bit 2 which is set by the players kinematic object
						
						v.wheelShape = createWheelShape(v.node, v.netInfo.x, v.netInfo.y, v.netInfo.z, v.radius, v.suspTravel, v.spring, v.damper, v.mass, collisionMask, v.wheelShape);
						v.width = widthBak;
						--print(string.format("node %d, x %.4f, y %.4f, z %.4f, radius %.4f, suspTravel %.4f, width %.4f, spring %.4f, damper %.4f, mass %.4f, collisionMask %d, wheelShape %d", v.node, v.netInfo.x, v.netInfo.y, v.netInfo.z, v.radius, v.suspTravel, v.width, v.spring, v.damper, v.mass, collisionMask, v.wheelShape));
					end;
				else
					print("WARNING: number of wheelsSpring elements not equal number of wheels for vehicle "..self.configFileName);
				end;
			end;
			
		end;
		
	end;
	
	self.counter = self.counter - 1;
	if self.counter == 0 and self.debugVehicleManipulation then
		
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
	
	if self:getIsActive() then
		for k,v in pairs (self.components) do
			local x,y,z = getCenterOfMass(v.node);
			x,y,z = localToWorld(v.node,x,y,z);
			--drawDebugPoint(x,y,z,0,1,1,1);
		end;
	end;
	
end;

function VehicleManipulation:updateTick(dt)
    if self.isActive then
        for _, implement in pairs(self.attachedImplements) do
            if implement.object ~= nil then
                local jointDesc = self.attacherJoints[implement.jointDescIndex];
                if self.isServer then
                    if jointDesc.allowsLowering and jointDesc.allowsJointLimitMovement then
                        if implement.object.attacherJoint.allowsJointTransLimitMovementMod then
                            for i=1, 3 do
                                local newTransLimit = Utils.lerp(implement.minTransLimit[i], implement.maxTransLimit[i], jointDesc.moveAlpha);
                                if math.abs(newTransLimit - implement.jointTransLimit[i]) > 0.0005 then
                                    setJointTranslationLimit(jointDesc.jointIndex, i-1, true, 0, newTransLimit);
                                    implement.jointTransLimit[i] = newTransLimit;
                                end;
                            end;
                        end;
                    end;
                end;
            end
        end;
    end;
end;

function VehicleManipulation:draw()
	if self.debugRenderVehicleManipulation and self.isDrivable and not self.attacherJointMovementLocked then
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