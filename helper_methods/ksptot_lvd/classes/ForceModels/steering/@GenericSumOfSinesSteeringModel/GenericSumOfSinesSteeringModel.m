classdef GenericSumOfSinesSteeringModel < AbstractSteeringModel
    %GenericSumOfSinesSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gammaAngleModel(1,1) SumOfSinesModel = SumOfSinesModel(0);
        betaAngleModel(1,1) SumOfSinesModel = SumOfSinesModel(0);
        alphaAngleModel(1,1) SumOfSinesModel = SumOfSinesModel(0);
        
        gammaContinuity(1,1) logical = false;
        betaContinuity(1,1) logical = false;
        alphaContinuity(1,1) logical = false;
        
        refFrame AbstractReferenceFrame
        controlFrame AbstractControlFrame
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            gammaAng = obj.gammaAngleModel.getValueAtTime(ut);
            betaAng = obj.betaAngleModel.getValueAtTime(ut);
            alphaAng = obj.alphaAngleModel.getValueAtTime(ut);
            
%             elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
%             if(not(isempty(obj.refFrame.getOriginBody())))
%                 elemSet = elemSet.convertToFrame(obj.refFrame);
%             end
            
            dcm = real(obj.controlFrame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, obj.refFrame));
        end

        function [angleModel, continuity] = getAngleNModel(obj, n)
            angleModel = SumOfSinesModel.empty(1,0);
            
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
                
%                 if(not(isempty(obj.refFrame.getOriginBody())))
%                     elemSet = elemSet.convertToFrame(obj.refFrame);
%                 end
                
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
            newSteeringModel = GenericSumOfSinesSteeringModel(obj.gammaAngleModel.deepCopy(), obj.betaAngleModel.deepCopy(), obj.alphaAngleModel.deepCopy());
            
            newSteeringModel.gammaContinuity = obj.gammaContinuity;
            newSteeringModel.betaContinuity = obj.betaContinuity;
            newSteeringModel.alphaContinuity = obj.alphaContinuity;
            newSteeringModel.refFrame = obj.refFrame;
            newSteeringModel.controlFrame = obj.controlFrame;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetGenericSumOfSinesSteeringModelActionOptimVar(obj);
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
            enum = SteerModelTypeEnum.SumOfSinesAngles;
        end
    end
    
    methods(Access=private)
        function obj = GenericSumOfSinesSteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel)
            obj.gammaAngleModel = gammaAngleModel;
            obj.betaAngleModel = betaAngleModel;
            obj.alphaAngleModel = alphaAngleModel;
            
            obj.controlFrame = InertialControlFrame();
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            gammaAngleModel = SumOfSinesModel(0);
            betaAngleModel = SumOfSinesModel(0);
            alphaAngleModel = SumOfSinesModel(0);
            
            model = GenericSumOfSinesSteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.GenericSumOfSines.nameStr;
        end
    end
end