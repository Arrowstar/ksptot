classdef SumOfSinesModel < AbstractSteeringMathModel
    %SumOfSinesModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        const(1,1) double = 0;    
        varConst(1,1) logical = false;
        constUb(1,1) double = 0;
        constLb(1,1) double = 0;
        
        sines(1,:) SineModel
    end
    
    methods
        function obj = SumOfSinesModel(const)
            obj.const = const;
            
            obj.sines = SineModel(0,1,2*pi,0);
        end
        
        function addSine(obj, sine)
            obj.sines(end+1) = sine;
        end
        
        function removeSine(obj, sine)
            obj.sines([obj.sines] == sine) = [];
        end
        
        function numSines = getNumSines(obj)
            numSines = length(obj.sines);
        end
        
        function value = getValueAtTime(obj,ut)            
            value = obj.const;
            
            for(i=1:length(obj.sines))
                value = value + obj.sines(i).getValueAtTime(ut);
            end
        end
        
        function period = getLongestPeriod(obj)
            period = 0;
            
            for(i=1:length(obj.sines))
                if(period < obj.sines(i).period)
                    period = obj.sines(i).period;
                end
            end
        end
        
        function [listBoxStr, sines] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.sines))
                listBoxStr{end+1} = obj.sines(i).getListboxStr(); %#ok<AGROW>
            end
            
            sines = obj.sines;
        end
        
        function newSumOfSineModel = deepCopy(obj)
            newSumOfSineModel = SumOfSinesModel(obj.const);
            
            newSumOfSineModel.const = obj.const;
            newSumOfSineModel.varConst = obj.varConst;
            newSumOfSineModel.constUb = obj.constUb;
            newSumOfSineModel.constLb = obj.constLb;
            
            for(i=1:length(obj.sines))
                newSumOfSineModel.sines(i) = obj.sines(i).deepCopy();
            end
        end
        
        function inds = getIndsForSines(obj, indSines)
            inds = find(ismember(obj.sines, indSines));
        end
        
        function indSine = getSineAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.sines))
                indSine = obj.sines(ind);
            else
                indSine = SineModel.empty(1,0);
            end
        end
        
        function t0 = getT0(obj)
            t0 = 0;
            
            if(~isempty(obj.sines))
                t0 = obj.sines(1).t0;
            end
        end

        function setT0(obj, newT0)
            for(i=1:length(obj.sines))
                obj.sines(i).t0 = newT0;
            end
        end
        
        function timeOffset = getTimeOffset(obj)
            timeOffset = 0;
            
            if(~isempty(obj.sines))
                timeOffset = obj.sines(1).tOffset;
            end
        end
        
        function setTimeOffset(obj, timeOffset)
            for(i=1:length(obj.sines))
                obj.sines(i).tOffset = timeOffset;
            end
        end
               
        function setConstValueForContinuity(obj, contValue)
            t0 = obj.getT0();
            
            valueSumSines = 0;
            for(i=1:length(obj.sines))
                valueSumSines = valueSumSines + obj.sines(i).getValueAtTime(t0);
            end
            
            obj.const = contValue - valueSumSines;
        end
        
        function numVars = getNumVars(obj)
            numVars = 1; %constant
            for(i=1:length(obj.sines))
                numVars = numVars + obj.sines(i).getNumVars();
            end
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,1);
            
            if(obj.varConst)
                x(1) = obj.const;
            end
            
            for(i=1:length(obj.sines))
                x = [x, obj.sines(i).getXsForVariable()]; %#ok<AGROW>
            end
        end
        
        function updateObjWithVarValue(obj, x)
            if(not(isnan(x(1))))
                obj.const = x(1);
            end
            
            iVar = 2;
            for(i=1:length(obj.sines))
                inds = iVar : iVar + obj.sines(i).getNumVars() - 1;
                subX = x(inds);
                obj.sines(i).updateObjWithVarValue(subX);
                
                iVar = inds(end) + 1;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.constLb;
            ub = obj.constUb;
            
            for(i=1:length(obj.sines))
                [sLb, sUb] = obj.sines(i).getBndsForVariable();
                
                lb = [lb, sLb]; %#ok<AGROW>
                ub = [ub, sUb]; %#ok<AGROW>
            end
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(not(isnan(lb(1))))
                obj.constLb = lb(1);
            end
            
            if(not(isnan(ub(1))))
                obj.constUb = ub(1);
            end
            
            iVar = 2;
            for(i=1:length(obj.sines))
                inds = iVar : iVar + obj.sines(i).getNumVars() - 1;
                subLb = lb(inds);
                subUb = ub(inds);
                obj.sines(i).setBndsForVariable(subLb, subUb);
                
                iVar = inds(end) + 1;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varConst];
            
            for(i=1:length(obj.sines))
                useTf = [useTf, obj.sines(i).getUseTfForVariable()]; %#ok<AGROW>
            end
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varConst = useTf(1);
            
            iVar = 2;
            for(i=1:length(obj.sines))
                inds = iVar : iVar + obj.sines(i).getNumVars() - 1;
                subUseTf = useTf(inds);
                obj.sines(i).setUseTfForVariable(subUseTf);
                
                iVar = inds(end) + 1;
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            nameStrs = {'Constant Offset'};
            
            for(i=1:length(obj.sines))
                varNames = obj.sines(i).getStrNamesOfVars();
                for(j=1:length(varNames))
                    varNames{j} = sprintf('Sine %u %s', i, varNames{j});
                end
                
                nameStrs = horzcat(nameStrs, varNames); %#ok<AGROW>
            end
        end
    end
end