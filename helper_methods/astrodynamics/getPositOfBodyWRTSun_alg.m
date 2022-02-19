function [rVectB, vVectB] = getPositOfBodyWRTSun_alg(times, smas, eccs, incs, raans, args, means, epochs, parentGMs)   
    numTimes = length(times);
    rVectB = zeros(3,numTimes);
    vVectB = zeros(3,numTimes);
    for(i = 1:length(parentGMs))       
        [rVect, vVect] = getStateAtTime_alg(times, smas(i), eccs(i), incs(i), raans(i), args(i), means(i), epochs(i), parentGMs(i));
        rVectB = rVectB + rVect;
        vVectB = vVectB + vVect;
    end
end