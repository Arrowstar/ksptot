classdef(Abstract) AbstractAnglePolySteeringModel < AbstractSteeringModel
    %AbstractAnglePolySteeringModel Summary of this class goes here
    %   Detailed explanation goes here
   
    methods 
        [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
        
        angleModel = getAngleNModel(obj, n)
        
        [tf, lb, ub] = getAngleNModelOptVarParams(obj, n)
        
        setT0(obj, newT0)
        
        setConstTerms(obj, angle1, angle2, angle3)
        
        setLinearTerms(obj, angle1, angle2, angle3)
        
        setAccelTerms(obj, angle1, angle2, angle3)
        
        function enum = getSteeringModelTypeEnum(~)
            enum = SteerModelTypeEnum.PolyAngles;
        end
                
        function tf = usesRefFrame(obj)
            tf = false;
        end
        
        function refFrame = getRefFrame(obj)
            refFrame = AbstractReferenceFrame.empty(1,0);
        end
        
        function setRefFrame(obj, refFrame)
            return;
        end
        
        function tf = usesControlFrame(obj)
            tf = false;
        end
        
        function cFrame = getControlFrame(obj)
            cFrame = AbstractControlFrame.empty(1,0);
        end
        
        function setControlFrame(obj, cFrame)
            return;
        end
        
        function tf = requiresReInitAfterSoIChange(obj)
            tf = true;
        end
    end
end