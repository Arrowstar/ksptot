function steeringModel = promptForSteeringModelType(selectedEnum)
    [listboxStr, enums] = SteerModelTypeEnum.getListBoxStr();
    
    if(not(isempty(selectedEnum)))
        initialValue = find(selectedEnum == enums, 1, 'first');
        
        if(isempty(initialValue))
            initialValue = 1;
        end
    else
        initialValue = 1;
    end
    
    [Selection,ok] = listdlgARH('ListString',listboxStr, ...
                                'Name','Select Steering Model Type', ...
                                'PromptString',{'Select steering model type:'}, ...
                                'SelectionMode','single', ...
                                'ListSize',[300 300], ...
                                'InitialValue', initialValue);
    if(ok)
        enum = SteerModelTypeEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum
            case SteerModelTypeEnum.PolyAngles
                steeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
                
            case SteerModelTypeEnum.QuaterionInterp
                steeringModel = GenericQuatInterpSteeringModel.getDefaultSteeringModel();
                
            case SteerModelTypeEnum.LinearTangentAngles
                steeringModel = GenericLinearTangentSteeringModel.getDefaultSteeringModel();

            case SteerModelTypeEnum.SumOfSinesAngles
                steeringModel = GenericSumOfSinesSteeringModel.getDefaultSteeringModel();
                
            otherwise
                error('Unknown steering model type: %s', enum.name);
        end
    else
        steeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
    end
end