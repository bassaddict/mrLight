TrailerManipulation = {};

function TrailerManipulation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Trailer, specializations);
end;

function TrailerManipulation:load(xmlFile)
	self.firstRunTrailerManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	local i = 0;
    while true do
        local key = string.format("vehicle.tipAnimations.tipAnimation(%d)", i);
        if not hasXMLProperty(xmlFile, key) then
            break;
        end
		local origAnimation = getXMLInt(xmlFile, key .. "#mrlOrigAnimation");
		if origAnimation == nil then
			break;
		end;

        local tipAnimation = self.tipAnimations[origAnimation];
		
        
        if tipAnimation.dischargeEndTime ~= nil then
            if self.isClient then
				if tipAnimation.dischargeParticleSystems == nil then
					tipAnimation.dischargeParticleSystems = {};
				end;
				
                local j = 0;
                while true do
                    local keyPS = string.format(key..".dischargeParticleSystems.dischargeParticleSystem(%d)", j);
                    local t = getXMLString(xmlFile, keyPS .. "#type");
                    if t == nil then
                        break;
                    end;
                    local fillType = Fillable.fillTypeNameToInt[t];
                    if fillType ~= nil then
						print("baseDirectory: " .. self.baseDirectory);
                        local currentPS = Utils.getNoNil(tipAnimation.dischargeParticleSystems[fillType], {});
                        local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, keyPS, self.components, false, nil, self.baseDirectory);
                        tipAnimation.dischargeParticleSystems[fillType] = currentPS;
                    end;
                    j = j + 1;
                end;

                local fillTypes = getXMLString(xmlFile, key..".tipEffect#fillTypes");
                if fillTypes ~= nil then
                    for _, typeStr in pairs(Utils.splitString(" ", fillTypes)) do
                        if Fillable.fillTypeNameToInt[typeStr] ~= nil then
                            if tipAnimation.tipEffectFillTypes == nil then
                                tipAnimation.tipEffectFillTypes = {};
                            end;
                            tipAnimation.tipEffectFillTypes[Fillable.fillTypeNameToInt[typeStr]] = true;
                        end;
                    end;
                end;

                tipAnimation.tipEffect = EffectManager:loadEffect(xmlFile, key..".tipEffect", self.components, self);
            end
        else
            print("Error: invalid tip animation "..i.." in "..self.configFileName);
        end
        i = i + 1;
    end
	
	
	self.debugRenderTrailerManipulation = false;
end;

function TrailerManipulation:delete()
end;

function TrailerManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function TrailerManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function TrailerManipulation:update(dt)

end;

function TrailerManipulation:draw()
	if self.debugRenderTrailerManipulation then
		--setTextAlignment(RenderText.ALIGN_RIGHT);
		--renderText(0.99, 0.80, 0.018, string.format("fillLevel: %.4f, capacity: %.4f", self.fillLevel, self.capacity));
		--setTextAlignment(RenderText.ALIGN_LEFT);
	end;
end;
