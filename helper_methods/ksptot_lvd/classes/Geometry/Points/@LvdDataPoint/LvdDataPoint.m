classdef LvdDataPoint < AbstractGeometricPoint
    %LvdDataPoint Summary of this class goes here
    %   Detailed explanation goes here

    properties
        allTimes cell = {};
        allRVVect cell = {};
        allFrames(1,:) AbstractReferenceFrame
        allGIs cell = {};

        name(1,:) char = 'New Point';

        inputLvdData LvdData
        lvdData LvdData

        %marker
        markerColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.RightTriangle;
        
        %track line
        plotTrkLine(1,1) logical = true;
        trkLineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        trkLineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end

    methods
        function obj = LvdDataPoint(inputLvdData, lvdData, name)
            arguments
                inputLvdData(1,1) LvdData %the lvd data that contains the trajectory to be loaded
                lvdData(1,1) LvdData %the lvd data for the current case/scenario/mission
                name(1,:) char %the name of the point
            end

            obj.name = name;
            obj.lvdData = lvdData;

            obj.loadLvdData(inputLvdData, lvdData);
        end

        function tf = hasValidLvdData(obj)
            tf = true;

            if(isempty(obj.inputLvdData) || ...
               obj.inputLvdData == obj.lvdData)
                tf = false;

                return;
            end
        end

        function cartElems = getPositionAtTime(obj, inputTimes, ~, inFrame)
            cartElems = obj.getCartElemForTime(inputTimes, inFrame);
        end

        function loadLvdData(obj, inputLvdData, lvdData)
            obj.inputLvdData = inputLvdData;

            stateLog = inputLvdData.script.executeScript(false, inputLvdData.script.getEventForInd(1), true, false, false, false);
            
            obj.allTimes = {};
            obj.allRVVect = {};
            obj.allFrames = AbstractReferenceFrame.empty(1,0);
            obj.allGIs = {};

            for(i=1:inputLvdData.script.getTotalNumOfEvents()) %#ok<*NO4LP> 
                evt = inputLvdData.script.getEventForInd(i);
                entries = stateLog.getAllStateLogEntriesForEvent(evt);

                [~,ia,~] = unique([entries.time], 'sorted');
                entries = entries(ia);

                if(numel(entries) > 2)
                    useFrame = entries(1).centralBody.getBodyCenteredInertialFrame();

                    times = [];
                    rvVects = [];
                    for(j=1:length(entries))
                        entry = entries(j);
                        maEntry = entry.getMAFormattedStateLogMatrix(true);
    
                        time = maEntry(1);
                        rVect = maEntry(2:4)';
                        vVect = maEntry(5:7)';   
                        
                        bodyInfo = lvdData.celBodyData.getBodyInfoById(maEntry(8));
                        frame = bodyInfo.getBodyCenteredInertialFrame();
    
                        ce = CartesianElementSet(time, rVect(:), vVect(:), frame);
                        ce = ce.convertToFrame(useFrame, true);
    
                        rvVect = [ce.rVect; ce.vVect];

                        times(j) = time; %#ok<AGROW> 
                        rvVects(:,j) = rvVect; %#ok<AGROW> 
                    end

                    obj.allTimes{end+1} = times;
                    obj.allRVVect{end+1} = rvVects;
                    obj.allFrames(end+1) = useFrame;
                    obj.allGIs{end+1} = griddedInterpolant(times,[rvVects;times]', "makima", "nearest");
                end
            end
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (LVD Trajectory)', obj.getName());
        end
        
        function useTf = openEditDialog(obj, ~)            
            output = AppDesignerGUIOutput({false});
            lvd_EditLvdTrajectoryPointGUI_App(obj, output, obj.lvdData);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj) %#ok<MANU> 
            tf = false;
        end
        
        function tf = canBePlotted(obj) %#ok<MANU> 
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

    methods(Access=private)
        function cartElem = getCartElemForTime(obj, qTimes, inFrame)
            fillerCe = CartesianElementSet(0, [0;0;0], [0;0;0], inFrame);
            cartElem = repmat(fillerCe, [1, numel(qTimes)]);

            for(i=1:length(obj.allTimes))
                times = obj.allTimes{i};
                minTime = min(times);
                maxTime = max(times);

                bool = qTimes >= minTime & qTimes <= maxTime;
                if(any(bool))
                    subQTimes = qTimes(bool);
                    gi = obj.allGIs{i};
                    frame = obj.allFrames(i);

                    rvVects = gi(subQTimes)';
                    subCe = CartesianElementSet(subQTimes, rvVects(1:3,:), rvVects(4:6,:), frame);
                    subCe = convertToFrame(subCe, inFrame, true);
                    cartElem(bool) = subCe;
                end
            end

            bool = cartElem == fillerCe;
            if(any(bool))
                outQTimes = qTimes(bool);

                for(i=1:length(obj.allTimes))
                    times = obj.allTimes{i};
                    minTime = min(times);
                    maxTime = max(times);

                    distToLb = abs(outQTimes - minTime);
                    distToUb = abs(outQTimes - maxTime);
                    distToBnd(:,i) = min([distToLb(:), distToUb(:)], [], 2); %#ok<AGROW> 
                end

                boolInds = find(bool);

                [~,I] = min(distToBnd, [], 2);
                for(i=1:length(I))
                    qTime = outQTimes(i);
                    Ii = I(i);
                    
                    gi = obj.allGIs{Ii};
                    frame = obj.allFrames(Ii);

                    rvVects = gi(qTime)';
                    rVects = rvVects(1:3,:);
                    vVects = rvVects(4:6,:);
                    nearestTimes = rvVects(7,:);
                    subCe = CartesianElementSet(nearestTimes, rVects, vVects, frame);
                    subCe = convertToFrame(subCe, inFrame, true);
                    cartElem(boolInds(i)) = subCe;
                end
            end
        end
    end
end