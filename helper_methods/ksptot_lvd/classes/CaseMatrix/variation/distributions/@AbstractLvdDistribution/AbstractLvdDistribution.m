classdef(Abstract) AbstractLvdDistribution < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLvdDistribution A one dimensional probability distribution used
    %to disperse a sweep/Monte Carlo parameter.
    %
    %   Sampling is always done by the inverse CDF method: the sampler
    %   generates uniform numbers on [0, 1] (plainly random, or stratified
    %   for a Latin hypercube) and each distribution maps them onto its own
    %   support.  Keeping every distribution to that one interface is what
    %   lets the sampler stratify and seed a run without knowing anything
    %   about the distributions in it.
    %
    %   The inverse CDFs are written out in closed form on base MATLAB
    %   rather than being delegated to the Statistics and Machine Learning
    %   Toolbox's makedist/icdf, so a dispersion run has no toolbox
    %   dependency beyond what LVD already requires and so the values can be
    %   checked against an independent oracle in the tests.

    properties
        id(1,1) double = 0;
    end

    methods(Abstract)
        %invCdf Maps u on [0, 1] onto the distribution's support.
        x = invCdf(obj, u)

        %getTypeName Short display name, e.g. 'Normal'.
        name = getTypeName(obj)

        %getSummaryStr One line description including the parameters.
        str = getSummaryStr(obj)

        %getParamNames Names of the (up to three) editable parameters, in
        %the order getParamValues/setParamValues use.
        names = getParamNames(obj)

        values = getParamValues(obj)

        setParamValues(obj, values)

        %getSupport Smallest interval that contains every possible sample.
        [lb, ub] = getSupport(obj)
    end

    methods
        function m = getMean(obj)
            %getMean Distribution mean.  Defaults to a numeric quadrature of
            %the inverse CDF, which is exact enough for the summary shown
            %next to a dispersion definition; subclasses with a closed form
            %override it.
            u = linspace(0.5/1000, 1 - 0.5/1000, 1000);
            m = mean(obj.invCdf(u));
        end

        function s = getStdDev(obj)
            u = linspace(0.5/1000, 1 - 0.5/1000, 1000);
            s = std(obj.invCdf(u), 1);
        end

        function x = sample(obj, n, randStream)
            %sample n plain random draws.  Provided for convenience; the
            %sweep engine goes through LvdSweepSampler so that Latin
            %hypercube stratification is available too.
            arguments
                obj(1,1) AbstractLvdDistribution
                n(1,1) double
                randStream(1,1) RandStream
            end

            x = obj.invCdf(rand(randStream, n, 1));
        end
    end

    methods(Static)
        function dists = getAllDistributionTypes()
            %getAllDistributionTypes One default constructed instance of each
            %concrete distribution, for populating a type dropdown.
            dists = [LvdUniformDistribution(0, 1), ...
                     LvdNormalDistribution(0, 1), ...
                     LvdTriangularDistribution(0, 0.5, 1)];
        end

        function dist = createByTypeName(typeName, nominalValue)
            %createByTypeName A distribution of the named type, sized around
            %a parameter's current value so a freshly added dispersion has
            %sensible defaults.
            arguments
                typeName(1,:) char
                nominalValue(1,1) double = 0;
            end

            spread = abs(nominalValue) * 0.05;
            if(spread <= 0)
                spread = 1;
            end

            switch typeName
                case 'Uniform'
                    dist = LvdUniformDistribution(nominalValue - spread, nominalValue + spread);

                case 'Normal'
                    dist = LvdNormalDistribution(nominalValue, spread/3);

                case 'Triangular'
                    dist = LvdTriangularDistribution(nominalValue - spread, nominalValue, nominalValue + spread);

                otherwise
                    error('LvdDistribution:unknownType', 'Unknown distribution type: %s', typeName);
            end
        end

        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end
        end
    end

    methods(Sealed)
        function tf = eq(A, B)
            tf = [A.id] == [B.id];
        end

        function tf = ne(A, B)
            tf = [A.id] ~= [B.id];
        end
    end
end
