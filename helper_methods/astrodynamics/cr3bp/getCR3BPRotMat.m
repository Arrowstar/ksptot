function rotMatEci2Cr3bp = getCR3BPRotMat(ut, secBodyInfo, celBodyData)
    priBodyInfo = secBodyInfo.getParBodyInfo(celBodyData);
    gmu = priBodyInfo.gm;
    
    [rVectS, vVectS] = getStateAtTime(secBodyInfo, ut, gmu);
    
    xVectCR3BP = normVector(rVectS);
    zVectCR3BP = normVector(crossARH(rVectS, vVectS));
    yVectCR3BP = normVector(crossARH(zVectCR3BP, xVectCR3BP));
    
    rotMatEci2Cr3bp = [xVectCR3BP, yVectCR3BP, zVectCR3BP];
end