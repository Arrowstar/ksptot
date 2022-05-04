function [g] = computeGradAtPoint(fun, x0, fAtX0, h, diffType, numPts, sparsity, useParallel)
%computeGradAtPoint Summary of this function goes here
%   Detailed explanation goes here

    switch diffType
        case FiniteDiffTypeEnum.Central
            if(mod(numPts,2) == 0) %even
                numPtsPerSide = numPts/2;
            else %odd
                numPtsPerSide = (numPts-1)/2;
            end        

            if(numPtsPerSide <= 0)
                numPtsPerSide = 1;
            end

            xPts = [-numPtsPerSide:1:0, 1:1:numPtsPerSide];
            
        case FiniteDiffTypeEnum.Forward
            xPts = 0:1:(numPts-1);
            
        case FiniteDiffTypeEnum.Backward
            xPts = 0:-1:(numPts-1);
            
        otherwise
            error('Invalid finite difference type!  Only forward, backward, and central allowed!');
    end
    xPts = xPts(:)';

    [diffCoeff,~,~] = TT(xPts,1);
    
    if(useParallel)
        p = gcp('nocreate');
        if(isempty(p))
            error('Cannot run gradient in parallel: no parallel pool exists!');
        else
%             M = p.NumWorkers;
            M = parforOptions(p, 'RangePartitionMethod','fixed', 'SubrangeSize',1);
            C = parallel.pool.Constant({fun});
        end
    else
        M = 0;
        C.Value{1} = fun;
    end
    
    numFunOutputs = length(fAtX0);
    x0 = x0(:);
    g = nan([numel(x0),numFunOutputs]);
    zeroArr = zeros(1,size(g,1));
	parfor(i=1:size(g,1), M)
% 	for(i=1:size(g,1))
        if(isempty(sparsity) || (not(isempty(sparsity)) && sparsity(i) ~= 0)) 
            varArr = zeroArr;
            varArr(i) = 1;

            xDeltas = h.*(varArr(:) .* xPts); %consider FMINCON style: delta = v.*sign?(x).*max(abs(x),TypicalX); or delta = v.*max(abs(x),TypicalX);

            xToEvalAt = bsxfun(@plus, x0, xDeltas);

            numPtsToEval = size(xToEvalAt, 2);

            numerator = zeros(1,numFunOutputs);
            for(j=1:numPtsToEval) %#ok<*NO4LP> 
                if(diffCoeff(j) ~= 0) %#ok<PFBNS> %otherwise we're just adding zero regardless
                    if(not(isempty(fAtX0)) && all(x0 == xToEvalAt(:,j)))
                        fAtX = fAtX0;
                    else
%                         if(useParallel)
                            f = C.Value{1}; %#ok<PFBNS> 
                            fAtX = f(xToEvalAt(:,j)); %#ok<PFBNS>
%                         else
%                             fAtX = fun(xToEvalAt(:,j)); %#ok<PFBNS>
%                         end
                    end
                    numerator = numerator + diffCoeff(j) .* fAtX(:)'; 
                end
            end

            g(i,:) = numerator/h;
        else
            g(i,:) = zeros(1,numFunOutputs);
        end
	end
end