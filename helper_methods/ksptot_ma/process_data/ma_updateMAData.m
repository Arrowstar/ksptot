function maData = ma_updateMAData(maData)
%ma_updateMAData Summary of this function goes here
%   Detailed explanation goes here
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'strictSoISearch')))
        maData.settings.strictSoISearch = false;
	end
    
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'parallelScriptOptim')))
        maData.settings.parallelScriptOptim = false;
	end
    
    thrusters = maData.spacecraft.thrusters;
    for(i=1:length(thrusters)) %#ok<*NO4LP>
        thruster = thrusters{i};
        if(~isfield(thruster,'thrust'))
            thruster.thrust = 100;
            thrusters{i} = thruster;
        end
        
        script = maData.script;
        for(j=1:length(script))
            event = script{j};
            if(isfield(event,'thruster'))
                if(isempty(event.thruster))
                    event.thruster = thrusters{1};
                end
                if(event.thruster.id == thruster.id)
                    event.thruster = thruster;
                end
            end
            script{j} = event;
        end
        maData.script = script;
    end
    maData.spacecraft.thrusters = thrusters;
    
    if(~isfield(maData.settings,'numStateLogPtsPerCoast'))
        maData.settings.numStateLogPtsPerCoast = 1000;
    end
    
    if(~isfield(maData.settings,'numSoISearchRevs'))
        maData.settings.numSoISearchRevs = 3;
    end
end

