classdef DescendingNodeTermCondition < LatitudeTermCondition
    %DescendingNodeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = DescendingNodeTermCondition()
            obj = obj@LatitudeTermCondition(0.0);
            obj.direction = -1.0;
        end
                
        function name = getName(obj)
            name = sprintf('Descending Node');
        end
                
        function params = getTermCondUiStruct(obj)
            params = getTermCondUiStruct@LatitudeTermCondition(obj);  
            
            params.paramName = 'Descending Node';
            params.paramUnit = '';
            params.useParam = 'off';
        end
        
        function optVar = getNewOptVar(obj)
            optVar = AbstractOptimizationVariable.empty(0,1);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine)
            termCond = DescendingNodeTermCondition();
        end
    end
end