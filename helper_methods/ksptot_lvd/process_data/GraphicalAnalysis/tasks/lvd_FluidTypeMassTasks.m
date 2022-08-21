function datapt = lvd_FluidTypeMassTasks(stateLogEntry, subTask, fluidType)
%lvd_FluidTypeMassTasks Summary of this function goes here
%   Detailed explanation goes here
    datapt = -1;

    switch subTask
        case 'totalFluidTypeMass'
            fluidTypes = stateLogEntry.launchVehicle.tankTypes.types;
            massesByType = stateLogEntry.getTotalVehiclePropMassesByFluidType();
            
            datapt = massesByType(fluidType == fluidTypes);
    end
end