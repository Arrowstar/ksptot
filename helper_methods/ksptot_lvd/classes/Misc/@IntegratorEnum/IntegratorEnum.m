classdef IntegratorEnum < matlab.mixin.SetGet
    %IntegratorEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        ODE45('ODE45','Most of the time ode45 should be the first solver you try.', true, false);
        ODE113('ODE113','ode113 can be more efficient than ode45 at problems with stringent error tolerances, or when the ODE function is expensive to evaluate.', true, false);
        ODE78('ODE78','ode78 can be more efficient than ode45 at problems with smooth solutions that have high accuracy requirements.', true, false);
        ODE89('ODE89','ode89 can be more efficient than ode78 on very smooth problems, when integrating over long time intervals, or when tolerances are especially tight.', true, false)
        ODE23('ODE23','ode23 can be more efficient than ode45 at problems with crude tolerances, or in the presence of moderate stiffness.', true, false);
        ODE15s('ODE15s','Try ode15s when ode45 fails or is inefficient and you suspect that the problem is stiff.', true, false);
        ODE23s('ODE23s','ode23s can be more efficient than ode15s at problems with crude error tolerances. It can solve some stiff problems for which ode15s is not effective.', true, false);
        ODE5('ODE5','ODE5 is a fixed step size integrator.  This integrator may be faster on events where the integration time is short.  Integration time is highly dependent on the step size in options.', true, false)
        RKN1210('RKN1210','RKN1210 can be very efficient when acceleration is only a function of position (i.e. gravity) and tolerances are tight.', false, true);
    end
    
    properties
        nameStr char = '';
        descStr char = '';
        isFirstOrder(1,1) logical = true;
        isSecondOrder(1,1) logical = false;
    end
    
    methods
        function obj = IntegratorEnum(nameStr, descStr, isFirstOrder, isSecondOrder)
            obj.nameStr = nameStr;
            obj.descStr = descStr;
            obj.isFirstOrder = isFirstOrder;
            obj.isSecondOrder = isSecondOrder;
        end
    end
        
    methods(Static)       
        function [listBoxStr, m] = getListBoxStrs(getFirstOrder, getSecondOrder)
            arguments
                getFirstOrder(1,1) logical = true;
                getSecondOrder(1,1) logical = true;
            end

            [m,~] = enumeration('IntegratorEnum');
            m = m(([m.isFirstOrder] & getFirstOrder) | ([m.isSecondOrder] & getSecondOrder));

            listBoxStr = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                listBoxStr{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function [ind, mInd] = getIndOfListboxStr(nameStr, getFirstOrder, getSecondOrder)
            arguments
                nameStr(1,:) char
                getFirstOrder(1,1) logical = true;
                getSecondOrder(1,1) logical = true;
            end

            [~, m] = IntegratorEnum.getListBoxStrs(getFirstOrder, getSecondOrder);
            
            ind = -1;
            mInd = IntegratorEnum.empty(1,0);
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

                case IntegratorEnum.ODE78
                    integratorObj = ODE78Integrator();

                case IntegratorEnum.ODE89
                    integratorObj = ODE89Integrator();
                    
                case IntegratorEnum.ODE5
                    integratorObj = ODE5Integrator();

                case IntegratorEnum.RKN1210   
                    integratorObj = RKN1210Integrator();

                otherwise
                    error('Unknown integrator type.');
            end
        end
    end
end