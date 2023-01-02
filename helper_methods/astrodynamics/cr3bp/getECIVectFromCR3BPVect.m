function [rVectECI, vVectECI] = getECIVectFromCR3BPVect(ut, rVectCR3BP, vVectCR3BP, secBodyInfo, celBodyData)

    priBodyInfo = secBodyInfo.getParBodyInfo(celBodyData);
    gmu = priBodyInfo.gm;
    
    rotMatEci2Cr3bp = getCR3BPRotMat(ut, secBodyInfo, celBodyData);
    zVectCR3BP = rotMatEci2Cr3bp(:,3);
    
    rotMatCr3bp2Eci = rotMatEci2Cr3bp;
    rVectECI = rotMatCr3bp2Eci * rVectCR3BP;
    
    secPeriod = computePeriod(secBodyInfo.sma, gmu);
    rotRateRadSec = 2*pi/secPeriod;
    omegaRI = zVectCR3BP * rotRateRadSec;

    vVectECI = rotMatCr3bp2Eci*(vVectCR3BP + crossARH(omegaRI, rVectCR3BP));
end