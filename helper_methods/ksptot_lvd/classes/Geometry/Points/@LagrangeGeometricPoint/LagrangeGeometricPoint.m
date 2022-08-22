classdef LagrangeGeometricPoint < AbstractGeometricPoint
    %LagrangeGeometricPoint Summary of this class goes here
    %   Detailed explanation goes here

    properties
        lpoint(1,1) LagrangeGeometricPointEnum = LagrangeGeometricPointEnum.L1;
        frame TwoBodyRotatingFrame

        name(1,:) char
        
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
        function obj = LagrangeGeometricPoint(lpoint, frame, lvdData, name)
            arguments
                lpoint(1,1) LagrangeGeometricPointEnum
                frame(1,1) TwoBodyRotatingFrame
                lvdData(1,1) LvdData
                name(1,:) char
            end

            obj.lpoint = lpoint;
            obj.frame = frame;
            obj.name = name;
            obj.lvdData = lvdData;
        end

        function newCartElem = getPositionAtTime(obj, time, ~, inFrame)
            muStar = obj.frame.getMuStar();
            LPCoord = obj.lpoint.getNormalizedLPointCoordinates(muStar); 

            primBodyInfo = obj.frame.primaryBodyInfo;
            secBodyInfo = obj.frame.secondaryBodyInfo;
            [rVectSunToPrimaryBody, ~] = getPositOfBodyWRTSun(time, primBodyInfo, primBodyInfo.celBodyData);            
            [rVectSunToSecondaryBody, ~] = getPositOfBodyWRTSun(time, secBodyInfo, secBodyInfo.celBodyData);
            
            rPrimaryToSecondary = rVectSunToSecondaryBody - rVectSunToPrimaryBody;
            LU = vecNormARH(rPrimaryToSecondary);

            x1 = -muStar;
            x2 = 1 - muStar;
            switch obj.frame.originPt
                case TwoBodyRotatingFrameOriginEnum.Primary
                    xOffset = x1;

                case TwoBodyRotatingFrameOriginEnum.Secondary
                    xOffset = x2;

                otherwise
                    error('Unknown origin: %s', obj.frame.originPt.name);
            end

            LPCoord(1) = LPCoord(1) + xOffset;
            rVect = LU .* LPCoord;

            for(i=1:length(time)) %#ok<*NO4LP> 
                newCartElem(i) = CartesianElementSet(time(i), rVect(:,i), [0;0;0], obj.frame); %#ok<*AGROW> 
            end

            newCartElem = convertToFrame(newCartElem, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            primBodyName= obj.frame.primaryBodyInfo.name;
            secBodyName = obj.frame.secondaryBodyInfo.name;

            listboxStr = sprintf('%s (%s - %s Lagrange Point: %s)', obj.getName(), primBodyName, secBodyName, obj.lpoint.name);
        end
        
        function useTf = openEditDialog(obj, ~)
            output = AppDesignerGUIOutput({false});
            lvd_EditLagrangePointGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(~)
            tf = false;
        end
        
        function tf = canBePlotted(~)
            tf = true;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.cartElem.frame.getOriginBody();
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


