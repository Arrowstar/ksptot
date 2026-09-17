classdef(Abstract) AbstractPropagator < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractPropagator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [t,y,te,ye,ie] = propagate(obj, integrator, tspan, eventInitStateLogEntry, ...
                                    eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, ...
                                    tStartPropTime, maxPropTime, minAltIsTerrainRelative)
                                
        odeFH = getOdeFunctionHandle(obj, eventInitStateLogEntry)
        
        odeEventsFH = getOdeEventsFunctionHandle(~, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, minAltIsTerrainRelative)
        
        odeOutputFH = getOdeOutputFunctionHandle(~, tStartPropTime, maxPropTime)
        
        [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry);
        
        openOptionsDialog(obj);

        tf = canProduceThrust(obj);
    end
    
    methods(Static)
        function [value,isterminal,direction, causes] = odeEvents(t,y, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, minAltIsTerrainRelative)
            %odeEvents Builds the integrator's event vector.
            %
            %   evtTermCond may be a single function handle (one termination
            %   condition, the historical form) or a cell array of handles
            %   (A1: several conditions on one event).  termCondDir is scalar
            %   or an array matched to it.
            %
            %   minAltIsTerrainRelative (optional, default false) measures the
            %   minimum-altitude floor against the central body's heightmap
            %   instead of its mean radius (A10).
            if(nargin < 12)
                minAltIsTerrainRelative = false;
            end

            persistent maxSimTimeCause minAltTermCause eventTermCondCause emptyCause
            if(isempty(maxSimTimeCause))
                maxSimTimeCause = MaxEventSimTimeIntTermCause();
                minAltTermCause = MinAltitudeIntTermCause();
                eventTermCondCause = EventTermCondIntTermCause();
                emptyCause = AbstractIntegrationTerminationCause.empty(1,0);
            end

            if(nargout > 3)
                createCausesArr = true;
            else
                createCausesArr = false;
                causes = emptyCause;
            end
            
            y = y(:);

            bodyInfo = eventInitStateLogEntry.centralBody;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();
            if(holdDownEnabled)
                %Need to convert back to ECI if the hold downs are enabled because
                %we are integrating in body fixed in this case
                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t, y(1:3,:)', bodyInfo, y(4:6,:)');
                y = [rVectECI; vVectECI; y(7:end,:)];
            end

            ut = t;
            rVect = y(1:3);
            rVect = rVect(:);
            
            vVect = y(4:6);
            vVect = vVect(:);

            %Max Sim Time Constraint
            simTimeRemaining = maxSimTime - ut;
            value(1) = simTimeRemaining;
            isterminal(1) = 1;
            direction(1) = 0;

            if(createCausesArr)
                causes = maxSimTimeCause;
            end

            %Min Altitude Constraint
            rMag = norm(rVect);
            altitude = rMag - bodyInfo.radius;

            if(minAltIsTerrainRelative)
                %Measure the floor against the terrain under the vehicle
                %rather than the mean radius, the same way
                %HeightAboveTerrainCondition does.
                altitude = altitude - AbstractPropagator.getTerrainHeight(ut, rVect, vVect, bodyInfo);
            end

            value(end+1) = altitude - minAltitude;
            isterminal(end+1) = 1;
            direction(end+1) = -1;

            if(createCausesArr)
                causes(end+1) = minAltTermCause;
            end

            %Non-Sequence Events
            for(i=1:length(nonSeqTermConds)) %#ok<*NO4LP> 
                nonSeqTermCond = nonSeqTermConds{i};

                [value(end+1),isterminal(end+1),direction(end+1)] = nonSeqTermCond(t,y); %#ok<AGROW>
                if(createCausesArr)
                    causes(end+1) = nonSeqTermCauses(i); %#ok<AGROW>
                end
            end

            if(checkForSoITrans)
                %SoI transitions
                [soivalue, soiisterminal, soidirection, soicauses] = getSoITransitionOdeEvents(ut, rVect, vVect, bodyInfo, celBodyData, createCausesArr);

                value = horzcat(value, soivalue);
                isterminal = horzcat(isterminal, soiisterminal);
                direction = horzcat(direction, soidirection);

                if(createCausesArr)
                    causes = horzcat(causes, soicauses);
                end
            end

            %Event Termination Condition(s)
            if(iscell(evtTermCond))
                for(i=1:numel(evtTermCond))
                    [value(end+1),isterminal(end+1),direction(end+1)] = evtTermCond{i}(t,y); %#ok<AGROW>
                    direction(end) = termCondDir(i).direction;

                    if(createCausesArr)
                        causes(end+1) = EventTermCondIntTermCause(i); %#ok<AGROW>
                    end
                end
            else
                [value(end+1),isterminal(end+1),direction(end+1)] = evtTermCond(t,y);
                direction(end) = termCondDir.direction;

                if(createCausesArr)
                    causes(end+1) = eventTermCondCause;
                end
            end
        end

        function terrainHeight = getTerrainHeight(ut, rVect, vVect, bodyInfo)
            %getTerrainHeight Heightmap elevation (km) under the given
            %inertial state, or 0 for a body with no heightmap.
            heightMapGI = bodyInfo.getHeightMap();

            if(isempty(heightMapGI))
                terrainHeight = 0;
                return;
            end

            cartElem = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
            geoElemSet = cartElem.convertToFrame(bodyInfo.getBodyFixedFrame(), true).convertToGeographicElementSet();

            terrainHeight = heightMapGI(angleNegPiToPi(geoElemSet.lat), angleNegPiToPi(geoElemSet.long));
        end
        
        function [ut, rVect, vVect, tankStates, pwrStorageStates] = decomposeIntegratorTandY(t,y, numTankStates, numPwrStorageStates)
            ut = t;
            rVect = y(1:3);
            vVect = y(4:6);

            if(numel(y) > 6)
                tankStates = y(7:6+numTankStates);
                pwrStorageStates = y(6+numTankStates+1 : 6+numTankStates+numPwrStorageStates);
            else
                tankStates = zeros(numTankStates,1);
                pwrStorageStates = zeros(numPwrStorageStates,1);
            end
        end
    end
end