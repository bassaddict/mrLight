SprayerManipulation = {};

function SprayerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations);
end;

function SprayerManipulation:load(xmlFile)
	--self.getWorkingWidth = SpecializationUtil.callSpecializationsFunction("getWorkingWidth");
	self.firstRunSprayerManipulation = true;
	self.oldFillLitersPerSecond = self.fillLitersPerSecond;
	self.fillLitersPerSecond = 2;
	self.fillSpeedFX = 0;
	
	self.defaultSprayLitersPerSecond = 1;
	self.sprayLitersPerHectare = {};
	self.sprayLitersPerHectare[Fillable.FILLTYPE_FERTILIZER] = 500; --500l fertilizer per ha
	self.sprayLitersPerHectare[Fillable.FILLTYPE_LIQUIDMANURE] = 20000; --20m3 per ha
	self.sprayLitersPerHectare[Fillable.FILLTYPE_MANURE] = 20 / 0.00065; -- hardcoded due to not available at loading time...  Fillable.fillTypeIndexToDesc[Fillable.FILLTYPE_MANURE].massPerLiter; --20t per ha
	
	self.workingWidth = 10;
	
	
	self.debugRenderSprayerManipulation = false;
end;

function SprayerManipulation:delete()
end;

function SprayerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function SprayerManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function SprayerManipulation:update(dt)

	if self.firstRunSprayerManipulation then
		self.firstRunSprayerManipulation = false;
		self.workingWidth = MrLightUtils.getWorkingWidth(self.workAreas, self.rootNode);
	end;
	if self.updateWorkingWidth then
		self.updateWorkingWidth = false;
		if self.attachedTool ~= nil then
			self.workingWidth = MrLightUtils.getWorkingWidth(self.attachedTool.workAreas, self.attachedTool.rootNode);
		else
			self.workingWidth = MrLightUtils.getWorkingWidth(self.workAreas, self.rootNode);
		end;
		--print("working width updated: "..tostring(self.workingWidth));
	end;
	if self.isTurnedOn and self.currentFillType ~= Fillable.FILLTYPE_UNKNOWN then
		-- 10000sqm / speed in m/s = duration to work 1ha with 1m working width
		-- ha usage / 1ha1m work duration = usage in l/s for 1m working width
		-- min working speed: 2.5km/h
		if self.sprayLitersPerHectare[self.currentFillType] == nil then
			self.sprayLitersPerHectare[self.currentFillType] = self.sprayLitersPerHectare[Fillable.FILLTYPE_FERTILIZER];
		end;
		self.sprayLitersPerSecond[self.currentFillType] = self.sprayLitersPerHectare[self.currentFillType] / math.min(10000 / (Utils.getNoNil(self.lastMovedDistance, 0.0001) * (1000 / dt)), 14400) * self.workingWidth;
		if self.debugRenderSprayerManipulation then
			print(string.format("sprayLitersPerSecond: %.4f, sprayLitersPerHectare: %.2f, lastMovedDistance: %.4f, workingWidth: %.2f", Utils.getNoNil(self.sprayLitersPerSecond[self.currentFillType], 0), Utils.getNoNil(self.sprayLitersPerHectare[self.currentFillType], 0), Utils.getNoNil(self.lastMovedDistance, 0), Utils.getNoNil(self.workingWidth,0)));
		end;
		if self.attachedTool ~= nil then
			self.attachedTool.sprayLitersPerSecond[self.currentFillType] = self.sprayLitersPerSecond[self.currentFillType];
		end;
	end;
	
	
	if self.isFilling then
		self.fillSpeedFX = math.min(1, Utils.getNoNil(self.fillSpeedFX, 0.01) + dt/5000);
		self.fillLitersPerSecond = self.oldFillLitersPerSecond * self.fillSpeedFX;
	else
		self.fillSpeedFX = 0;
	end;
	
end;

function SprayerManipulation:draw()
	if self.debugRenderSprayerManipulation then
		setTextAlignment(RenderText.ALIGN_RIGHT);
		renderText(0.99, 0.80, 0.018, string.format("lastMovedDistance: %.4f, workingWidth: %.2f, sprayLitersPerSecond: %.4f, fillLevel: %.2f", self.lastMovedDistance, self.workingWidth, Utils.getNoNil(self.sprayLitersPerSecond[self.currentFillType], 0), Utils.getNoNil(self.fillLevel,0)));
		--renderText(0.99, 0.78, 0.018, string.format("fillDelta: %.4f",self.deltaFill));
		setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;



