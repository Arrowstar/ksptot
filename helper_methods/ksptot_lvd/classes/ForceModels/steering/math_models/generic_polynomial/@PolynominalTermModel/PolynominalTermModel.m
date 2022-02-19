classdef PolynominalTermModel < matlab.mixin.SetGet
    %PolynominalTermModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Time
        t0(1,1) double = 0;
        tOffset(1,1) double = 0;
        
        %Coefficient
        coeff(1,1) double = 1;
        varCoeff(1,1) logical = false;
        coeffUb(1,1) double = 0;
        coeffLb(1,1) double = 0;
        
        %Exponent
        exponent(1,1) double = 1;
        varExp(1,1) logical = false;
        expUb(1,1) double = 0;
        expLb(1,1) double = 0;
    end
    
    methods
        function obj = PolynominalTermModel(t0, coeff, exponent)
            obj.t0 = t0;
            obj.coeff = real(coeff);
            obj.exponent = real(exponent);
        end
               
        function value = getValueAtTime(obj,ut)
            dt = (ut - obj.t0) + obj.tOffset;
            
            value = obj.coeff * (dt^obj.exponent);
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = sprintf('%0.3f * (t-t0) ^ %0.3f', rad2deg(obj.coeff), obj.exponent);
        end
        
        function newPolyTermModel = deepCopy(obj)
            newPolyTermModel = PolynominalTermModel(obj.t0, obj.coeff, obj.exponent);
            
            newPolyTermModel.t0 = obj.t0;
            newPolyTermModel.tOffset = obj.tOffset;
            
            newPolyTermModel.coeff = obj.coeff;
            newPolyTermModel.varCoeff = obj.varCoeff;
            newPolyTermModel.coeffUb = obj.coeffUb;
            newPolyTermModel.coeffLb = obj.coeffLb;
            
            newPolyTermModel.exponent = obj.exponent;
            newPolyTermModel.varExp = obj.varExp;
            newPolyTermModel.expUb = obj.expUb;
            newPolyTermModel.expLb = obj.expLb;
        end
        
        function numVars = getNumVars(~)
            numVars = 2;
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,2);
            
            if(obj.varCoeff)
                x(1) = obj.coeff;
            end
            
            if(obj.varExp)
                x(2) = obj.exponent;
            end
        end
        
        function updateObjWithVarValue(obj, x)
            if(not(isnan(x(1))))
                obj.coeff = x(1);
            end
            
            if(not(isnan(x(2))))
                obj.exponent = x(2);
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = [obj.coeffLb, obj.expLb];
            ub = [obj.coeffUb, obj.expUb];
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(not(isnan(lb(1))))
                obj.coeffLb = lb(1);
            end
            
            if(not(isnan(lb(2))))
                obj.expLb = lb(2);
            end
            
            if(not(isnan(ub(1))))
                obj.coeffUb = ub(1);
            end
            
            if(not(isnan(ub(2))))
                obj.expUb = ub(2);
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varCoeff, obj.varExp];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varCoeff = useTf(1);
            obj.varExp = useTf(2);
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            nameStrs = {'Polynomial Term Coefficient', 'Polynomial Term Exponent'};
        end
    end
end