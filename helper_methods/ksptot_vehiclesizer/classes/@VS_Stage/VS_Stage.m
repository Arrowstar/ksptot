classdef VS_Stage < VS_AbstractStage
    %VS_Stage Basic stage with one tank and one engine (and no boosters)
    %   Detailed explanation goes here
       
    properties
        %direct inputs
        isp double = 300; %seconds
        dryMassFrac(1,1) double = 0.2;
        desiredT2W(1,1) double = 1.0;
        bodyInfo KSPTOT_BodyInfo = KSPTOT_BodyInfo.empty(1,0);
        
        %computed
        %payloadStage(1,:) VS_Stage = VS_Stage.empty(1,0);
        
        %optimized quantities
        dryMass(1,1) double = 1; %kg
        deltaV(1,1) double = 0; %m/s
        
        %flags
        isPayload(1,1) logical = false;
    end
    
    methods
        function obj = VS_Stage(phase)
            obj.phase = phase;
        end
        
        function deltaV = getStageDeltaV(obj)
            deltaV = obj.deltaV;
        end
                      
        function dryMass = getTotalStageDryMass(obj)
            dryMass = obj.dryMass;
        end
               
        function expPropMass = computeExpendedPropMass(obj)
            expPropMass = obj.computeInitMass() - obj.computeFinalMass();
        end
        
        function tgtDryMass = computeTgtDryMass(obj)
            tgtDryMass = (obj.dryMassFrac/(1 - obj.dryMassFrac)) * obj.computeExpendedPropMass();
        end
        
        function stageTotalMass = computeStageTotalMass(obj)
            stageTotalMass = obj.dryMass + obj.computeExpendedPropMass();
        end
                        
        function str = getStageOutputStr(obj)
            str = cell(0,1);
            str{end+1} = sprintf('\tStage: %s', obj.name);
            str{end+1} = sprintf('\t\tTotal Stage Dry Mass: %0.3f mT', obj.dryMass/1000);
            str{end+1} = sprintf('\t\tTotal Stage Prop Mass: %0.3f mT', obj.computeExpendedPropMass()/1000);
            str{end+1} = sprintf('\t\tTotal Stage Mass: %0.3f mT', obj.computeStageTotalMass()/1000);
            str{end+1} = sprintf('\t\tTotal Stage Delta-V: %0.3f km/s', obj.deltaV/1000);
            str{end+1} = sprintf('\t\tStage Req''d Thrust: %0.3f kN', obj.computeReqdThrust()/1000);
            str{end+1} = sprintf('\t\tStage Burn Time: %0.3f sec', obj.computeEngineBurnTime());
            str{end+1} = sprintf('\t\t----');
            str{end+1} = sprintf('\t\tStage Isp: %0.3f sec', obj.isp);
            str{end+1} = sprintf('\t\tStage Dry Mass Fraction: %0.3f', obj.dryMassFrac);
            str{end+1} = sprintf('\t\tStage Celestial Body: %s', obj.bodyInfo.name);
        end
        
        %%%%%%%% For Optimizer Use %%%%%%%%%
        function initStageForOpt(obj, phaseDvPerStage)
            obj.deltaV = phaseDvPerStage;
            
            if(not(obj.isPayloadOnlyStage()))
                diff = Inf;
                iterCnt = 1;
                while(diff >= 0.01 && iterCnt <=200)
                    obj.dryMass = obj.computeTgtDryMass();

                    diff = abs(obj.dryMass - obj.computeTgtDryMass());
                    iterCnt = iterCnt + 1;
                end
            end
        end
        
        function x = getStageOptimizerVars(obj)
            x = [];
            
            if(not(obj.isPayloadOnlyStage())) 
                x = [obj.deltaV, obj.dryMass];
            end
        end
        
        function updateStageWithVars(obj, x)
            if(not(obj.isPayloadOnlyStage()))  
                obj.deltaV = x(1);
                obj.dryMass = x(2);
            end
        end
        
        function [lb,ub] = getStageOptVarBounds(obj)
            lb = [];
            ub = [];
            
            if(not(obj.isPayloadOnlyStage()))                
                lb = [0, 0]; %dV and dry mass have lower bounds of 0
                ub = [Inf, Inf]; %no upper bounds on these variables
            end
        end
        
        function [c, ceq] = getStageNlConValues(obj)
            c = [];
            ceq = [];
            
            if(not(obj.isPayloadOnlyStage()))
                ceq(1) = obj.getTotalStageDryMass() - obj.computeTgtDryMass();
            end
        end
    end
    
    methods(Access=private)
        function finalMass = computeFinalMass(obj)
            finalMass = obj.computePayloadMass() + obj.dryMass;
        end
        
        function initMass = computeInitMass(obj)
            finalMass = obj.computeFinalMass();
            g0 = getG0();
            
            initMass = finalMass * exp(obj.deltaV/(g0*obj.isp));
        end
        
        function payloadMass = computePayloadMass(obj)
            if(isempty(obj.payloadStage))
                payloadMass = 0;
            else
                payloadMass = obj.payloadStage.computeInitMass();
            end
        end
        
        function reqdThrust = computeReqdThrust(obj)
            reqdThrust = obj.desiredT2W * (obj.computeStageTotalMass() + obj.computePayloadMass()) * obj.computeGforBody();
        end
        
        function engineBurnTime = computeEngineBurnTime(obj)
            engineBurnTime = obj.computeExpendedPropMass() / (obj.computeReqdThrust() / (getG0() * obj.isp));
        end
        
        function tf = isPayloadOnlyStage(obj)
            tf = obj.isPayload;
        end
    end
end