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

        dcmCacheTime(1,1) double = NaN;
        dcmCache(3,3) double = NaN(3,3);
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            if(numel(ut) == 1 && ut == obj.dcmCacheTime)
                dcm = obj.dcmCache;
            else
                rollAng = obj.rollModel.getValueAtTime(ut);
                pitchAng = obj.pitchModel.getValueAtTime(ut);
                yawAng = obj.yawModel.getValueAtTime(ut);
                            
                baseFrame = bodyInfo.getBodyFixedFrame();
                [~, ~, ~, dcm] = computeInertialBodyAxesFromFrameEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng, baseFrame);
                dcm = real(dcm);

                obj.dcmCacheTime = ut;
                obj.dcmCache = dcm;
            end
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
        
        function t0 = getT0(obj)
            t0 = obj.yawModel.t0;
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
        
        function setTimeOffsets(obj, timeOffset)
            obj.rollModel.tOffset = timeOffset;
            obj.pitchModel.tOffset = timeOffset;
            obj.yawModel.tOffset = timeOffset;
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
        
        function setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)            
            t0 = stateLogEntry.time;
            obj.setT0(t0);

            obj.rollModel.tOffset = obj.rollModel.tOffset + tOffsetDelta;
            obj.pitchModel.tOffset = obj.pitchModel.tOffset + tOffsetDelta;
            obj.yawModel.tOffset = obj.yawModel.tOffset + tOffsetDelta;
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(~)
            angle1Name = 'Roll Angle';
            angle2Name = 'Pitch Angle';
            angle3Name = 'Yaw Angle';
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

        function [addActionTf, steeringModel] = openEditSteeringModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditActionSetSteeringModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            steeringModel = output.output{2};
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
            typeStr = SteeringModelEnum.RollPitchYawPoly.nameStr;
        end
    end
end