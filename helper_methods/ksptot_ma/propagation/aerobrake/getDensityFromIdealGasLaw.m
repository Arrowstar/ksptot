function density = getDensityFromIdealGasLaw(staticPresskPa, atmoTempK, atmosphereMolarMass)
%     gasConstant = getIdealGasConstant();
    density = (staticPresskPa * 1000 * atmosphereMolarMass) / (getIdealGasConstant() * atmoTempK);
end