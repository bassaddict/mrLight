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
	seed = 1,
	woodTrunks = 0.33
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
	value = getXMLFloat(xmlFile, xmlMainNode .. ".woodTrunksPriceBalancing#value");
	if value~=nil then
		MrLightUtils.PriceBalanceFactors.woodTrunks = value;
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
		--[[if Utils.startsWith(configFile, "$pdlcdir$") then
			local tmp1 = string.gsub(configFile, "$pdlcdir$", "");
			local s,e = string.find(tmp1, "%w+/");
			if s ~= nil then
				local tmp = string.sub(tmp1,s,e-1);
				--local tmp = string.gfind(tmp1, "%w+/");
				if getfenv(0)["pdlc_"..tmp] == nil then
					configFile = nil;
				else
					configFile = g_dlcsDirectories[1].path .. "/" .. string.sub(configFile, 10);
					--TODO
				end;
			end;
		end;]]
		configFile = Utils.convertFromNetworkFilename(configFile);
		--if configFile ~= nil then
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
		--end;
		i = i + 1;
	end;

	print("--- MRL: vehicle configs loaded");
end;

function MrLightUtils.setStoreData()
	for k,v in pairs(MrLightUtils.vehicleConfigs) do
		k = string.lower(k);
		if StoreItemsUtil.storeItemsByXMLFilename[k] ~= nil then
			if v.price ~= nil then
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
			if v.workingWidth ~= nil then
				StoreItemsUtil.storeItemsByXMLFilename[k].specs.workingWidth = Utils.getNoNil(tonumber(v.workingWidth), StoreItemsUtil.storeItemsByXMLFilename[k].specs.workingWidth);
			end;
			if v.capacity ~= nil then
				StoreItemsUtil.storeItemsByXMLFilename[k].capacity = Utils.getNoNil(tonumber(v.capacity), StoreItemsUtil.storeItemsByXMLFilename[k].capacity);
			end;
			if v.incomePerHour ~= nil then
				StoreItemsUtil.storeItemsByXMLFilename[k].incomePerHour = Utils.getNoNil({tonumber(v.incomePerHour) * 4, tonumber(v.incomePerHour) * 2, tonumber(v.incomePerHour)}, StoreItemsUtil.storeItemsByXMLFilename[k].incomePerHour);
			end;
		end;
	end;
	
	for _,v in pairs(StoreItemsUtil.storeItemsByXMLFilename) do
		v.isMod = false;
	end;
	
	StoreItemsUtil.storeItemsByXMLFilename.cow.dailyUpkeep = 15; --default 40
	StoreItemsUtil.storeItemsByXMLFilename.sheep.dailyUpkeep = 1.6; --default 20
	StoreItemsUtil.storeItemsByXMLFilename.chicken.dailyUpkeep = 0.5; --default 1
	
	print("--- MRL: store data set");
end;

MrLightUtils.numFillableClasses = 5;
MrLightUtils.FILLABLE_CLASS_UNKNOWN = 1;
MrLightUtils.FILLABLE_CLASS_GRAINS = 2;
MrLightUtils.FILLABLE_CLASS_CHAFF = 3;
MrLightUtils.FILLABLE_CLASS_TUBERS = 4;
MrLightUtils.FILLABLE_CLASS_FLUIDS = 5;

function MrLightUtils.getFillableInfos(fillTypeName)
	-- pricePerKg of some fruit/filltype should NEVER be 0
	-- example : grass. there is some random computation done by the game engine at some times, and when you play in mp, the client game will crash (only XP OS)
	
	local density = 0.75; --kg/L
	local pricePerKg = 1; --€/T
	local fillableClass = MrLightUtils.FILLABLE_CLASS_UNKNOWN;
	local found = false;

	if fillTypeName~=nil and fillTypeName~="" then
	
		--20140622 - everything in lower case since some modders use uppercase and some don't
		fillTypeName = fillTypeName:lower();		
	
		found = true;
		
		--*********************** FRUITS filltype
		if fillTypeName=="wheat" then
			density, pricePerKg, fillableClass = 0.79, 0.200, MrLightUtils.FILLABLE_CLASS_GRAINS; -- 200€/T
		elseif fillTypeName=="barley" then
			density, pricePerKg, fillableClass = 0.71, 0.195, MrLightUtils.FILLABLE_CLASS_GRAINS; -- 195€/T
		elseif fillTypeName=="maize" then
			density, pricePerKg, fillableClass = 0.82, 0.190, MrLightUtils.FILLABLE_CLASS_GRAINS; -- 190€/T
		elseif fillTypeName=="rape" then
			density, pricePerKg, fillableClass = 0.64, 0.400, MrLightUtils.FILLABLE_CLASS_GRAINS; -- 400€/T
		elseif fillTypeName=="chaff" or fillTypeName=="forage" then
			density, pricePerKg, fillableClass = 0.40, 0.040, MrLightUtils.FILLABLE_CLASS_CHAFF; -- 2000€/ha =>	2000€/50T => 40€/T			
		elseif fillTypeName=="sugarbeet" then
			density, pricePerKg, fillableClass = 0.69, 0.040, MrLightUtils.FILLABLE_CLASS_TUBERS; --40€/T
		elseif fillTypeName=="potato" then
			density, pricePerKg, fillableClass = 0.67, 0.065, MrLightUtils.FILLABLE_CLASS_TUBERS; --65€/T. should be something like 150-200€/T but in the game, we do not have to irrigate, prepare the soil, weed or clean/wash/sort the potatoes
				
		elseif fillTypeName=="manure" then
			density, pricePerKg, fillableClass = 0.65, 0.020, MrLightUtils.FILLABLE_CLASS_CHAFF;	--20€/T
		elseif fillTypeName=="liquidmanure" then
			density, pricePerKg, fillableClass = 0.92, 0.007, MrLightUtils.FILLABLE_CLASS_FLUIDS;	--7€/T
			
		elseif fillTypeName=="seeds" then
			density, pricePerKg, fillableClass = 0.654, 0, MrLightUtils.FILLABLE_CLASS_UNKNOWN;	--bassaddict: Density averaged over the different seed types since density for each seed type is not implemented. Maybe a future feature.
					
		--*************************** WINDROW filltype
		elseif fillTypeName=="wheat_windrow" then
			density, pricePerKg, fillableClass = 0.040, 0.040*MrLightUtils.PriceBalanceFactors.windrow, MrLightUtils.FILLABLE_CLASS_CHAFF;	--40€/T
		elseif fillTypeName=="barley_windrow" then
			density, pricePerKg, fillableClass = 0.036, 0.044*MrLightUtils.PriceBalanceFactors.windrow, MrLightUtils.FILLABLE_CLASS_CHAFF;	--44€/T
		elseif fillTypeName=="drygrass_windrow" or fillTypeName=="drygrass" then
			density, pricePerKg, fillableClass = 0.050, 0.085*MrLightUtils.PriceBalanceFactors.windrow, MrLightUtils.FILLABLE_CLASS_CHAFF; -- 85€/T			
		elseif fillTypeName=="grass_windrow" or fillTypeName=="grass" then
			density, pricePerKg, fillableClass = 0.25, 0.015*MrLightUtils.PriceBalanceFactors.windrow, MrLightUtils.FILLABLE_CLASS_CHAFF; -- 15€/T	 
			
		--*************************** OTHER filltype
		elseif fillTypeName=="silage" then
			density, pricePerKg, fillableClass = 0.4, 0.175*MrLightUtils.PriceBalanceFactors.silage, MrLightUtils.FILLABLE_CLASS_CHAFF;	--175€/T   compress silage = 0.85 density / uncompressed = 0.4
		elseif fillTypeName=="forage_mixing" then -- TMR
			density, pricePerKg, fillableClass = 0.2, 0.300, MrLightUtils.FILLABLE_CLASS_CHAFF; --300€/T
		
		elseif fillTypeName=="fuel" then
			density, pricePerKg, fillableClass = 0.83, 1.025*MrLightUtils.PriceBalanceFactors.fuel, MrLightUtils.FILLABLE_CLASS_FLUIDS;	--0.85€/L == 1.025€/Kg.  
		elseif fillTypeName=="fertilizer" then
			density, pricePerKg, fillableClass = 1.28, 0.190*MrLightUtils.PriceBalanceFactors.fertilizer, MrLightUtils.FILLABLE_CLASS_UNKNOWN;	--230€/M3 == 190€/T.   factor 4 to balance gameplay
			
		elseif fillTypeName=="milk" then
			density, pricePerKg, fillableClass = 1.03, 0.485*MrLightUtils.PriceBalanceFactors.milk, MrLightUtils.FILLABLE_CLASS_FLUIDS; -- 0.5€/L = 0.485€/kg
		elseif fillTypeName=="egg" then
			density, pricePerKg, fillableClass = 0.37, 1.35*MrLightUtils.PriceBalanceFactors.egg, MrLightUtils.FILLABLE_CLASS_UNKNOWN; -- density of an egg box, price = 0.50€ per egg for not-industrial eggs (1 egg = 60g)   the pricePerLiter for egg = price for 1 egg in the game.   Factor 10 to balance gameplay (you have to manually pick up eggs in the game)
		elseif fillTypeName=="wool" then -- 50kg/m3
			density, pricePerKg, fillableClass = 0.05, 1*MrLightUtils.PriceBalanceFactors.wool, MrLightUtils.FILLABLE_CLASS_UNKNOWN;	-- "real" price = 1€/kg -- wanted price ingame (hard difficulty) = 1€/L -> 20€/kg (there is already the priceBalancing applied, that means we need a woolPriceBalancing of 4)
			
		elseif fillTypeName=="water" then
			density, pricePerKg, fillableClass = 1, 0, MrLightUtils.FILLABLE_CLASS_FLUIDS;		
			
		elseif fillTypeName=="woodchips" then
			density, pricePerKg, fillableClass = 0.21, 0.130*MrLightUtils.PriceBalanceFactors.woodChips, MrLightUtils.FILLABLE_CLASS_CHAFF;	-- 130€/T
			
		elseif fillTypeName=="treesaplings" then
			density, pricePerKg, fillableClass = 10, 2.765, MrLightUtils.FILLABLE_CLASS_UNKNOWN;	-- 1L = 1 seedling = 10kgs / 17 seedling = 470€ => 2.765€ per kilo		
			
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
	
	return found, density, pricePerKg, pricePerLiter, fillableClass;
end;

function MrLightUtils.setFillableInfos(fillTypeName, newGame)
	local desc = Fillable.fillTypeNameToDesc[fillTypeName];	
	local found, density, pricePerKg, pricePerLiter, fillableClass = MrLightUtils.getFillableInfos(desc.name);
	
	if found then
		desc.massPerLiter = density * 0.001;
		desc.startPricePerLiter = pricePerLiter;
		desc.fillableClass = fillableClass;
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
			seedPrice, usage, yield, windrowYield = 0, 0, 8.22, 0; -- this is just a factor. goal: maize chaff with 125000L / ha = 50T
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
			print(string.format("WARNING: MR-Light detected a corrupted fruit! Fruit '%s' does not use the proper data structure given by GIANTS Software", desc.name));
			desc.seedUsagePerSqm = 0.1;
			desc.seedPricePerLiter = 0.1;
		elseif desc.seedUsagePerSqm > 0 then
			--set sell price as seed price
			local fillType = FruitUtil.fruitTypeToFillType[desc.index];
			desc.seedPricePerLiter = Fillable.fillTypeIndexToDesc[fillType].pricePerLiter;
		end;
	end;
end;

function MrLightUtils.setWoodTrunksPrice()
	for _,splitType in pairs(SplitUtil.splitTypes) do
		splitType.pricePerLiter = splitType.pricePerLiter * MrLightUtils.PriceBalanceFactorGlobal * MrLightUtils.PriceBalanceFactors.woodTrunks;
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
	
	MrLightUtils.setWoodTrunksPrice();
	print("--- MRL: fruit data set");
end;




function MrLightUtils:reloadVehicleConfigFile()
	local xmlPath = MrLightUtils.modDir.."mrLightSettings.xml";
	if fileExists(xmlPath) then
		local xmlFile = loadXMLFile("settings", xmlPath);
		MrLightUtils.loadVehicleConfigs(xmlFile);
		delete(xmlFile);
	end;
end;
addConsoleCommand('aReloadMrlightVehicleConfig', 'set rotation for attacher joint', 'reloadVehicleConfigFile', MrLightUtils);





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





--**********************************************--
--*   get working width from workAreas table   *--
--**********************************************--
function MrLightUtils.getWorkingWidth(workAreas, rootNode)
	local minX = 1000;
	local maxX = -1000;
	if workAreas ~= nil then
		for _,workArea in pairs(workAreas) do
		
			local x1,y1,z1 = getWorldTranslation(workArea.start)
			local x2,y2,z2 = getWorldTranslation(workArea.width)
			local x3,y3,z3 = getWorldTranslation(workArea.height)
			local lx1,ly1,lz1 = worldToLocal(rootNode,x1,y1,z1)
			local lx2,ly2,lz2 = worldToLocal(rootNode,x2,y2,z2)
			local lx3,ly3,lz3 = worldToLocal(rootNode,x3,y3,z3)
			
			if lx1 < minX then
				minX = lx1;
			end
			if lx1 > maxX then
				maxX = lx1;
			end
			if lx2 < minX then
				minX = lx2;
			end
			if lx2 > maxX then
				maxX = lx2;
			end
			if lx3 < minX then
				minX = lx3;
			end
			if lx3 > maxX then
				maxX = lx3;
			end
		end;
	end;
	return math.min(math.abs(maxX - minX), 50); --no wider than 50m allowed, backup to prevent insane values in case the workAreas aren't detected correctly.
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
			setXMLFloat(xmlFile, "settings.balancing.woodTrunksPriceBalancing#value", MrLightUtils.PriceBalanceFactors.woodTrunks);
			saveXMLFile(xmlFile);
		end;
	end;
end;



local oldDriveInDirection = AIVehicleUtil.driveInDirection;
AIVehicleUtil.driveInDirection = function(self, a,b,c,d,e,f,g,h,i,j,k)
	local newB = b / 2;
	local newE = e / 2;
	oldDriveInDirection(self, a,newB,c,d,newE,f,g,h,i,j,k);
	--print(string.format("self: %s, a: %s,newB: %s,c: %s,d: %s,newE: %s,f: %s,g: %s,h: %s,i: %s,j: %s,k: %s", tostring(self), tostring(a), tostring(newB), tostring(c), tostring(d), tostring(newE), tostring(f), tostring(g), tostring(h), tostring(i), tostring(j), tostring(k)));
end;



function Utils.loadParticleSystemFromData(data, particleSystems, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
    if defaultLinkNode == nil then
        defaultLinkNode = linkNodes;
        if type(linkNodes) == "table" then
            defaultLinkNode = linkNodes[1].node
        end;
    end;
    local linkNode = Utils.getNoNil(Utils.indexToObject(linkNodes, data.nodeStr), defaultLinkNode);
    local psFile = data.psFile;
    if psFile == nil then
        psFile = defaultPsFile;
    end;
    if psFile == nil then
        return;
    end;
	psFile = Utils.convertFromNetworkFilename(psFile);
    psFile = Utils.getFilename(psFile, baseDir);
	
	
	--print("psFile: " .. psFile);
	
	
	
    local rootNodeFile = loadI3DFile(psFile, true, true, false);
    local rootNode = rootNodeFile;
    if rootNode == 0 then
        print("Error: failed to load particle system "..psFile);
        return;
    end;

    if data.psRootNodeStr ~= nil then
        local newRootNode = Utils.indexToObject(rootNode, data.psRootNodeStr);
        if newRootNode ~= nil then
            rootNode = newRootNode;
        end;
    end;
    if linkNode ~= nil then
        link(linkNode, rootNode);
    end;
    local posX, posY, posZ = data.posX, data.posY, data.posZ;
    if posX ~= nil and posY ~= nil and posZ ~= nil then
        setTranslation(rootNode, posX, posY, posZ);
    end;
    local rotX, rotY, rotZ = data.rotX, data.rotY, data.rotZ;
    if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
        setRotation(rootNode, rotX, rotY, rotZ);
    end;

    local returnValue = Utils.loadParticleSystemFromNode(rootNode, particleSystems, defaultEmittingState, data.forceNoWorldSpace, data.forceFullLifespan);
    if rootNode ~= rootNodeFile then
        delete(rootNodeFile);
    end;

    return returnValue;
end

--Utils.loadParticleSystemFromData = Utils.overwrittenFunction(Utils.loadParticleSystemFromData, MrLightUtils.loadParticleSystemFromData);


--[[function Utils.getModNameAndBaseDirectory(filename)
    local modName = nil;
    local baseDirectory = "";
    local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(filename)
    --if isMod or isDlc then
	if filename ~= modFilename then
		local f,l = modFilename:find("/");
		if f ~= nil and l ~= nil and f>1 then
			modName = modFilename:sub(1, f-1);
			if isDlc then
				baseDirectory = g_dlcsDirectories[dlcsDirectoryIndex].path .."/"..modName.."/";
				if g_dlcModNameHasPrefix[modName] then
					modName = g_uniqueDlcNamePrefix..modName;
				end
			elseif isMod then
				baseDirectory = g_modsDirectory.."/"..modName.."/";
			else
				print("MRL Notice: Something went really wrong in Utils.getModNameAndBaseDirectory!");
				print("    filename: " .. tostring(filename));
				print("    modFilename: " .. tostring(modFilename));
			end;
		end;
	else
		print("MRL Notice: filename is equals modFilename, " .. filename);
    end;
    return modName, baseDirectory;
end;]]

--Utils.getModNameAndBaseDirectory = Utils.overwrittenFunction(Utils.getModNameAndBaseDirectory, MrLightUtils.getModNameAndBaseDirectory);



-- overwrite mixer wagon bale trigger for correct bale decompression
MixerWagon.mixerWagonBaleTriggerCallback = function(self, triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter then
        -- this happens if a compound child of a deleted compound is entering
        if otherActorId ~= 0 then
            local object = g_currentMission:getNodeObject(otherActorId);
            if object ~= nil then
                if object:isa(Bale) then
					local decompressionFactor = 1.5; -- decompress bales by factor 1.5
                    local fillLevel = object:getFillLevel();
                    local fillType = object:getFillType();
					local width = object.baleWidth;
					local length = object.baleLength;
					local height = object.baleHeight;
					local diameter = object.baleDiameter;
                    if self:allowFillType(fillType, false) then
						local newFillLevel = fillLevel;
						if diameter ~= nil and width ~= nil then
							newFillLevel = math.pi * (diameter / 2)^2 * width * 1000 * decompressionFactor;
						elseif width ~= nil and length ~= nil and height ~= nil then
							newFillLevel = width * length * height * 1000 * decompressionFactor;
						end;
                        self:setFillLevel(self:getFillLevel(fillType)+newFillLevel, fillType, false);
                    end
                    object:delete();
                    self.mixingActiveTimer = self.mixingActiveTimerMax;
                    self:raiseDirtyFlags(self.mixerWagonDirtyFlag);
                end;
            end;
        end;
    end;
end;