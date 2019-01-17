classdef IntegratorEnum < matlab.mixin.SetGet
    %IntegratorEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        ODE45('ODE45','Most of the time ode45 should be the first solver you try.',@ode45);
        ODE113('ODE113','ode113 can be more efficient than ode45 at problems with stringent error tolerances, or when the ODE function is expensive to evaluate.',@ode113);
        ODE23('ODE23','ode23 can be more efficient than ode45 at problems with crude tolerances, or in the presence of moderate stiffness.',@ode23);
        ODE15s('ODE15s','Try ode15s when ode45 fails or is inefficient and you suspect that the problem is stiff. Also use ode15s when solving differential algebraic equations (DAEs).',@ode15s);
        ODE23s('ODE23s','ode23s can be more efficient than ode15s at problems with crude error tolerances. It can solve some stiff problems for which ode15s is not effective.',@ode23s);
        DOP853('DOP853','Runge-Kutta method of order (8)5,3',@dop853);
%         RKN1210('RKN1210','12th/10th order Runge-Kutta-Nyström integrator.  Highly efficient, but can ONLY use GRAVITY force model.  All other force models should be DESELECTED!',@rkn1210);
            %There are issues with the RKN1210 integrator, it's not finding
            %events correctly.  Don't use for now.
    end
    
    properties
        nameStr char = '';
        descStr char = '';
        functionHandle(1,1)
    end
    
    methods
        function obj = IntegratorEnum(nameStr, descStr, functionHandle)
            obj.nameStr = nameStr;
            obj.descStr = descStr;
            obj.functionHandle = functionHandle;
        end
    end
    
    methods
        function odeFH = getOdeFunctionHandle(obj, simDriver, eventInitStateLogEntry, dryMass, forceModels)
            switch obj
                case {IntegratorEnum.ODE45, ...
                      IntegratorEnum.ODE113, ...
                      IntegratorEnum.ODE23, ...
                      IntegratorEnum.ODE15s, ...
                      IntegratorEnum.ODE23s, ...
                      IntegratorEnum.DOP853}
                    odeFH = FirstOrderODE.getOdeFunctionHandle(simDriver, eventInitStateLogEntry, dryMass, forceModels);
                
                case IntegratorEnum.RKN1210
                    odeFH = SecondOrderODE.getOdeFunctionHandle(simDriver, eventInitStateLogEntry, dryMass, forceModels);
                
                otherwise
                    error('Unknown integrator in IntegratorEnum!');
            end
        end
        
        function odeEventsFH = getOdeEventsFunctionHandle(obj, simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses)
            switch obj
                case {IntegratorEnum.ODE45, ...
                      IntegratorEnum.ODE113, ...
                      IntegratorEnum.ODE23, ...
                      IntegratorEnum.ODE15s, ...
                      IntegratorEnum.ODE23s, ...
                      IntegratorEnum.DOP853}
                    odeEventsFH = FirstOrderODE.getOdeEventsFunctionHandle(simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
                
                case IntegratorEnum.RKN1210
                    odeEventsFH = SecondOrderODE.getOdeEventsFunctionHandle(simDriver, eventInitStateLogEntry, eventTermCondFuncHandle, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
                
                otherwise
                    error('Unknown integrator in IntegratorEnum!');
            end
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(obj, tStartPropTime, maxPropTime)
            switch obj
                case {IntegratorEnum.ODE45, ...
                      IntegratorEnum.ODE113, ...
                      IntegratorEnum.ODE23, ...
                      IntegratorEnum.ODE15s, ...
                      IntegratorEnum.ODE23s, ...
                      IntegratorEnum.DOP853}
                    odeOutputFH = FirstOrderODE.getOdeOutputFunctionHandle(tStartPropTime, maxPropTime);
                
                case IntegratorEnum.RKN1210
                    odeOutputFH = SecondOrderODE.getOdeOutputFunctionHandle(tStartPropTime, maxPropTime);
                
                otherwise
                    error('Unknown integrator in IntegratorEnum!');
            end
        end
        
        function [t,y,te,ye,ie] = callIntegrator(obj, odefun, tspan, options, eventInitStateLogEntry)
            switch obj
                case {IntegratorEnum.ODE45, ...
                      IntegratorEnum.ODE113, ...
                      IntegratorEnum.ODE23, ...
                      IntegratorEnum.ODE15s, ...
                      IntegratorEnum.ODE23s, ...
                      IntegratorEnum.DOP853}
                    [~,y0, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
                    [t,y,te,ye,ie] = obj.functionHandle(odefun, tspan, y0, options);
                
                case IntegratorEnum.RKN1210
                    [~,y0,yp0] = eventInitStateLogEntry.getSecondOrderIntegratorStateRepresentation();
                    [t, y, yp, te, ye, ype, ie, ~, ~] = obj.functionHandle(odefun, tspan, y0, yp0, options);
                    
                    [~,y0, tankStateInds] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
                    initTankStates = y0(tankStateInds);
                    yTankStates = repmat(initTankStates,[size(y,1),1]);
                    yeTankStates = repmat(initTankStates, [size(ye,1),1]);
                    
                    y = [y,yp,yTankStates];
                    ye = [ye,ype,yeTankStates];
                otherwise
                    error('Unknown integrator in IntegratorEnum!');
            end
        end
        
        function [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry)
            switch obj
                case {IntegratorEnum.ODE45, ...
                      IntegratorEnum.ODE113, ...
                      IntegratorEnum.ODE23, ...
                      IntegratorEnum.ODE15s, ...
                      IntegratorEnum.ODE23s, ...
                      IntegratorEnum.DOP853}
                    [t,y, ~] = stateLogEntry.getFirstOrderIntegratorStateRepresentation();
                    [value,isterminal,direction,causes] = odeEventsFun(t,y);
                    
                case IntegratorEnum.RKN1210
                    [t,y,yp] = stateLogEntry.getSecondOrderIntegratorStateRepresentation();
                    [value,isterminal,direction,causes] = odeEventsFun(t,y,yp);

                otherwise
                    error('Unknown integrator in IntegratorEnum!');
            end
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
    end
end