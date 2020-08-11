classdef LaunchVehicleDerivativeCalcState < AbstractLaunchVehicleCalculusState
    %LaunchVehicleDerivativeCalcState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods     
        function obj = LaunchVehicleDerivativeCalcState(derivCalcObj)
            obj.calcObj = derivCalcObj;
        end
        
        function deriv = getValueAtTime(obj,time)
            [deriv,~,~] = derivest(obj.gridInterp, time, 'DerivativeOrder',1, 'MethodOrder',2, 'Style','central', 'Vectorized','yes');
            
            if(isnan(deriv))
                [deriv,~,~] = derivest(obj.gridInterp, time, 'DerivativeOrder',1, 'MethodOrder',2, 'Style','forward', 'Vectorized','yes');
                
                if(isnan(deriv))
                    [deriv,~,~] = derivest(obj.gridInterp, time, 'DerivativeOrder',1, 'MethodOrder',2, 'Style','backward', 'Vectorized','yes');
                end
                
%                 if(isnan(deriv))
%                     error('Derivative value is NaN: %s', obj.calcObj.quantStr);
%                 end
            end
        end
    end
end