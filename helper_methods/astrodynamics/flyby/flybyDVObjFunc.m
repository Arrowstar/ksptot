function [dv, dvVect, Rp, xferOrbitIn, xferOrbitOut, flyByOrbitInResult, flyByOrbitOutResult, dvVectNTW] = flybyDVObjFunc(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr)
departTime = x(1);
flybyTime = x(2);
arrivalTime = x(3);

[rVect1, vVect1] = getStateAtTime(departBodyInfo, departTime, gmuXfr);
[rVect2, vVect2] = getStateAtTime(flybyBodyInfo, flybyTime, gmuXfr);
[rVect3, vVect3] = getStateAtTime(arrivalBodyInfo, arrivalTime, gmuXfr);

shortLongWayVect=[1 1; -1 1; 1 -1; -1 -1];

for(i=1:size(shortLongWayVect,1))
    [vInfIn, vInfOut, xferOrbitIn, xferOrbitOut] = flybyDVObjVInfCompFunc(departTime, flybyTime, arrivalTime, rVect1, rVect2, rVect3, vVect2, gmuXfr, shortLongWayVect(i,:));
    [dv, dvVect, orbitIn, orbitOut] = flybyDVObjCompFunc(vInfIn, vInfOut, flybyBodyInfo.gm); %changed from gmuXfr
    dvResults(i) = dv;
    dvVectResults{i} = dvVect;
    RpResults(i) = orbitIn(7);
    flyByOrbitIn{i} = orbitIn;
    flyByOrbitOut{i} = orbitOut;
end

[~, I] = min(dvResults);
dv = dvResults(I);
dvVect = dvVectResults{I};
Rp = RpResults(I);
flyByOrbitInResult = flyByOrbitIn{I};
flyByOrbitOutResult = flyByOrbitOut{I};

[rVect, vVect] = getStatefromKepler(flyByOrbitInResult(1), flyByOrbitInResult(2), flyByOrbitInResult(3), flyByOrbitInResult(4), flyByOrbitInResult(5), 0, flybyBodyInfo.gm);

tHat = vVect/norm(vVect);
wHat = cross(rVect,vVect)/norm(cross(rVect,vVect));
nHat = cross(tHat,wHat)/norm(cross(tHat,wHat));
ECI2TWNRotMat = [tHat,wHat,nHat];
dvVectNTW = ECI2TWNRotMat \ dvVect;

end