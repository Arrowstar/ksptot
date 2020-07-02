classdef VS_Problem < matlab.mixin.SetGet
    %VS_Problem Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        phases(1,:) VS_Phase
    end
    
    methods
        function obj = VS_Problem()

        end
        
        function addPhase(obj, newPhase)
            obj.phases(end+1) = newPhase;
        end
        
        function removePhase(obj, phase)
            obj.phases(obj.phases == phase) = [];
        end    
        
        function phase = getPhaseForInd(obj, ind)
            if(ind <= length(obj.phases) && ind >= 1)
                phase = obj.phases(ind);
            else
                phase = VS_Phase.empty(1,0);
            end
        end
        
        function ind = getIndOfPhase(obj, phase)
            ind = find(obj.phases == phase,1);
        end
        
        function movePhaseUp(obj, phase)
            ind = obj.getIndOfPhase(phase);
            
            if(ind > 1)
                obj.phases([ind,ind-1]) = obj.phases([ind-1,ind]);
            end
        end
        
        function movePhaseDown(obj, phase)
            ind = obj.getIndOfPhase(phase);
            
            if(ind < length(obj.phases))
                obj.phases([ind+1,ind]) = obj.phases([ind,ind+1]);
            end
        end
        
        function str = getPhasesListboxStr(obj)
            str = {};
            
            for(i=1:length(obj.phases))
                str{i} = sprintf('Phase %u: %s', length(obj.phases)-i+1, obj.phases(i).name); %#ok<AGROW>
            end
        end
        
        function totalMass = computeTotalVehicleMass(obj)
            totalMass = 0;
            
            for(i=1:length(obj.phases))
                totalMass = totalMass + obj.phases(i).getPhaseTotalMass();
            end
        end
        
        function totalDryMass = computeTotalVehicleDryMass(obj)
            totalDryMass = 0;
            
            for(i=1:length(obj.phases))
                totalDryMass = totalDryMass + obj.phases(i).getPhaseTotalDryMass();
            end
        end
        
        function totalPropMass = computeTotalVehiclePropMass(obj)
            totalPropMass = 0;
            
            for(i=1:length(obj.phases))
                totalPropMass = totalPropMass + obj.phases(i).getPhaseTotalPropMass();
            end
        end
        
        function stages = getAllProblemStages(obj)
            stages = VS_Stage.empty(1,0);
            
            for(i=1:length(obj.phases))
                stages = horzcat(stages, obj.phases(i).getPhaseStages()); %#ok<AGROW>
            end
        end
        
        %%%%%%%% For Optimizer Use %%%%%%%%%
        function x = getProblemState(obj)
            stages = obj.getAllProblemStages();
            
            x = [];
            for(i=1:length(stages))
                stage = stages(i);
                
                x = horzcat(x, stage.getStageOptimizerVars()); %#ok<AGROW>
            end
        end
        
        function updateStagesWithVars(obj, x)
            stages = obj.getAllProblemStages();
            
            for(i=1:length(stages))
                stage = stages(i);
                numVars = stage.getNumVariables();
                
                stage.updateStageWithVars(x(1:numVars));
                x(1:numVars) = []; %pop off the vars we just assigned
            end
        end
        
        function [lb, ub] = getVarBounds(obj)
            stages = obj.getAllProblemStages();
            
            lb = [];
            ub = [];
            for(i=1:length(stages))   
                stage = stages(i);
                
                [lbS,ubS] = stage.getStageOptVarBounds();
                
                lb = horzcat(lb, lbS); %#ok<AGROW> 
                ub = horzcat(ub, ubS); %#ok<AGROW> 
            end
        end
        
        function f = objFunc(obj, x)
            obj.updateStagesWithVars(x);
            
            f = obj.computeTotalVehicleMass();
        end  
        
        function [c, ceq] = nonlcon(obj, x)
            obj.updateStagesWithVars(x);
            
            c = [];
            ceq = [];
            
            stages = obj.getAllProblemStages();
            for(i=1:length(stages))
                stage = stages(i);
                
                [cS, ceqS] = stage.getStageNlConValues();
                c = horzcat(c, cS); %#ok<AGROW>
                ceq = horzcat(ceq, ceqS); %#ok<AGROW>
            end
            
            for(i=1:length(obj.phases))
                phase = obj.phases(i);
                ceq(end+1) = phase.phaseDv - phase.getPhaseTotalDeltaV(); %#ok<AGROW>
            end
        end
        
        function initProblemForOptimization(obj)
            %1) Split desired delta-v per phase equally into all phase stages
            %2) Starting with upper-most dry mass, iterate on just that dry mass such that it equals its target dry mass
            %   Repeat for all subsequent dry masses            
            
            for(i=1:length(obj.phases))
                phase = obj.phases(i);
                stages = phase.getPhaseStages();
                
                phaseDvPerStage = phase.phaseDv/length(stages);
                for(j=1:length(stages))
                    stage = stages(j);
                    
                    stage.initStageForOpt(phaseDvPerStage);
                end
            end
        end
        
        function [x,fval,exitflag,output] = sizeVehicle(obj)
            preOptStage = obj.getProblemState();
            
            obj.initProblemForOptimization();
            objFcn = @(x) obj.objFunc(x);
            nonlcon = @(x) obj.nonlcon(x);
            x0 = obj.getProblemState();
            [lb, ub] = obj.getVarBounds();
            options = optimoptions(@fmincon, 'Display','iter', 'Algorithm','sqp');
            
            [x,fval,exitflag,output] = fmincon(objFcn,x0,[],[],[],[],lb,ub,nonlcon,options);
            
            if(exitflag > 0)
                obj.updateStagesWithVars(x);
            else
                obj.updateStagesWithVars(preOptStage);
            end
        end
        
        function str = getProblemOutputStr(obj,exitflag,output)
            str = cell(1,0);
            
            str{end+1} = '-------------------------------------------------------------------';
            str{end+1} = '------------------------ Vehicle Data -----------------------------';
            str{end+1} = '-------------------------------------------------------------------';
            
            str{end+1} = sprintf('Vehicle Total Dry Mass: %0.3f mT',obj.computeTotalVehicleDryMass()/1000);
            str{end+1} = sprintf('Vehicle Total Propellant Mass: %0.3f mT',obj.computeTotalVehiclePropMass()/1000);
            str{end+1} = sprintf('Vehicle Total Mass: %0.3f mT',obj.computeTotalVehicleMass()/1000);
            str{end+1} = ' ';
            
            for(i=1:length(obj.phases))
                str = horzcat(str,obj.phases(i).getPhaseOutputStr()); %#ok<AGROW>
                
                if(i<length(obj.phases))
                    str{end+1} = ' '; %#ok<AGROW>
                end
            end
            
            str{end+1} = ' ';
            str{end+1} = '-------------------------------------------------------------------';
            str{end+1} = '------------------- Solver Exit Information -----------------------';
            str{end+1} = '-------------------------------------------------------------------';
            str{end+1} = ' ';
            str{end+1} = sprintf('Solver Run On: %s', datestr(now(),'yyyy-mm-dd HH:MM:SS'));
            str{end+1} = sprintf('Solver Exit Flag: %u', exitflag);
            str{end+1} = sprintf('Solver Exit Message:');
            str{end+1} = ' ';
            str{end+1} = sprintf('%s', output.message);
            
            str = str(:);
        end
    end
    
    methods(Static)
        function vsProb = getDefaultVsProblem(celBodyData)
            vsProb = VS_Problem();

            %Payload Phase
            phase0 = VS_Phase(vsProb);
            phase0.name = 'Untitled Phase';
            phase0.phaseDv = 5000;
            vsProb.addPhase(phase0);
           
            bodynames = celBodyData.fieldnames();
            
            stage0 = VS_Stage(phase0);
            stage0.name = 'Untitled Stage';
            stage0.isp = 300;
            stage0.dryMassFrac = 0.2;
            stage0.desiredT2W = 1;
            stage0.bodyInfo = celBodyData.(bodynames{1});
            stage0.dryMass = 500;
            stage0.isPayload = true;
            phase0.addStage(stage0);
            
%             %Payload Phase
%             phase0 = VS_Phase(vsProb);
%             phase0.name = 'Payload';
%             phase0.phaseDv = 0;
%             vsProb.addPhase(phase0);
%             
%             stage0 = VS_Stage(phase0);
%             stage0.name = 'Payload Stage';
%             stage0.isp = 300;
%             stage0.dryMassFrac = 0.2;
%             stage0.desiredT2W = 1;
%             stage0.bodyInfo = celBodyData.kerbin;
%             stage0.dryMass = 500;
%             stage0.isPayload = true;
%             phase0.addStage(stage0);
%             
%             %Phase 1 Eve
%             phase1 = VS_Phase(vsProb);
%             phase1.name = 'Eve';
%             phase1.phaseDv = 10445;
%             vsProb.addPhase(phase1);
%             
%             stage1 = VS_Stage(phase1);
%             stage1.name = 'Eve 3rd';
%             stage1.isp = 345;
%             stage1.dryMassFrac = 0.18;
%             stage1.desiredT2W = 1;
%             stage1.bodyInfo = celBodyData.eve;
%             stage1.dryMass = 607.73;
%             stage1.deltaV = 4237.78;
%             phase1.addStage(stage1);
%             
%             stage2 = VS_Stage(phase1);
%             stage2.name = 'Eve 2nd';
%             stage2.isp = 290;
%             stage2.dryMassFrac = 0.18;
%             stage2.desiredT2W = 1.4;
%             stage2.bodyInfo = celBodyData.eve;
%             stage2.dryMass = 3343.01;
%             stage2.deltaV = 3226.36;
%             phase1.addStage(stage2);
%             
%             stage3 = VS_Stage(phase1);
%             stage3.name = 'Eve 1st';
%             stage3.isp = 285;
%             stage3.dryMassFrac = 0.19;
%             stage3.desiredT2W = 1.4;
%             stage3.bodyInfo = celBodyData.eve;
%             stage3.dryMass = 18139.93;
%             stage3.deltaV = 2980.86;
%             phase1.addStage(stage3);
%             
%             %Phase 1 Kerbin
%             phase2 = VS_Phase(vsProb);
%             phase2.name = 'Kerbin';
%             phase2.phaseDv = 5175;
%             vsProb.addPhase(phase2);
%             
%             stage4 = VS_Stage(phase2);
%             stage4.name = 'Kerbin 3rd';
%             stage4.isp = 340;
%             stage4.dryMassFrac = 0.20;
%             stage4.desiredT2W = 1;
%             stage4.bodyInfo = celBodyData.kerbin;
%             stage4.dryMass = 41375.90;
%             stage4.deltaV = 2375.46;
%             phase2.addStage(stage4);
%             
%             stage5 = VS_Stage(phase2);
%             stage5.name = 'Kerbin 2nd';
%             stage5.isp = 300;
%             stage5.dryMassFrac = 0.20;
%             stage5.desiredT2W = 1.4;
%             stage5.bodyInfo = celBodyData.kerbin;
%             stage5.dryMass = 62345.40;
%             stage5.deltaV = 1462.83;
%             phase2.addStage(stage5);
%             
%             stage6 = VS_Stage(phase2);
%             stage6.name = 'Kerbin 1st';
%             stage6.isp = 295;
%             stage6.dryMassFrac = 0.20;
%             stage6.desiredT2W = 1.3;
%             stage6.bodyInfo = celBodyData.kerbin;
%             stage6.dryMass = 109549.07;
%             stage6.deltaV = 1336.71;
%             phase2.addStage(stage6);
        end
    end
end