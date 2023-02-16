time = 0;
[rVectSC, vVectSC] = getStatefromKepler(600, 0, 0, 0, 0, 0, celBodyData.mun.gm);
bodyScChain = celBodyData.mun.getOrbitElemsChain();
bodyOtherChain = getOrbitElemsChain(celBodyData.jool);

numRuns = 10000;
 
tic;
for(i=1:numRuns) %#ok<*NO4LP>
    getAbsPositBetweenSpacecraftAndBody_fast(time, rVectSC, bodyScChain, bodyOtherChain, vVectSC);
end
toc;

tic;
for(i=1:numRuns)
    getAbsPositBetweenSpacecraftAndBody_fast_mex(time, rVectSC, bodyScChain, bodyOtherChain, vVectSC);
end
toc;