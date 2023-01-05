classdef NomadSurrogateWeightTypeEnum < matlab.mixin.SetGet
    %NomadSurrogateDistanceTypeEnum Summary of this class goes here
    %   See: https://nomad-4-user-guide.readthedocs.io/en/latest/SgteLib.html
    
    enumeration
        WTA1('WTA1', 'WTA1',          '$w_k \propto \mathcal{E}_{sum} - \mathcal{E}_k$')
        WTA3('WTA3', 'WTA3',          '$w_k \propto (\mathcal{E}_k + \alpha\mathcal{E}_{mean})^{\beta}$')
        SELECT('SELECT', 'SELECT',    '$w_k \propto 1$ if $\mathcal{E}_k = \mathcal{E}_{min}$')
        SELECT1('SELECT1', 'SELECT1', '$w_k \propto \mathcal{E}_{sum}^1 - \mathcal{E}_k$')
        SELECT2('SELECT2', 'SELECT2', '$w_k \propto \mathcal{E}_{sum}^2 - \mathcal{E}_k$')
        SELECT3('SELECT3', 'SELECT3', '$w_k \propto \mathcal{E}_{sum}^3 - \mathcal{E}_k$')
        SELECT4('SELECT4', 'SELECT4', '$w_k \propto \mathcal{E}_{sum}^4 - \mathcal{E}_k$')
        SELECT5('SELECT5', 'SELECT5', '$w_k \propto \mathcal{E}_{sum}^5 - \mathcal{E}_k$')
        SELECT6('SELECT6', 'SELECT6', '$w_k \propto \mathcal{E}_{sum}^6 - \mathcal{E}_k$')
        OPTIM('OPTIM', 'OPTIM',       '${w}$ minimizes $\mathcal{E}(w)$')
    end
    
    properties
        optionStr char = ''
        name char = '';
        desc char = '';
    end
    
    methods
        function obj = NomadSurrogateWeightTypeEnum(optionStr, name, desc)
            obj.optionStr = optionStr;
            obj.name = name;
            obj.desc = desc;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('NomadSurrogateWeightTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadSurrogateWeightTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadSurrogateWeightTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end