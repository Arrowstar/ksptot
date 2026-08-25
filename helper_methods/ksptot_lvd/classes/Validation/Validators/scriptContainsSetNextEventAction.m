function tf = scriptContainsSetNextEventAction(lvdData)
%SCRIPTCONTAINSSETNEXTEVENTACTION Detects script-flow-modifying actions.
%
%   tf = scriptContainsSetNextEventAction(lvdData) returns true if any
%   action of any event (sequential or non-sequential) in the mission
%   script is a SetNextEventAction.
%
%   Scripts that use SetNextEventAction have execution orders that cannot
%   be statically determined (loops, skips), so consumers that cache or
%   reuse earlier events' propagation results must re-propagate the entire
%   script to stay correct.

    tf = false;

    evts = lvdData.script.evts;

    for(i = 1:length(evts))
        if(evtHasSetNextEventAction(evts(i)))
            tf = true;
            return;
        end
    end

    nonSeqEvts = lvdData.script.nonSeqEvts.evts;

    for(i = 1:length(nonSeqEvts))
        if(evtHasSetNextEventAction(nonSeqEvts(i)))
            tf = true;
            return;
        end
    end
end

function tf = evtHasSetNextEventAction(evt)
    tf = false;

    for(i = 1:length(evt.actions))
        if(isa(evt.actions(i), 'SetNextEventAction'))
            tf = true;
            return;
        end
    end
end
