VehicleManipulation = {};

function VehicleManipulation.prerequisitesPresent(specializations)
    return true;
end;

function VehicleManipulation:load(xmlFile)
	self.firstRunVehicleManipulation = true;
	
	
	self.debugRender = false;
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
		--print("--VehicleManipulation first update "..self.configFileName);
		
		if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
			if MrLightUtils.vehicleConfigs[self.configFileName].masses ~= nil then
				-print("--VehicleManipulation vehicle exists, masses exists, "..self.configFileName);
				local numComponents = #self.components;
				if numComponents > 1 then
					local massesT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].masses);
					if #massesT == numComponents then
						for k,v in pairs(massesT) do
							--print("--VehicleManipulation set mass multiple components "..tostring(v));
							setMass(self.components[k].node, tonumber(v));
							--print("--mass: "..tostring(getMass(self.components[k].node)));
						end;
					else
						print("WARNING: number of masses in configFile not equals number of components for vehicle "..self.configFileName);
					end;
				elseif numComponents == 1 then
					--print("--VehicleManipulation set mass single component");
					setMass(self.rootNode, MrLightUtils.vehicleConfigs[self.configFileName].masses);
				end;
			end;
		end;
	end;
	
end;

function VehicleManipulation:draw()
	if self.debugRender then
		--setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		--setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;