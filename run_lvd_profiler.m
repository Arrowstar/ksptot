clc; clear all; format long g; close all;

load('lvdExample_ComplexDrag_AsparagusStaging.mat');

for(i=1:length(lvdData.script.evts))
    lvdData.script.evts(i).integratorObj.options.AbsTol = 1E-6;
    lvdData.script.evts(i).integratorObj.options.RelTol = 1E-6;
end

profile on;
% run 3 times
for(i=1:3)
    stateLog = lvdData.script.executeScript(false, lvdData.script.evts(1), true, false, false, false); 
end
profile off;

p = profile('info');

funcsToFind = {'ForceModelPropagator.odefun', 'TotalForceModel.getForce', 'DragForceModel.getForce', 'ThrustForceModel.getForce', 'RollPitchYawPolySteeringModel.getBody2InertialDcmAtTime'};

for k=1:length(funcsToFind)
    funcIdx = find(contains({p.FunctionTable.FunctionName}, funcsToFind{k}));
    if ~isempty(funcIdx)
        funcData = p.FunctionTable(funcIdx(1));
        fprintf('\n--- %s details ---\n', funcsToFind{k});
        fprintf('Total Time: %f, Num Calls: %d\n', funcData.TotalTime, funcData.NumCalls);
        
        % sort children by total time
        if ~isempty(funcData.Children)
            children = funcData.Children;
            childTimes = [children.TotalTime];
            [~, sortIdx] = sort(childTimes, 'descend');
            
            fprintf('Top 5 Children:\n');
            for j=1:min(5, length(sortIdx))
                childIdx = children(sortIdx(j)).Index;
                childName = p.FunctionTable(childIdx).FunctionName;
                fprintf('  %s: %f s, %d calls\n', childName, children(sortIdx(j)).TotalTime, children(sortIdx(j)).NumCalls);
            end
        end
    end
end
