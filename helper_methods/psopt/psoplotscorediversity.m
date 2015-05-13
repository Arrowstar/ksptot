function [state,options] = psoplotscorediversity(options,state,flag)
% Plots a histogram containing the best and mean scores of particle swarm.

if strcmp(flag,'init')
    set(gca,'NextPlot','replacechildren',...
        'XLabel',xlabel('Scores'),...
        'YLabel',ylabel('Number of inidividuals'))
end

[n,bins] = hist(state.Score) ;
bar(bins,n,'Tag','scorehistogram','FaceColor',[0.1 0.1 0.5])