classdef LvdDataPoint < AbstractGeometricPoint
    %LvdDataPoint Summary of this class goes here
    %   Detailed explanation goes here

    properties
        allTimes cell
        allStates cell
    end

    methods
        function obj = LvdDataPoint(inputLvdData, lvdData)
            arguments
                inputLvdData(1,1) LvdData
                lvdData(1,1) LvdData
            end

            stateLog = inputLvdData.script.executeScript(false, inputLvdData.script.getEventForInd(1), true, false, false, false);
            
            obj.allTimes = {};
            obj.allStates = {};
            for(i=1:inputLvdData.script.getTotalNumOfEvents()) %#ok<*NO4LP> 
                evt = inputLvdData.script.getEventForInd(i);
                entries = stateLog.getAllStateLogEntriesForEvent(evt);

                for(j=1:length(entries))
                    entry = entries(j);
                    maEntry = entry.getMAFormattedStateLogMatrix(true);

                    time = maEntry(1);
                    rVect = maEntry(2:4)';
                    vVect = maEntry(5:7)';   
                    bodyInfo = lvdData.celBodyData.getBodyInfoById(maEntry(8));

                    ce = CartesianElementSet(time, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());

                    times(j) = time; %#ok<AGROW> 
                    states(j) = ce; %#ok<AGROW> 
                end

                obj.allTimes{i} = times;
                obj.allStates{i} = states;
            end
        end

        function cartElems = getPositionAtTime(obj, inputTimes, ~, inFrame)
            for(i=1:length(inputTimes))
                time = inputTimes(i);

                cartElem = CartesianElementSet.empty(1,0);
                for(j=1:length(obj.allTimes))
                    times = obj.allTimes{j};
                    states = obj.allStates{j};
    
                    if(time >= min(times) && time <= max(times))
                        cartElem = obj.getCartElemForTime(time, times, states, inFrame);

                        break;
                    end
                end

                if(isempty(cartElem))
                    for(j=1:length(obj.allTimes))
                        times = obj.allTimes{j};
                        distToLb = abs(time - min(times));
                        distToUb = abs(time - max(times));
                        dists(j) = min([distToLb, distToUb]); %#ok<AGROW> 
                    end

                    [~, I] = min(dists);

                    times = obj.allTimes{I};
                    states = obj.allStates{I};

                    distToLb = abs(time - min(times));
                    distToUb = abs(time - max(times));
                    if(distToLb < distToUb) 
                        timeToUse = min(times);
                    else
                        timeToUse = max(times);
                    end

                    cartElem = obj.getCartElemForTime(timeToUse, times, states, inFrame);
                end

                cartElems(i) = cartElem; %#ok<AGROW> 
            end
        end

        function cartElem = getCartElemForTime(obj, time, times, states, inFrame)
            [times,ia,~] = unique(times);

            states = states(ia);
            states = convertToFrame(states, inFrame, true);

            rVects = [states.rVect];
            vVects = [states.vVect];
            rvVects = [rVects; vVects]';

            gi = griddedInterpolant(times,rvVects, "makima", "nearest");
            rvVect = gi(time);
            rvVect = rvVect';
            
            rVectInterp = rvVect(1:3,:);
            vVectInterp = rvVect(4:6,:);

            cartElem = CartesianElementSet(time, rVectInterp, vVectInterp, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s', obj.getName());
        end
        
        function useTf = openEditDialog(obj, ~)            
%             output = AppDesignerGUIOutput({false});
%             lvd_EditCelestialBodyPointGUI_App(obj, output);
%             useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = false;
        end
        
        function tf = canBePlotted(obj)
            tf = true;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.bodyInfo;
        end
        
        function tf = usesGroundObj(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricPoint(obj);
        end
    end
end