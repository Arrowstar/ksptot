classdef VS_Phase < matlab.mixin.SetGet
    %VS_Phase Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name char = 'Untitled Phase';
        stages(1,:) VS_AbstractStage
        
        %direct inputs
        phaseDv(1,1) double = 0;
        
        %data
        vsProb VS_Problem
    end
    
    methods
        function obj = VS_Phase(vsProb)
            obj.vsProb = vsProb;
        end
        
        function addStage(obj, newStage)
            obj.stages(end+1) = newStage;
        end
        
        function removeStage(obj, stage)
            obj.stages(obj.stages == stage) = [];
        end   
        
        function stages = getPhaseStages(obj)
            stages = obj.stages;
        end
        
        function ind = getIndOfStage(obj, stage)
            ind = find(obj.stages == stage,1);
        end
        
        function moveStageUp(obj, stage)
            ind = obj.getIndOfStage(stage);
            
            if(ind > 1)
                obj.stages([ind,ind-1]) = obj.stages([ind-1,ind]);
            end
        end
        
        function moveStageDown(obj, stage)
            ind = obj.getIndOfStage(stage);
            
            if(ind < length(obj.stages))
                obj.stages([ind+1,ind]) = obj.stages([ind,ind+1]);
            end
        end
        
        function totalMass = getPhaseTotalMass(obj)
            totalMass = 0;
            
            for(i=1:length(obj.stages))
                totalMass = totalMass + obj.stages(i).computeStageTotalMass();
            end
        end
        
        function totalDryMass = getPhaseTotalDryMass(obj)
            totalDryMass = 0;
            
            for(i=1:length(obj.stages))
                totalDryMass = totalDryMass + obj.stages(i).getTotalStageDryMass();
            end
        end
        
        function totalPropMass = getPhaseTotalPropMass(obj)
            totalPropMass = 0;
            
            for(i=1:length(obj.stages))
                totalPropMass = totalPropMass + obj.stages(i).computeExpendedPropMass();
            end
        end
        
        function totalDv = getPhaseTotalDeltaV(obj)
            totalDv = 0;
            
            for(i=1:length(obj.stages))
                totalDv = totalDv + obj.stages(i).getStageDeltaV();
            end
        end
        
        function str = getPhaseOutputStr(obj)
            str = cell(0,1);
            str{end+1} = sprintf('Phase: %s', obj.name);
            str{end+1} = sprintf('\tDesired Delta-v: %0.3f m/s', obj.phaseDv);
            str{end+1} = sprintf('\tAchieved Delta-v: %0.3f m/s', obj.getPhaseTotalDeltaV());
            str{end+1} = ' ';
            
            for(i=1:length(obj.stages))
                str = horzcat(str,obj.stages(i).getStageOutputStr()); %#ok<AGROW>
                
                if(i<length(obj.stages))
                    str{end+1} = ' '; %#ok<AGROW>
                end
            end

        end
        
        function stage = getStageForInd(obj, ind)
            if(ind <= length(obj.stages)  && ind >= 1)
                stage = obj.stages(ind);
            else
                stage = VS_Stage.empty(1,0);
            end
        end
        
        function str = getStagesListboxStr(obj)
            str = {};
            
            for(i=1:length(obj.stages))
                str{i} = sprintf('Stage %u: %s', length(obj.stages)-i+1, obj.stages(i).name); %#ok<AGROW>
            end
        end
    end
end