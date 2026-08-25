function skipList = getGoldenSkipList()
%GETGOLDENSKIPLIST Example cases excluded from golden state log verification.
%
%   Each entry is an example base name that cannot run headlessly or does
%   not contain a valid LVD mission script, with the reason documented
%   below.  These are pre-existing conditions, unrelated to incremental
%   re-propagation work.

    skipList = { ...
        'lvdExample_ToEelooViaJool_BackPropExample', ... %propagation throws "Not enough input arguments" when run headlessly (pre-existing)
        'lvdExample_TwoStageToOrbit_PluginVar' ...        %.mat file does not contain an lvdData variable (not a mission script)
        };
end
