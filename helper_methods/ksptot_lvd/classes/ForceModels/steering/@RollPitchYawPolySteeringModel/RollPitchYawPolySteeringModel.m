classdef RollPitchYawPolySteeringModel < AbstractAnglePolySteeringModel
    %RollPitchYawSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rollModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        pitchModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        yawModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        
        rollContinuity(1,1) logical = false;
        pitchContinuity(1,1) logical = false;
        yawContinuity(1,1) logical = false;
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            rollAng = obj.rollModel.getValueAtTime(ut);
            pitchAng = obj.pitchModel.getValueAtTime(ut);
            yawAng = obj.yawModel.getValueAtTime(ut);
            
            [~, ~, ~, dcm] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng);
        end

        function [angleModel, continuity] = getAngleNModel(obj, n)
            angleModel = PolynominalModel.empty(1,0);
            
            switch n
                case 1
                    angleModel = obj.rollModel;
                    continuity = obj.rollContinuity;
                case 2
                    angleModel = obj.pitchModel;
                    continuity = obj.pitchContinuity;
                case 3
                    angleModel = obj.yawModel;
                    continuity = obj.yawContinuity;
            end
        end
        
        function setT0(obj, newT0)
            obj.rollModel.t0 = newT0;
            obj.pitchModel.t0 = newT0;
            obj.yawModel.t0 = newT0;
        end
        
        function setConstTerms(obj, rollConst, pitchConst, yawConst)
            obj.rollModel.constTerm = rollConst;
            obj.pitchModel.constTerm = pitchConst;
            obj.yawModel.constTerm = yawConst;
        end
        
        function setLinearTerms(obj, roll, pitch, yaw)
            obj.rollModel.linearTerm = roll;
            obj.pitchModel.linearTerm = pitch;
            obj.yawModel.linearTerm = yaw;
        end
        
        function setAccelTerms(obj, roll, pitch, yaw)
            obj.rollModel.accelTerm = roll;
            obj.pitchModel.accelTerm = pitch;
            obj.yawModel.accelTerm = yaw;
        end
        
        function [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(obj)
            angle1Cont = obj.rollContinuity;
            angle2Cont = obj.pitchContinuity;
            angle3Cont = obj.yawContinuity;
        end
        
        function setContinuityTerms(obj, angle1Cont, angle2Cont, angle3Cont)
            obj.rollContinuity = angle1Cont;
            obj.pitchContinuity = angle2Cont;
            obj.yawContinuity = angle3Cont;
        end
        
        function setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)
            if(obj.rollContinuity || obj.pitchContinuity || obj.yawContinuity)
                [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromInertialBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
                
                if(obj.rollContinuity)
                    obj.rollModel.constTerm = rollAngle;
                end
                
                if(obj.pitchContinuity)
                    obj.pitchModel.constTerm = pitchAngle;
                end
                
                if(obj.yawContinuity)
                    obj.yawModel.constTerm = yawAngle;
                end
            end
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(~)
            angle1Name = 'Roll';
            angle2Name = 'Pitch';
            angle3Name = 'Yaw';
        end
        
        function newSteeringModel = deepCopy(obj)
            newSteeringModel = RollPitchYawPolySteeringModel(obj.rollModel.deepCopy(), obj.pitchModel.deepCopy(), obj.yawModel.deepCopy());
            newSteeringModel.rollContinuity = obj.rollContinuity;
            newSteeringModel.pitchContinuity = obj.pitchContinuity;
            newSteeringModel.yawContinuity = obj.yawContinuity;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetRPYSteeringModelActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
    end
    
    methods(Access=private)
        function obj = RollPitchYawPolySteeringModel(rollModel, pitchModel, yawModel)
            obj.rollModel = rollModel;
            obj.pitchModel = pitchModel;
            obj.yawModel = yawModel;
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            rollModel = PolynominalModel(0,0,0,0);
            pitchModel = PolynominalModel(0,0,0,0);
            yawModel = PolynominalModel(0,0,0,0);
            
            model = RollPitchYawPolySteeringModel(rollModel, pitchModel, yawModel);
        end
        
        function typeStr = getTypeNameStr()
%             typeStr = 'Roll/Pitch/Yaw Steering';
            typeStr = SteeringModelEnum.RollPitchYawPoly.nameStr;
        end
    end
end