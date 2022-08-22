classdef FixedVectorInFrame < AbstractGeometricVector
    %FixedVectorInFrame Provides the vector from point 1 to point 2.
    %   Detailed explanation goes here
    
    properties
        vect(3,1) double 
        frame AbstractReferenceFrame
        
        name(1,:) char
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
        
        lvdData LvdData
    end
    
    methods        
        function obj = FixedVectorInFrame(vect, frame, name, lvdData) 
            obj.vect = vect;
            obj.frame = frame;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            [~, ~, ~, rotMatToInertial12] = obj.frame.getOffsetsWrtInertialOrigin(time, vehElemSet);
            [~, ~, ~, rotMatToInertial32] = inFrame.getOffsetsWrtInertialOrigin(time, vehElemSet);
            
            rotMat = pagemtimes(permute(rotMatToInertial32, [2 1 3]), rotMatToInertial12);
            vect = squeeze(pagemtimes(rotMat, repmat(obj.vect, [1 1 length(time)])));
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Fixed in Frame: %s)', obj.getName(), obj.frame.getNameStr());
        end
        
        function useTf = openEditDialog(obj)
%             useTf = lvd_EditFixedInFrameVectorGUI(obj, obj.lvdData);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditFixedInFrameVectorGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = false;
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            origin = [0;0;0];
        end
        
        function tf = usesGroundObj(obj, groundObj)
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
            tf = lvdData.usesGeometricVector(obj);
        end
        
        function vect = getRVect(obj)
            vect = obj.vect;
        end
        
        function setRVect(obj, vect)
            obj.vect = vect;
        end
        
        function frame = getFrame(obj)
            frame = obj.frame;
        end
    end
end