classdef GenericPolySteeringModel < AbstractAnglePolySteeringModel
    %GenericPolySteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gammaAngleModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        betaAngleModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        alphaAngleModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        
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
            angleModel = PolynominalModel.empty(1,0);
            
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
            t0 = obj.alphaAngleModel.t0;
        end
        
        function setT0(obj, newT0)
            obj.gammaAngleModel.t0 = newT0;
            obj.betaAngleModel.t0 = newT0;
            obj.alphaAngleModel.t0 = newT0;
        end
        
        function setConstTerms(obj, gammaConst, betaConst, alphaConst)
            obj.gammaAngleModel.constTerm = gammaConst;
            obj.betaAngleModel.constTerm = betaConst;
            obj.alphaAngleModel.constTerm = alphaConst;
        end
        
        function setLinearTerms(obj, gammaRate, betaRate, alphaRate)
            obj.gammaAngleModel.linearTerm = gammaRate;
            obj.betaAngleModel.linearTerm = betaRate;
            obj.alphaAngleModel.linearTerm = alphaRate;
        end
        
        function setAccelTerms(obj, gammaRateRate, betaRateRate, alphaRateRate)
            obj.gammaAngleModel.accelTerm = gammaRateRate;
            obj.betaAngleModel.accelTerm = betaRateRate;
            obj.alphaAngleModel.accelTerm = alphaRateRate;
        end
        
        function setTimeOffsets(obj, timeOffset)
            obj.gammaAngleModel.tOffset = timeOffset;
            obj.betaAngleModel.tOffset = timeOffset;
            obj.alphaAngleModel.tOffset = timeOffset;
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
                    obj.gammaAngleModel.constTerm = gammaAngle;
                end
                
                if(obj.betaContinuity)
                    obj.betaAngleModel.constTerm = betaAngle;
                end
                
                if(obj.alphaContinuity)
                    obj.alphaAngleModel.constTerm = alphaAngle;
                end
            end
        end
        
        function setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)
            t0 = stateLogEntry.time;
            obj.setT0(t0);
            
            obj.gammaAngleModel.tOffset = obj.gammaAngleModel.tOffset + tOffsetDelta;
            obj.betaAngleModel.tOffset = obj.betaAngleModel.tOffset + tOffsetDelta;
            obj.alphaAngleModel.tOffset = obj.alphaAngleModel.tOffset + tOffsetDelta;
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
            angleNames = obj.controlFrame.getControlFrameEnum().angleNames;
            angle1Name = angleNames{1};
            angle2Name = angleNames{2};
            angle3Name = angleNames{3};
        end
        
        function newSteeringModel = deepCopy(obj)
            newSteeringModel = GenericPolySteeringModel(obj.gammaAngleModel.deepCopy(), obj.betaAngleModel.deepCopy(), obj.alphaAngleModel.deepCopy());
            newSteeringModel.gammaContinuity = obj.gammaContinuity;
            newSteeringModel.betaContinuity = obj.betaContinuity;
            newSteeringModel.alphaContinuity = obj.alphaContinuity;
            newSteeringModel.refFrame = obj.refFrame;
            newSteeringModel.controlFrame = obj.controlFrame;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetGenericPolySteeringModelActionOptimVar(obj);
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
        
        function tf = requiresReInitAfterSoIChange(obj)
            tf = false;
        end

        function [addActionTf, steeringModel] = openEditSteeringModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditActionSetSteeringModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            steeringModel = output.output{2};
        end
    end
    
    methods(Access=private)
        function obj = GenericPolySteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel)
            obj.gammaAngleModel = gammaAngleModel;
            obj.betaAngleModel = betaAngleModel;
            obj.alphaAngleModel = alphaAngleModel;
            
            obj.controlFrame = NedControlFrame();
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            gammaAngleModel = PolynominalModel(0,0,0,0);
            betaAngleModel = PolynominalModel(0,0,0,0);
            alphaAngleModel = PolynominalModel(0,0,0,0);
            
            model = GenericPolySteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.GenericPoly.nameStr;
        end
    end
end