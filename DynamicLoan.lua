DynamicLoan = {};

DynamicLoan.firstUpdate = true;
DynamicLoan.firstLoadMap = true;

function DynamicLoan:loadMap(name)
	self.totalVehicleValue = 0;
	self.totalSoldValue = 0;
end;

function DynamicLoan:deleteMap()
	DynamicLoan.firstUpdate = true;
end;

function DynamicLoan:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DynamicLoan:keyEvent(unicode, sym, modifier, isDown)
end;

function DynamicLoan:update(dt)
	if DynamicLoan.firstUpdate or DynamicLoan.updateValueFlag then
		self.totalVehicleValue = 0;
		for k,vehicle in pairs(g_currentMission.vehicles) do
			local price = 0;
			local cfgFile = string.lower(vehicle.configFileName);
			if StoreItemsUtil.storeItemsByXMLFilename[cfgFile] ~= nil then
				price = StoreItemsUtil.storeItemsByXMLFilename[cfgFile].price;
			end;
			if price > 0 then
				self.totalVehicleValue = self.totalVehicleValue + price;
			end;
		end;
		g_currentMission.missionStats.loanMax = DynamicLoan:getLoanValue(self.totalVehicleValue);
		print(g_currentMission.missionStats.loanMax);
		DynamicLoan.firstUpdate = false;
		DynamicLoan.updateValueFlag = false;
	end;
	--ShopScreen.onVehicleSold()
	--ShopScreen.onVehicleBought()
end;

function DynamicLoan:updateTotalVehicleValue()
	--self.totalVehicleValue = self.totalVehicleValue - self.totalSoldValue;
	--self.totalVehicleValue = self.totalVehicleValue + value;
	--g_currentMission.missionStats.loanMax = DynamicLoan:getLoanValue(self.totalVehicleValue);
	DynamicLoan.updateValueFlag = true;
end;

--[[function DynamicLoan:updateTotalSoldValue(value)
	self.totalSoldValue = self.totalSoldValue + value;
end;]]

function DynamicLoan:draw()
end;

function DynamicLoan:getLoanValue(totalVehicleValue)
	local absoluteValue = totalVehicleValue * 0.5; --50% of buy price
	local factor = math.floor(absoluteValue / 5000);
	return math.max(200000, factor * 5000); --loan rounded to default 5000 steps
end;

addModEventListener(DynamicLoan);




local oldOnVehicleBought = ShopScreen.onVehicleBought;
ShopScreen.onVehicleBought = function(self, ...)
	if oldOnVehicleBought ~= nil then
		oldOnVehicleBought(self, ...);
	end;
	DynamicLoan:updateTotalVehicleValue();
end;

--[[local oldOnVehicleSold = ShopScreen.onVehicleSold;
ShopScreen.onVehicleSold = function(self, a, b, c, d, e, f, g, h, i, j, k, l)
	if oldOnVehicleSold ~= nil then
		oldOnVehicleSold(self, a, b, c, d, e, f, g, h, i, j, k, l);
	end;
	DynamicLoan:updateTotalSoldValue(self.currentSellItem.price);
	--ZZZ_getVars.getVars:getVariablesRecursive(self);
	--print("--------------------------------------------------");
end;]]