classdef(Abstract) AbstractLaunchVehicleCalculusCalc < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLaunchVehicleCalculusCalc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        quantStr char 
        frame AbstractReferenceFrame
        unitStr char
        
        id(1,1) double = 0;

        %Deprecated
        refBody KSPTOT_BodyInfo
    end
    
    methods        
        nameStr = getNameStr(obj);
        
        initState = createInitialState(obj);
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesCalculusCalc(obj);
        end
    end
    
    methods(Sealed)
        function tf = eq(a,b)
            tf = [a.id] == [b.id];
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.frame))
                if(not(isempty(obj.refBody)))
                    obj.frame = obj.refBody.getBodyCenteredInertialFrame();
                else
                    obj.frame = LvdData.getDefaultInitialBodyInfo(obj.lvdData.celBodyData).getBodyCenteredInertialFrame();
                end
            end
        end        
    end
end