classdef AeroAnglesPolySteeringModel < AbstractAnglePolySteeringModel
    %AeroAnglesPolySteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bankModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        aoAModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        slipModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        
        bankContinuity(1,1) logical = true;
        aoAContinuity(1,1) logical = true;
        slipContinuity(1,1) logical = true;

        dcmCacheTime(1,1) double = NaN;
        dcmCache(3,3) double = NaN(3,3);
    end
    
    methods       
        function R_body_2_inertial = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            if(numel(ut) == 1 && ut == obj.dcmCacheTime)
                R_body_2_inertial = obj.dcmCache;
            else
                bankAng = obj.bankModel.getValueAtTime(ut);
                angOfAttack = obj.aoAModel.getValueAtTime(ut);
                angOfSideslip = obj.slipModel.getValueAtTime(ut);
                
                baseFrame = bodyInfo.getBodyFixedFrame();
                [~, ~, ~, R_body_2_inertial] = computeInertialBodyAxesFromFrameAeroAngles(ut, rVect, vVect, bodyInfo, bankAng, angOfAttack, angOfSideslip, baseFrame);

                obj.dcmCacheTime = ut;
                obj.dcmCache = R_body_2_inertial;
            end
        end
        
        function [angleModel, continuity] = getAngleNModel(obj, n)
            angleModel = PolynominalModel.empty(1,0);
            
            switch n
                case 1
                    angleModel = obj.bankModel;
                    continuity = obj.bankContinuity;
                case 2
                    angleModel = obj.aoAModel;
                    continuity = obj.aoAContinuity;
                case 3
                    angleModel = obj.slipModel;
                    continuity = obj.slipContinuity;
            end
        end
        
        function t0 = getT0(obj)
            t0 = obj.slipModel.t0;
        end
        
        function setT0(obj, newT0)
            obj.bankModel.t0 = newT0;
            obj.aoAModel.t0 = newT0;
            obj.slipModel.t0 = newT0;
        end
        
        function setConstTerms(obj, bankConst, aoaConst, slipConst)
            obj.bankModel.constTerm = bankConst;
            obj.aoAModel.constTerm = aoaConst;
            obj.slipModel.constTerm = slipConst;
        end
        
        function setLinearTerms(obj, bank, aoa, slip)
            obj.bankModel.linearTerm = bank;
            obj.aoAModel.linearTerm = aoa;
            obj.slipModel.linearTerm = slip;
        end
        
        function setAccelTerms(obj, bank, aoa, slip)
            obj.bankModel.accelTerm = bank;
            obj.aoAModel.accelTerm = aoa;
            obj.slipModel.accelTerm = slip;
        end
        
        function setTimeOffsets(obj, timeOffset)
            obj.bankModel.tOffset = timeOffset;
            obj.aoAModel.tOffset = timeOffset;
            obj.slipModel.tOffset = timeOffset;
        end
        
        function [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(obj)
            angle1Cont = obj.bankContinuity;
            angle2Cont = obj.aoAContinuity;
            angle3Cont = obj.slipContinuity;
        end
        
        function setContinuityTerms(obj, angle1Cont, angle2Cont, angle3Cont)
            obj.bankContinuity = angle1Cont;
            obj.aoAContinuity = angle2Cont;
            obj.slipContinuity = angle3Cont;
        end
        
        function setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)
            if(obj.bankContinuity || obj.aoAContinuity || obj.slipContinuity)
                [bankAng,angOfAttack,angOfSideslip] = computeAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
                
                if(obj.bankContinuity)
                    obj.bankModel.constTerm = bankAng;
                end
                
                if(obj.aoAContinuity)
                    obj.aoAModel.constTerm = angOfAttack;
                end
                
                if(obj.slipContinuity)
                    obj.slipModel.constTerm = angOfSideslip;
                end
            end
        end
        
        function setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)
            t0 = stateLogEntry.time;
            obj.setT0(t0);
            
            obj.bankModel.tOffset = obj.bankModel.tOffset + tOffsetDelta;
            obj.aoAModel.tOffset = obj.aoAModel.tOffset + tOffsetDelta;
            obj.slipModel.tOffset = obj.slipModel.tOffset + tOffsetDelta;
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(~)
            angle1Name = 'Bank Angle';
            angle2Name = 'Angle of Attack';
            angle3Name = 'Side Slip Angle';
        end
        
        function newSteeringModel = deepCopy(obj)
            newSteeringModel = AeroAnglesPolySteeringModel(obj.bankModel.deepCopy(), obj.aoAModel.deepCopy(), obj.slipModel.deepCopy());
            newSteeringModel.bankContinuity = obj.bankContinuity;
            newSteeringModel.aoAContinuity = obj.aoAContinuity;
            newSteeringModel.slipContinuity = obj.slipContinuity;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetAeroSteeringModelActionOptimVar(obj);
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
        function obj = AeroAnglesPolySteeringModel(bankModel, aoAModel, slipModel)
            obj.bankModel = bankModel;
            obj.aoAModel = aoAModel;
            obj.slipModel = slipModel;
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            bankModel = PolynominalModel(0,0,0,0);
            aoAModel = PolynominalModel(0,0,0,0);
            slipModel = PolynominalModel(0,0,0,0);
            
            model = AeroAnglesPolySteeringModel(bankModel, aoAModel, slipModel);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.AeroAnglesPoly.nameStr;
        end
    end
end