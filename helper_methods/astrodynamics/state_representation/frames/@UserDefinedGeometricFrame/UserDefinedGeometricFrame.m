classdef UserDefinedGeometricFrame < AbstractReferenceFrame
    %UserDefinedGeometricFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        geometricFrame(1,1) AbstractGeometricRefFrame
        lvdData LvdData
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.UserDefined
    end
    
    methods
        function obj = UserDefinedGeometricFrame(geometricFrame, lvdData)
            obj.geometricFrame = geometricFrame;
            obj.lvdData = lvdData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, vehElemSet)
            baseFrame = obj.lvdData.getBaseFrame();
            
            [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = obj.geometricFrame.getRefFrameAtTime(time, vehElemSet,  baseFrame);
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.geometricFrame.origin.getOriginBody();
        end
        
        function setOriginBody(~, ~)
            %do nothing, I think
        end
        
        function nameStr = getNameStr(obj)
            nameStr = obj.geometricFrame.getName();
        end
        
        function newFrame = editFrameDialogUI(obj, context)
            numFrames = obj.lvdData.geometry.refFrames.getNumRefFrames();
            
            if(numFrames >= 1)
                [listBoxStr, frames] = obj.lvdData.geometry.refFrames.getListboxStr();
                
                if(context == EditReferenceFrameContextEnum.ForState || ...
                   context == EditReferenceFrameContextEnum.ForView)    %can't have vehicle dependent frames for states
                    goodInds = [];
                    for(i=1:length(frames))
                        if(frames(i).isVehDependent() == false)
                            goodInds(end+1) = i; %#ok<AGROW>
                        end
                    end
                    
                    listBoxStr = listBoxStr(goodInds);
                    frames = frames(goodInds);
                end
                
                curSelInd = find(ismember(frames, obj.geometricFrame));
                
                out = AppDesignerGUIOutput();
                listdlgARH_App('ListString', listBoxStr, ...
                            'SelectionMode', 'single', ...
                            'ListSize', [300 300], ...
                            'InitialValue', curSelInd, ...
                            'Name', 'Select Geometric Reference Frame', ...
                            'PromptString', 'Select the desired reference frame:', ...
                            'out',out);
                Selection = out.output{1};
                ok = out.output{2};
                                        
                if(ok == 1)
                    newFrame = UserDefinedGeometricFrame(frames(Selection), obj.lvdData);
                else
                    newFrame = obj;
                end
            else
                errordlg('There are no user defined geometric frames available to select from.');
            end
        end
    end
end