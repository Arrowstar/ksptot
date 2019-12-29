classdef SetKinematicStateActionVariable < AbstractOptimizationVariable
    %InitialStateVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) SetKinematicStateAction = SetKinematicStateAction();
        
        %For Time var
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        useTf(1,1) = false;
        
        %For Orbit
        orbitVar AbstractOrbitModelVariable
    end
    
    methods
        function obj = SetKinematicStateActionVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            switch obj.varObj.orbitModel.typeEnum
                case ElementSetEnum.CartesianElements
                    obj.orbitVar = CartesianElementSetVariable(obj.varObj.orbitModel);
                    
                case ElementSetEnum.KeplerianElements
                    obj.orbitVar = KeplerianElementSetVariable(obj.varObj.orbitModel);
                    
                case ElementSetEnum.GeographicElements
                    obj.orbitVar = GeographicElementSetVariable(obj.varObj.orbitModel);
                    
                otherwise
                    error('Unknown orbit type while creating initial state variable: %s', class(obj.varObj.orbitModel.typeEnum))
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
            if(obj.useTf)
                obj.varObj.time = x(1);
                obj.orbitVar.updateObjWithVarValue(x(2:end));
            else
                obj.orbitVar.updateObjWithVarValue(x(1:end));
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum)
            nameStrs = horzcat(sprintf('Event %i Time', evtNum), obj.orbitVar.getStrNamesOfVars(evtNum));
        end
    end
end