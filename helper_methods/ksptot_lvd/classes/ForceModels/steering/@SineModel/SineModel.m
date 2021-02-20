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
        
        %Frequency
        freq(1,1) double = 2*pi; %Hz = 1/s
        varFreq(1,1) logical = false;
        freqUb(1,1) double = 0;
        freqLb(1,1) double = 0;
        
        %Phase Shift
        phase(1,1) double = 0; %s
        varPhase(1,1) logical = false;
        phaseUb(1,1) double = 0;
        phaseLb(1,1) double = 0;
    end
    
    methods
        function obj = SineModel(t0, amp, freq, phase)
            obj.t0 = t0;
            obj.amp = real(amp);
            obj.freq = real(freq);
            obj.phase = real(phase);
        end
        
        function value = getValueAtTime(obj,ut)
            dt = (ut - obj.t0) + obj.tOffset;
            
            value = obj.amp * sin(obj.freq*(dt + obj.phase));
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = sprintf('%0.3f * sin(%0.3f * (dt + %0.3f))', obj.amp, obj.freq, obj.phase);
        end
        
        function newSineModel = deepCopy(obj)
            newSineModel = SineModel(obj.t0, obj.amp, obj.freq, obj.phase);
        end
        
        function numVars = getNumVars(~)
            numVars = 3;
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,3);
            
            if(obj.varAmp)
                x(1) = obj.amp;
            end
            
            if(obj.varFreq)
                x(2) = obj.freq;
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
                obj.freq = x(2);
            end
            
            if(not(isnan(x(3))))
                obj.phase = x(3);
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = [obj.ampLb, obj.freqLb, obj.phaseLb];
            ub = [obj.ampUb, obj.freqUb, obj.phaseUb];
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(not(isnan(lb(1))))
                obj.ampLb = lb(1);
            end
            
            if(not(isnan(lb(2))))
                obj.freqLb = lb(2);
            end
            
            if(not(isnan(lb(3))))
                obj.phaseLb = lb(3);
            end
            
            if(not(isnan(ub(1))))
                obj.ampUb = ub(1);
            end
            
            if(not(isnan(ub(2))))
                obj.freqUb = ub(2);
            end
            
            if(not(isnan(ub(3))))
                obj.phaseUb = ub(3);
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varAmp, obj.varFreq, obj.varPhase];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varAmp = useTf(1);
            obj.varFreq = useTf(2);
            obj.varPhase = useTf(3);
        end
        
        function nameStrs = getStrNamesOfVars(obj)
            nameStrs = {'Sine Amplitude', 'Sine Frequency', 'Sine Phase Shift'};
        end
    end
end