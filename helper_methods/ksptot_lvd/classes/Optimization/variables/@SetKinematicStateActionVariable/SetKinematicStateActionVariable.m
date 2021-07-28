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
                    
                case ElementSetEnum.UniversalElements
                    obj.orbitVar = UniversalElementSetVariable(obj.varObj.orbitModel);
                    
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
            
            if(not(isempty(obj.orbitVar)))
                x = horzcat(x, obj.orbitVar.getXsForVariable());
            end
            
            tankStates = obj.varObj.tankStates;
            for(i=1:length(tankStates))
                x = horzcat(x, tankStates(i).optVar.getXsForVariable()); %#ok<AGROW>
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            for(i=1:length(epsStorageStates))
                x = horzcat(x, epsStorageStates(i).optVar.getXsForVariable()); %#ok<AGROW>
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(obj.useTf);
            ub = obj.ub(obj.useTf);
            
            if(not(isempty(obj.orbitVar)))
                [oLb, oUb] = obj.orbitVar.getBndsForVariable();
                lb = horzcat(lb, oLb);
                ub = horzcat(ub, oUb);
            end
            
            tankStates = obj.varObj.tankStates;
            for(i=1:length(tankStates))
                [tLb, tUb] = tankStates(i).optVar.getBndsForVariable();
                lb = horzcat(lb, tLb); %#ok<AGROW>
                ub = horzcat(ub, tUb); %#ok<AGROW>
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            for(i=1:length(epsStorageStates))
                [sLb, sUb] = epsStorageStates(i).optVar.getBndsForVariable();
                lb = horzcat(lb, sLb); %#ok<AGROW>
                ub = horzcat(ub, sUb); %#ok<AGROW>
            end
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.lb;
            
            if(not(isempty(obj.orbitVar)))
                [oLb, oUb] = obj.orbitVar.getAllBndsForVariable();
                lb = horzcat(lb, oLb);
                ub = horzcat(ub, oUb);
            end
            
            tankStates = obj.varObj.tankStates;
            for(i=1:length(tankStates))
                [tLb, tUb] = tankStates(i).optVar.getAllBndsForVariable();
                lb = horzcat(lb, tLb); %#ok<AGROW>
                ub = horzcat(ub, tUb); %#ok<AGROW>
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            for(i=1:length(epsStorageStates))
                [sLb, sUb] = epsStorageStates(i).optVar.getAllBndsForVariable();
                lb = horzcat(lb, sLb); %#ok<AGROW>
                ub = horzcat(ub, sUb); %#ok<AGROW>
            end
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == obj.getNumMaxVariables() && length(ub) == obj.getNumMaxVariables())
                obj.lb = lb(1);
                obj.ub = ub(1);

                obj.orbitVar.setBndsForVariable(lb(2:7), ub(2:7));
                
                ind = 8;
                
                tankStates = obj.varObj.tankStates;
                for(i=1:length(tankStates))
                    tankStates(i).optVar.setBndsForVariable(lb(ind), ub(ind));
                    ind = ind + 1;
                end
                
                epsStorageStates = obj.varObj.epsStorageStates;
                for(i=1:length(epsStorageStates))
                    epsStorageStates(i).optVar.setBndsForVariable(lb(ind), ub(ind));
                    ind = ind + 1;
                end
            else
                ind = 1;
                if(obj.useTf)
                    obj.lb = lb(ind);
                    obj.ub = ub(ind);
                    ind = ind+1;
                end

                oUseTf = obj.orbitVar.getUseTfForVariable();
                oUseTfCnt = sum(oUseTf);
                if(oUseTfCnt > 0)
                    oInds = ind : 1 : ind+oUseTfCnt-1;
                    obj.orbitVar.setBndsForVariable(lb(oInds), ub(oInds));
                    ind = oInds(end) + 1;
                end

                tankStates = obj.varObj.tankStates;
                for(i=1:length(tankStates))
                    if(tankStates(i).optVar.getUseTfForVariable() == true)
                        tankStates(i).optVar.setBndsForVariable(lb(ind), ub(ind));
                        ind = ind + 1;
                    end
                end

                epsStorageStates = obj.varObj.epsStorageStates;
                for(i=1:length(epsStorageStates))
                    if(epsStorageStates(i).optVar.getUseTfForVariable() == true)
                        epsStorageStates(i).optVar.setBndsForVariable(lb(ind), ub(ind));
                        ind = ind + 1;
                    end
                end
            end
            
%             if(length(lb) == 7 && length(ub) == 7)
%                 obj.lb = lb(1);
%                 obj.ub = ub(1);
% 
%                 obj.orbitVar.setBndsForVariable(lb(2:end), ub(2:end));
%             else
%                 useTfVar = obj.getUseTfForVariable();
% 
%                 if(useTfVar(1))
%                     obj.lb(1) = lb(1);
%                     obj.ub(1) = ub(1);
%                     
%                     obj.orbitVar.setBndsForVariable(lb(2:end), ub(2:end));
%                 else
%                     obj.orbitVar.setBndsForVariable(lb, ub);
%                 end
%             end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
            
            useTf = horzcat(useTf, obj.orbitVar.getUseTfForVariable());
            
            tankStates = obj.varObj.tankStates;
            for(i=1:length(tankStates))
                useTf = horzcat(useTf, tankStates(i).optVar.getUseTfForVariable()); %#ok<AGROW>
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            for(i=1:length(epsStorageStates))
                useTf = horzcat(useTf, epsStorageStates(i).optVar.getUseTfForVariable()); %#ok<AGROW>
            end
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf(1);
            
            obj.orbitVar.setUseTfForVariable(useTf(2:7));
            
            tankStates = obj.varObj.tankStates;
            ind = 8;
            for(i=1:length(tankStates))
                tankStates(i).optVar.setUseTfForVariable(useTf(ind));
                ind = ind + 1;
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            for(i=1:length(epsStorageStates))
                epsStorageStates(i).optVar.setUseTfForVariable(useTf(ind));
                ind = ind + 1;
            end
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;
            if(obj.useTf)
                obj.varObj.time = x(ind);
                ind = ind+1;
            end
            
            oUseTf = obj.orbitVar.getUseTfForVariable();
            oUseTfCnt = sum(oUseTf);
            if(oUseTfCnt > 0)
                oInds = ind : 1 : ind+oUseTfCnt-1;
                obj.orbitVar.updateObjWithVarValue(x(oInds));
                ind = oInds(end) + 1;
            end            
            
            tankStates = obj.varObj.tankStates;
            for(i=1:length(tankStates))
                if(tankStates(i).optVar.getUseTfForVariable() == true)
                    tankStates(i).optVar.updateObjWithVarValue(x(ind));
                    ind = ind + 1;
                end
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            for(i=1:length(epsStorageStates))
                if(epsStorageStates(i).optVar.getUseTfForVariable() == true)
                    epsStorageStates(i).optVar.updateObjWithVarValue(x(ind));
                    ind = ind + 1;
                end
            end
            
%             if(obj.useTf)
%                 obj.varObj.time = x(1);
%                 obj.orbitVar.updateObjWithVarValue(x(2:end));
%             else
%                 obj.orbitVar.updateObjWithVarValue(x(1:end));
%             end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            if(obj.useTf)
                initTime = sprintf('%s Time', subStr);
            else
                initTime = {};
            end
            
            tankStates = obj.varObj.tankStates;
            tankStateVarStrs = {};
            for(i=1:length(tankStates))
                if(tankStates(i).optVar.getUseTfForVariable() == true)
                    tankStateVarStrs = horzcat(tankStateVarStrs, tankStates(i).optVar.getStrNamesOfVars(evtNum, varLocType)); %#ok<AGROW>
                end
            end
            
            epsStorageStates = obj.varObj.epsStorageStates;
            epsStorageStateVarStrs = {};
            for(i=1:length(epsStorageStates))
                if(epsStorageStates(i).optVar.getUseTfForVariable() == true)
                    epsStorageStateVarStrs = horzcat(epsStorageStateVarStrs, epsStorageStates(i).optVar.getStrNamesOfVars(evtNum, varLocType)); %#ok<AGROW>
                end
            end
            
            nameStrs = horzcat(initTime, obj.orbitVar.getStrNamesOfVars(evtNum, varLocType), tankStateVarStrs, epsStorageStateVarStrs);
        end
        
        function numMaxVars = getNumMaxVariables(obj)
            numMaxVars = 1 + 6 + ...
                         numel(obj.varObj.tankStates) + ...
                         numel(obj.varObj.epsStorageStates);
            
        end
    end
end