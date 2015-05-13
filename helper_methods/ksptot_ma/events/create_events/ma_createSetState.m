function setState = ma_createSetState(name, epoch, sma, ecc, inc, raan, arg, true, centralBodyInfo, dryMass, fuelOxMass, monoMass, xenonMass)
%ma_createSetState Summary of this function goes here
%   Detailed explanation goes here
    
    gmu = centralBodyInfo.gm;
    [rVect,vVect]=getStatefromKepler(sma, ecc, inc, raan, arg, true, gmu);

    setState = struct();
    setState.name        = name;
    setState.type        = 'Set_State';
    setState.epoch       = epoch;
    setState.centralBody = centralBodyInfo;
    setState.rVect       = rVect;
    setState.vVect       = vVect;
    setState.dryMass     = dryMass;
    setState.fuelOxMass  = fuelOxMass;
    setState.monoMass    = monoMass;
    setState.xenonMass   = xenonMass;
    setState.id          = rand(1);
end

