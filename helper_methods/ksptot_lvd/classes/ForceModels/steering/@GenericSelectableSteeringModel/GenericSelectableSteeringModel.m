classdef GenericSelectableSteeringModel < AbstractSteeringModel
    %GenericSelectableSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
        %Stored Models
        % Gamma
        gammaSelModel(1,1) SteerMathModelTypeEnum = SteerMathModelTypeEnum.GenericPoly
        gammaAngleSumPoly(1,1) SumOfPolyTermsModel = SumOfPolyTermsModel(0);
        gammaAngleSumSines(1,1) SumOfSinesModel = SumOfSinesModel(0);
        gammaAngleLinearTan(1,1) LinearTangentSelectableModel = LinearTangentSelectableModel(0,0,0,0,0);
        gammaAngleFitNet(1,1) FitNetModel = FitNetModel(5);
        
        % Beta
        betaSelModel(1,1) SteerMathModelTypeEnum = SteerMathModelTypeEnum.GenericPoly
        betaAngleSumPoly(1,1) SumOfPolyTermsModel = SumOfPolyTermsModel(0);
        betaAngleSumSines(1,1) SumOfSinesModel = SumOfSinesModel(0);
        betaAngleLinearTan(1,1) LinearTangentSelectableModel = LinearTangentSelectableModel(0,0,0,0,0);
        betaAngleFitNet(1,1) FitNetModel = FitNetModel(5);
        
        % Alpha
        alphaSelModel(1,1) SteerMathModelTypeEnum = SteerMathModelTypeEnum.GenericPoly
        alphaAngleSumPoly(1,1) SumOfPolyTermsModel = SumOfPolyTermsModel(0);
        alphaAngleSumSines(1,1) SumOfSinesModel = SumOfSinesModel(0);
        alphaAngleLinearTan(1,1) LinearTangentSelectableModel = LinearTangentSelectableModel(0,0,0,0,0);
        alphaAngleFitNet(1,1) FitNetModel = FitNetModel(5);

        %Continuity
        gammaContinuity(1,1) logical = false;
        betaContinuity(1,1) logical = false;
        alphaContinuity(1,1) logical = false;
        
        %Frames
        refFrame AbstractReferenceFrame
        controlFrame AbstractControlFrame
    end
    
    properties(Dependent)
        gammaAngleModel(1,1) AbstractSteeringMathModel
        betaAngleModel(1,1) AbstractSteeringMathModel
        alphaAngleModel(1,1) AbstractSteeringMathModel
    end
    
    methods       
        function model = get.gammaAngleModel(obj)
            switch obj.gammaSelModel
                case SteerMathModelTypeEnum.GenericPoly
                    model = obj.gammaAngleSumPoly;
                    
                case SteerMathModelTypeEnum.SumOfSines
                    model = obj.gammaAngleSumSines;
                    
                case SteerMathModelTypeEnum.LinearTangent
                    model = obj.gammaAngleLinearTan;
                    
                case SteerMathModelTypeEnum.FitNet
                    model = obj.gammaAngleFitNet;
                    
                otherwise
                    error('Unknown Gamma angle steering model');
            end
        end
        
        function model = get.betaAngleModel(obj)
            switch obj.betaSelModel
                case SteerMathModelTypeEnum.GenericPoly
                    model = obj.betaAngleSumPoly;
                    
                case SteerMathModelTypeEnum.SumOfSines
                    model = obj.betaAngleSumSines;
                    
                case SteerMathModelTypeEnum.LinearTangent
                    model = obj.betaAngleLinearTan;
                    
                case SteerMathModelTypeEnum.FitNet
                    model = obj.betaAngleFitNet;
                    
                otherwise
                    error('Unknown Beta angle steering model');
            end
        end
        
        function model = get.alphaAngleModel(obj)
            switch obj.alphaSelModel
                case SteerMathModelTypeEnum.GenericPoly
                    model = obj.alphaAngleSumPoly;
                    
                case SteerMathModelTypeEnum.SumOfSines
                    model = obj.alphaAngleSumSines;
                    
                case SteerMathModelTypeEnum.LinearTangent
                    model = obj.alphaAngleLinearTan;
                    
                case SteerMathModelTypeEnum.FitNet
                    model = obj.alphaAngleFitNet;
                    
                otherwise
                    error('Unknown Alpha angle steering model');
            end
        end
        
        function set.gammaAngleModel(obj, newModel)
            switch class(newModel)
                case 'SumOfPolyTermsModel'
                    obj.gammaAngleSumPoly = newModel;
                    
                case 'SumOfSinesModel'
                    obj.gammaAngleSumSines = newModel;
                    
                case 'LinearTangentSelectableModel'
                    obj.gammaAngleLinearTan = newModel;
                    
                case 'FitNetModel'
                    obj.gammaAngleFitNet = newModel;
                    
                otherwise
                    error('Unknown Gamma angle steering model class');
            end
        end
        
        function set.betaAngleModel(obj, newModel)
            switch class(newModel)
                case 'SumOfPolyTermsModel'
                    obj.betaAngleSumPoly = newModel;
                    
                case 'SumOfSinesModel'
                    obj.betaAngleSumSines = newModel;
                    
                case 'LinearTangentSelectableModel'
                    obj.betaAngleLinearTan = newModel;
                    
                case 'FitNetModel'
                    obj.betaAngleFitNet = newModel;
                    
                otherwise
                    error('Unknown Beta angle steering model class');
            end
        end
        
        function set.alphaAngleModel(obj, newModel)
            switch class(newModel)
                case 'SumOfPolyTermsModel'
                    obj.alphaAngleSumPoly = newModel;
                    
                case 'SumOfSinesModel'
                    obj.alphaAngleSumSines = newModel;
                    
                case 'LinearTangentSelectableModel'
                    obj.alphaAngleLinearTan = newModel;
                    
                case 'FitNetModel'
                    obj.alphaAngleFitNet = newModel;
                    
                otherwise
                    error('Unknown Alpha angle steering model class');
            end
        end
        
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            gammaAng = obj.gammaAngleModel.getValueAtTime(ut);
            betaAng = obj.betaAngleModel.getValueAtTime(ut);
            alphaAng = obj.alphaAngleModel.getValueAtTime(ut);
                        
            dcm = real(obj.controlFrame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, obj.refFrame));
        end

        function [angleModel, continuity] = getAngleNModel(obj, n)
            angleModel = AbstractSteeringMathModel.empty(1,0);
            
            switch n
                case 1
                    angleModel = obj.gammaAngleModel;
                    continuity = obj.gammaContinuity;
                case 2
                    angleModel = obj.betaAngleModel;
                    continuity = obj.betaContinuity;
                case 3
                    angleModel = obj.alphaAngleModel;
                    continuity = obj.alphaContinuity;
            end
        end
        
        function t0 = getT0(obj)
            t0 = obj.alphaAngleModel.getT0();
        end
        
        function setT0(obj, newT0)
            obj.gammaAngleModel.setT0(newT0);
            obj.betaAngleModel.setT0(newT0);
            obj.alphaAngleModel.setT0(newT0);
        end
        
        function setTimeOffsets(obj, timeOffset)
            obj.gammaAngleModel.setTimeOffset(timeOffset);
            obj.betaAngleModel.setTimeOffset(timeOffset);
            obj.alphaAngleModel.setTimeOffset(timeOffset);
        end
        
        function [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(obj)
            angle1Cont = obj.gammaContinuity;
            angle2Cont = obj.betaContinuity;
            angle3Cont = obj.alphaContinuity;
        end
        
        function setContinuityTerms(obj, angle1Cont, angle2Cont, angle3Cont)
            obj.gammaContinuity = angle1Cont;
            obj.betaContinuity = angle2Cont;
            obj.alphaContinuity = angle3Cont;
        end
        
        function setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)
            if(obj.gammaContinuity || obj.betaContinuity || obj.alphaContinuity)
                elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
                                
                [gammaAngle, betaAngle, alphaAngle] = obj.controlFrame.getAnglesFromInertialBodyAxes(LaunchVehicleAttitudeState(dcm), elemSet.time, elemSet.rVect(:), elemSet.vVect(:), elemSet.frame.getOriginBody(), obj.refFrame);
             
                if(obj.gammaContinuity)
                    obj.gammaAngleModel.setConstValueForContinuity(gammaAngle);
                end
                
                if(obj.betaContinuity)
                    obj.betaAngleModel.setConstValueForContinuity(betaAngle);
                end
                
                if(obj.alphaContinuity)
                    obj.alphaAngleModel.setConstValueForContinuity(alphaAngle);
                end
            end
        end
        
        function setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)
            t0 = stateLogEntry.time;
            obj.setT0(t0);
            
            obj.gammaAngleModel.setTimeOffset(obj.gammaAngleModel.getTimeOffset() + tOffsetDelta);
            obj.betaAngleModel.setTimeOffset(obj.betaAngleModel.getTimeOffset() + tOffsetDelta);
            obj.alphaAngleModel.setTimeOffset(obj.alphaAngleModel.getTimeOffset() + tOffsetDelta);
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
            angleNames = obj.controlFrame.getControlFrameEnum().angleNames;
            angle1Name = angleNames{1};
            angle2Name = angleNames{2};
            angle3Name = angleNames{3};
        end
        
        function newSteeringModel = deepCopy(obj)
            newSteeringModel = GenericSelectableSteeringModel(obj.gammaAngleModel.deepCopy(), obj.betaAngleModel.deepCopy(), obj.alphaAngleModel.deepCopy());
            
            newSteeringModel.gammaContinuity = obj.gammaContinuity;
            newSteeringModel.betaContinuity = obj.betaContinuity;
            newSteeringModel.alphaContinuity = obj.alphaContinuity;
            
            newSteeringModel.refFrame = obj.refFrame;
            newSteeringModel.controlFrame = obj.controlFrame;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetGenericSelectableSteeringModelActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
        
        function tf = usesRefFrame(~)
            tf = true;
        end
        
        function refFrame = getRefFrame(obj)
            refFrame = obj.refFrame;
        end
        
        function setRefFrame(obj, refFrame)
            obj.refFrame = refFrame;
        end
        
        function tf = usesControlFrame(~)
            tf = true;
        end
        
        function cFrame = getControlFrame(obj)
            cFrame = obj.controlFrame;
        end
        
        function setControlFrame(obj, cFrame)
            obj.controlFrame = cFrame;
        end
        
        function tf = requiresReInitAfterSoIChange(~)
            tf = false;
        end
        
        function enum = getSteeringModelTypeEnum(~)
            enum = SteerModelTypeEnum.SelectableModelAngles;
        end

        function [addActionTf, steeringModel] = openEditSteeringModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditActionSetSelectableSteeringModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            steeringModel = output.output{2};
        end
    end
    
    methods(Access=private)
        function obj = GenericSelectableSteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel)
            obj.gammaAngleModel = gammaAngleModel;
            obj.betaAngleModel = betaAngleModel;
            obj.alphaAngleModel = alphaAngleModel;
            
            obj.controlFrame = InertialControlFrame();
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            gammaAngleModel = SumOfPolyTermsModel(0);
            betaAngleModel = SumOfPolyTermsModel(0);
            alphaAngleModel = SumOfPolyTermsModel(0);
            
            model = GenericSelectableSteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.GenericSelectable.nameStr;
        end
    end
end