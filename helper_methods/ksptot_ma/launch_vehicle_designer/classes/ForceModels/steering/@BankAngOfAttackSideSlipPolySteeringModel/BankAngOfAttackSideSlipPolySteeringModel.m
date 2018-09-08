classdef BankAngOfAttackSideSlipPolySteeringModel < AbstractSteeringModel
    %RollPitchYawSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bankModel(1,1) PolynominalModel
        aoAModel(1,1) PolynominalModel
        slipModel(1,1) PolynominalModel
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect)
            bankAng = obj.bankModel.getValueAtTime(ut);
            angOfAttack = obj.aoAModel.getValueAtTime(ut);
            angOfSideslip = obj.slipModel.getValueAtTime(ut);
            
            [~, ~, ~, dcm] = computeBodyAxesFromAeroAngles(rVect, vVect, angOfAttack, angOfSideslip, bankAng);
        end
    end
    
    methods(Access=private)
        function obj = BankAngOfAttackSideSlipPolySteeringModel(bankModel, aoAModel, slipModel)
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
            
            model = BankAngOfAttackSideSlipPolySteeringModel(bankModel, aoAModel, slipModel);
        end
    end
end