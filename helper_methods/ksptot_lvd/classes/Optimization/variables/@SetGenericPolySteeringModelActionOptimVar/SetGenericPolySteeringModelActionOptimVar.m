classdef SetGenericPolySteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetGenericPolySteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = GenericPolySteeringModel.getDefaultSteeringModel()
        
        lb(1,10) double
        ub(1,10) double
        
        varGammaConst(1,1) logical = false;
        varGammaLin(1,1) logical   = false;
        varGammaAccel(1,1) logical = false;
        
        varBetaConst(1,1) logical = false;
        varBetaLin(1,1) logical   = false;
        varBetaAccel(1,1) logical = false;
        
        varAlphaConst(1,1) logical = false;
        varAlphaLin(1,1) logical   = false;
        varAlphaAccel(1,1) logical = false;
        
        varTimeOffset(1,1) logical = false;
    end
    
    methods
        function obj = SetGenericPolySteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,10);
            
            if(obj.varGammaConst)
                x(1) = obj.varObj.gammaAngleModel.constTerm;
            end
            if(obj.varGammaLin)
                x(2) = obj.varObj.gammaAngleModel.linearTerm;
            end
            if(obj.varGammaAccel)
                x(3) = obj.varObj.gammaAngleModel.accelTerm;
            end
            
            if(obj.varBetaConst)
                x(4) = obj.varObj.betaAngleModel.constTerm;
            end
            if(obj.varBetaLin)
                x(5) = obj.varObj.betaAngleModel.linearTerm;
            end
            if(obj.varBetaAccel)
                x(6) = obj.varObj.betaAngleModel.accelTerm;
            end
            
            if(obj.varAlphaConst)
                x(7) = obj.varObj.alphaAngleModel.constTerm;
            end
            if(obj.varAlphaLin)
                x(8) = obj.varObj.alphaAngleModel.linearTerm;
            end
            if(obj.varAlphaAccel)
                x(9) = obj.varObj.alphaAngleModel.accelTerm;
            end
            
            if(obj.varTimeOffset)
                x(10) = obj.varObj.alphaAngleModel.tOffset; %this applies for all angle models
            end
            
            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            useTf = obj.getUseTfForVariable();

            lb = obj.lb(useTf);
            ub = obj.ub(useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.lb;
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == 10 && length(ub) == 10)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varGammaConst obj.varGammaLin obj.varGammaAccel ...
                     obj.varBetaConst obj.varBetaLin obj.varBetaAccel ...
                     obj.varAlphaConst obj.varAlphaLin obj.varAlphaAccel ...
                     obj.varTimeOffset];
        end
        
        function setUseTfForVariable(obj, useTf)                 
            obj.varGammaConst = useTf(1);
            obj.varGammaLin = useTf(2);
            obj.varGammaAccel = useTf(3);
            
            obj.varBetaConst = useTf(4);
            obj.varBetaLin = useTf(5);
            obj.varBetaAccel = useTf(6);
            
            obj.varAlphaConst = useTf(7);
            obj.varAlphaLin = useTf(8);
            obj.varAlphaAccel = useTf(9);
            
            obj.varTimeOffset = useTf(10);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;
            
            if(obj.varGammaConst)
                obj.varObj.gammaAngleModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varGammaLin)
                obj.varObj.gammaAngleModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varGammaAccel)
                obj.varObj.gammaAngleModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varBetaConst)
                obj.varObj.betaAngleModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varBetaLin)
                obj.varObj.betaAngleModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varBetaAccel)
                obj.varObj.betaAngleModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varAlphaConst)
                obj.varObj.alphaAngleModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varAlphaLin)
                obj.varObj.alphaAngleModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varAlphaAccel)
                obj.varObj.alphaAngleModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varTimeOffset)
                obj.varObj.alphaAngleModel.tOffset = x(ind);
                obj.varObj.betaAngleModel.tOffset = x(ind);
                obj.varObj.gammaAngleModel.tOffset = x(ind);
                ind = ind + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
           if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Gamma Angle Constant', subStr), ...
                        sprintf('%s Gamma Angle Rate', subStr), ...
                        sprintf('%s Gamma Angle Acceleration', subStr), ...
                        sprintf('%s Beta Angle Constant', subStr), ...
                        sprintf('%s Beta Angle Rate', subStr), ...
                        sprintf('%s Beta Angle Acceleration', subStr), ...
                        sprintf('%s Alpha Angle Constant', subStr), ...
                        sprintf('%s Alpha Angle Rate', subStr), ...
                        sprintf('%s Alpha Angle Acceleration', subStr), ...
                        sprintf('%s Steering Time Offset', subStr)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end