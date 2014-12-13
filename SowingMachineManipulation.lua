SowingMachineManipulation = {};

function SowingMachineManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function SowingMachineManipulation:load(xmlFile)
	self.myLastFillLevel = self.fillLevel;
	self.firstRunSowingMachineManipulation = true;
	self.deltaFill = 0;
	self.oldFillLitersPerSecond = self.fillLitersPerSecond;
	self.fillLitersPerSecond = 2;
	self.fillSpeedFX = 0;
	self.lastSeed = self.currentSeed;
	
	
	self.debugRenderSowingMachineManipulation = false;
end;

function SowingMachineManipulation:delete()
end;

function SowingMachineManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function SowingMachineManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function SowingMachineManipulation:update(dt)

	if self.firstRunSowingMachineManipulation then
		self.firstRunSowingMachineManipulation = false;
		self.myLastFillLevel = self.fillLevel;
		self.lastSeed = self.currentSeed;
	else
		if self.myLastFillLevel < self.fillLevel then
			self.deltaFill = self.fillLevel - self.myLastFillLevel;
			local curSeed = self.seeds[self.currentSeed];
			local price = self.deltaFill * FruitUtil.fruitIndexToDesc[curSeed].seedPricePerLiter;
			g_currentMission:addSharedMoney(-price, "other");
		end;
		self.deltaFill = 0;
		self.myLastFillLevel = self.fillLevel
		
		if self.lastSeed ~= self.currentSeed then
			local tLastSeed = self.seeds[self.lastSeed];
			local price = self.fillLevel * FruitUtil.fruitIndexToDesc[tLastSeed].seedPricePerLiter * 0.85;
			g_currentMission:addSharedMoney(price, "other");
			self.fillLevel = 0;
		end;
		self.lastSeed = self.currentSeed;
	end;
	
	if self.isFilling then
		self.fillSpeedFX = math.min(1, Utils.getNoNil(self.fillSpeedFX, 0.01) + dt/5000);
		self.fillLitersPerSecond = self.oldFillLitersPerSecond * self.fillSpeedFX;
	else
		self.fillSpeedFX = 0;
	end;
	
end;

function SowingMachineManipulation:draw()
	if self.debugRenderSowingMachineManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, lastFillLevel: %.4f, currentSeed: %d, isFilling: %s", self.fillLevel, self.myLastFillLevel, self.currentSeed, tostring(self.isFilling)));
		renderText(0.99, 0.78, 0.018, string.format("fillDelta: %.4f",self.deltaFill));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;