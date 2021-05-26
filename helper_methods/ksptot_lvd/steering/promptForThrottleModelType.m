function throttleModel = promptForThrottleModelType(selectedEnum)
    [listboxStr, enums] = ThrottleModelEnum.getThrottleModelTypeNameStrs();
    
    if(not(isempty(selectedEnum)))
        initialValue = find(selectedEnum == enums, 1, 'first');
        
        if(isempty(initialValue))
            initialValue = 1;
        end
    else
        initialValue = 1;
    end
    
    [Selection,ok] = listdlgARH('ListString',listboxStr, ...
                                'Name','Select Throttle Model', ...
                                'PromptString',{'Select throttle model type:'}, ...
                                'SelectionMode','single', ...
                                'ListSize',[300 300], ...
                                'InitialValue', initialValue);
    if(ok)
        enum = ThrottleModelEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum
            case ThrottleModelEnum.PolyModel
                throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
                
            case ThrottleModelEnum.T2WModel
                throttleModel = T2WThrottleModel.getDefaultThrottleModel();
                
            otherwise
                error('Unknown throttle model type: %s', enum.nameStr);
        end
    else
        throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end
end