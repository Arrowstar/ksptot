classdef SineModel < matlab.mixin.SetGet
    %SineModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Time
        t0(1,1) double = 0;
        tOffset(1,1) double = 0;
        
        %Amplitude
        amp(1,1) double = 1;
        varAmp(1,1) logical = false;
        ampUb(1,1) double = 0;
        ampLb(1,1) double = 0;
        
        %Period
        period(1,1) double = 1;  %sec
        varPeriod(1,1) logical = false;
        periodUb(1,1) double = 0;
        periodLb(1,1) double = 0;
        
        %Phase Shift
        phase(1,1) double = 0; %s
        varPhase(1,1) logical = false;
        phaseUb(1,1) double = 0;
        phaseLb(1,1) double = 0;
    end
    
    properties(Dependent)
        %Frequency
        freq(1,1) double
        varFreq(1,1) logical 
        freqUb(1,1) double 
        freqLb(1,1) double         
    end
    
    methods
        function obj = SineModel(t0, amp, freq, phase)
            obj.t0 = t0;
            obj.amp = real(amp);
            obj.freq = real(freq);
            obj.phase = real(phase);
        end
        
        function value = get.freq(obj)
            value = 2*pi/obj.period;
        end
        
        function set.freq(obj,value)
            obj.period = 2*pi/value;
        end
        
        function value = get.varFreq(obj)
            value = obj.varPeriod;
        end
        
        function set.varFreq(obj,value)
            obj.varPeriod = value;
        end
        
        function value = get.freqUb(obj)
            value = 2*pi/obj.periodUb;
        end
        
        function set.freqUb(obj,value)
            obj.periodUb = 2*pi/value;
        end
        
        function value = get.freqLb(obj)
            value = 2*pi/obj.periodLb;
        end
        
        function set.freqLb(obj,value)
            obj.periodLb = 2*pi/value;
        end
        
        function value = getValueAtTime(obj,ut)
            dt = (ut - obj.t0) + obj.tOffset;
            
            value = obj.amp * sin(obj.freq*(dt + obj.phase));
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = sprintf('%0.3f * sin((2*pi/%0.3f) * (dt + %0.3f))', rad2deg(obj.amp), obj.period, obj.phase);
        end
        
        function newSineModel = deepCopy(obj)
            newSineModel = SineModel(obj.t0, obj.amp, obj.freq, obj.phase);
            
            newSineModel.t0 = obj.t0;
            newSineModel.tOffset = obj.tOffset;
            
            newSineModel.amp = obj.amp;
            newSineModel.varAmp = obj.varAmp;
            newSineModel.ampUb = obj.ampUb;
            newSineModel.ampLb = obj.ampLb;
            
            newSineModel.period = obj.period;
            newSineModel.varPeriod = obj.varPeriod;
            newSineModel.periodUb = obj.periodUb;
            newSineModel.periodLb = obj.periodLb;
            
            newSineModel.phase = obj.phase;
            newSineModel.varPhase = obj.varPhase;
            newSineModel.phaseUb = obj.phaseUb;
            newSineModel.phaseLb = obj.phaseLb;
        end
        
        function numVars = getNumVars(~)
            numVars = 3;
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,3);
            
            if(obj.varAmp)
                x(1) = obj.amp;
            end
            
            if(obj.varPeriod)
                x(2) = obj.period;
            end
            
            if(obj.varPhase)
                x(3) = obj.phase;
            end
        end
        
        function updateObjWithVarValue(obj, x)
            if(not(isnan(x(1))))
                obj.amp = x(1);
            end
            
            if(not(isnan(x(2))))
                obj.period = x(2);
            end
            
            if(not(isnan(x(3))))
                obj.phase = x(3);
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = [obj.ampLb, obj.periodLb, obj.phaseLb];
            ub = [obj.ampUb, obj.periodUb, obj.phaseUb];
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(not(isnan(lb(1))))
                obj.ampLb = lb(1);
            end
            
            if(not(isnan(lb(2))))
                obj.periodLb = lb(2);
            end
            
            if(not(isnan(lb(3))))
                obj.phaseLb = lb(3);
            end
            
            if(not(isnan(ub(1))))
                obj.ampUb = ub(1);
            end
            
            if(not(isnan(ub(2))))
                obj.periodUb = ub(2);
            end
            
            if(not(isnan(ub(3))))
                obj.phaseUb = ub(3);
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varAmp, obj.varPeriod, obj.varPhase];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varAmp = useTf(1);
            obj.varPeriod = useTf(2);
            obj.varPhase = useTf(3);
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            nameStrs = {'Sine Amplitude', 'Sine Period', 'Sine Phase Shift'};
        end
    end
end