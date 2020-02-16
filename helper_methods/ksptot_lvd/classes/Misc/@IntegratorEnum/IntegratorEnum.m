classdef IntegratorEnum < matlab.mixin.SetGet
    %IntegratorEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        ODE45('ODE45','Most of the time ode45 should be the first solver you try.');
        ODE113('ODE113','ode113 can be more efficient than ode45 at problems with stringent error tolerances, or when the ODE function is expensive to evaluate.');
        ODE23('ODE23','ode23 can be more efficient than ode45 at problems with crude tolerances, or in the presence of moderate stiffness.');
        ODE15s('ODE15s','Try ode15s when ode45 fails or is inefficient and you suspect that the problem is stiff.');
        ODE23s('ODE23s','ode23s can be more efficient than ode15s at problems with crude error tolerances. It can solve some stiff problems for which ode15s is not effective.');
    end
    
    properties
        nameStr char = '';
        descStr char = '';
    end
    
    methods
        function obj = IntegratorEnum(nameStr, descStr)
            obj.nameStr = nameStr;
            obj.descStr = descStr;
        end
    end
        
    methods(Static)       
        function listBoxStr = getListBoxStrs()
            [m,~] = enumeration('IntegratorEnum');
            
            listBoxStr = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                listBoxStr{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function [ind, mInd] = getIndOfListboxStr(nameStr)
            [m,~] = enumeration('IntegratorEnum');
            
            ind = -1;
            for(i=1:length(m))
                if(strcmpi(m(i).nameStr,nameStr))
                    ind = i;
                    mInd = m(i);
                    break;
                end
            end
        end
        
        function integratorObj = getIntegratorObjFromEnum(m)
            switch m
                case IntegratorEnum.ODE113
                    integratorObj = ODE113Integrator();

                case IntegratorEnum.ODE15s
                    integratorObj = ODE15sIntegrator();

                case IntegratorEnum.ODE23
                    integratorObj = ODE23Integrator();

                case IntegratorEnum.ODE23s
                    integratorObj = ODE23sIntegrator();

                case IntegratorEnum.ODE45
                    integratorObj = ODE45Integrator();

                otherwise
                    error('Unknown integrator type.');
            end
        end
    end
end