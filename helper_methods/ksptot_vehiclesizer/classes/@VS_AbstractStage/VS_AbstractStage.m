classdef(Abstract) VS_AbstractStage < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %VS_AbstractStage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %direct inputs
        name char = 'Untitled Stage';
    end
    
    properties
        phase VS_Phase
    end
    
    properties(Dependent)
        %computed
        payloadStage(1,:) VS_Stage
    end
    
    methods
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
        
        deltaV = getStageDeltaV(obj)
                      
        dryMass = getTotalStageDryMass(obj)
               
        expPropMass = computeExpendedPropMass(obj)
        
        tgtDryMass = computeTgtDryMass(obj)
        
        stageTotalMass = computeStageTotalMass(obj)
                        
        str = getStageOutputStr(obj)
        
        %%%%%%%% For Optimizer Use %%%%%%%%%
        initStageForOpt(obj, phaseDvPerStage)
        
        x = getStageOptimizerVars(obj)
        
        function numVars = getNumVariables(obj)
            numVars = length(obj.getStageOptimizerVars());
        end
        
        updateStageWithVars(obj, x)
        
        [lb,ub] = getStageOptVarBounds(obj)
        
        [c, ceq] = getStageNlConValues(obj)
    end
    
    methods(Access=protected)
        function g = computeGforBody(obj)
            if(not(isempty(obj.bodyInfo)))
                g = (obj.bodyInfo.gm / obj.bodyInfo.radius^2) * 1000; %km/s/s -> m/s/s
            else
                g = getG0();
            end
        end
    end
end