function pos2 = getbracketpairpos(s,pos1)
    % POS2 = GETBRACKETPAIRpos1(STR,POS1) gets the bracket position in a
    %   string given the position of the other paired bracket.
    %
    % Input:
    %   STR : string (can be a nested string)
    %   POS1: position of a bracket (can be either left or right)
    %
    % Note:
    %   1. Any bracket of '{[(<>)]}' can be recognized.
    %   2. Input position can be either left or right bracket.
    %   3. Mixed pair types are supported.
    %   4. Nested pairs are supported.
    %
    % Example:
    %   str = 'window.addEventListener("load", {w2_timing.logTime("windowLoad");reportPageData({"standard":{"untested"}})})';
    %   getbracketpairpos(str,24)
    %
    % By Newport Quantitative
    %   https://newportquant.com
    % Revision 1.0 $2019.01.21$
    allbracket = '{[(<>)]}';
    type_idx = find(allbracket == s(pos1));
    if isempty(type_idx)
        error('Not a valid bracket');
    end
    left = allbracket(min([length(allbracket)-type_idx+1,type_idx]));   % symbol of left bracket
    right = allbracket(max([length(allbracket)-type_idx+1,type_idx]));  % symbol of right bracket
    isleft = type_idx <= length(allbracket)/2;  % is input a left bracket?
    if isleft   % extract strings after pos1
        s = s(pos1:end);
    else
        s = s(1:pos1);  % extract strings before pos1
    end
    [~,bracket_pos1_in_str] = find(s==left | s==right);
    [~,left_bracket_pos1_in_str] = find(s==left);
    [~,right_bracket_pos1_in_str] = find(s==right);
    smap = zeros(1,length(s));
    smap(left_bracket_pos1_in_str) = 1;
    smap(right_bracket_pos1_in_str) = -1;
    if isleft
        b = cumsum(smap(bracket_pos1_in_str));
        pos2 =  bracket_pos1_in_str(find(b == 0,1,'first')) + pos1-1;
    else
        b = cumsum(flip(smap(bracket_pos1_in_str)));
        pos2 =  bracket_pos1_in_str(length(b)+1-find(b == 0,1,'first'));
    end
end
