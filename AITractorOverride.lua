oldAITractorLoad = AITractor.load;
AITractor.load = function(self, xmlFile)
	
	oldAITractorLoad(self, xmlFile);
	
    self.aiTractorTurnRadius = getXMLFloat(xmlFile, "vehicle.aiTractorTurnRadius");
	
	if self.aiTractorTurnRadius == nil then
		--try to compute the turn radius
		--if self.realNbWheels == 4 then
			local sumRot = 0;
			local divider = 0;
			
			for k, wheel in pairs(self.wheels) do
				local rot = math.min(math.abs(wheel.rotMax), math.abs(wheel.rotMin));
				if rot>0 then
					divider = divider + 1;
					sumRot = sumRot + rot;
				end;					
			end;
			
			if sumRot>0 then
				local avgRot = sumRot / divider;
				--local cosValue = math.cos(0.5*math.pi - avgRot);					
				local tanValue = math.tan(avgRot);
				
				if tanValue>0 then
					--computing the wheelbase
					local x1,_,z1 = getTranslation(self.wheels[1].repr);
					local x2,_,z2 = getTranslation(self.wheels[2].repr);
					local x3,_,z3 = getTranslation(self.wheels[3].repr);
					local wheelBase = math.max(math.abs(z1-z2), math.abs(z1-z3));						
					local axleWidth = 2*math.max(math.abs(x3), math.max(math.abs(x1), math.abs(x2)));
					
					--print("tanValue = " .. tostring(tanValue));
					--print("wheelBase = " .. tostring(wheelBase));
					
					if wheelBase>0 then
						self.aiTractorTurnRadius = wheelBase/tanValue; 
						local margin = 7.5/self.aiTractorTurnRadius*0.5*axleWidth; -- to take into account the tyre width, the uneven ground, slippage and slow turning speed worker
						self.aiTractorTurnRadius = self.aiTractorTurnRadius + margin;
						--print(self.realVehicleName .. " turnradius = " .. tostring(self.aiTractorTurnRadius) .. " wheelbase="..tostring(wheelBase) .. " axleWidth=" .. tostring(axleWidth));
					end;
				end;
			end;
		--end;
		if self.aiTractorTurnRadius == nil then				
			self.aiTractorTurnRadius = 6.5; -- default value			
		end;
	end;
	
	
	if self.maxTurningRadius == nil or self.maxTurningRadius == 0 then
		self.maxTurningRadius = 6.5;
	end;
	-- print("self.maxTurningRadius: " .. self.maxTurningRadius .. ", self.aiTractorTurnRadius: " .. self.aiTractorTurnRadius);
	
	
	self.realTurnStage2Step = 0;
	self.realAiTurnStage2Step0TargetTurningCircleX=nil;
	self.realAiTurnStage2Step0TargetTurningCircleZ=nil;
	self.realAiBackMarkerToDirectionNodeDistance = 0;
	
	
    self.aiTurnWidthScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnWidthScale#value"), 0.95); --5% overlap
    self.aiTurnWidthMaxDifference = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnWidthMaxDifference#value"), 0.25); -- do at most a 0.25m overlap


end;

AITractor.updateAIMovement = function(self, dt)

    if not self.isControlled then
        if g_currentMission.environment.needsLights then
            self:setLightsVisibility(true);
        else
            self:setLightsVisibility(false);
        end;
    end;

	--print(self.turnStage);
    local allowedToDrive = true;
    for _,v in pairs(self.numCollidingVehicles) do
        if v > 0 then
            allowedToDrive = false;
            break;
        end;
    end;
    --if self.turnStage > 0 then
        if self.waitForTurnTime > g_currentMission.time then
            allowedToDrive = false;
        end;
    --end;
    if not allowedToDrive then
        self.isHirableBlocked = true;
        --local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
        --local lx, lz = 0, 1; --AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, self.aiTractorTargetX, y, self.aiTractorTargetZ);
        --AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, lx, lz)
        AIVehicleUtil.mrlDriveInDirection(self, dt, 0, false, moveForwards);
        return;
    end;
    self.isHirableBlocked = false;

    local maxSpeed,_ = self:getSpeedLimit();
    maxSpeed = math.min(maxSpeed, self.cruiseControl.speed);
    if self.turnStage > 0 then
        maxSpeed = math.max(8, maxSpeed / 2);
    end;

    if not self:getIsAITractorAllowed() then
        self:stopAITractor();
        return;
    end;
	
	--added bassaddict
	--if self.waitForTurnTime > g_currentMission.time then
	--	allowedToDrive = false;
	--end;


    -- Seeding:
    --      Required: Cultivated, Ploughed
    -- Direct Planting:
    --      Required: Seeded, Cultivated, Ploughed without Fruit of current type
    -- Forage Wagon:
    --      Required: Windrow of current type
    -- Spray:
    --      Required: Seeded, Cultivated, Ploughed without Sprayed
    -- Mower:
    --      Required: Fruit of type grass

    local leftMarker = self.aiCurrentLeftMarker;
    local rightMarker = self.aiCurrentRightMarker;
    local backMarker = self.aiCurrentBackMarker;
    local groundInfoObject = self.aiCurrentGroundInfoObject;

    local terrainDetailRequiredMask = 0;
    if groundInfoObject.aiTerrainDetailChannel1 >= 0 then
        terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel1);
        if groundInfoObject.aiTerrainDetailChannel2 >= 0 then
            terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel2);
            if groundInfoObject.aiTerrainDetailChannel3 >= 0 then
                terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel3);
                if groundInfoObject.aiTerrainDetailChannel4 >= 0 then
                    terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel4);
                end
            end
        end
    end

    local terrainDetailProhibitedMask = groundInfoObject.aiTerrainDetailProhibitedMask;
    local requiredFruitType = groundInfoObject.aiRequiredFruitType;
    local requiredMinGrowthState = groundInfoObject.aiRequiredMinGrowthState;
    local requiredMaxGrowthState = groundInfoObject.aiRequiredMaxGrowthState;
    local prohibitedFruitType = groundInfoObject.aiProhibitedFruitType;
    local prohibitedMinGrowthState = groundInfoObject.aiProhibitedMinGrowthState;
    local prohibitedMaxGrowthState = groundInfoObject.aiProhibitedMaxGrowthState;


    local newTargetX, newTargetY, newTargetZ;

    local moveForwards = true;
    local updateWheels = true;

    self.turnTimer = self.turnTimer - dt;

    self.lastArea = 0;

    if self.turnTimer < 0 or self.turnStage > 0 then
        if self.turnStage > 1 then
            local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
            local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
            local myDirX, myDirY, myDirZ = localDirectionToWorld(self.aiTractorDirectionNode, 0, 0, 1);

            newTargetX = self.aiTractorTargetX;
            newTargetY = y;
            newTargetZ = self.aiTractorTargetZ;
            if self.turnStage == 2 then
                self.turnStageTimer = self.turnStageTimer - dt;
                --if myDirX*dirX + myDirZ*dirZ > 0.2 or self.turnStageTimer < 0 then
				if myDirX*dirX + myDirZ*dirZ > -0.1 or self.turnStageTimer < 0 then
                    if self.aiTurnNoBackward then
                        self.turnStage = 4;
                    else
                        self.turnStage = 3;
                        moveForwards = false;
						self.waitForTurnTime = g_currentMission.time + 1200; --TODO: dynamic
                    end;
                    if self.turnStageTimer < 0 then

                        self.aiTractorTargetBeforeSaveX = self.aiTractorTargetX;
                        self.aiTractorTargetBeforeSaveZ = self.aiTractorTargetZ;

                        newTargetX = self.aiTractorTargetBeforeTurnX;
                        newTargetZ = self.aiTractorTargetBeforeTurnZ;

                        moveForwards = false;
                        self.turnStage = 6;
                        self.turnStageTimer = self.turnStage6Timeout;
                    else
                        self.turnStageTimer = self.turnStage3Timeout;
                    end;
                end;
            elseif self.turnStage == 3 then
				
                self.turnStageTimer = self.turnStageTimer - dt;
				moveForwards = false;
                --if myDirX*dirX + myDirZ*dirZ > 0.95 or self.turnStageTimer < 0 then
				if myDirX*dirX + myDirZ*dirZ > 0.7 then
					local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
					local distance = Utils.vector2Length(newTargetX - x, newTargetZ - z);
                    self.turnStage = 4;
					if distance > 6 or self.turnStageTimer < 0 then
						self.turnStage = 4;
						moveForwards = true;	
						self.waitForTurnTime = g_currentMission.time + 1200; --TODO: dynamic							
					end;
                end;
            elseif self.turnStage == 4 then
                local dx, dz = x-newTargetX, z-newTargetZ;
                local dot = dx*dirX + dz*dirZ;
                if -dot < self.turnEndDistance then
                    --newTargetX = self.aiTractorTargetX + dirX*(self.turnTargetMoveBack + self.aiToolExtraTargetMoveBack);
					newTargetX = self.aiTractorTargetX + dirX*(self.realAiBackMarkerToDirectionNodeDistance+1);
                    newTargetY = y;
                    --newTargetZ = self.aiTractorTargetZ + dirZ*(self.turnTargetMoveBack + self.aiToolExtraTargetMoveBack);
					newTargetZ = self.aiTractorTargetZ + dirZ*(self.realAiBackMarkerToDirectionNodeDistance+1);
                    self.turnStage = 5;
                    --print("turning done");
                end;
            elseif self.turnStage == 5 then
                local backX, backY, backZ = getWorldTranslation(backMarker);
                local dx, dz = backX-newTargetX, backZ-newTargetZ;
                local dot = dx*dirX + dz*dirZ;
                if -dot < self.realAiBackMarkerToDirectionNodeDistance+2 then
                    self.turnTimer = self.turnTimeoutLong;
                    self.turnStage = 0;
                    self:setAIImplementsMoveDown(true);
                    self.waitForTurnTime = g_currentMission.time + self.waitForTurnTimeout;
                    AITractor.updateInvertLeftRight(self);
                    leftMarker = self.aiCurrentLeftMarker;
                    rightMarker = self.aiCurrentRightMarker;
                    --print("turning done");
                end;
            elseif self.turnStage == 6 then
                self.turnStageTimer = self.turnStageTimer - dt;
                if self.turnStageTimer < 0 then
                    self.turnStageTimer = self.turnStage2Timeout;
                    self.turnStage = 2;

                    newTargetX = self.aiTractorTargetBeforeSaveX;
                    newTargetZ = self.aiTractorTargetBeforeSaveZ;
                else
                    local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
                    local dirX, dirZ = -self.aiTractorDirectionX, -self.aiTractorDirectionZ;
                    -- just drive along direction
                    local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ;
                    local dx, dz = x-targetX, z-targetZ;
                    local dot = dx*dirX + dz*dirZ;

                    local projTargetX = targetX +dirX*dot;
                    local projTargetZ = targetZ +dirZ*dot;

                    newTargetX = projTargetX-dirX*self.aiTractorLookAheadDistance;
                    newTargetZ = projTargetZ-dirZ*self.aiTractorLookAheadDistance;
                    moveForwards = false;
                end;
            end;
        elseif self.turnStage == 1 then
            -- turn
            AITractor.updateInvertLeftRight(self);
            leftMarker = self.aiCurrentLeftMarker;
            rightMarker = self.aiCurrentRightMarker;

            local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
            local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
            local sideX, sideZ = -dirZ, dirX;
            local lX,  lY,  lZ = getWorldTranslation(leftMarker);
            local rX,  rY,  rZ = getWorldTranslation(rightMarker);

            local markerWidth = Utils.vector2Length(lX-rX, lZ-rZ);

            local lWidthX = lX + dirX * self.sideWatchDirOffset;
            local lWidthZ = lZ + dirZ * self.sideWatchDirOffset;
            local lStartX = lWidthX - sideX*0.7*markerWidth;
            local lStartZ = lWidthZ - sideZ*0.7*markerWidth;
            local lHeightX = lStartX + dirX*self.sideWatchDirSize;
            local lHeightZ = lStartZ + dirZ*self.sideWatchDirSize;

            local rWidthX = rX + dirX * self.sideWatchDirOffset;
            local rWidthZ = rZ + dirZ * self.sideWatchDirOffset;
            local rStartX = rWidthX + sideX*0.7*markerWidth;
            local rStartZ = rWidthZ + sideZ*0.7*markerWidth;
            local rHeightX = rStartX + dirX*self.sideWatchDirSize;
            local rHeightZ = rStartZ + dirZ*self.sideWatchDirSize;

            local leftArea, leftAreaTotal = AITractor.getAIArea(self, lStartX, lStartZ, lWidthX, lWidthZ, lHeightX, lHeightZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)
            local rightArea, rightAreaTotal = AITractor.getAIArea(self, rStartX, rStartZ, rWidthX, rWidthZ, rHeightX, rHeightZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)

            -- turn to where ground/fruit is to be changed

            local leftOk = (leftArea > 0 and leftArea > 0.15*leftAreaTotal);
            local rightOk = (rightArea > 0 and rightArea > 0.15*rightAreaTotal);

            if self.aiTractorTurnLeft == nil then
                if leftOk or rightOk then
                    if leftArea > rightArea then
                        self.aiTractorTurnLeft = true;
                    else
                        self.aiTractorTurnLeft = false;
                    end
                else
                    self:stopAITractor();
                    return;
                end;
            else
                self.aiTractorTurnLeft = not self.aiTractorTurnLeft;
                if (self.aiTractorTurnLeft and not leftOk) or (not self.aiTractorTurnLeft and not rightOk) then
                    self:stopAITractor();
                    return;
                end
            end

            local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ;
            --[[local x = (lX+rX)/2;
            local z = (lZ+rZ)/2;
            local markerSideOffset, lY, lZ = worldToLocal(self.aiTractorDirectionNode, x, (lY+rY)/2, z);
            markerSideOffset = math.abs(markerSideOffset);
            local dx, dz = x-targetX, z-targetZ;
            local dot = dx*dirX + dz*dirZ;
            local x, z = targetX + dirX*dot, targetZ + dirZ*dot;]]
            markerWidth = math.max(markerWidth*self.aiTurnWidthScale, markerWidth-self.aiTurnWidthMaxDifference); -- - markerSideOffset;

            local invertsMarker = AITractor.invertsMarkerOnTurn(self, self.aiTractorTurnLeft);
            if not invertsMarker then
                -- if not inverting, we need to adjust the markerWidth
                local mx = (lX+rX)*0.5;
                local mz = (lZ+rZ)*0.5;
                local markerSideOffset, _, _ = worldToLocal(self.aiTractorDirectionNode, mx, (lY+rY)*0.5, mz);
                --markerSideOffset = math.abs(markerSideOffset);
                markerWidth = markerWidth + markerSideOffset;
                --local dx, dz = x-targetX, z-targetZ;
                --local dot = dx*dirX + dz*dirZ;
                --local x, z = targetX + dirX*dot, targetZ + dirZ*dot;]]
            end;


            --local backX, backY, backZ = getWorldTranslation(backMarker);
            local projTargetLX, projTargetLZ = Utils.projectOnLine(lX, lZ, targetX, targetZ, dirX, dirZ)
            local projTargetRX, projTargetRZ = Utils.projectOnLine(rX, rZ, targetX, targetZ, dirX, dirZ)

            x = (projTargetLX+projTargetRX)*0.5;
            z = (projTargetLZ+projTargetRZ)*0.5;

            local _, _, localZ = worldToLocal(self.aiTractorDirectionNode, x, (lY+rY)*0.5, z);
            self.aiToolExtraTargetMoveBack = math.max(-localZ, 0);

			--**************************************************************
			--20140424 - look at the ai back marker distance
			local backX, backY, backZ = getWorldTranslation(backMarker);
			local projAiBackMarkerX, projAiBackMarkerZ = Utils.projectOnLine(backX, backZ, targetX, targetZ, dirX, dirZ);
			local _, _, localZ2 = worldToLocal(self.aiTractorDirectionNode, projAiBackMarkerX, y, projAiBackMarkerZ);
            self.realAiBackMarkerToDirectionNodeDistance = math.max(-localZ2, 0);
			--*************************************************************

            if self.aiTractorTurnLeft then
                newTargetX = x-sideX*markerWidth;
                newTargetY = y;
                newTargetZ = z-sideZ*markerWidth;
                AITractor.aiRotateLeft(self, true);
            else
                newTargetX = x+sideX*markerWidth;
                newTargetY = y;
                newTargetZ = z+sideZ*markerWidth;
                AITractor.aiRotateRight(self, true);
            end;
            local aiForceTurnNoBackward = false;
            for _,implement in pairs(self.attachedImplements) do
                if implement.object.aiForceTurnNoBackward then
                    aiForceTurnNoBackward = true;
                    break;
                end;
            end;
			
            self.aiTurnNoBackward = (markerWidth >= 2*self.maxTurningRadius) or aiForceTurnNoBackward;

            self.aiTractorTargetBeforeTurnX = self.aiTractorTargetX;
            self.aiTractorTargetBeforeTurnZ = self.aiTractorTargetZ;

            self.aiTractorDirectionX = -dirX;
            self.aiTractorDirectionZ = -dirZ;

            self.turnStage = 2;
            self.turnStageTimer = self.turnStage2Timeout;

            if self.aiTractorTurnLeft then
                --print("turning left ", markerWidth);
            else
                --print("turning right ", markerWidth);
            end;
        else
			if self.turnTimer < -400 then
				self.turnStage = 1;
				self:setAIImplementsMoveDown(false);
				self.waitForTurnTime = g_currentMission.time + self.waitForTurnTimeout;
			end;
			allowedToDrive = false;
            --updateWheels = false;
            self.hasSeenValidArea = false;
        end;
    else
        local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
        local lX,  lY,  lZ = getWorldTranslation(leftMarker);
        local rX,  rY,  rZ = getWorldTranslation(rightMarker);
        self.lastFrontMarkerDistance = self.lastSpeed*self.turnTimeout;
        local scaledDistance = self.lastFrontMarkerDistance*self.frontMarkerDistanceScale
        local lX2 = lX + dirX*scaledDistance;
        local lZ2 = lZ + dirZ*scaledDistance;

        local rX2 = rX + dirX*scaledDistance;
        local rZ2 = rZ + dirZ*scaledDistance;

        local heightX = lX2 + dirX*2;
        local heightZ = lZ2 + dirZ*2;

        local area = AITractor.getAIArea(self, lX2, lZ2, rX2, rZ2, heightX, heightZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState);

        self.lastArea = area;

        local fieldIsOwned = g_currentMission:getIsFieldOwnedAtWorldPos((lX+rX)/2, (lZ+rZ)/2);

        if area >= 1 and fieldIsOwned then
            self.turnTimer = math.max(self.turnTimer, self.turnTimeout);
            self.hasSeenValidArea = true;
        elseif area == 0 and self.hasSeenValidArea then
            self.turnTimer = math.min(self.turnTimer, self.turnTimeout);
        end;

        if not fieldIsOwned then
            self:stopAITractor();
            return;
        end;

        local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
        local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
        -- just drive along direction
        local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ;
        local dx, dz = x-targetX, z-targetZ;
        local dot = dx*dirX + dz*dirZ;

        local projTargetX = targetX +dirX*dot;
        local projTargetZ = targetZ +dirZ*dot;

        --print("old target: "..targetX.." ".. targetZ .. " distOnDir " .. dot.." proj: "..projTargetX.." "..projTargetZ);

        newTargetX = projTargetX+self.aiTractorDirectionX*self.aiTractorLookAheadDistance;
        newTargetY = y;
        newTargetZ = projTargetZ+self.aiTractorDirectionZ*self.aiTractorLookAheadDistance;
        --print(distOnDir.." target: "..newTargetX.." ".. newTargetZ);

        --check if tool is folded/unfolded
        for _,implement in pairs(self.attachedImplements) do
            if implement.object ~= nil then
                --if implement.object.turnOnFoldDirection ~= nil and implement.object.turnOnFoldDirection ~= 0 then
                if implement.object.getIsInWorkPosition ~= nil then
                    updateWheels = updateWheels and implement.object:getIsInWorkPosition();
                end;
            end;
        end;
        if updateWheels then
            self:setAIImplementsMoveDown(true);
            for _,implement in pairs(self.attachedImplements) do
                if implement.object ~= nil then
                    if implement.object.attacherJoint.needsLowering and implement.object.aiNeedsLowering then
                        local jointDesc = self.attacherJoints[implement.jointDescIndex];
                        if jointDesc.moveAlpha ~= jointDesc.lowerAlpha then
                            updateWheels = false;
                            self:setJointMoveDown(implement.jointDescIndex, true, true);
                        else
                            updateWheels = updateWheels and true;
                        end;
                    end;
                end;
            end;
        end;

        if updateWheels then
            for _,implement in pairs(self.attachedImplements) do
                if implement.object ~= nil and implement.object.getIsTurnedOn ~= nil and not implement.object:getIsTurnedOn() and implement.object:getIsTurnedOnAllowed(true) then
                    implement.object:aiTurnOn();
                    updateWheels = updateWheels and implement.object:getIsTurnedOn();
                end;
            end;
        end;

        if not updateWheels then
            --local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, newTargetX, newTargetY, newTargetZ);
            --AIVehicleUtil.driveInDirection(self, dt, 25, 1.0, 0.5, 20, false, moveForwards, lx, lz, 0, 1.0);
            self.turnTimer = math.max(self.turnTimer, self.turnTimeout);
        end;

    end;

    if updateWheels then
        local lx, lz = 0, 0;
		
		if moveForwards then
			lx, lz = AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, newTargetX, newTargetY, newTargetZ);
			lx, lz = AITractor.realGetDriveDirectionFix(self, lx, lz, newTargetX, newTargetZ);
			--print("lx: ", lx, ", lz: ", lz);
		else
			--setting a target point behind the tractor
			local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
			local distance = Utils.vector2Length(newTargetX - x, newTargetZ - z);
			
			local x2,z2 = Utils.projectOnLine(x, z, newTargetX, newTargetZ, self.aiTractorDirectionX, self.aiTractorDirectionZ)
			
			local reverseTargetX, reverseTargetY, reverseTargetZ = x2-2*self.aiTractorDirectionX, newTargetY, z2-2*self.aiTractorDirectionZ;			
			lx, lz = AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, reverseTargetX, reverseTargetY, reverseTargetZ);
			
		end;
		

        --[[if self.turnStage == 3 and math.abs(lx) < 0.1 then
            self.turnStage = 4;
            moveForwards = true;
        end;]]

		if allowedToDrive then
			AIVehicleUtil.mrlDriveInDirection(self, dt, 1, true, moveForwards, lx, lz, maxSpeed);
		else
			AIVehicleUtil.mrlDriveInDirection(self, dt, 0, false, moveForwards, lx, lz);
		end;

        --local maxAngle = 0.785398163; --45°;
        local maxlx = 0.7071067; --math.sin(maxAngle);
        local colDirX = lx;
        local colDirZ = lz;

        if colDirX > maxlx then
            colDirX = maxlx;
            colDirZ = 0.7071067; --math.cos(maxAngle);
        elseif colDirX < -maxlx then
            colDirX = -maxlx;
            colDirZ = 0.7071067; --math.cos(maxAngle);
        end;

        for triggerId,_ in pairs(self.numCollidingVehicles) do
            AIVehicleUtil.setCollisionDirection(self.aiTractorDirectionNode, triggerId, colDirX, colDirZ);
        end;
    end;

    if newTargetX ~= nil and newTargetZ ~= nil then
        self.aiTractorTargetX = newTargetX;
        self.aiTractorTargetZ = newTargetZ;
    end;
end;






AITractor.realGetDriveDirectionFix = function(self, lx, lz, targetX, targetZ)
	if self.aiTurnNoBackward then
		if self.turnStage==0 then
			--print("reset");
			--resetting variables for next maneuver
			self.realTurnStage2Step = 0;
			self.realAiTurnStage2Step0TargetTurningCircleX=nil;
			self.realAiTurnStage2Step0TargetTurningCircleZ=nil;
		end;
		if self.realAiTurnStage2Step0TargetTurningCircleX~=nil then
			local ty = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.realAiTurnStage2Step0TargetTurningCircleX, 0, self.realAiTurnStage2Step0TargetTurningCircleZ);
			--drawDebugPoint(self.realAiTurnStage2Step0TargetTurningCircleX,ty+0.5,self.realAiTurnStage2Step0TargetTurningCircleZ,1,1,1,1);
			--print("draw debug, x: ", self.realAiTurnStage2Step0TargetTurningCircleX, ", y: ", ty, ", z: ", self.realAiTurnStage2Step0TargetTurningCircleZ);
		end;
		if self.turnStage==2 then
			--print("ts2");
			local myDirX, myDirY, myDirZ = localDirectionToWorld(self.aiTractorDirectionNode, 0, 0, 1);	
			if self.realTurnStage2Step==0 then
				--print("rts2s 0");
				--set the center point of the turning circle when the tractor is at the final target position (turning circle at the opposite side from where the tractor started its turning stage)
				if self.realAiTurnStage2Step0TargetTurningCircleX==nil then	
					local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
					local sideX, sideZ = -self.aiTractorDirectionZ, self.aiTractorDirectionX;
					if self.aiTractorTurnLeft then
						-- 0.9 factor for aiToolExtraTargetMoveBack because we loose some time (and distance) when rotating the wheels
						self.realAiTurnStage2Step0TargetTurningCircleX = targetX+sideX*self.maxTurningRadius + self.aiTractorDirectionX*self.aiToolExtraTargetMoveBack*0.9; -- side offset and then longitudinal offset	 
							--print("targetX: "..targetX.." sideX: "..sideX.." self.maxTurningRadius: "..self.maxTurningRadius.." self.aiTractorDirectionX: "..self.aiTractorDirectionX.." self.aiToolExtraTargetMoveBack: "..self.aiToolExtraTargetMoveBack);
							
						self.realAiTurnStage2Step0TargetTurningCircleZ = targetZ+sideZ*self.maxTurningRadius + self.aiTractorDirectionZ*self.aiToolExtraTargetMoveBack*0.9; -- side offset and then longitudinal offset 
							--print("targetZ: "..targetZ.." sideZ: "..sideZ.." self.maxTurningRadius: "..self.maxTurningRadius.." self.aiTractorDirectionZ: "..self.aiTractorDirectionZ.." self.aiToolExtraTargetMoveBack: "..self.aiToolExtraTargetMoveBack);
					else							
						self.realAiTurnStage2Step0TargetTurningCircleX = targetX-sideX*self.maxTurningRadius + self.aiTractorDirectionX*self.aiToolExtraTargetMoveBack*0.9; -- side offset and then longitudinal offset  
							--print("targetX: "..targetX.." sideX: "..sideX.." self.maxTurningRadius: "..self.maxTurningRadius.." self.aiTractorDirectionX: "..self.aiTractorDirectionX.." self.aiToolExtraTargetMoveBack: "..self.aiToolExtraTargetMoveBack);
							
						self.realAiTurnStage2Step0TargetTurningCircleZ = targetZ-sideZ*self.maxTurningRadius + self.aiTractorDirectionZ*self.aiToolExtraTargetMoveBack*0.9; -- side offset and then longitudinal offset  
							--print("targetZ: "..targetZ.." sideZ: "..sideZ.." self.maxTurningRadius: "..self.maxTurningRadius.." self.aiTractorDirectionZ: "..self.aiTractorDirectionZ.." self.aiToolExtraTargetMoveBack: "..self.aiToolExtraTargetMoveBack);
					end;
				end;
				

				local steeringWantedDir = -1;
				if self.aiTractorTurnLeft then
					steeringWantedDir = 1;
				end;
				--set the center point of the current turning circle (turning circle at the side where the final target is)
				local turningCircleX,_,turningCircleZ = localToWorld(self.aiTractorDirectionNode, steeringWantedDir*self.maxTurningRadius, 0, 0);
				local minDistance = 1.15*3*self.maxTurningRadius;--5% more since there can be slippage or the ground is not even
				
				local distance = Utils.vector2Length(turningCircleX-self.realAiTurnStage2Step0TargetTurningCircleX, turningCircleZ-self.realAiTurnStage2Step0TargetTurningCircleZ);
				
				
				--take into account current vehicle position and turning radius
				--cos angle between "tractor direction" and -targetDirection = scalar
				--local cosAngle = myDirX*-self.aiTractorDirectionX + myDirZ*-self.aiTractorDirectionZ;					
				--projected distance because of the current tractor direction that would require extra turning to return back to the correct position
				--distance = distance + self.aiTractorTurnRadius * 3*(1-cosAngle);
				--print("distance: ", distance, ", minDistance: ", minDistance);
				if distance>minDistance then
					-- minDistance reach
					self.realTurnStage2Step = 1;
				else
					--turn the wheel to the opposite side to get a better turn radius after									
					if self.aiTractorDirectionX*myDirX + self.aiTractorDirectionZ*myDirZ > -0.7 then --about 45°
						--move in a straight line to move away
						lx = 0;
						lz = 1;						
					else
						--turn to the opposite side (compared to the targetX,targetZ point) until we are at 45° compared to the target direction
						lz = 0;
						lx = 1;
						if self.aiTractorTurnLeft then
							lx = -1;
						end;
					end;
				end;
			end;
			
			if self.realTurnStage2Step==1 then
				--print("rts2s 1");
				lz = 0;
				lx = -1;
				if self.aiTractorTurnLeft then
					lx = 1;
				end;	

				--if we are perpendicular to the target direction vector, just move in a straight line to reach the line that goes through the direction vector
				if math.abs(self.aiTractorDirectionX*myDirX + self.aiTractorDirectionZ*myDirZ) < 0.1 then
					self.realTurnStage2Step = 2;
				end;			
					
			end; -- end turn stage 2 step 1
			if self.realTurnStage2Step == 2 then
				--print("rts2s 2");
				local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);	
				local normU = Utils.vector2Length(self.aiTractorDirectionX, self.aiTractorDirectionZ);
				local normCrossProd = math.abs((z-targetZ)*self.aiTractorDirectionX - (x-targetX)*self.aiTractorDirectionZ); 
				local distance = normCrossProd/normU;
				
				if distance<self.turnEndDistance/Utils.clamp(0.25*self.aiToolExtraTargetMoveBack, 1, 2) then
					self.turnStage=4;
				else
					--straight line						
					lx = 0;
					lz = 1;	
				end;
			
			end; -- end turn stage 2 step 3
			
			lz = math.max(0, lz);
				
		end; -- end turn stage 2
		if self.turnStage==4 or self.turnStage==5 then
			--we want to target the std target point with some offset function of tractor direction and distance from the std target point
			local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);	
			local newTargetX =  2*targetX - x;
			local newTargetZ =  2*targetZ - z;
			local dist = 0.66*Utils.vector2Length(targetX - x, targetZ - z);
			newTargetX = newTargetX - self.aiTractorDirectionX*dist;
			newTargetZ = newTargetZ - self.aiTractorDirectionZ*dist;
			lx, lz = AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, newTargetX, y, newTargetZ);
		
		end; -- end turn stage 4
					
	end;
	return lx,lz;
end;






AIVehicleUtil.mrlDriveInDirection = function(self, dt, acceleration, allowedToDrive, moveForwards, lx, lz, speedLevel)

	local angle = 0;
	if lx ~= nil and lz ~= nil then
	
		if not moveForwards then
			lz = -lz;
		end;
		
		angle = math.deg(math.acos(lz));
		if angle < 0 then
			angle = 90;
		end;

		local turnLeft = lx > 0.00001;
		
		local targetRotTime = 0;
		

		if turnLeft then
			--rotate to the left
			targetRotTime = self.maxRotTime
			if self.maxRotation>0 then
				targetRotTime = targetRotTime*math.min(angle/math.deg(self.maxRotation), 1);
			end;
		else
			--rotate to the right
			targetRotTime = self.minRotTime;
			if self.maxRotation>0 then
				targetRotTime = targetRotTime*math.min(angle/math.deg(self.maxRotation), 1);
			end;
		end;
		
		if targetRotTime > self.rotatedTime then
			self.rotatedTime = math.min(self.rotatedTime + dt*self.aiSteeringSpeed, targetRotTime);
		else
			self.rotatedTime = math.max(self.rotatedTime - dt*self.aiSteeringSpeed, targetRotTime);
		end;
	end

	

	if self.firstTimeRun then
		local acc = acceleration;
		if speedLevel ~= nil and speedLevel ~= 0 then					
			self.motor:setSpeedLimit(speedLevel);
			if self.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
                self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE);
            end;
		else
			acc = acceleration / 2;
		end;		
		if not moveForwards then
			acc = -acc;
		end;
		if not allowedToDrive then
			acc = 0;
		end;
		WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal, acc, not allowedToDrive, self.requiredDriveMode);
	end;
	
end;