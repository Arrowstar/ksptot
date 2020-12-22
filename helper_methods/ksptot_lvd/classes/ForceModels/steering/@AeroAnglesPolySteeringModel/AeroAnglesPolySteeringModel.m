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
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            bankAng = obj.bankModel.getValueAtTime(ut);
            angOfAttack = obj.aoAModel.getValueAtTime(ut);
            angOfSideslip = obj.slipModel.getValueAtTime(ut);
            
            [~, ~, ~, dcm] = computeBodyAxesFromAeroAngles(ut, rVect, vVect, bodyInfo, angOfAttack, angOfSideslip, bankAng);
            dcm = real(dcm);
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
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(~)
            angle1Name = 'Bank';
            angle2Name = 'Angle of Attack';
            angle3Name = 'Side Slip';
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