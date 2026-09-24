classdef LvdSweepSetup < matlab.mixin.SetGet
    %LvdSweepSetup The persisted definition of a case matrix or Monte Carlo
    %run.
    %
    %   Two of these hang off LvdData (caseMatrixSetup and monteCarloSetup)
    %   so a user's trade study and dispersion definitions are saved with the
    %   mission instead of being retyped every time the window opens.
    %   Neither is touched by propagation.
    %
    %   The parameter and variation arrays run in parallel -- variations(i)
    %   says how params(i) is varied -- and are only ever changed through
    %   addParameter/removeParameter so they cannot drift out of step.

    properties
        params(1,:) AbstractLvdSweepParameter = AbstractLvdSweepParameter.empty(1,0);
        variations(1,:) AbstractLvdSweepVariation = AbstractLvdSweepVariation.empty(1,0);

        responses(1,:) LvdSweepResponse = LvdSweepResponse.empty(1,0);

        %Display/file name for runs of this definition.  The Case Matrix
        %window leaves the historical default; Monte Carlo setups say
        %MonteCarlo.  Editable in the Monte Carlo window; stored runs can
        %be renamed again in its Stored Runs table.
        runName(1,:) char = 'Sweep';

        samplingMode(1,1) LvdSweepSamplingEnum = LvdSweepSamplingEnum.FullFactorial;
        numSamples(1,1) double {mustBePositive, mustBeInteger} = 100;
        seed(1,1) double = 0;

        %When true the GUI draws a fresh seed at every run start (recorded
        %in the results, so the run stays reproducible).  When false the
        %seed field above is used as-is.
        randomizeSeedEachRun(1,1) logical = false;

        runMode(1,1) LvdCaseMatrixRunModeEnum = LvdCaseMatrixRunModeEnum.Optimize;

        numWorkers(1,1) double {mustBePositive, mustBeInteger} = 1;
        maxNumAttempts(1,1) double {mustBePositive, mustBeInteger} = 2;

        outputLocation(1,:) char = '';

        writeXlsx(1,1) logical = true;
        writeMat(1,1) logical = true;
        writeCsv(1,1) logical = false;

        %The per-case graphical analysis time series sheet the original case
        %matrix always wrote.  Off by default now: at Monte Carlo sample
        %counts it is the single most expensive part of a run and nobody
        %reads a thousand of them.
        writeGaTimeSeries(1,1) logical = false;

        %One .mat per case.  Indispensable in Optimize mode (it is what the
        %warm start reads) and untenable at N = 5000 in propagate-only mode.
        persistCaseFiles(1,1) logical = true;

        id(1,1) double = 0;
    end

    methods
        function obj = LvdSweepSetup()
            obj.id = rand();
        end

        function addParameter(obj, param, variation)
            arguments
                obj(1,1) LvdSweepSetup
                param(1,1) AbstractLvdSweepParameter
                variation(1,1) AbstractLvdSweepVariation
            end

            obj.params(end+1) = param;
            obj.variations(end+1) = variation;
        end

        function removeParameterAtInd(obj, ind)
            if(ind >= 1 && ind <= numel(obj.params))
                obj.params(ind) = [];
                obj.variations(ind) = [];
            end
        end

        function setVariationAtInd(obj, ind, variation)
            arguments
                obj(1,1) LvdSweepSetup
                ind(1,1) double
                variation(1,1) AbstractLvdSweepVariation
            end

            if(ind >= 1 && ind <= numel(obj.variations))
                obj.variations(ind) = variation;
            end
        end

        function n = getNumParameters(obj)
            n = numel(obj.params);
        end

        function n = getNumResponses(obj)
            n = numel(obj.responses);
        end

        function addResponse(obj, response)
            arguments
                obj(1,1) LvdSweepSetup
                response(1,1) LvdSweepResponse
            end

            obj.responses(end+1) = response;
        end

        function removeResponseAtInd(obj, ind)
            if(ind >= 1 && ind <= numel(obj.responses))
                obj.responses(ind) = [];
            end
        end

        function numCases = getNumCases(obj)
            numCases = LvdSweepSampler.getNumCases(obj.variations, obj.samplingMode, obj.numSamples);
        end

        function X = generateInputMatrix(obj)
            %generateInputMatrix The N x P matrix of values this run will
            %apply, produced up front on the client so the run is
            %reproducible from the seed alone.
            X = LvdSweepSampler.generate(obj.variations, obj.samplingMode, obj.numSamples, obj.seed);
        end

        function labels = getParameterLabels(obj)
            labels = cell(1, numel(obj.params));

            for(i=1:numel(obj.params)) %#ok<*NO4LP>
                labels{i} = obj.params(i).getFullLabel();
            end
        end

        function labels = getResponseLabels(obj)
            labels = cell(1, numel(obj.responses));

            for(i=1:numel(obj.responses))
                labels{i} = obj.responses(i).getName();
            end
        end

        function tf = resolveAll(obj, lvdData)
            %resolveAll Rebinds every parameter onto the given mission.
            %Returns false if any of them could not be found.
            arguments
                obj(1,1) LvdSweepSetup
                lvdData(1,1) LvdData
            end

            tf = true;

            for(i=1:numel(obj.params))
                tf = obj.params(i).resolve(lvdData) && tf;
            end
        end

        function captureBaselines(obj, lvdData)
            %captureBaselines Refreshes every multiplier parameter's baseline
            %off the pristine template.  Called once at run start.
            arguments
                obj(1,1) LvdSweepSetup
                lvdData(1,1) LvdData
            end

            for(i=1:numel(obj.params))
                obj.params(i).captureBaseline(lvdData);
            end
        end

        function [tf, msg] = validate(obj, lvdData)
            %validate Everything that must be true before a run starts, with
            %one message the GUI can put straight into a uialert.
            arguments
                obj(1,1) LvdSweepSetup
                lvdData LvdData = LvdData.empty(1,0);
            end

            tf = false;

            if(isempty(obj.params))
                msg = 'At least one parameter must be selected to sweep over.';
                return;
            end

            if(isempty(obj.responses) && not(obj.writeGaTimeSeries))
                msg = 'At least one response must be selected, or the per-case time series output must be enabled; otherwise the run would produce no results.';
                return;
            end

            numCases = obj.getNumCases();
            if(numCases < 1)
                msg = 'The selected parameters and sampling scheme produce no cases to run.';
                return;
            end

            if(isempty(obj.outputLocation) || not(isfolder(obj.outputLocation)))
                msg = 'A valid output folder must be selected.';
                return;
            end

            if(not(isempty(lvdData)))
                unresolved = {};

                for(i=1:numel(obj.params))
                    if(not(obj.params(i).resolve(lvdData)))
                        unresolved{end+1} = obj.params(i).getName(); %#ok<AGROW>
                    end
                end

                if(not(isempty(unresolved)))
                    msg = sprintf('These parameters no longer exist in this mission and must be removed: %s', ...
                                  strjoin(unresolved, ', '));
                    return;
                end
            end

            tf = true;
            msg = '';
        end

        function newObj = deepCopy(obj)
            %deepCopy An independent copy, used when the Monte Carlo window
            %edits a setup the user may then cancel out of.
            newObj = getArrayFromByteStream(getByteStreamFromArray(obj));
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end

            if(isempty(obj.runName))
                obj.runName = 'Sweep';
            end

            if(isempty(obj.randomizeSeedEachRun))
                obj.randomizeSeedEachRun = false;
            end

            %A setup saved with mismatched arrays (only reachable by hand
            %editing) would index out of range on the first run; trim
            %instead of failing to load the mission.
            n = min(numel(obj.params), numel(obj.variations));
            obj.params = obj.params(1:n);
            obj.variations = obj.variations(1:n);
        end

        function obj = getDefaultMonteCarloSetup()
            %getDefaultMonteCarloSetup A dispersion run is always sampled and
            %always propagate-only; the case matrix defaults are the wrong
            %way round for it.
            obj = LvdSweepSetup();

            obj.runName = 'MonteCarlo';
            obj.samplingMode = LvdSweepSamplingEnum.LatinHypercube;
            obj.numSamples = 200;
            obj.runMode = LvdCaseMatrixRunModeEnum.PropagateOnly;
            obj.persistCaseFiles = false;
            obj.writeGaTimeSeries = false;
        end
    end
end
