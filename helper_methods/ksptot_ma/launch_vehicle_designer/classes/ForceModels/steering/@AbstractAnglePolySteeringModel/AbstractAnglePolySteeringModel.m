classdef(Abstract) AbstractAnglePolySteeringModel < AbstractSteeringModel
    %AbstractAnglePolySteeringModel Summary of this class goes here
    %   Detailed explanation goes here
        
    methods 
        [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
        
        angleModel = getAngleNModel(obj, n)
        
        [tf, lb, ub] = getAngleNModelOptVarParams(obj, n)
        
        function addActionTf = openEditSteeringModelUI(obj, lv)
            fakeAction = struct();
            fakeAction.steeringModel = obj;
            
            addActionTf = lvd_EditActionSetSteeringModelGUI(fakeAction, lv);
        end
    end
end