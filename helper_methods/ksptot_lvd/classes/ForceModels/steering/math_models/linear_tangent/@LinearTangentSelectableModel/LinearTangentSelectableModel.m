classdef LinearTangentSelectableModel < AbstractSteeringMathModel
    %SumOfSinesModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Time
        t0(1,1) double = 0;
        tOffset(1,1) double = 0;

        %A
        a(1,1) double = 0;
        varA(1,1) logical = false;
        aUb(1,1) double = 0;
        aLb(1,1) double = 0;
        
        %A Dot
        a_dot(1,1) double = 0;
        varADot(1,1) logical = false;
        aDotUb(1,1) double = 0;
        aDotLb(1,1) double = 0;
        
        %B
        b(1,1) double = 0;
        varB(1,1) logical = false;
        bUb(1,1) double = 0;
        bLb(1,1) double = 0;
        
        %B DOT
        b_dot(1,1) double = 0;
        varBDot(1,1) logical = false;
        bDotUb(1,1) double = 0;
        bDotLb(1,1) double = 0;
    end
    
    methods
        function obj = LinearTangentSelectableModel(t0, a, a_dot, b, b_dot)
            obj.t0 = t0;
            
            obj.a = real(a);
            obj.a_dot = real(a_dot);
            
            obj.b = real(b);
            obj.b_dot = real(b_dot);
        end
                
        function value = getValueAtTime(obj,ut)            
            dt = (ut - obj.t0) + obj.tOffset;
            
            a_value = obj.a + (obj.a_dot .* dt);
            b_value = obj.b + (obj.b_dot .* dt);
            value = atan(a_value .* dt + b_value);
        end
          
        function newModel = deepCopy(obj)
            newModel = LinearTangentModel(obj.t0, obj.a, obj.a_dot, obj.b, obj.b_dot);
            
            %Time
            newModel.t0 = obj.t0;
            newModel.tOffset = obj.tOffset;
            
            %A
            newModel.varA = obj.varA;
            newModel.aLb = obj.aLb;
            newModel.aUb = obj.aUb;
            
            %A Dot
            newModel.varADot = obj.varADot;
            newModel.aDotLb = obj.aDotLb;
            newModel.aDotUb = obj.aDotUb;
            
            %B
            newModel.varB = obj.varB;
            newModel.bLb = obj.bLb;
            newModel.bUb = obj.bUb;
            
            %B Dot
            newModel.varBDot = obj.varBDot;
            newModel.bDotLb = obj.bDotLb;
            newModel.bDotUb = obj.bDotUb;
        end
        
        function t0 = getT0(obj)
            t0 = obj.t0;
        end

        function setT0(obj, newT0)
            obj.t0 = newT0;
        end
        
        function timeOffset = getTimeOffset(obj)
            timeOffset = obj.tOffset;
        end
        
        function setTimeOffset(obj, timeOffset)
            obj.tOffset = timeOffset;
        end
               
        function setConstValueForContinuity(obj, contValue)
            obj.b = tan(contValue);
        end
        
        function numVars = getNumVars(obj)
            numVars = 4; 
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,4);
            
            if(obj.varA)
                x(1) = obj.a;
            end
            
            if(obj.varADot)
                x(2) = obj.a_dot;
            end

            if(obj.varB)
                x(3) = obj.b;
            end
            
            if(obj.varBDot)
                x(4) = obj.b_dot;
            end
        end
        
        function updateObjWithVarValue(obj, x)
            if(not(isnan(x(1))))
                obj.a = x(1);
            end
            
            if(not(isnan(x(2))))
                obj.a_dot = x(2);
            end
            
            if(not(isnan(x(3))))
                obj.b = x(31);
            end
            
            if(not(isnan(x(4))))
                obj.b_dot = x(4);
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = [obj.aLb, obj.aDotLb, obj.bLb, obj.bDotLb];
            ub = [obj.aUb, obj.aDotUb, obj.bUb, obj.bDotUb];
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(not(isnan(lb(1))))
                obj.aLb = lb(1);
            end
            
            if(not(isnan(lb(2))))
                obj.aDotLb = lb(2);
            end
            
            if(not(isnan(lb(3))))
                obj.bLb = lb(3);
            end
            
            if(not(isnan(lb(4))))
                obj.bDotLb = lb(4);
            end
            
            if(not(isnan(ub(1))))
                obj.aUb = ub(1);
            end
            
            if(not(isnan(ub(2))))
                obj.aDotUb = ub(2);
            end
            
            if(not(isnan(ub(3))))
                obj.bUb = ub(3);
            end
            
            if(not(isnan(ub(4))))
                obj.bDotUb = ub(4);
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varA, obj.varADot, obj.varB, obj.varBDot];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varA = useTf(1);
            obj.varADot = useTf(2);
            obj.varB = useTf(3);
            obj.varBDot = useTf(4);
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            nameStrs = {'Linear Tangent A', 'Linear Tangent A Dot', 'Linear Tangent B', 'Linear Tangent B Dot'};
        end
    end
end