classdef SetGenericSelectableSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetGenericSelectableSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = GenericSelectableSteeringModel.getDefaultSteeringModel()
        
        varTimeOffset(1,1) logical = false;
        tOffsetLb(1,1) double = 0;
        tOffsetUb(1,1) double = 0;
    end
    
    methods
        function obj = SetGenericSelectableSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function [numVars, gammaVars, betaVars, alphaVars] = getMaxNumVars(obj)
            numVars = 1; %tOffset
            
            gammaVars = obj.varObj.gammaAngleModel.getNumVars();
            numVars = numVars + gammaVars;
            
            betaVars = obj.varObj.betaAngleModel.getNumVars();
            numVars = numVars + betaVars;
            
            alphaVars = obj.varObj.alphaAngleModel.getNumVars();
            numVars = numVars + alphaVars;
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,1);
            
            if(obj.varTimeOffset)
                x(1) = obj.varObj.alphaAngleModel.getTimeOffset(); %this applies for all angle models
            end
            
            x = [x, obj.varObj.gammaAngleModel.getXsForVariable(), ...
                    obj.varObj.betaAngleModel.getXsForVariable(), ...
                    obj.varObj.alphaAngleModel.getXsForVariable()];

            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)     
            useTf = obj.getUseTfForVariable();
            [lb, ub] = obj.getAllBndsForVariable();
            
            lb = lb(useTf);
            ub = ub(useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            [gammaLb, gammaUb] = obj.varObj.gammaAngleModel.getBndsForVariable();
            [betaLb, betaUb] = obj.varObj.betaAngleModel.getBndsForVariable();
            [alphaLb, alphaUb] = obj.varObj.alphaAngleModel.getBndsForVariable();
            
            lb = [obj.tOffsetLb, gammaLb, betaLb, alphaLb];
            ub = [obj.tOffsetUb, gammaUb, betaUb, alphaUb];
        end
        
        function setBndsForVariable(obj, lb, ub)
            [numVars, ~, ~, ~] = obj.getMaxNumVars();
            
            if(length(lb) ~= numVars || length(ub) ~= numVars)
                useTf = obj.getUseTfForVariable();
                
                useLb = NaN(1,numVars);
                useUb = NaN(1,numVars);
                
                useLb(useTf) = lb;
                useUb(useTf) = ub;
            else
                useLb = lb;
                useUb = ub;
            end
            
            if(not(isnan(useLb(1))))
                obj.tOffsetLb = useLb(1);
            end
            
            if(not(isnan(useUb(1))))
                obj.tOffsetUb = useUb(1);
            end
        
            iVar = 2;

            %gamma
            inds = iVar : iVar + obj.varObj.gammaAngleModel.getNumVars() - 1;
            subUseLb = useLb(inds);
            subUseUb = useUb(inds);
            obj.varObj.gammaAngleModel.setBndsForVariable(subUseLb, subUseUb);
            iVar = inds(end) + 1;
            
            %beta
            inds = iVar : iVar + obj.varObj.betaAngleModel.getNumVars() - 1;
            subUseLb = useLb(inds);
            subUseUb = useUb(inds);
            obj.varObj.betaAngleModel.setBndsForVariable(subUseLb, subUseUb);
            iVar = inds(end) + 1;
            
            %alpha
            inds = iVar : iVar + obj.varObj.alphaAngleModel.getNumVars() - 1;
            subUseLb = useLb(inds);
            subUseUb = useUb(inds);
            obj.varObj.alphaAngleModel.setBndsForVariable(subUseLb, subUseUb);
            iVar = inds(end) + 1; %#ok<NASGU>
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varTimeOffset, ...
                    obj.varObj.gammaAngleModel.getUseTfForVariable(), ...
                    obj.varObj.betaAngleModel.getUseTfForVariable(), ...
                    obj.varObj.alphaAngleModel.getUseTfForVariable()];
            useTf = logical(useTf);
        end
        
        function setUseTfForVariable(obj, useTf)                             
            obj.varTimeOffset = useTf(1);
            
            iVar = 2;

            %gamma
            inds = iVar : iVar + obj.varObj.gammaAngleModel.getNumVars() - 1;
            subUseTf = useTf(inds);
            obj.varObj.gammaAngleModel.setUseTfForVariable(subUseTf);
            iVar = inds(end) + 1;
            
            %beta
            inds = iVar : iVar + obj.varObj.betaAngleModel.getNumVars() - 1;
            subUseTf = useTf(inds);
            obj.varObj.betaAngleModel.setUseTfForVariable(subUseTf);
            iVar = inds(end) + 1;
            
            %alpha
            inds = iVar : iVar + obj.varObj.alphaAngleModel.getNumVars() - 1;
            subUseTf = useTf(inds);
            obj.varObj.alphaAngleModel.setUseTfForVariable(subUseTf);
            iVar = inds(end) + 1; %#ok<NASGU>
        end
        
        function updateObjWithVarValue(obj, x)
            [numVars, ~, ~, ~] = obj.getMaxNumVars();
            
            if(length(x) ~= numVars)
                useTf = obj.getUseTfForVariable();
                
                useX = NaN(1,numVars);                
                useX(useTf) = x;
            else
                useX = x;
            end
           
            if(obj.varTimeOffset && not(isnan(useX(1))))
                obj.varObj.alphaAngleModel.getTimeOffset(useX(1));
                obj.varObj.betaAngleModel.getTimeOffset(useX(1));
                obj.varObj.gammaAngleModel.getTimeOffset(useX(1));
            end
            
            iVar = 2;

            %gamma
            inds = iVar : iVar + obj.varObj.gammaAngleModel.getNumVars() - 1;
            subUseX = useX(inds);
            obj.varObj.gammaAngleModel.updateObjWithVarValue(subUseX);
            iVar = inds(end) + 1;
            
            %beta
            inds = iVar : iVar + obj.varObj.betaAngleModel.getNumVars() - 1;
            subUseX = useX(inds);
            obj.varObj.betaAngleModel.updateObjWithVarValue(subUseX);
            iVar = inds(end) + 1;
            
            %alpha
            inds = iVar : iVar + obj.varObj.alphaAngleModel.getNumVars() - 1;
            subUseX = useX(inds);
            obj.varObj.alphaAngleModel.updateObjWithVarValue(subUseX);
            iVar = inds(end) + 1; %#ok<NASGU>
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
           [angle1Name, angle2Name, angle3Name] = obj.varObj.getAngleNames();
            
            nameStrs = {sprintf('%s Steering Time Offset', subStr)};
            
            %gamma
            modelNameStrs = obj.varObj.gammaAngleModel.getStrNamesOfVars();
            for(i=1:length(modelNameStrs))
                nameStrs = horzcat(nameStrs, sprintf('%s %s %s', subStr, angle1Name, modelNameStrs{i})); %#ok<AGROW>
            end
            
            %beta
            modelNameStrs = obj.varObj.betaAngleModel.getStrNamesOfVars();
            for(i=1:length(modelNameStrs))
                nameStrs = horzcat(nameStrs, sprintf('%s %s %s', subStr, angle2Name, modelNameStrs{i})); %#ok<AGROW>
            end
            
            %alpha
            modelNameStrs = obj.varObj.alphaAngleModel.getStrNamesOfVars();
            for(i=1:length(modelNameStrs))
                nameStrs = horzcat(nameStrs, sprintf('%s %s %s', subStr, angle3Name, modelNameStrs{i})); %#ok<AGROW>
            end
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end