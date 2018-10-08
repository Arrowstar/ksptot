classdef InitialStateVariable < AbstractOptimizationVariable
    %InitialStateVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) InitialStateModel = InitialStateModel();
        
        %For Time var
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) = false;
        
        %For Orbit
        orbitVar AbstractOrbitModelVariable
    end
    
    methods
        function obj = InitialStateVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            if(isa(obj.varObj.orbitModel,'BodyFixedOrbitStateModel'))
                obj.orbitVar = BodyFixedOrbitVariable(obj.varObj.orbitModel);
            elseif(isa(obj.varObj.orbitModel,'KeplerianOrbitStateModel'))
                obj.orbitVar = KeplerianOrbitVariable(obj.varObj.orbitModel);
            else
                error('Unknown orbit type while creating initial state variable: %s', class(obj.varObj.orbitModel))
            end
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x(end+1) = obj.varObj.time;
            end
            x = horzcat(x, obj.orbitVar.getXsForVariable());
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(obj.useTf);
            ub = obj.ub(obj.useTf);
            
            [oLb, oUb] = obj.orbitVar.getBndsForVariable();
            lb = horzcat(lb, oLb);
            ub = horzcat(ub, oUb);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.lb;
            
            [oLb, oUb] = obj.orbitVar.getAllBndsForVariable();
            lb = horzcat(lb, oLb);
            ub = horzcat(ub, oUb);
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == 7 && length(ub) == 7)
                obj.lb = lb(1);
                obj.ub = ub(1);

                obj.orbitVar.setBndsForVariable(lb(2:end), ub(2:end));
            else
                useTfVar = obj.getUseTfForVariable();

                if(useTfVar(1))
                    obj.lb(1) = lb(1);
                    obj.ub(1) = ub(1);
                    
                    obj.orbitVar.setBndsForVariable(lb(2:end), ub(2:end));
                else
                    obj.orbitVar.setBndsForVariable(lb, ub);
                end
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
            
            useTf = horzcat(useTf, obj.orbitVar.getUseTfForVariable());
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf(1);
            
            obj.orbitVar.setUseTfForVariable(useTf(2:end));
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.time = x(1);
        end
    end
end