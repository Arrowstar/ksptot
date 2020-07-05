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
        
        function plotTrajectoryWithActiveViewProfile(obj, handles)
            obj.selViewProfile.plotTrajectory(obj.lvdData, handles);
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
    end
    
    methods(Static)
        function obj = loadobj(obj)
            for(i=1:length(obj.viewProfiles))
                profile = obj.viewProfiles(i);

                if(isempty(profile.frame))
                    profile.frame = BodyCenteredInertialFrame(obj.lvdData.initialState.centralBody, obj.lvdData.celBodyData);                    
                end
            end
        end
    end
end

