classdef FitNetModel < matlab.mixin.SetGet
    %FitNetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Time
        t0(1,1) double = 0;
        tOffset(1,1) double = 0;
        
        %Constant
        const(1,1) double = 0;    
        varConst(1,1) logical = false;
        constUb(1,1) double = 0;
        constLb(1,1) double = 0;
        
        %Neural Network
        net(1,1) 
        varNetWB logical;
        netWbUb double = 0;
        netWbLb double = 0;
        hiddenSizes double = 5;
        gpuAvail(1,1) double = gpuDeviceCount("available");
    end
    
    methods
        function obj = FitNetModel(hiddenSizes)   
            obj.hiddenSizes = hiddenSizes;
            obj.net = FitNetModel.createNetwork(hiddenSizes);
            
            netWb = abs(getwb(obj.net));
            obj.netWbUb = 100 * netWb;
            obj.netWbLb = 100 * (-netWb);
            obj.varNetWB = false(size(netWb));
            
            obj.gpuAvail = gpuDeviceCount("available");
        end
        
        function value = getValueAtTime(obj,ut)
            if(obj.gpuAvail > 0)
                gpuStr = 'yes';
            else
                gpuStr = 'no';
            end
            
            dt = (ut - obj.t0) + obj.tOffset;
            value = sim(obj.net,dt, 'UseGPU',gpuStr);
        end
        
        function wbParams = getWbParams(obj)
            wbParams = getwb(obj.net);
        end
        
        function value = getWbParamAtInd(obj, ind)
            wbParams = obj.getWbParams();
            value = wbParams(ind);
        end
        
        function setWbParamAtInd(obj, newVal, ind)
            wbParams = obj.getWbParams();
            wbParams(ind) = newVal;
            obj.net = setwb(obj.net, wbParams);
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.varNetWB))
                listBoxStr{i} = sprintf('Parameter %u', i); %#ok<AGROW>
            end
        end
        
        function newModel = deepCopy(obj)
            newModel = FitNetModel(obj.hiddenSizes);
            newModel.net = setwb(newModel.net, getwb(obj.net));
            
            newModel.t0 = obj.t0;
            newModel.tOffset = obj.tOffset;
        
            %Constant
            newModel.const = obj.const;
            newModel.varConst = obj.varConst;
            newModel.constUb = obj.constUb;
            newModel.constLb = obj.constLb;

            %Neural Network
            newModel.varNetWB = obj.varNetWB;
            newModel.netWbUb = obj.netWbUb;
            newModel.netWbLb = obj.netWbLb;
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
            value = obj.getValueAtTime(obj.t0);
            
            obj.const = contValue - value;
        end
        
        function numVars = getNumVars(obj)
            numVars = 1 + numel(obj.varNetWB);
        end
        
        function x = getXsForVariable(obj)
            x = getwb(obj.net);
            x = x(obj.varNetWB);
            
            if(obj.varConst)
                x = [obj.const, x(:)'];
            end
            
            x = x(:)';
        end
        
        function updateObjWithVarValue(obj, x)
            if(obj.varConst)
                obj.const = x(1);
            end
            
            x = x(2:end);
            if(any(obj.varNetWB))
                wb = getwb(obj.net);
                wb(obj.varNetWB) = x;
                obj.net = setwb(obj.net, wb);
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = [obj.constLb obj.netWbLb(:)'];
            ub = [obj.constUb obj.netWbUb(:)'];
        end
        
        function setBndsForVariable(obj, lb, ub)      
            obj.constLb = lb(1);
            obj.constUb = ub(1);
            
            obj.netWbLb = lb(2:end);
            obj.netWbUb = ub(2:end);
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varConst, obj.varNetWB(:)'];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varConst = useTf(1);
            obj.varNetWB = useTf(2:end);
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            x = getwb(obj.net);
            nameStrs = {'Constant Offset'};
            
            for(i=1:length(x))
                nameStrs{end+1} = sprintf('Parameter %u', i); %#ok<AGROW>
            end
        end
        
        function randomizeWB(obj)
            rands = obj.netWbLb + (obj.netWbUb - obj.netWbLb).*rand(size(obj.netWbLb));
            obj.net = setwb(obj.net, rands);
        end
    end
    
    methods(Static, Access=private)
        function net = createNetwork(hiddenSizes)
            [x,t] = simplefit_dataset;
            
            net = fitnet(hiddenSizes);
            net = init(net);
            net = configure(net,x,t);
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            obj.gpuAvail = gpuDeviceCount("available");
        end
    end
end