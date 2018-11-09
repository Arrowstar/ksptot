classdef AscendingNodeTermCondition < LatitudeTermCondition
    %AscendingNodeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = AscendingNodeTermCondition()
            obj = obj@LatitudeTermCondition(0.0);
            obj.direction = 1.0;
        end
                
        function name = getName(obj)
            name = sprintf('Ascending Node');
        end
                
        function params = getTermCondUiStruct(obj)
            params = getTermCondUiStruct@LatitudeTermCondition(obj);  
            
            params.paramName = 'Ascending Node';
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
            termCond = AscendingNodeTermCondition();
        end
    end
end