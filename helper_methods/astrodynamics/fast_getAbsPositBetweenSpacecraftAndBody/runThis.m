time = 0;
[rVectSC, vVectSC] = getStatefromKepler(600, 0, 0, 0, 0, 0, celBodyData.mun.gm);
bodyScChain = celBodyData.mun.getOrbitElemsChain();
bodyOtherChain = getOrbitElemsChain([celBodyData.sun, celBodyData.moho, celBodyData.jool, celBodyData.laythe, celBodyData.pol, celBodyData.dres, celBodyData.eeloo]);
for(i=1:height(bodyOtherChain)); bodyOtherChain2(i) = {bodyOtherChain(i,:)}; end;