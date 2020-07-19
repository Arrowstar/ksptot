classdef LaunchVehicleGroundObjectSet < matlab.mixin.SetGet
    %LaunchVehicleGroundObjectSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        groundObjs(1,:) LaunchVehicleGroundObject = LaunchVehicleGroundObject.empty(1,0);
        
        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicleGroundObjectSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addGroundObj(obj, groundObj)
            obj.groundObjs(end+1) = groundObj;
        end
        
        function removeGroundObj(obj, groundObj)
            obj.groundObjs([obj.groundObjs] == groundObj) = [];
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.groundObjs))
                listBoxStr{end+1} = obj.groundObjs(i).name; %#ok<AGROW>
            end
        end
        
        function groundObjects = getGroundObjsForInds(obj, inds)
            groundObjects = obj.groundObjs(inds);
        end
        
        function inds = getIndsForGroundObjs(obj, grdObjs)
            inds = find(ismember(grdObjs, obj.groundObjs));
        end
        
        function grndObj = getGroundObjAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.groundObjs))
                grndObj = obj.groundObjs(ind);
            else
                grndObj = LaunchVehicleGroundObject.empty(1,0);
            end
        end
        
        function numGrndObjs = getNumGroundObj(obj)
            numGrndObjs = length(obj.groundObjs);
        end
    end
end

