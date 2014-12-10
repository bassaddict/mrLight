CylinderedManipulation = {};

function CylinderedManipulation.prerequisitesPresent(specializations)
    return true;
end;

function CylinderedManipulation:load(xmlFile)
	self.firstRunCylinderedManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
		if MrLightUtils.vehicleConfigs[self.configFileName].fixCraneAxis ~= nil then
			for _,v in pairs(self.movingTools) do
				if v.axis ~= nil then
					if v.axis == "AXIS_FRONTLOADER_TOOL" then
						v.axis = "AXIS_FRONTLOADER_ARM2";
						v.axisActionIndex = InputBinding[v.axis];
						v.invertAxis = not v.invertAxis;
						v.invertMouseAxis = v.invertAxis;
					elseif v.axis == "AXIS_FRONTLOADER_ARM2" then
						v.axis = "AXIS_FRONTLOADER_TOOL";
						v.invertAxis = not v.invertAxis;
						v.invertMouseAxis = v.invertAxis;
						v.axisActionIndex = InputBinding[v.axis];
					end;
					
				end;
			end;
			
			local tt = {}
			for k,v in pairs(self.mouseControlsIcons.AXIS_FRONTLOADER_TOOL) do
				tt[k] = v;
			end;
			self.mouseControlsIcons.AXIS_FRONTLOADER_TOOL = {};
			for k,v in pairs(self.mouseControlsIcons.AXIS_FRONTLOADER_ARM2) do
				self.mouseControlsIcons.AXIS_FRONTLOADER_TOOL[k] = v;
			end;
			for k,v in pairs(tt) do
				self.mouseControlsIcons.AXIS_FRONTLOADER_ARM2[k] = v;
			end;
		end;
	end;
	
	self.debugRender = false;
end;

function CylinderedManipulation:delete()
end;

function CylinderedManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function CylinderedManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function CylinderedManipulation:update(dt)

	if self.firstRunCylinderedManipulation then
		self.firstRunCylinderedManipulation = false;
		--print("--CylinderedManipulation first update "..self.configFileName);
		
		if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil then
			if MrLightUtils.vehicleConfigs[self.configFileName].masses ~= nil then
				--print("--CylinderedManipulation vehicle exists, masses exists, "..self.configFileName);
				local numComponents = #self.components;
				if numComponents > 1 then
					local massesT = Utils.splitString(" ", MrLightUtils.vehicleConfigs[self.configFileName].masses);
					if #massesT == numComponents then
						for k,v in pairs(massesT) do
							--print("--CylinderedManipulation set mass multiple components "..tostring(v));
							setMass(self.components[k].node, tonumber(v));
							--print("--mass: "..tostring(getMass(self.components[k].node)));
						end;
					else
						print("WARNING: number of masses in configFile not equals number of components for vehicle "..self.configFileName);
					end;
				elseif numComponents == 1 then
					--print("--CylinderedManipulation set mass single component");
					setMass(self.rootNode, MrLightUtils.vehicleConfigs[self.configFileName].masses);
				end;
			end;
		end;
	end;
	
end;

function CylinderedManipulation:draw()
	if self.debugRender then
		--setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		--setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;