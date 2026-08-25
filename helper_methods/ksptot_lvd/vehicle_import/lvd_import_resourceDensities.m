function densities = lvd_import_resourceDensities()
%lvd_import_resourceDensities Returns KSP resource densities in metric tons per unit.
%
%   densities = lvd_import_resourceDensities()
%
%   Returns a containers.Map keyed by KSP resource name (case preserved)
%   with metric-tons-per-unit values matching stock KSP resource
%   definitions. ElectricCharge is included with zero density so mass
%   calculations can iterate all resources uniformly.

    densities = containers.Map();

    densities('LiquidFuel')    = 0.005;
    densities('Oxidizer')      = 0.005;
    densities('MonoPropellant') = 0.004;
    densities('XenonGas')      = 0.0001;
    densities('SolidFuel')     = 0.0075;
    densities('ElectricCharge') = 0.0;

end
