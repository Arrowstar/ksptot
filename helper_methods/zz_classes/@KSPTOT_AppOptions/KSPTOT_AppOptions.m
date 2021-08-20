classdef KSPTOT_AppOptions < handle
    %KSPTOT_AppOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %KSPTOT Options
        bodiesinifile
        rtshostname
        timesystem char
        gravparamtype char
        
        plotmaxdeltav double
        porkchopptsaxes double
        porkchopnumsynperiods double
        departplotnumoptiters double
        quant2opt char
        
        %LVD Options
        lvdrecentmsncasefiles(1,:) char = '';
    end
    
    events
        GravParamTypeUpdated
        TimeSystemUpdated
    end
    
    methods
        function obj = KSPTOT_AppOptions()
            
        end
    end
end

