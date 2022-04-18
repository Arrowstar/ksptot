classdef SumOfPolyTermsModel < AbstractSteeringMathModel
    %SumOfPolyTermsModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        const(1,1) double = 0;    
        varConst(1,1) logical = false;
        constUb(1,1) double = 0;
        constLb(1,1) double = 0;
        
        terms(1,:) PolynominalTermModel
    end
    
    methods
        function obj = SumOfPolyTermsModel(const)
            obj.const = const;
            
            obj.terms = PolynominalTermModel(0,deg2rad(1),1);
        end
        
        function addTerm(obj, term)
            obj.terms(end+1) = term;
        end
        
        function removeTerm(obj, term)
            obj.terms([obj.terms] == term) = [];
        end
        
        function numTerms = getNumTerms(obj)
            numTerms = length(obj.terms);
        end
        
        function value = getValueAtTime(obj,ut)            
            value = obj.const;
            
%             for(i=1:length(obj.terms))
%                 value = value + obj.terms(i).getValueAtTime(ut);
%             end

            value = value + sum(getValueAtTime(obj.terms, ut));
        end
        
        function [listBoxStr, terms] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.terms))
                listBoxStr{end+1} = obj.terms(i).getListboxStr(); %#ok<AGROW>
            end
            
            terms = obj.terms;
        end
        
        function newSumOfPolyTermsModel = deepCopy(obj)
            newSumOfPolyTermsModel = SumOfPolyTermsModel(obj.const);
            
            newSumOfPolyTermsModel.const = obj.const;
            newSumOfPolyTermsModel.varConst = obj.varConst;
            newSumOfPolyTermsModel.constUb = obj.constUb;
            newSumOfPolyTermsModel.constLb = obj.constLb;
            
            for(i=1:length(obj.terms))
                newSumOfPolyTermsModel.terms(i) = obj.terms(i).deepCopy();
            end
        end
        
        function inds = getIndsForTerms(obj, indTerms)
            inds = find(ismember(obj.terms, indTerms));
        end
        
        function indTerm = getTermAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.terms))
                indTerm = obj.terms(ind);
            else
                indTerm = PolynominalTermModel.empty(1,0);
            end
        end
        
        function t0 = getT0(obj)
            t0 = 0;
            
            if(~isempty(obj.terms))
                t0 = obj.terms(1).t0;
            end
        end

        function setT0(obj, newT0)
            for(i=1:length(obj.terms))
                obj.terms(i).t0 = newT0;
            end
        end
        
        function timeOffset = getTimeOffset(obj)
            timeOffset = 0;
            
            if(~isempty(obj.terms))
                timeOffset = obj.terms(1).tOffset;
            end
        end
        
        function setTimeOffset(obj, timeOffset)
            for(i=1:length(obj.terms))
                obj.terms(i).tOffset = timeOffset;
            end
        end
               
        function setConstValueForContinuity(obj, contValue)
            t0 = obj.getT0();
            
            valueSumTerms = 0;
            for(i=1:length(obj.terms))
                valueSumTerms = valueSumTerms + obj.terms(i).getValueAtTime(t0);
            end
            
            obj.const = contValue - valueSumTerms;
        end
        
        function numVars = getNumVars(obj)
            numVars = 1; %constant
            for(i=1:length(obj.terms))
                numVars = numVars + obj.terms(i).getNumVars();
            end
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,1);
            
            if(obj.varConst)
                x(1) = obj.const;
            end
            
            for(i=1:length(obj.terms))
                x = [x, obj.terms(i).getXsForVariable()]; %#ok<AGROW>
            end
        end
        
        function updateObjWithVarValue(obj, x)
            if(not(isnan(x(1))))
                obj.const = x(1);
            end
            
            iVar = 2;
            for(i=1:length(obj.terms))
                inds = iVar : iVar + obj.terms(i).getNumVars() - 1;
                subX = x(inds);
                obj.terms(i).updateObjWithVarValue(subX);
                
                iVar = inds(end) + 1;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.constLb;
            ub = obj.constUb;
            
            for(i=1:length(obj.terms))
                [tLb, tUb] = obj.terms(i).getBndsForVariable();
                
                lb = [lb, tLb]; %#ok<AGROW>
                ub = [ub, tUb]; %#ok<AGROW>
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
            for(i=1:length(obj.terms))
                inds = iVar : iVar + obj.terms(i).getNumVars() - 1;
                subLb = lb(inds);
                subUb = ub(inds);
                obj.terms(i).setBndsForVariable(subLb, subUb);
                
                iVar = inds(end) + 1;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varConst];
            
            for(i=1:length(obj.terms))
                useTf = [useTf, obj.terms(i).getUseTfForVariable()]; %#ok<AGROW>
            end
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varConst = useTf(1);
            
            iVar = 2;
            for(i=1:length(obj.terms))
                inds = iVar : iVar + obj.terms(i).getNumVars() - 1;
                subUseTf = useTf(inds);
                obj.terms(i).setUseTfForVariable(subUseTf);
                
                iVar = inds(end) + 1;
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            nameStrs = {'Constant Offset'};
            
            for(i=1:length(obj.terms))
                varNames = obj.terms(i).getStrNamesOfVars();
                for(j=1:length(varNames))
                    varNames{j} = sprintf('Polynomial Term %u %s', i, varNames{j});
                end
                
                nameStrs = horzcat(nameStrs, varNames); %#ok<AGROW>
            end
        end
    end
end