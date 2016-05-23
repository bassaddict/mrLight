AnimatedVehicleManipulation = {};

function AnimatedVehicleManipulation.prerequisitesPresent(specializations)
    return true;
end;

function AnimatedVehicleManipulation:load(xmlFile)
	--self.firstRunAnimatedVehicleManipulation = true;
	
	if MrLightUtils ~= nil and MrLightUtils.vehicleConfigs[self.configFileName] ~= nil and MrLightUtils.vehicleConfigs[self.configFileName].xmlFile ~= nil then
		local xmlPath = MrLightUtils.modDir .. "" .. MrLightUtils.vehicleConfigs[self.configFileName].xmlFile;
		xmlFile = loadXMLFile("settings", xmlPath);
	end;
	
	
	local i=0;
    while true do
        local key = string.format("vehicle.animations.animation(%d)", i);
        if not hasXMLProperty(xmlFile, key) then
            break;
        end;

        local name = getXMLString(xmlFile, key.."#mrlOrigAnimName");
        if name ~= nil and self.animations[name] ~= nil then
			--print(name);
            local animation = self.animations[name];
            animation.currentTime = 0;
            animation.currentSpeed = 1;
            animation.looping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#looping"), false);

            local partI = 0;
            while true do
                local partKey = key..string.format(".part(%d)", partI);
                if not hasXMLProperty(xmlFile, partKey) then
                    break;
                end;
				
				local origPartIndex = getXMLInt(xmlFile, partKey .. "#mrlOrigPartIndex");
				local part = {};
				local newPart = false;
				if origPartIndex ~= nil then
					part = animation.parts[origPartIndex];
					--print("part" .. origPartIndex);
				else
					newPart = true;
				end;

                local node = Utils.indexToObject(self.components, getXMLString(xmlFile, partKey.."#node"));
                local startTime = getXMLFloat(xmlFile, partKey.."#startTime");
                local duration = getXMLFloat(xmlFile, partKey.."#duration");
                local endTime = getXMLFloat(xmlFile, partKey.."#endTime");
                local direction = Utils.sign(Utils.getNoNil(getXMLInt(xmlFile, partKey.."#direction"), 0));
                local startRot = Utils.getRadiansFromString(getXMLString(xmlFile, partKey.."#startRot"), 3);
                local endRot = Utils.getRadiansFromString(getXMLString(xmlFile, partKey.."#endRot"), 3);
                local startTrans = Utils.getVectorNFromString(getXMLString(xmlFile, partKey.."#startTrans"), 3);
                local endTrans = Utils.getVectorNFromString(getXMLString(xmlFile, partKey.."#endTrans"), 3);
                local startScale = Utils.getVectorNFromString(getXMLString(xmlFile, partKey.."#startScale"), 3);
                local endScale = Utils.getVectorNFromString(getXMLString(xmlFile, partKey.."#endScale"), 3);
                local visibility = getXMLBool(xmlFile, partKey.."#visibility");
                local componentJointIndex = getXMLInt(xmlFile, partKey.."#componentJointIndex");
                local componentJoint;
                if componentJointIndex ~= nil then
                    componentJoint = self.componentJoints[componentJointIndex+1];
                end
                local startRotLimit = Utils.getRadiansFromString(getXMLString(xmlFile, partKey.."#startRotLimit"), 3);
                local endRotLimit = Utils.getRadiansFromString(getXMLString(xmlFile, partKey.."#endRotLimit"), 3);
                local startTransLimit = Utils.getVectorNFromString(getXMLString(xmlFile, partKey.."#startTransLimit"), 3);
                local endTransLimit = Utils.getVectorNFromString(getXMLString(xmlFile, partKey.."#endTransLimit"), 3);

                if startTime ~= nil and (duration ~= nil or endTime ~= nil) and
                  ( (node ~= nil and (endRot ~= nil or endTrans ~= nil or endScale ~= nil or visibility ~= nil)) or
                    (componentJoint ~= nil and (endRotLimit ~= nil or endTransLimit ~= nil)))
                then
                    if endTime ~= nil then
                        duration = endTime - startTime;
                    end;
                    part.node = node;
                    part.startTime = startTime*1000;
                    part.duration = duration*1000;
                    part.direction = direction;
                    if node ~= nil then
                        if endRot ~= nil then
                            part.startRot = startRot;
                            part.endRot = endRot;
                        end;
                        if endTrans ~= nil then
                            part.startTrans = startTrans;
                            part.endTrans = endTrans;
                        end;
                        if endScale ~= nil then
                            part.startScale = startScale;
                            part.endScale = endScale;
                        end;

                        part.visibility = visibility;
                    end
                    if self.isServer then
                        if componentJoint ~= nil then
                            if endRotLimit ~= nil then
                                part.componentJoint = componentJoint;
                                part.startRotLimit = startRotLimit;
                                part.endRotLimit = endRotLimit;
                            end
                            if endTransLimit ~= nil then
                                part.componentJoint = componentJoint;
                                part.startTransLimit = startTransLimit;
                                part.endTransLimit = endTransLimit;
                            end
                        end
                    end
					if newPart then
						table.insert(animation.parts, part);
					end;
                end;
                partI = partI + 1;
            end;

            -- sort parts by start/end time
            animation.partsReverse = {};
            for _, part in ipairs(animation.parts) do
                table.insert(animation.partsReverse, part);
            end;
            table.sort(animation.parts, AnimatedVehicle.animPartSorter);
            table.sort(animation.partsReverse, AnimatedVehicle.animPartSorterReverse);

            AnimatedVehicle.initializeParts(self, animation);

            animation.currentPartIndex = 1;
            animation.duration = 0;
            for _, part in ipairs(animation.parts) do
                animation.duration = math.max(animation.duration, part.startTime + part.duration);
            end;

            --self.animations[name] = animation;
        end;

        i = i+1;
    end;
	
	--self.debugRenderAnimatedVehicleManipulation = false;
end;

function AnimatedVehicleManipulation:delete()
end;

function AnimatedVehicleManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AnimatedVehicleManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function AnimatedVehicleManipulation:update(dt)
end;

function AnimatedVehicleManipulation:draw()
end;