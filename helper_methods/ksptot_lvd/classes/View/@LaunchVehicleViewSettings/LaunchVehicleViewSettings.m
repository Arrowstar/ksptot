classdef LaunchVehicleViewSettings < matlab.mixin.SetGet
    %LaunchVehicleViewSettings Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        viewProfiles(1,:) LaunchVehicleViewProfile

        selViewProfile LaunchVehicleViewProfile 

        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicleViewSettings(lvdData)
            obj.lvdData = lvdData;
            
            newProfile = LaunchVehicleViewProfile();
            newProfile.name = 'Default LVD View Profile';
            
            obj.viewProfiles(1) = newProfile;
            obj.selViewProfile = newProfile;
        end
        
        function plotTrajectoryWithActiveViewProfile(obj, handles, app)
            obj.selViewProfile.plotTrajectory(obj.lvdData, handles, app);
        end
        
        function addViewProfile(obj, newProfile)
            obj.viewProfiles(end+1) = newProfile;
        end
        
        function removeViewProfile(obj, profile)
            obj.viewProfiles([obj.viewProfiles] == profile) = [];
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.viewProfiles))
                if(obj.viewProfiles(i) == obj.selViewProfile)
                    listBoxStr{end+1} = sprintf('*%s',obj.viewProfiles(i).name); %#ok<AGROW>
                else
                    listBoxStr{end+1} = obj.viewProfiles(i).name; %#ok<AGROW>
                end
            end
        end
        
        function viewProfiles = getProfilesArray(obj)
            viewProfiles = obj.viewProfiles;
        end
        
        function numProfiles = getNumProfiles(obj)
            numProfiles = length(obj.viewProfiles);
        end
        
        function profile = getProfileAtInd(obj, ind)
            profile = obj.viewProfiles(ind);
        end
        
        function moveProfileAtIndexDown(obj, ind)
            if(ind < length(obj.viewProfiles))
                obj.viewProfiles([ind+1,ind]) = obj.viewProfiles([ind,ind+1]);
            end
        end
        
        function moveProfileAtIndexUp(obj, ind)
            if(ind > 1)
                obj.viewProfiles([ind,ind-1]) = obj.viewProfiles([ind-1,ind]);
            end
        end
        
        function setProfileAsActive(obj, profile)
            obj.selViewProfile = profile;
        end
        
        function ind = getIndOfSelectedProfile(obj)
            ind = find([obj.viewProfiles] == obj.selViewProfile,1,'first');
        end
        
        function setProfileAtIndAsActive(obj, ind)
            obj.setProfileAsActive(obj.getProfileAtInd(ind));
        end
        
        function tf = isProfileActive(obj,profile)
            if(obj.selViewProfile == profile)
                tf = true;
            else
                tf = false;
            end
        end
        
        function removeGrdObjFromViewProfiles(obj, grdObj)
            for(i=1:length(obj.viewProfiles)) %#ok<*NO4LP> 
                obj.viewProfiles(i).removeGrdObjFromList(grdObj);
            end
        end
        
        function removeGeoPointFromViewProfiles(obj, point)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeGeoPointFromList(point);
            end
        end
        
        function removeGeoVectorFromViewProfiles(obj, vector)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeGeoVectorFromList(vector);
            end
        end
        
        function removeGeoRefFrameFromViewProfiles(obj, refFrame)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeGeoRefFrameFromList(refFrame);
            end
        end
        
        function removeGeoAngleFromViewProfiles(obj, angle)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeGeoAngleFromList(angle);
            end
        end
        
        function removeGeoPlaneFromViewProfiles(obj, plane)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeGeoPlaneFromList(plane);
            end
        end
        
        function removeSensorFromViewProfiles(obj, sensor)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeSensorFromList(sensor);
            end
        end
        
        function removeSensorTargetsFromViewProfiles(obj, target)
            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeSensorTargetFromList(target);
            end
        end

        function removeEventFromListOfPlottedEvents(obj, event)
            arguments
                obj(1,1) LaunchVehicleViewSettings
                event(1,1) LaunchVehicleEvent
            end

            for(i=1:length(obj.viewProfiles))
                obj.viewProfiles(i).removeEventFromListOfPlottedEvents(event);
            end
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            % Handle struct case from older MAT files where viewProfiles is struct array
            if isstruct(obj)
                % ViewSettings was saved as struct? Nothing to do - will be converted via default
                return;
            end
            for(i=1:length(obj.viewProfiles))
                profile = obj.viewProfiles(i);

                if(isempty(profile.frame))
                    try
                        profile.frame = obj.lvdData.initialState.centralBody.getBodyCenteredInertialFrame();
                    catch
                    end
                end

                % Skybox migration: ensure skyboxTexture /Custom path and manager exist
                try
                    % If struct array element is still struct (due to class change), convert?
                    if isstruct(profile)
                        continue;
                    end
                    if isempty(profile.skyboxManager) || ~isvalid(profile.skyboxManager)
                        profile.skyboxManager = SkyboxManager(profile);
                    end
                    % Sync deprecated string -> enum (handles both previous string and new enum)
                    try
                        profile.syncSkyboxTextureFromDeprecated();
                    catch
                    end
                    % Ensure deprecated handle transients are cleared (they are transient anyway)
                catch
                end
            end

            % Validate selViewProfile still exists in list; if not, reset to first
            try
                if ~isempty(obj.selViewProfile)
                    found = false;
                    for i=1:length(obj.viewProfiles)
                        if obj.viewProfiles(i) == obj.selViewProfile
                            found = true;
                            break;
                        end
                    end
                    if ~found && ~isempty(obj.viewProfiles)
                        obj.selViewProfile = obj.viewProfiles(1);
                    end
                elseif ~isempty(obj.viewProfiles)
                    obj.selViewProfile = obj.viewProfiles(1);
                end
            catch
            end
        end
    end
end

