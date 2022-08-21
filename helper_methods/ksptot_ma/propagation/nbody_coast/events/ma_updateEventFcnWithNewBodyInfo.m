function [events] = ma_updateEventFcnWithNewBodyInfo(events, newBodyInfo, celBodyData)
%ma_updateEventFcnWithNewBodyInfo Summary of this function goes here
%   Detailed explanation goes here

    for(i=1:length(events)) %#ok<*NO4LP>
        event = events{i};
        
        if(~isempty(strfind(func2str(event), 'ma_SoITransitionEvents')))
            event = @(T,Y) ma_SoITransitionEvents(T,Y, newBodyInfo, celBodyData);
            
        elseif(~isempty(strfind(func2str(event), 'ma_TrueAnomalyEvent')))
            [truTarget,~,refBody,~] = event('getInfo',[]);
            event = @(T,Y) ma_TrueAnomalyEvent(T,Y, truTarget, newBodyInfo, refBody);
            
        elseif(~isempty(strfind(func2str(event), 'ma_NodeEvents')))
            [node,~,refBody,~] = event('getInfo',[]);
            event = @(T,Y) ma_NodeEvents(T,Y, node, newBodyInfo, refBody);
            
        else
            error(['Unknown event function handle: ', func2str(event)]);
        end
        
        events{i} = event;
    end
end

