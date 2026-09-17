function [g] = computeGradAtPoint(fun, x0, fAtX0, h, diffType, numPts, sparsity, useParallel)
%computeGradAtPoint Finite-difference gradient/Jacobian of fun at x0.
%
%   g = computeGradAtPoint(fun, x0, fAtX0, h, diffType, numPts, sparsity, useParallel)
%   returns g of size [numel(x0) x numel(fAtX0)]: row i holds d(fun)/dx_i.
%
%   sparsity may be:
%     []                        - dense, every x element is perturbed
%     vector (numel(x0) x 1)    - x element i is skipped (row of zeros) when
%                                 sparsity(i) == 0
%     matrix [numel(x0) x numel(fAtX0)] - structural pattern; an x element
%                                 whose whole row is zero is skipped without
%                                 any function evaluation, otherwise the
%                                 column is evaluated and the structurally
%                                 zero entries are forced to exactly 0.
%   Dense and vector behaviour is unchanged by the matrix form.

    numFunOutputs = length(fAtX0);
    x0 = x0(:);

    sparsityMatrix = [];
    if(not(isempty(sparsity)))
        %The matrix shape is tested first so that a 1-variable or 1-output
        %pattern (which is also a vector) is still treated as the pattern.
        if(isequal(size(sparsity), [numel(x0), numFunOutputs]))
            sparsityMatrix = logical(sparsity);
            sparsity = double(any(sparsityMatrix, 2));
        elseif(isvector(sparsity) && numel(sparsity) == numel(x0))
            %per-x-element vector: unchanged legacy behaviour
        else
            error('computeGradAtPoint:badSparsity', ...
                  'sparsity must be empty, a vector with numel(x0) = %u elements, or a matrix [numel(x0) x numel(fAtX0)] = [%u x %u].', ...
                  numel(x0), numel(x0), numFunOutputs);
        end
    end

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
        %Store the function in a cell so the same indexing works below for
        %both pool Constants and plain serial execution.  (The previous
        %trick of dot-indexing an undefined variable happened to work for
        %simple closures but broke for handles closing over large object
        %graphs once they crossed the parfor body boundary.)
        C = {fun};
    end
    
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
                        if(isa(C, 'parallel.pool.Constant'))
                            f = C.Value{1}; %#ok<PFBNS>
                        else
                            f = C{1}; %#ok<PFBNS>
                        end
                        fAtX = f(xToEvalAt(:,j)); %#ok<PFBNS>
                    end
                    numerator = numerator + diffCoeff(j) .* fAtX(:)'; 
                end
            end

            g(i,:) = numerator/h;
        else
            g(i,:) = zeros(1,numFunOutputs);
        end
	end

    if(not(isempty(sparsityMatrix)))
        g(not(sparsityMatrix)) = 0;
    end
end