classdef VS_Stage < matlab.mixin.SetGet
    %VS_Stage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %direct inputs
        name char = 'Untitled Stage';
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
        
        %data
        phase VS_Phase
    end
    
    properties(Dependent)
        %computed
        payloadStage(1,:) VS_Stage
    end
    
    methods
        function obj = VS_Stage(phase)
            obj.phase = phase;
        end
        
        function payloadStage = get.payloadStage(obj)
            allPhaseStages = obj.phase.getPhaseStages();
            stageInd = obj.phase.getIndOfStage(obj);
            
            if(stageInd == 1)
                vsProb = obj.phase.vsProb;
                phaseInd = vsProb.getIndOfPhase(obj.phase);
                if(phaseInd == 1)
                    payloadStage = VS_Stage.empty(1,0);
                else
                    nextPhase = vsProb.getPhaseForInd(phaseInd - 1);
                    nextPhaseStages = nextPhase.getPhaseStages();
                    payloadStage = nextPhaseStages(end);
                end
            else
                payloadStage = allPhaseStages(stageInd - 1);
            end
        end
        
        function payloadMass = computePayloadMass(obj)
            if(isempty(obj.payloadStage))
                payloadMass = 0;
            else
                payloadMass = obj.payloadStage.computeInitMass();
            end
        end
        
        function finalMass = computeFinalMass(obj)
            finalMass = obj.computePayloadMass() + obj.dryMass;
        end
        
        function initMass = computeInitMass(obj)
            finalMass = obj.computeFinalMass();
            g0 = getG0();
            
            initMass = finalMass * exp(obj.deltaV/(g0*obj.isp));
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
        
        function reqdThrust = computeReqdThrust(obj)
            reqdThrust = obj.desiredT2W * (obj.computeStageTotalMass() + obj.computePayloadMass()) * obj.computeGforBody();
        end
        
        function engineBurnTime = computeEngineBurnTime(obj)
            engineBurnTime = obj.computeExpendedPropMass() / (obj.computeReqdThrust() / (getG0() * obj.isp));
        end
        
        function tf = isPayloadOnlyStage(obj)
            tf = obj.isPayload;
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
    end
    
    methods(Access=private)
        function g = computeGforBody(obj)
            if(not(isempty(obj.bodyInfo)))
                g = (obj.bodyInfo.gm / obj.bodyInfo.radius^2) * 1000; %km/s/s -> m/s/s
            else
                g = getG0();
            end
        end
    end
end