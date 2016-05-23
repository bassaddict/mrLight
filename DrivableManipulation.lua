DrivableManipulation = {};

function DrivableManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations);
end;

function DrivableManipulation:load(xmlFile)
	self.collectMaxRpm = false;
	self.collected = false;
	self.collectedInput = "";
	--self.firstRunDrivableManipulation = true;
	
	self.toggleDifferentialLock = DrivableManipulation.toggleDifferentialLock;
	self.inRange = DrivableManipulation.inRange;
	
	
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
	
	
	
	
	self.debugRenderDrivableManipulation = true;
end;

function DrivableManipulation:delete()
end;

function DrivableManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DrivableManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function DrivableManipulation:update(dt)
	
	
	
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
		
		v.slip = self:inRange((1 - (v.distPerSecond / (math.abs(v.rotPerSecond) * (v.radius * 2 * math.pi)))), -1, 1);
		if v.rotPerSecond == 0 and v.distPerSecond == 0 then v.slip = 0 end;
		v.slipDisplay = (v.slipDisplay * 0.95) + (v.slip * 0.05);
		self.slip = self.slip + v.slipDisplay;
		--local a, b, c = getTranslation(v.driveNode)
		--local x1,y1,z1 = worldToLocal(v.driveNode, x, y, z);
		--print(x1, " ", y1, " ", z1);
		
		local a, b, c = worldToLocal(v.node, getWorldTranslation(v.driveNode));
		self.wheelsGroundContactPos[k] = {localToWorld(v.node, a, b-v.radius, c)};
		
	end;
	self.slip = self:inRange((self.slip / self.numWheels), -1, 1);
	
	
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
	self.anglePercentFrontBack = 100 / math.sqrt(math.pow(distFrontBack, 2) - math.pow(yDifFrontBack, 2)) * yDifFrontBack;
end;

function DrivableManipulation:toggleDifferentialLock()
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
end;

function DrivableManipulation:draw()
	if self.debugRenderDrivableManipulation then
		setTextAlignment(RenderText.ALIGN_LEFT);
		renderText(0.85, 0.01, 0.012, string.format("slip: %.3f, incline X: %.3f, incline Z: %.3f", self.slip*100, self.anglePercentLeftRight, self.anglePercentFrontBack));
		setTextAlignment(RenderText.ALIGN_RIGHT);
		
		local i = 0;
		for k,v in pairs(self.wheels) do
			i = i + 0.01;
			--local engineSlip = getWheelShapeSlip(self.rootNode, k);
			--renderText(0.8, i, 0.012, string.format("r/s: %02.2f, m/s: %02.2f, slip: %02.2f, slipDisplay: %02.2f,", v.rotPerSecond, v.distPerSecond, v.slip*100, v.slipDisplay*100));
			renderText(0.8, i, 0.012, string.format("slip: %02.2f, slipDisplay: %02.2f,", v.slip*100, v.slipDisplay*100));
		end;
	end;
	setTextAlignment(RenderText.ALIGN_LEFT);
end;

function DrivableManipulation:inRange(value, lower, upper)
	return math.max(lower, math.min(value, upper));
end;
