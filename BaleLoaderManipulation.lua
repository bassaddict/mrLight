BaleLoaderManipulation = {};

function BaleLoaderManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(BaleLoader, specializations);
end;

function BaleLoaderManipulation:load(xmlFile)
	self.lastFillLevel = self.fillLevel;
	self.debugRenderBaleLoaderManipulation = false;
end;

function BaleLoaderManipulation:delete()
end;

function BaleLoaderManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BaleLoaderManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function BaleLoaderManipulation:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	return BaseMission.VEHICLE_LOAD_OK;
end;

function BaleLoaderManipulation:getSaveAttributesAndNodes(nodeIdent)
end;

function BaleLoaderManipulation:update(dt)
end;

function BaleLoaderManipulation:draw()
end;




local oldBaleLoaderLoad = BaleLoader.load;
BaleLoader.load = function(self, xmlFile)
	if oldBaleLoaderLoad ~= nil then
		oldBaleLoaderLoad(self, xmlFile)
	end;
	self.myCounter = 2;
end;

local oldBaleLoaderUpdate = BaleLoader.update;
BaleLoader.update = function(self, dt)
	if oldBaleLoaderUpdate ~= nil then
		oldBaleLoaderUpdate(self, dt)
	end;
	if self.myCounter > 0 then
		self.myCounter = self.myCounter - 1;
		if self.myCounter == 0 then
			self.myCurrentMass = self.emptyMass;
			--print("self.myCurrentMass: " .. tostring(self.myCurrentMass));
		end;
	end;
end;

function BaleLoader:doStateChange(id, nearestBaleServerId)
    if id == BaleLoader.CHANGE_DROP_BALES then
        -- drop all bales to ground (and add to save by mission)
        self.currentBalePlace = 1;
        for _, balePlace in pairs(self.balePlaces) do
            if balePlace.bales ~= nil then
                for _, baleServerId in pairs(balePlace.bales) do
                    local bale = networkGetObject(baleServerId);
                    if bale ~= nil then
                        bale:unmount();
                    end;
                    self.balesToMount[baleServerId] = nil;
                end;
                balePlace.bales = nil;
            end;
        end;
        self.fillLevel = 0;
		
		-- bassaddict
		if self.isServer then
			setMass(self.fillMassNode, self.emptyMass);
			self.myCurrentMass = self.emptyMass;
		end;
		
		self:playAnimation("releaseFrontplattform", 1, nil, true);
        self:playAnimation("closeGrippers", -1, nil, true);
        self.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK;
    elseif id == BaleLoader.CHANGE_SINK then
        self:playAnimation("emptyRotate", -1, nil, true);
        self:playAnimation("moveBalePlacesToEmpty", -5, nil, true);
        self:playAnimation("emptyHidePusher1", -1, nil, true);
        self:playAnimation(self.rotatePlatformEmptyAnimName, -1, nil, true);
        if not self.isInWorkPosition then
            self:playAnimation("closeGrippers", 1, self:getAnimationTime("closeGrippers"), true);
            self:playAnimation("baleGrabberTransportToWork", 1, nil, true);
        end;
        self.emptyState = BaleLoader.EMPTY_SINK;
    elseif id == BaleLoader.CHANGE_EMPTY_REDO then
        self:playAnimation("emptyRotate", 1, nil, true);
        self.emptyState = BaleLoader.EMPTY_ROTATE2;
    elseif id == BaleLoader.CHANGE_EMPTY_START then
        -- move to work position in case it is not there now
        BaleLoader.moveToWorkPosition(self);
        self.emptyState = BaleLoader.EMPTY_TO_WORK;
    elseif id == BaleLoader.CHANGE_EMPTY_CANCEL then
        self:playAnimation("emptyRotate", -1, nil, true);
        self.emptyState = BaleLoader.EMPTY_CANCEL;
    elseif id == BaleLoader.CHANGE_MOVE_TO_TRANSPORT then
        if self.isInWorkPosition then
            self.grabberIsMoving = true;
            self.isInWorkPosition = false;
            -- move to transport position
            BaleLoader.moveToTransportPosition(self);
			for _, part in pairs(self.baleloaderUVScrollParts) do
				setShaderParameter(part.node, "uvScrollSpeed", 0, 0, 0, 0, false);
			end;
        end;
    elseif id == BaleLoader.CHANGE_MOVE_TO_WORK then
        if not self.isInWorkPosition then
            self.grabberIsMoving = true;
            self.isInWorkPosition = true;
            -- move to work position
            BaleLoader.moveToWorkPosition(self);
			for _, part in pairs(self.baleloaderUVScrollParts) do
				setShaderParameter(part.node, "uvScrollSpeed", part.speed[1], part.speed[2], 0, 0, false);
			end;
        end;
    elseif id == BaleLoader.CHANGE_GRAB_BALE then
        local bale = networkGetObject(nearestBaleServerId);
		local addMass = 0; -- bassaddict
        self.baleGrabber.currentBale = nearestBaleServerId;
        if bale ~= nil then
			-- bassaddict
			local fillType = bale:getFillType();
			local fillLevel = bale:getFillLevel();
			local mass = fillLevel * Fillable.fillTypeIndexToDesc[fillType].massPerLiter;
			if mass ~= nil then
				addMass = mass
			end;
		
            bale:mount(self, self.baleGrabber.grabNode, 0,0,0, 0,0,0);
            self.balesToMount[nearestBaleServerId] = nil;
        else
            self.balesToMount[nearestBaleServerId] = {serverId=nearestBaleServerId, linkNode=self.baleGrabber.grabNode, trans={0,0,0}, rot={0,0,0} };
        end;
        self.grabberMoveState = BaleLoader.GRAB_MOVE_UP;
        self:playAnimation("baleGrabberWorkToDrop", 1, nil, true);
		self.fillLevel = self.fillLevel + 1;
		
		-- bassaddict
		if self.isServer then
			if addMass ~= 0 then
				local newMass = self.myCurrentMass + addMass;
				setMass(self.fillMassNode, newMass);
				self.myCurrentMass = newMass;
			end;
		end;
		
        if self.isClient then
            if self:getIsActiveForSound() then
                Utils.playSample(self.sampleBaleGrab, 1, 0, nil);
            end;
            Utils.setEmittingState(self.baleGrabParticleSystems, true);
            self.baleGrabParticleSystemDisableTime = g_currentMission.time + self.baleGrabParticleSystemDisableDuration;
        end;
    elseif id == BaleLoader.CHANGE_GRAB_MOVE_UP then
        self.currentBaleGrabberDropBaleAnimName = self:getBaleGrabberDropBaleAnimName();
        self:playAnimation(self.currentBaleGrabberDropBaleAnimName, 1, nil, true);
        self.grabberMoveState = BaleLoader.GRAB_DROP_BALE;
    elseif id == BaleLoader.CHANGE_GRAB_DROP_BALE then
        -- drop bale at platform
        if self.startBalePlace.count < 2 and self.startBalePlace.node ~= nil then
            local attachNode = getChildAt(self.startBalePlace.node, self.startBalePlace.count)
            local bale = networkGetObject(self.baleGrabber.currentBale);
            if bale ~= nil then
                bale:mount(self, attachNode, 0,0,0, 0,0,0);
                self.balesToMount[self.baleGrabber.currentBale] = nil;
            else
                self.balesToMount[self.baleGrabber.currentBale] = {serverId=self.baleGrabber.currentBale, linkNode=attachNode, trans={0,0,0}, rot={0,0,0} };
            end;
            self.startBalePlace.count = self.startBalePlace.count + 1;
            table.insert(self.startBalePlace.bales, self.baleGrabber.currentBale);
            self.baleGrabber.currentBale = nil;
            --setRotation(baleNode, 0, 0, 0);
            --setTranslation(baleNode, 0, 0, 0);
            if self.startBalePlace.count == 1 then
                self.frontBalePusherDirection = 1;
                self:playAnimation("balesToOtherRow", 1, nil, true);
                self:playAnimation("frontBalePusher", 1, nil, true);
            elseif self.startBalePlace.count == 2 then
                BaleLoader.rotatePlatform(self);
            end;
            self:playAnimation(self.currentBaleGrabberDropBaleAnimName, -5, nil, true);
            self:playAnimation("baleGrabberWorkToDrop", -1, nil, true);
            self.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN;
        end;
    elseif id == BaleLoader.CHANGE_GRAB_MOVE_DOWN then
        self.grabberMoveState = nil;
    elseif id == BaleLoader.CHANGE_FRONT_PUSHER then
        if self.frontBalePusherDirection > 0 then
            self:playAnimation("frontBalePusher", -1, nil, true);
            self.frontBalePusherDirection = -1;
        else
            self.frontBalePusherDirection = 0;
        end;
    elseif id == BaleLoader.CHANGE_ROTATE_PLATFORM then
        if self.rotatePlatformDirection > 0 then
            -- drop bales
            local balePlace = self.balePlaces[self.currentBalePlace];
            self.currentBalePlace = self.currentBalePlace + 1;
            for i=1, table.getn(self.startBalePlace.bales) do
                local node = getChildAt(self.startBalePlace.node, i-1);
                local x,y,z = getTranslation(node);
                local rx,ry,rz = getRotation(node);
                local baleServerId = self.startBalePlace.bales[i];
                local bale = networkGetObject(baleServerId);
                if bale ~= nil then
                    bale:mount(self, balePlace.node, x,y,z, rx,ry,rz);
                    self.balesToMount[baleServerId] = nil;
                else
                    self.balesToMount[baleServerId] = {serverId=baleServerId, linkNode=balePlace.node, trans={ x,y,z}, rot={rx,ry,rz} };
                end;
            end;
            balePlace.bales = self.startBalePlace.bales;
            self.startBalePlace.bales = {};
            self.startBalePlace.count = 0;
            for i=1, 2 do
                local node = getChildAt(self.startBalePlace.node, i-1);
                setRotation(node, unpack(self.startBalePlace.origRot[i]));
                setTranslation(node, unpack(self.startBalePlace.origTrans[i]));
            end;
            if self.emptyState == BaleLoader.EMPTY_NONE then
                -- we are not waiting to start emptying, rotate back
                self.rotatePlatformDirection = -1;
                self:playAnimation(self.rotatePlatformBackAnimName, -1, nil, true);
                if self.moveBalePlacesAfterRotatePlatform then
                    -- currentBalePlace+1 needs to be at the first position
                    if self.currentBalePlace <= table.getn(self.balePlaces) then
                        self:playAnimation("moveBalePlaces", 1, (self.currentBalePlace-1)/table.getn(self.balePlaces), true);
                        self:setAnimationStopTime("moveBalePlaces", (self.currentBalePlace)/table.getn(self.balePlaces));
                        self:playAnimation("moveBalePlacesExtrasOnce", 1, nil, true);
                    end
                end
            else
                self.rotatePlatformDirection = 0;
            end;
        else
            self.rotatePlatformDirection = 0;
        end;
    elseif id == BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM then
        self.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM;
        if self.startBalePlace.count == 0 then
            self:playAnimation(self.rotatePlatformEmptyAnimName, 1, nil, true);
        else
            BaleLoader.rotatePlatform(self)
        end;
    elseif id == BaleLoader.CHANGE_EMPTY_ROTATE1 then
        self:playAnimation("emptyRotate", 1, nil, true);
        self:setAnimationStopTime("emptyRotate", 0.2);
        local balePlacesTime = self:getRealAnimationTime("moveBalePlaces");
        self:playAnimation("moveBalePlacesToEmpty", 1.5, balePlacesTime/self:getAnimationDuration("moveBalePlacesToEmpty"), true);
        self:playAnimation("moveBalePusherToEmpty", 1.5, balePlacesTime/self:getAnimationDuration("moveBalePusherToEmpty"), true);
        self.emptyState = BaleLoader.EMPTY_ROTATE1;
    elseif id == BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS then
        self:playAnimation("closeGrippers", 1, nil, true);
        self.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS;
    elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 then
        self:playAnimation("emptyHidePusher1", 1, nil, true);
        self.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1;
    elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 then
        self:playAnimation("moveBalePusherToEmpty", -2, nil, true);
        self.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2;
    elseif id == BaleLoader.CHANGE_EMPTY_ROTATE2 then
        self:playAnimation("emptyRotate", 1, self:getAnimationTime("emptyRotate"), true);
        self.emptyState = BaleLoader.EMPTY_ROTATE2;
    elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP then
        -- wait for the user to react (abort or drop)
        self.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP;
    elseif id == BaleLoader.CHANGE_EMPTY_STATE_NIL then
        self.emptyState = BaleLoader.EMPTY_NONE;
        BaleLoader.moveToTransportPosition(self);
        if self.isServer then
            g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self);
        end;
    elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO then
        self.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO;
    elseif id == BaleLoader.CHANGE_BUTTON_EMPTY then
        -- Server only code
        assert(self.isServer);
        if self.emptyState ~= BaleLoader.EMPTY_NONE then
            if self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
                -- BaleLoader.CHANGE_DROP_BALES
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_DROP_BALES), true, nil, self);
            elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
                -- BaleLoader.CHANGE_SINK
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_SINK), true, nil, self);
            elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
                -- BaleLoader.CHANGE_EMPTY_REDO
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_REDO), true, nil, self);
            end;
        else
            --BaleLoader.CHANGE_EMPTY_START
            if BaleLoader.getAllowsStartUnloading(self) then
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_START), true, nil, self);
            end;
        end;
    elseif id == BaleLoader.CHANGE_BUTTON_EMPTY_ABORT then
        -- Server only code
        assert(self.isServer);
        if self.emptyState ~= BaleLoader.EMPTY_NONE then
            if self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
                --BaleLoader.CHANGE_EMPTY_CANCEL
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_CANCEL), true, nil, self);
            end;
        end;
    elseif id == BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT then
        -- Server only code
        assert(self.isServer);
        if self.emptyState == BaleLoader.EMPTY_NONE and self.grabberMoveState == nil then
            if self.isInWorkPosition then
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self);
            else
                g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self);
            end;
        end;
    end;
end;