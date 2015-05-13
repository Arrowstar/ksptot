function state = psocalculatepenalties(state)
% Calculates the penalty to apply for out-of-bounds particles when using
% the "penalize" constraint handling method.

% nx1 vector of penalties to apply to each particle
g = state.ConstrViolations ;
k = zeros(size(g));
n = size(state.Score,1);
% penalties = zeros(size(g,1),1) ;

if sum(state.OutOfBounds)
    idx = logical(state.OutOfBounds) ;
    k(idx,:) = (mean(state.Score).*g(idx,:))./sum(mean(g(idx,:),1).^2) ;
%     penalties = sum(k(idx,:).*g(idx,:),2) ;
    penalties = sum(k(idx,:).*g(idx,:),2) + max(state.Score(setdiff(1:n,idx))) ;
    
    % Apply the penalties to each particle's score
    state.Score(idx) = state.Score(idx) + penalties ;
end