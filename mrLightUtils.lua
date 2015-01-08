--print("--- load MrLightUtils ---");
MrLightUtils = {}; --FruitUtils Fillable Update

MrLightUtils.PriceBalanceFactors = {
	windrow = 2.5,
	fuel = 1,
	silage = 1,
	fertilizer = 1,
	milk = 1,
	egg = 3,
	wool = 4,
	woodChips = 1,
	seed = 1
};
MrLightUtils.PriceBalanceFactorGlobal = 1;

function MrLightUtils.setBalancingFactors(xmlFile)
	--print("set balance factors");
	
	local xmlMainNode = "settings.balancing";
	
	local value = getXMLFloat(xmlFile, xmlMainNode .. ".priceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactorGlobal = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".seedPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.seed = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".woolPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.wool = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".eggPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.egg = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".milkPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.milk = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".fuelPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.fuel = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".fertilizerPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.fertilizer = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".silagePriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.silage = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".windrowPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.windrow = value;
	end;
	
	value = getXMLFloat(xmlFile, xmlMainNode .. ".woodChipsPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.woodChips = value;
	end;
	print("--- MRL: balancing factors set");
end;


MrLightUtils.vehicleConfigs = {};
function MrLightUtils.loadVehicleConfigs(xmlFile)
	--print("load vehicle configs");
	local xmlMainNode = "settings.vehicles";
	
	local i = 0;
	while true do
		local vehicle = string.format(xmlMainNode..".vehicle(%d)", i);
		local configFile = getXMLString(xmlFile, vehicle.."#configFile");
		if configFile == nil then
			break;
		end;
		
		MrLightUtils.vehicleConfigs[configFile] = {};
		local j = 0;
		while true do
			local entry = string.format(vehicle..".entry(%d)", j)
			local key = getXMLString(xmlFile, entry.."#key");
			local vtype = getXMLString(xmlFile, entry.."#type");
			
			local value = nil;
			if vtype == "number" then
				value = getXMLFloat(xmlFile, entry.."#value");
			elseif vtype == "string" then
				value = getXMLString(xmlFile, entry.."#value");
			elseif vtype == "bool" then
				value = getXMLBool(xmlFile, entry.."#value");
			end;
			
			if key == nil or value == nil then
				break;
			end;
			MrLightUtils.vehicleConfigs[configFile][key] = value;
			j = j + 1;
		end;
		i = i + 1;
	end;
	print("--- MRL: cehicle configs loaded");
end;

function MrLightUtils.setStoreData()
	for k,v in pairs(MrLightUtils.vehicleConfigs) do
		k = string.lower(k);
		if v.price ~= nil then
			if StoreItemsUtil.storeItemsByXMLFilename[k] == nil then
				print("1 is nil");
				print("k: "..tostring(k)..", v: "..tostring(v));
			end;
			if StoreItemsUtil.storeItemsByXMLFilename[k].price == nil then
				print("3 is nil");
			end;
			StoreItemsUtil.storeItemsByXMLFilename[k].price = Utils.getNoNil(tonumber(v.price), StoreItemsUtil.storeItemsByXMLFilename[k].price);
		end;
		if v.dailyUpkeep ~= nil then
			StoreItemsUtil.storeItemsByXMLFilename[k].dailyUpkeep = Utils.getNoNil(tonumber(v.dailyUpkeep), StoreItemsUtil.storeItemsByXMLFilename[k].dailyUpkeep);
		end;
		if v.power ~= nil then
			StoreItemsUtil.storeItemsByXMLFilename[k].specs.power = Utils.getNoNil(tonumber(v.power), StoreItemsUtil.storeItemsByXMLFilename[k].specs.power);
		end;
		if v.neededPower ~= nil then
			StoreItemsUtil.storeItemsByXMLFilename[k].specs.neededPower = Utils.getNoNil(tonumber(v.neededPower), StoreItemsUtil.storeItemsByXMLFilename[k].specs.neededPower);
		end;
	end;
	print("--- MRL: store data set");
end;

function MrLightUtils.getFillableInfos(fillTypeName)
	-- pricePerKg of some fruit/filltype should NEVER be 0
	-- example : grass. there is some random computation done by the game engine at some times, and when you play in mp, the client game will crash (only XP OS)
	
	local density = 0.75; --kg/L
	local pricePerKg = 1; --€/T
	local found = false;

	if fillTypeName~=nil and fillTypeName~="" then
	
		--20140622 - everything in lower case since some modders use uppercase and some don't
		fillTypeName = fillTypeName:lower();		
	
		found = true;
		
		--*********************** FRUITS filltype
		if fillTypeName=="wheat" then
			density, pricePerKg = 0.79, 0.200; -- 200€/T
		elseif fillTypeName=="barley" then
			density, pricePerKg = 0.71, 0.195; -- 195€/T
		elseif fillTypeName=="maize" then
			density, pricePerKg = 0.82, 0.190; -- 190€/T
		elseif fillTypeName=="rape" then
			density, pricePerKg = 0.64, 0.400; -- 400€/T
		elseif fillTypeName=="chaff" or fillTypeName=="forage" then
			density, pricePerKg = 0.40, 0.040; -- 2000€/ha =>	2000€/50T => 40€/T			
		elseif fillTypeName=="sugarbeet" then
			density, pricePerKg = 0.69, 0.040; --40€/T
		elseif fillTypeName=="potato" then
			density, pricePerKg = 0.67, 0.065; --65€/T. should be something like 150-200€/T but in the game, we do not have to irrigate, prepare the soil, weed or clean/wash/sort the potatoes
				
		elseif fillTypeName=="manure" then
			density, pricePerKg = 0.65, 0.020;	--20€/T
		elseif fillTypeName=="liquidmanure" then
			density, pricePerKg = 0.92, 0.007;	--7€/T
			
		elseif fillTypeName=="seeds" then
			density, pricePerKg = 0.654, 0;	--bassaddict: Density averaged over the different seed types since density for each seed type is not implemented. Maybe a future feature.
					
		--*************************** WINDROW filltype
		elseif fillTypeName=="wheat_windrow" then
			density, pricePerKg = 0.040, 0.040*MrLightUtils.PriceBalanceFactors.windrow;	--40€/T
		elseif fillTypeName=="barley_windrow" then
			density, pricePerKg = 0.036, 0.044*MrLightUtils.PriceBalanceFactors.windrow;	--44€/T
		elseif fillTypeName=="drygrass_windrow" or fillTypeName=="drygrass" then
			density, pricePerKg = 0.050, 0.085*MrLightUtils.PriceBalanceFactors.windrow; -- 85€/T			
		elseif fillTypeName=="grass_windrow" or fillTypeName=="grass" then
			density, pricePerKg = 0.25, 0.015*MrLightUtils.PriceBalanceFactors.windrow; -- 15€/T	 
			
		--*************************** OTHER filltype
		elseif fillTypeName=="silage" then
			density, pricePerKg = 0.4, 0.175*MrLightUtils.PriceBalanceFactors.silage;	--175€/T   compress silage = 0.85 density / uncompressed = 0.4
		elseif fillTypeName=="forage_mixing" then -- TMR
			density, pricePerKg = 0.2, 0.300; --300€/T
		
		elseif fillTypeName=="fuel" then
			density, pricePerKg = 0.83, 1.025*MrLightUtils.PriceBalanceFactors.fuel;	--0.85€/L == 1.025€/Kg.  
		elseif fillTypeName=="fertilizer" then
			density, pricePerKg = 1.28, 0.190*MrLightUtils.PriceBalanceFactors.fertilizer;	--230€/M3 == 190€/T.   factor 4 to balance gameplay
			
		elseif fillTypeName=="milk" then
			density, pricePerKg = 1.03, 0.485*MrLightUtils.PriceBalanceFactors.milk; -- 0.5€/L = 0.485€/kg
		elseif fillTypeName=="egg" then
			density, pricePerKg = 0.37, 1.35*MrLightUtils.PriceBalanceFactors.egg; -- density of an egg box, price = 0.50€ per egg for not-industrial eggs (1 egg = 60g)   the pricePerLiter for egg = price for 1 egg in the game.   Factor 10 to balance gameplay (you have to manually pick up eggs in the game)
		elseif fillTypeName=="wool" then -- 50kg/m3
			density, pricePerKg = 0.05, 1*MrLightUtils.PriceBalanceFactors.wool;	-- "real" price = 1€/kg -- wanted price ingame (hard difficulty) = 1€/L -> 20€/kg (there is already the priceBalancing applied, that means we need a woolPriceBalancing of 4)
			
		elseif fillTypeName=="water" then
			density, pricePerKg = 1, 0;		
			
		elseif fillTypeName=="woodchips" then -- forest mod (Forst Mod)
			density, pricePerKg = 0.24, 0.075*MrLightUtils.PriceBalanceFactors.woodChips;	-- 75€/T
			
		elseif fillTypeName=="treesaplings" then -- forest mod (Forst Mod)
			density, pricePerKg = 10, 2.765;	-- 1L = 1 seedling = 10kgs / 17 seedling = 470€ => 2.765€ per kilo		
			
		else --no filltype matching the input filltypeName
			found = false;
			--20140531 - check if this is a windrow type
			if string.find(fillTypeName, "_windrow") then
				density = 0.04; -- default windrow density
			end;
		end;
		
	end;	
	
	-- price is multiplied by priceBalancing to mach an average 20000$ net profit in hard mode (for 1 ha done manually - no worker) => not realistic, but : who wants to "play" for more than 100 hours to afford a medium size tractor (Geotrac or Same explorer) ?  
	-- it would be too difficult or real if we put the right figures...
	-- and, in reality, you can't buy a new tractor every 10 hours or so of work...
	-- moreover, there are no starting stock in hard mode, there are no pre-seed fields like in FS2011 on the map and we must buy all the fields (there was no field buying in FS2011)
	-- meanwhile, there are great demand in FS2013 that allow the player to earn more if he use its farm silos.
	pricePerKg = MrLightUtils.PriceBalanceFactorGlobal*pricePerKg;
	local pricePerLiter = density * pricePerKg;
	
	return found, density, pricePerKg, pricePerLiter;
end;

function MrLightUtils.setFillableInfos(fillTypeName, newGame)
	local desc = Fillable.fillTypeNameToDesc[fillTypeName];	
	local found, density, pricePerKg, pricePerLiter = MrLightUtils.getFillableInfos(desc.name);
	
	if found then
		desc.massPerLiter = density * 0.001;
		desc.startPricePerLiter = pricePerLiter;
		if newGame then
			desc.pricePerLiter = pricePerLiter;
			desc.previousHourPrice = pricePerLiter;
		end;
	end;
end;

function MrLightUtils.getFruitUtilInfos(fruitName)
	-- price per liter
	local seedPrice = 0.5; -- 0.5€ / L		
	local usage = 0.025;-- 250L / hectare
	local yield = 1;-- 10000L/hectare	
	local found = false;
	local windrowYield = 0; --no windrow

	if fruitName~=nil then
	
		found = true;
		
		fruitName=fruitName:lower();
			
		if fruitName=="wheat" then
			seedPrice, usage, yield, windrowYield = 0.525, 0.02, 1.25, 12.5; -- 12500L/ha = 9.87T
		elseif fruitName=="barley" then
			seedPrice, usage, yield, windrowYield = 0.495, 0.0225, 1.08, 11; -- 10800L/ha = 7.67T
		elseif fruitName=="maize" then
			seedPrice, usage, yield, windrowYield = 4.5, 0.0037, 1.52, 0; -- 15200L/ha = 12.46T
		elseif fruitName=="rape" then
			seedPrice, usage, yield, windrowYield = 14, 0.0004, 0.69, 0; -- 6900L/Ha = 4.4T | 2.4kg/ha => 4L/ha => 400 000 graines ~= 56€
		elseif fruitName=="grass" then
			seedPrice, usage, yield, windrowYield = 1.2, 0.0067, 1.065, 14; -- 140000L/ha = 35T
		elseif fruitName=="drygrass" then
			seedPrice, usage, yield, windrowYield = 0, 0, 0.18, 12; -- 120000L/ha = 6T -- a little less liters than wet grass because there are some losses when doing hay
		elseif fruitName=="chaff" then
			seedPrice, usage, yield, windrowYield = 0, 0, 10.96, 0; -- this is just a factor. goal: maize chaff with 125000L / ha = 50T
		elseif fruitName=="potato" then
			seedPrice, usage, yield, windrowYield = 0.25, 0.285, 7.4, 0; -- 50T/ha  0.67 density => 74 000L / ha
		elseif fruitName=="sugarbeet" then
			seedPrice, usage, yield, windrowYield = 80, 0.000375, 11.6, 0; -- 80T / ha   0.69 density => 116 000L / ha
		else
			found=false;
		end;
		
	end;
	
	-- actual yield will be twice as much as the standard yield with manure or fertilizer. not quite realistic, but its a game, and we want to do some transport too (who wants to thresh for 2 hours to do a field and fill only one small tipper ?)
	return found, MrLightUtils.PriceBalanceFactorGlobal*MrLightUtils.PriceBalanceFactors.seed*seedPrice, usage, yield*0.75, windrowYield;	-- considering the "2" factor when fertilized, that means 50% more yield than actual figures
end;

function MrLightUtils.setFruitUtilInfos(fruitName)
	local desc = FruitUtil.fruitTypes[fruitName];
	local found, seedPrice, usage, yield, windrowYield = MrLightUtils.getFruitUtilInfos(fruitName);
	
	if found then
		desc.seedPricePerLiter = seedPrice;
		desc.seedUsagePerSqm = usage;
		desc.literPerSqm = yield;
		
		desc.massPerLiter = Fillable.fillTypeNameToDesc[fruitName].massPerLiter; --also setting the correct density for the crop in the FruitUtil table.
		
		if windrowYield ~= 0 then
			desc.windrowLiterPerSqm = windrowYield;
			desc.windrowMassPerLiter = Fillable.fillTypeNameToDesc[fruitName.."_windrow"].massPerLiter; --also setting the correct density for the crop windrow in the FruitUtil table.
		end;
	else
		if desc.seedUsagePerSqm == nil then
			print(string.format("WARNING: MR-Light detected a corrupted fruit! fruit '%s' does not use the proper data structure given by Giants Software", desc.name));
			desc.seedUsagePerSqm = 0.1;
			desc.seedPricePerLiter = 0.1;
		elseif desc.seedUsagePerSqm > 0 then
			--set sell price as seed price
			local fillType = FruitUtil.fruitTypeToFillType[desc.index];
			desc.seedPricePerLiter = Fillable.fillTypeIndexToDesc[fillType].pricePerLiter;
		end;
	end;
end;

function MrLightUtils.setFruitData(newGame)
	MrLightUtils.setFillableInfos("fertilizer", true);
	MrLightUtils.setFillableInfos("fuel", true);
	g_fuelPricePerLiter = Fillable.fillTypeNameToDesc["fuel"].pricePerLiter;
	
	for k, fillType in pairs(Fillable.fillTypeNameToDesc) do
		MrLightUtils.setFillableInfos(fillType.name, newGame);
	end;
	
	for k, fruitType in pairs(FruitUtil.fruitTypes) do
		MrLightUtils.setFruitUtilInfos(fruitType.name)
	end;
	print("--- MRL: fruit data set");
end;





--********************************--
--*   setting development mode   *--
--********************************--
MrLightUtils.developMode = false;
MrLightUtils.developSpeedFactor = 1;
function MrLightUtils.setMRLightDevelopMode(val)
	if val == nil or val == false then
		MrLightUtils.developMode = false;
		MrLightUtils.developSpeedFactor = 1;
	elseif val then
		MrLightUtils.developMode = true;
		MrLightUtils.developSpeedFactor = 100;
	end;
end;
addConsoleCommand('setMRLightDevelopMode', 'set development mode for MR light: true|false', 'setMRLightDevelopMode', MrLightUtils);





--************************************--
--*   hired worker using resources   *--
--************************************--
function MrLightUtils.getIsHired(self)
  return false;
end;
Vehicle.getIsHired = MrLightUtils.getIsHired;

local origHirableUpdate = Hirable.update;
Hirable.update = function(self, dt)
	if origHirableUpdate ~= nil then
		origHirableUpdate(self, dt);
	end;
	if self.isHired then
		if (self.fuelFillLevel / self.fuelCapacity) < 0.025 then
			if self.isAITractorActivated ~= nil then
				self:stopAITractor();
			elseif self.isAIThreshing ~= nil then
				self:stopAIThreshing();
			end;
		end;
		for k,v in pairs(self.attachedImplements) do
			if v.object ~= nil and v.object.capacity ~= nil and v.object.capacity ~= 0 then
				if v.object.fillLevel <= 0 then
					if self.isAITractorActivated ~= nil then
						self:stopAITractor();
					elseif self.isAIThreshing ~= nil then
						self:stopAIThreshing();
					end;
				end;
			end;
		end;
	end;
end;





--********************************************--
--*   little fix for sprayer working width   *--
--*   for sprayer attachments (Zunhammer)    *--
--********************************************--
local oldSprayerOnTurnedOn = Sprayer.onTurnedOn;
Sprayer.onTurnedOn = function(self, isTurnedOn, noEventSend)
	if oldSprayerOnTurnedOn ~= nil then
		oldSprayerOnTurnedOn(self, isTurnedOn, noEventSend)
	end;
	self.updateWorkingWidth = true;
end;





--*******************************--
--*   set correct bale masses   *--
--*******************************--
MrLightUtils.oldItemToSave = BaseMission.addItemToSave;
function MrLightUtils.addItemToSave(self, obj)
	MrLightUtils.oldItemToSave(self, obj);
	if obj:isa(Bale) then
		local newMass = Fillable.fillTypeIndexToDesc[obj.fillType].massPerLiter * obj.fillLevel;
		setMass(obj.nodeId, newMass);
		--print("i3d filename: " .. obj.i3dFilename);
		--print("mpl: " .. tostring(newMassPerLiter) .. ", fl: " .. tostring(newFillLevel) .. ", mass: " .. tostring(newMass));
	end;
	--for k,v in pairs(obj) do
	--	print("k: " .. tostring(k) .. ", v: " .. tostring(v));
	--end;
end;
BaseMission.addItemToSave = MrLightUtils.addItemToSave;
--Utils.overwrittenFunction(BaseMission.addItemToSave, MrLightUtils.addItemToSave);





--******************************************--
--*   saving price balancing config file   *--
--******************************************--
local oldCareerScreenSaveSavegame = g_careerScreen.saveSavegame;
g_careerScreen.saveSavegame = function(self, savegame)
	oldCareerScreenSaveSavegame(self, savegame)
	
	--ZZZ_getVars.getVars:getVariables(savegame);
	--print("savegame: " .. tostring(savegame));
	--local dir = self.savegames[self.selectedIndex].savegameDirectory;
	local settingsFile = savegame.savegameDirectory .. "/mrLightSettings.xml"
	if not fileExists(settingsFile) then
		local xmlFile = createXMLFile("mrLightSettings", settingsFile, "settings");
		if xmlFile ~= nil then
			setXMLFloat(xmlFile, "settings.balancing.priceBalancing#value", MrLightUtils.PriceBalanceFactorGlobal);
			
			setXMLFloat(xmlFile, "settings.balancing.seedPriceBalancing#value", MrLightUtils.PriceBalanceFactors.seed);
			setXMLFloat(xmlFile, "settings.balancing.woolPriceBalancing#value", MrLightUtils.PriceBalanceFactors.wool);
			setXMLFloat(xmlFile, "settings.balancing.eggPriceBalancing#value", MrLightUtils.PriceBalanceFactors.egg);
			setXMLFloat(xmlFile, "settings.balancing.milkPriceBalancing#value", MrLightUtils.PriceBalanceFactors.milk);
			setXMLFloat(xmlFile, "settings.balancing.fuelPriceBalancing#value", MrLightUtils.PriceBalanceFactors.fuel);
			setXMLFloat(xmlFile, "settings.balancing.fertilizerPriceBalancing#value", MrLightUtils.PriceBalanceFactors.fertilizer);
			setXMLFloat(xmlFile, "settings.balancing.silagePriceBalancing#value", MrLightUtils.PriceBalanceFactors.silage);
			setXMLFloat(xmlFile, "settings.balancing.windrowPriceBalancing#value", MrLightUtils.PriceBalanceFactors.windrow);
			setXMLFloat(xmlFile, "settings.balancing.woodChipsPriceBalancing#value", MrLightUtils.PriceBalanceFactors.woodChips);
			saveXMLFile(xmlFile);
		end;
	end;
end;



