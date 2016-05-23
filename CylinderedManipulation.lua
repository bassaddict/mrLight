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
	
	self.debugRenderCylinderedManipulation = false;
end;

function CylinderedManipulation:delete()
end;

function CylinderedManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function CylinderedManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function CylinderedManipulation:update(dt)
end;

function CylinderedManipulation:draw()
end;