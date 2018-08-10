function propTypeIndex = ma_getPropTypeIndexFromInternalPropName(internalPropName)
%ma_getPropTypeIndexFromInternalPropName Summary of this function goes here
%   Detailed explanation goes here

    switch internalPropName
        case 'fuelOxMass'
            propTypeIndex = 1;
        case 'monoMass'
            propTypeIndex = 2;
        case 'xenonMass'
            propTypeIndex = 3;
    end
end

