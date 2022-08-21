classdef SetGenericLinearTangentSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetGenericLinearTangentSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = GenericLinearTangentSteeringModel.getDefaultSteeringModel();
        
        lb(1,11) double
        ub(1,11) double
        
        varGammaConst(1,1) logical = false;
        varGammaLin(1,1) logical   = false;
        varGammaAccel(1,1) logical = false;
        
        varBetaA(1,1) logical = false;
        varBetaADot(1,1) logical = false;
        varBetaB(1,1) logical = false;
        varBetaBDot(1,1) logical = false;
        
        varAlphaConst(1,1) logical = false;
        varAlphaLin(1,1) logical   = false;
        varAlphaAccel(1,1) logical = false;
        
        varTimeOffset(1,1) logical = false;
    end
    
    methods
        function obj = SetGenericLinearTangentSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,11);
            
            if(obj.varGammaConst)
                x(1) = obj.varObj.gammaAngleModel.constTerm;
            end
            if(obj.varGammaLin)
                x(2) = obj.varObj.gammaAngleModel.linearTerm;
            end
            if(obj.varGammaAccel)
                x(3) = obj.varObj.gammaAngleModel.accelTerm;
            end
            
            if(obj.varBetaA)
                x(4) = obj.varObj.betaAngleModel.a;
            end
            if(obj.varBetaADot)
                x(5) = obj.varObj.betaAngleModel.a_dot;
            end
            if(obj.varBetaB)
                x(6) = obj.varObj.betaAngleModel.b;
            end
            if(obj.varBetaBDot)
                x(7) = obj.varObj.betaAngleModel.b_dot;
            end
            
            if(obj.varAlphaConst)
                x(8) = obj.varObj.alphaAngleModel.constTerm;
            end
            if(obj.varAlphaLin)
                x(9) = obj.varObj.alphaAngleModel.linearTerm;
            end
            if(obj.varAlphaAccel)
                x(10) = obj.varObj.alphaAngleModel.accelTerm;
            end
            
            if(obj.varTimeOffset)
                x(11) = obj.varObj.alphaAngleModel.tOffset; %this applies for all angle models
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
            if(length(lb) == 11 && length(ub) == 11)
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
                     obj.varBetaA obj.varBetaADot obj.varBetaB obj.varBetaBDot ...
                     obj.varAlphaConst obj.varAlphaLin obj.varAlphaAccel, ...
                     obj.varTimeOffset];
        end
        
        function setUseTfForVariable(obj, useTf)                 
            obj.varGammaConst = useTf(1);
            obj.varGammaLin = useTf(2);
            obj.varGammaAccel = useTf(3);
            
            obj.varBetaA = useTf(4);
            obj.varBetaADot = useTf(5);
            obj.varBetaB = useTf(6);
            obj.varBetaBDot = useTf(7);
            
            obj.varAlphaConst = useTf(8);
            obj.varAlphaLin = useTf(9);
            obj.varAlphaAccel = useTf(10);
            
            obj.varTimeOffset = useTf(11);
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
            
            if(obj.varBetaA)
                obj.varObj.betaAngleModel.a = x(ind);
                ind = ind + 1;
            end
            if(obj.varBetaADot)
                obj.varObj.betaAngleModel.a_dot = x(ind);
                ind = ind + 1;
            end
            if(obj.varBetaB)
                obj.varObj.betaAngleModel.b = x(ind);
                ind = ind + 1;
            end
            if(obj.varBetaBDot)
                obj.varObj.betaAngleModel.b_dot = x(ind);
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
                        sprintf('%s Beta Angle Linear Tangent A', subStr), ...
                        sprintf('%s Beta Angle Linear Tangent A Rate', subStr), ...
                        sprintf('%s Beta Angle Linear Tangent B', subStr), ...
                        sprintf('%s Beta Angle Linear Tangent B Rate', subStr), ...
                        sprintf('%s Alpha Angle Constant', subStr), ...
                        sprintf('%s Alpha Angle Rate', subStr), ...
                        sprintf('%s Alpha Angle Acceleration', subStr), ...
                        sprintf('%s Steering Time Offset', subStr)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end