classdef GenericLinearTangentSteeringModel < AbstractSteeringModel
    %GenericLinearTangentSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gammaAngleModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        betaAngleModel(1,1) LinearTangentModel = LinearTangentModel(0,0,0,0,0);
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
            
            elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
            elemSet = elemSet.convertToFrame(obj.refFrame);
            
            dcm = obj.controlFrame.computeDcmToInertialFrame(elemSet.time, elemSet.rVect, elemSet.vVect, elemSet.frame.getOriginBody(), gammaAng, betaAng, alphaAng, obj.refFrame);
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
        
        function setT0(obj, newT0)
            obj.gammaAngleModel.t0 = newT0;
            obj.betaAngleModel.t0 = newT0;
            obj.alphaAngleModel.t0 = newT0;
        end
        
        function setConstTerms(obj, gammaConst, alphaConst)
            obj.gammaAngleModel.constTerm = gammaConst;
            obj.alphaAngleModel.constTerm = alphaConst;
        end
        
        function setLinearTerms(obj, gammaRate, alphaRate)
            obj.gammaAngleModel.linearTerm = gammaRate;
            obj.alphaAngleModel.linearTerm = alphaRate;
        end
        
        function setAccelTerms(obj, gammaRateRate, alphaRateRate)
            obj.gammaAngleModel.accelTerm = gammaRateRate;
            obj.alphaAngleModel.accelTerm = alphaRateRate;
        end
        
        function setLinearTangentTerms(obj, a, a_dot, b, b_dot)
            obj.betaAngleModel.a = a;
            obj.betaAngleModel.a_dot = a_dot;
            obj.betaAngleModel.b = b;
            obj.betaAngleModel.b_dot = b_dot;
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
                elemSet = elemSet.convertToFrame(obj.refFrame);
                
                [gammaAngle, betaAngle, alphaAngle] = obj.controlFrame.getAnglesFromInertialBodyAxes(dcm, elemSet.time, elemSet.rVect(:), elemSet.vVect(:), elemSet.frame.getOriginBody(), obj.refFrame);
             
                if(obj.gammaContinuity)
                    obj.gammaAngleModel.constTerm = gammaAngle;
                end
                
                if(obj.betaContinuity)
                    obj.betaAngleModel.setBForContinuity(betaAngle);
                end
                
                if(obj.alphaContinuity)
                    obj.alphaAngleModel.constTerm = alphaAngle;
                end
            end
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(~)
            angle1Name = 'Gamma';
            angle2Name = 'Beta';
            angle3Name = 'Alpha';
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
            optVar = SetGenericLinearTangentSteeringModelActionOptimVar(obj);
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
        
        function enum = getSteeringModelTypeEnum(~)
            enum = SteerModelTypeEnum.LinearTangentAngles;
        end
    end
    
    methods(Access=private)
        function obj = GenericLinearTangentSteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel)
            obj.gammaAngleModel = gammaAngleModel;
            obj.betaAngleModel = betaAngleModel;
            obj.alphaAngleModel = alphaAngleModel;
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            gammaAngleModel = PolynominalModel(0,0,0,0);
            betaAngleModel = LinearTangentModel(0,0,0,0,0);
            alphaAngleModel = PolynominalModel(0,0,0,0);
            
            model = GenericLinearTangentSteeringModel(gammaAngleModel, betaAngleModel, alphaAngleModel);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.GenericLinTan.nameStr;
        end
    end
end