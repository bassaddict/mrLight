SpecializationUtil.registerSpecialization("mrLightUtils", "MrLightUtils", g_currentModDirectory.."mrLightUtils.lua");

SpecializationUtil.registerSpecialization("sowingMachineManipulation", "SowingMachineManipulation", g_currentModDirectory.."SowingMachineManipulation.lua");
SpecializationUtil.registerSpecialization("sprayerManipulation", "SprayerManipulation", g_currentModDirectory.."SprayerManipulation.lua");
SpecializationUtil.registerSpecialization("trailerManipulation", "TrailerManipulation", g_currentModDirectory.."TrailerManipulation.lua");
SpecializationUtil.registerSpecialization("fillableManipulation", "FillableManipulation", g_currentModDirectory.."FillableManipulation.lua");
SpecializationUtil.registerSpecialization("balerManipulation", "BalerManipulation", g_currentModDirectory.."BalerManipulation.lua");
SpecializationUtil.registerSpecialization("powerConsumerManipulation", "PowerConsumerManipulation", g_currentModDirectory.."PowerConsumerManipulation.lua");
SpecializationUtil.registerSpecialization("motorizedManipulation", "MotorizedManipulation", g_currentModDirectory.."MotorizedManipulation.lua");
SpecializationUtil.registerSpecialization("drivableManipulation", "DrivableManipulation", g_currentModDirectory.."DrivableManipulation.lua");
SpecializationUtil.registerSpecialization("vehicleManipulation", "VehicleManipulation", g_currentModDirectory.."VehicleManipulation.lua");
SpecializationUtil.registerSpecialization("cylinderedManipulation", "CylinderedManipulation", g_currentModDirectory.."CylinderedManipulation.lua");
SpecializationUtil.registerSpecialization("attachableManipulation", "AttachableManipulation", g_currentModDirectory.."AttachableManipulation.lua");
SpecializationUtil.registerSpecialization("workAreaManipulation", "WorkAreaManipulation", g_currentModDirectory.."WorkAreaManipulation.lua");
SpecializationUtil.registerSpecialization("animatedVehicleManipulation", "AnimatedVehicleManipulation", g_currentModDirectory.."AnimatedVehicleManipulation.lua");
SpecializationUtil.registerSpecialization("baleLoaderManipulation", "BaleLoaderManipulation", g_currentModDirectory.."BaleLoaderManipulation.lua");





loaderClass = {};

loaderClass.firstUpdate = true;
loaderClass.firstLoadMap = true;
MrLightUtils.modDir = g_currentModDirectory;

function loaderClass:loadMap(name)
	
	if loaderClass.firstLoadMap then
		--print("first load map")
		loaderClass.firstLoadMap = false;
		local xmlPath = MrLightUtils.modDir.."mrLightSettings.xml";
		if fileExists(xmlPath) then
			local xmlFile = loadXMLFile("settings", xmlPath);
			MrLightUtils.loadVehicleConfigs(xmlFile);
			delete(xmlFile);
		end;
	end;
	
	--add specializations to vehicles
	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		if not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("vehicleManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("vehicleManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(SowingMachine, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("sowingMachineManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("sowingMachineManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Sprayer, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("sprayerManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("sprayerManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Trailer, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("trailerManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("trailerManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Fillable, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("fillableManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("fillableManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Baler, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("balerManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("balerManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(PowerConsumer, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("powerConsumerManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("powerConsumerManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Motorized, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("motorizedManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("motorizedManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Drivable, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("drivableManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("drivableManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Cylindered, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("cylinderedManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("cylinderedManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(Attachable, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("attachableManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("attachableManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(WorkArea, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("workAreaManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("workAreaManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(AnimatedVehicle, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("animatedVehicleManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("animatedVehicleManipulation"));
		end;
		if SpecializationUtil.hasSpecialization(BaleLoader, v.specializations) and not SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization("baleLoaderManipulation"), v.specializations) then
			table.insert(v.specializations, SpecializationUtil.getSpecialization("baleLoaderManipulation"));
		end;
	end;
	print("--- MRL: specializations added, map loaded");
	
end;

function loaderClass:deleteMap()
	loaderClass.firstLoadMap = true;
	loaderClass.firstUpdate = true;
end;

function loaderClass:mouseEvent(posX, posY, isDown, isUp, button)
end;

function loaderClass:keyEvent(unicode, sym, modifier, isDown)
end;

function loaderClass:update(dt)
	if loaderClass.firstUpdate then
		loaderClass.firstUpdate = false;
		
		MrLightUtils.setStoreData();
		
		
		local xmlFile = "";
		if g_currentMission.missionInfo.isValid then
			local xmlPath = getUserProfileAppPath() .. "savegame".. g_currentMission.missionInfo.savegameIndex .. "/mrLightSettings.xml";
			if fileExists(xmlPath) then
				xmlFile = loadXMLFile("settings", xmlPath);
			end;
		else
			local xmlPath = MrLightUtils.modDir.."mrLightSettings.xml";
			xmlFile = loadXMLFile("settings", xmlPath);
		end;
		if xmlFile ~= nil and xmlFile ~= "" then
			MrLightUtils.setBalancingFactors(xmlFile);
			delete(xmlFile);
		end;
		
		MrLightUtils.setFruitData(not g_currentMission.missionInfo.isValid);
		
		for k,v in pairs(g_currentMission.itemsToSave) do
			if v.item:isa(Bale) then
				local newMass = Fillable.fillTypeIndexToDesc[v.item.fillType].massPerLiter * v.item.fillLevel;
				setMass(v.item.nodeId, newMass);
			end;
		end;
	end;
	
end;

function loaderClass:draw()
end;

addModEventListener(loaderClass);

