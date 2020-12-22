function [rVectCR3BP, vVectCR3BP] = getCR3BPVectFromECIVect(ut, rVectECI, vVectECI, secBodyInfo, celBodyData)

    priBodyInfo = secBodyInfo.getParBodyInfo(celBodyData);
    gmu = priBodyInfo.gm;
    
    rotMatEci2Cr3bp = getCR3BPRotMat(ut, secBodyInfo, celBodyData);
    rotMatEci2Cr3bp = rotMatEci2Cr3bp';
    zVectCR3BP = rotMatEci2Cr3bp(:,3);
    
    rVectCR3BP = rotMatEci2Cr3bp * rVectECI;
    
    secPeriod = computePeriod(secBodyInfo.sma, gmu);
    rotRateRadSec = 2*pi/secPeriod;
    omegaRI = zVectCR3BP * rotRateRadSec;

    vVectCR3BP = rotMatEci2Cr3bp*(vVectECI - crossARH(omegaRI, rVectECI));
end