classdef AeroAnglesPolySteeringModel < AbstractAnglePolySteeringModel
    %RollPitchYawSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bankModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        aoAModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        slipModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        
        bankContinuity(1,1) logical = true;
        aoAContinuity(1,1) logical = true;
        slipContinuity(1,1) logical = true;
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect)
            bankAng = obj.bankModel.getValueAtTime(ut);
            angOfAttack = obj.aoAModel.getValueAtTime(ut);
            angOfSideslip = obj.slipModel.getValueAtTime(ut);
            
            [~, ~, ~, dcm] = computeBodyAxesFromAeroAngles(rVect, vVect, angOfAttack, angOfSideslip, bankAng);
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
        
        function setConstsFromDcmAndContinuitySettings(obj, dcm, rVect, vVect)
            if(obj.bankContinuity || obj.aoAContinuity || obj.slipContinuity)
                [bankAng,angOfAttack,angOfSideslip] = computeAeroAnglesFromBodyAxes(rVect, vVect, dcm(:,1), dcm(:,2), dcm(:,3));
                
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
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(~)
            angle1Name = 'Bank';
            angle2Name = 'Angle of Attack';
            angle3Name = 'Side Slip';
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetAeroSteeringModelActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
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
%             typeStr = 'Aero Angles Steering';
            typeStr = SteeringModelEnum.AeroAnglesPoly.nameStr;
        end
    end
end