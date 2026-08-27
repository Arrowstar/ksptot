classdef lvd_ImportCraftGUI_App < handle
    %lvd_ImportCraftGUI_App Interactive wizard for importing a KSP .craft
    %file into the LVD vehicle builder.
    %
    %   lvd_ImportCraftGUI_App.launch(lvdData)   (recommended)
    %   app = lvd_ImportCraftGUI_App(lvdData)
    %
    %   The wizard lets the user pick a .craft file and an optional part
    %   database (.json/.mat; defaults to the bundled mini stock-parts
    %   database), reviews the inferred stages/tanks/engines and any
    %   warnings, then imports the vehicle into the supplied LVDData on
    %   confirmation.

    properties (SetAccess = private)
        UIFigure
        craftEdit
        dbEdit
        previewTextArea
        visAxes
        warningsTextArea
        statusLabel
        importButton
    end

    properties (SetAccess = private)
        lvdData
    end

    properties (Access = private)
        currentSpec
        currentWarnings
    end

    methods (Static)
        function launch(lvdData)
            lvd_ImportCraftGUI_App(lvdData);
        end
    end

    methods
        function obj = lvd_ImportCraftGUI_App(lvdData)
            obj.lvdData = lvdData;
            obj.currentSpec = [];
            obj.currentWarnings = {};

            obj.buildUI();
            uiwait(obj.UIFigure);
        end
    end

    methods (Access = private)
        function buildUI(obj)
            % Center the window on screen, clamp to display, and make it
            % modal so the main LVD window cannot be interacted with while
            % the importer is open.
            screenSize = get(0, 'ScreenSize');
            figW = min(1200, screenSize(3) - 40);
            figH = min(720, screenSize(4) - 80);
            figX = max(20, floor((screenSize(3) - figW) / 2));
            figY = max(20, floor((screenSize(4) - figH) / 2));

            fig = uifigure('Name', 'Import Craft File', ...
                           'Position', [figX, figY, figW, figH], ...
                           'WindowStyle', 'modal');
            try
                fig.Icon = 'ksptot_logo4_transparent.png';
            catch
            end
            obj.UIFigure = fig;

            grid = uigridlayout(fig, [8, 3]);
            grid.RowSpacing = 8;
            grid.ColumnSpacing = 8;
            grid.Padding = 12;
            grid.RowHeight = {22, 22, 22, 22, '1x', 22, 90, 34};
            grid.ColumnWidth = {110, '1x', 235};

            h = uilabel(grid);
            h.Text = 'Craft file:';
            h.FontWeight = 'bold';
            h.Layout.Row = 1;
            h.Layout.Column = 1;

            obj.craftEdit = uieditfield(grid, 'text');
            obj.craftEdit.Editable = false;
            obj.craftEdit.Layout.Row = 1;
            obj.craftEdit.Layout.Column = 2;

            h = uibutton(grid);
            h.Text = 'Browse...';
            h.ButtonPushedFcn = @(~, ~) obj.browseForCraft();
            h.Layout.Row = 1;
            h.Layout.Column = 3;

            h = uilabel(grid);
            h.Text = 'Part database:';
            h.FontWeight = 'bold';
            h.Layout.Row = 2;
            h.Layout.Column = 1;

            % Robust bundled path that survives MATLAB Compiler (see
            % lvd_import_getPartDatabase.getBundledDbPath)
            try
                tmpDB = lvd_import_getPartDatabase();
                defaultDB = tmpDB.sourcePath;
            catch
                defaultDB = fullfile(fileparts(mfilename('fullpath')), 'resources', 'partsDatabaseStockKSP.json');
            end
            if(~isfile(defaultDB))
                defaultDB = fullfile(fileparts(mfilename('fullpath')), 'resources', 'partsDatabaseStockKSP.json');
            end
            obj.dbEdit = uieditfield(grid, 'text');
            obj.dbEdit.Value = defaultDB;
            obj.dbEdit.Tooltip = 'Path to a .json/.mat database or a GameData/KSP root folder. Leave as bundled default for stock KSP (partsDatabaseStockKSP.json).';
            obj.dbEdit.Layout.Row = 2;
            obj.dbEdit.Layout.Column = 2;

            dbBtnGrid = uigridlayout(grid, [1, 2]);
            dbBtnGrid.Layout.Row = 2;
            dbBtnGrid.Layout.Column = 3;
            dbBtnGrid.RowHeight = {22};
            dbBtnGrid.ColumnWidth = {115, 115};
            dbBtnGrid.Padding = [0, 0, 0, 0];
            dbBtnGrid.ColumnSpacing = 5;

            h = uibutton(dbBtnGrid);
            h.Text = 'File...';
            h.Tooltip = 'Select a .json or .mat part database file';
            h.ButtonPushedFcn = @(~, ~) obj.browseForDatabaseFile();
            h.Layout.Row = 1;
            h.Layout.Column = 1;

            h = uibutton(dbBtnGrid);
            h.Text = 'Folder...';
            h.Tooltip = 'Select a GameData or KSP install folder';
            h.ButtonPushedFcn = @(~, ~) obj.browseForDatabaseFolder();
            h.Layout.Row = 1;
            h.Layout.Column = 2;

            h = uibutton(grid);
            h.Text = 'Export GameData to JSON...';
            h.Tooltip = 'Scan a GameData folder and save a portable .json database for future use';
            h.ButtonPushedFcn = @(~, ~) obj.exportGameData();
            h.Layout.Row = 3;
            h.Layout.Column = [2, 3];

            h = uilabel(grid);
            h.Text = 'Preview:';
            h.FontWeight = 'bold';
            h.Layout.Row = 4;
            h.Layout.Column = 1;

            previewContainer = uigridlayout(grid, [1, 2]);
            previewContainer.Layout.Row = 5;
            previewContainer.Layout.Column = [1, 3];
            previewContainer.RowHeight = {'1x'};
            previewContainer.ColumnWidth = {'1x', '1x'};
            previewContainer.Padding = [0, 0, 0, 0];
            previewContainer.ColumnSpacing = 8;
            previewContainer.RowSpacing = 0;

            obj.previewTextArea = uitextarea(previewContainer);
            obj.previewTextArea.Editable = false;
            obj.previewTextArea.FontName = 'FixedWidth';
            obj.previewTextArea.Layout.Row = 1;
            obj.previewTextArea.Layout.Column = 1;

            axesPaddingGrid = uigridlayout(previewContainer, [1, 1]);
            axesPaddingGrid.Layout.Row = 1;
            axesPaddingGrid.Layout.Column = 2;
            axesPaddingGrid.Padding = [45, 10, 10, 40];

            obj.visAxes = uiaxes(axesPaddingGrid);
            obj.visAxes.Layout.Row = 1;
            obj.visAxes.Layout.Column = 1;
            obj.visAxes.XGrid = 'on';
            obj.visAxes.YGrid = 'on';
            obj.visAxes.ZGrid = 'on';
            obj.visAxes.Box = 'on';
            obj.visAxes.Title.String = '3D Vehicle Layout';
            obj.visAxes.Title.FontWeight = 'bold';
            view(obj.visAxes, 28, 18);
            axis(obj.visAxes, 'vis3d');
            obj.clearVisualization();

            h = uilabel(grid);
            h.Text = 'Warnings:';
            h.FontWeight = 'bold';
            h.Layout.Row = 6;
            h.Layout.Column = 1;

            obj.warningsTextArea = uitextarea(grid);
            obj.warningsTextArea.Editable = false;
            obj.warningsTextArea.Layout.Row = 7;
            obj.warningsTextArea.Layout.Column = [1, 3];

            obj.statusLabel = uilabel(grid);
            obj.statusLabel.Text = 'Select a .craft file to analyze.';
            obj.statusLabel.FontAngle = 'italic';
            obj.statusLabel.Layout.Row = 8;
            obj.statusLabel.Layout.Column = [1, 2];

            btnGrid = uigridlayout(grid, [1, 2]);
            btnGrid.ColumnWidth = {110, 110};
            btnGrid.RowHeight = {34};
            btnGrid.Layout.Row = 8;
            btnGrid.Layout.Column = 3;
            btnGrid.Padding = [0, 0, 0, 0];
            btnGrid.ColumnSpacing = 6;

            obj.importButton = uibutton(btnGrid);
            obj.importButton.Text = 'Import';
            obj.importButton.FontWeight = 'bold';
            obj.importButton.Enable = 'off';
            obj.importButton.ButtonPushedFcn = @(~, ~) obj.doImport();
            obj.importButton.Layout.Row = 1;
            obj.importButton.Layout.Column = 1;

            h = uibutton(btnGrid);
            h.Text = 'Close';
            h.ButtonPushedFcn = @(~, ~) delete(obj.UIFigure);
            h.Layout.Row = 1;
            h.Layout.Column = 2;
        end

        function browseForCraft(obj)
            [fileName, pathName] = uigetfile('*.craft', ...
                'Select KSP Craft File');
            if(isequal(fileName, 0))
                return;
            end

            craftPath = fullfile(pathName, fileName);
            obj.craftEdit.Value = craftPath;
            obj.analyzeCurrentCraft();
        end

        function browseForDatabase(obj)
            % Legacy entry point — delegates to file picker for backward
            % compatibility.
            obj.browseForDatabaseFile();
        end

        function browseForDatabaseFile(obj)
            [fileName, pathName] = uigetfile({'*.json;*.mat', ...
                'Part Database (*.json, *.mat)'}, 'Select Part Database File');
            if(isequal(fileName, 0))
                return;
            end

            obj.dbEdit.Value = fullfile(pathName, fileName);
            if(~isempty(obj.craftEdit.Value))
                obj.analyzeCurrentCraft();
            end
        end

        function browseForDatabaseFolder(obj)
            folder = uigetdir('', 'Select GameData or KSP Install Folder');
            if(isequal(folder, 0) || isempty(folder))
                return;
            end

            obj.dbEdit.Value = folder;
            if(~isempty(obj.craftEdit.Value))
                obj.analyzeCurrentCraft();
            end
        end

        function exportGameData(obj)
            startPath = '';
            if(~isempty(obj.dbEdit.Value) && isfolder(obj.dbEdit.Value))
                startPath = obj.dbEdit.Value;
            elseif(~isempty(obj.dbEdit.Value) && isfile(obj.dbEdit.Value))
                startPath = fileparts(obj.dbEdit.Value);
            end
            gameDataPath = uigetdir(startPath, 'Select GameData Folder to Export');
            if(isequal(gameDataPath, 0) || isempty(gameDataPath))
                return;
            end
            if(isfolder(fullfile(gameDataPath, 'GameData')))
                gameDataPath = fullfile(gameDataPath, 'GameData');
            end
            % Validate that it looks like a GameData folder
            if(~isfolder(fullfile(gameDataPath, 'Squad')) && isempty(dir(fullfile(gameDataPath, '**', '*.cfg'))))
                choice = questdlg(sprintf('Selected folder does not look like a GameData folder (no Squad subfolder and no .cfg files found):\n%s\n\nContinue anyway?', gameDataPath), 'Invalid GameData Folder', 'Pick Again', 'Cancel', 'Cancel');
                if(strcmp(choice, 'Pick Again'))
                    obj.exportGameData();
                    return;
                else
                    return;
                end
            end
            [outFile, outPath] = uiputfile({'*.json','JSON Database (*.json)';'*.mat','MAT Database (*.mat)'}, 'Save Part Database As', fullfile(fileparts(mfilename('fullpath')), 'resources', 'ksp_parts_export.json'));
            if(isequal(outFile, 0))
                return;
            end
            outFull = fullfile(outPath, outFile);
            obj.statusLabel.Text = 'Exporting GameData...';
            drawnow;
            try
                [db, w] = lvd_import_getPartDatabase(gameDataPath);
                if(db.parts.Count == 0)
                    errordlg(sprintf('No PART definitions found in %s.\n\nThis folder does not appear to contain valid part configs (expected GameData/Squad/Parts/**/*.cfg).\n\nWarnings:\n%s', gameDataPath, strjoin(w, newline)), 'Export Failed');
                    obj.statusLabel.Text = 'Export failed: no parts found';
                    obj.warningsTextArea.Value = w;
                    return;
                end
                [~,~,ext] = fileparts(outFull);
                if(strcmpi(ext, '.json'))
                    s = struct();
                    s.schemaVersion = 1;
                    s.databaseName = sprintf('GameData export %s', datestr(now));
                    s.gameVersion = '1.12';
                    s.description = sprintf('Exported from %s on %s', gameDataPath, datestr(now));
                    dens = db.resourceDensities;
                    densStruct = struct();
                    dKeys = keys(dens);
                    for(kk = 1:numel(dKeys))
                        densStruct.(dKeys{kk}) = dens(dKeys{kk});
                    end
                    s.resourceDensities_t_per_unit = densStruct;
                    pKeys = keys(db.parts);
                    partsArr = struct('name', {}, 'title', {}, 'mass_t', {}, 'roles', {}, 'resources_u', {}, 'engines', {});
                    seenNames = containers.Map('KeyType','char','ValueType','logical');
                    for(kk = 1:numel(pKeys))
                        entry = db.parts(pKeys{kk});
                        key = lower(entry.name);
                        if(isKey(seenNames, key))
                            continue;
                        end
                        seenNames(key) = true;
                        partsArr(end+1) = entry; %#ok<AGROW>
                    end
                    s.parts = partsArr;
                    jsonStr = jsonencode(s, 'PrettyPrint', true);
                    fid = fopen(outFull, 'w');
                    fprintf(fid, '%s', jsonStr);
                    fclose(fid);
                else
                    partDB = db;
                    save(outFull, 'partDB');
                end
                obj.dbEdit.Value = outFull;
                obj.statusLabel.Text = sprintf('Exported %d parts to %s (%d warnings)', db.parts.Count, outFull, numel(w));
                if(~isempty(w))
                    obj.warningsTextArea.Value = w;
                else
                    obj.warningsTextArea.Value = {'Export succeeded.'};
                end
                drawnow;
            catch ME
                obj.statusLabel.Text = ['Export failed: ' ME.message];
                obj.warningsTextArea.Value = {ME.message};
                errordlg(ME.message, 'Export Failed');
            end
        end
    end

    methods (Access = public)
        function clearVisualization(obj)
            if(isempty(obj.visAxes) || ~isvalid(obj.visAxes))
                return;
            end
            cla(obj.visAxes);
            hold(obj.visAxes, 'on');
            text(obj.visAxes, 0.5, 0.5, 0.5, 'No vehicle loaded', ...
                'HorizontalAlignment', 'center', 'FontAngle', 'italic', ...
                'Color', [0.5 0.5 0.5]);
            obj.visAxes.XLim = [0 1];
            obj.visAxes.YLim = [0 1];
            obj.visAxes.ZLim = [0 1];
            view(obj.visAxes, 35, 22);
            obj.visAxes.Visible = 'on';
            grid(obj.visAxes, 'on');
        end

        function updateVisualization(obj, spec, ~)
            if(isempty(obj.visAxes) || ~isvalid(obj.visAxes))
                return;
            end
            ax = obj.visAxes;
            cla(ax);
            hold(ax, 'on');

            if(isempty(spec) || ~isfield(spec, 'stages') || isempty(spec.stages))
                obj.clearVisualization();
                return;
            end

            numStages = numel(spec.stages);
            % Vertical stacking: bottom stage (Stage 1, first to burn) at bottom,
            % top stage (payload) at top — as the rocket sits on the pad.
            stageHeight = 7;
            % Determine max prop mass for tank height scaling
            allPropMasses = [];
            for(s = 1:numStages)
                for(t = 1:numel(spec.stages(s).tanks))
                    allPropMasses(end+1) = spec.stages(s).tanks(t).propMass_mT; %#ok<AGROW>
                end
            end
            maxPropMass = max([allPropMasses, 1]);

            % Stage colors
            stageColors = lines(max(numStages, 7));
            stageColors = stageColors(1:numStages, :);

            % Storage for connection endpoints
            tankPositions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            enginePositions = containers.Map('KeyType', 'char', 'ValueType', 'any');

            % Layout: Z = stage stack (vertical), X = lateral spread within stage, Y = depth (fixed)
            for(s = 1:numStages)
                stg = spec.stages(s);
                % Map stage order bottom->top: Stage 1 at bottom (z=0), last stage at top
                stageBaseZ = (s-1) * stageHeight;
                nTanks = numel(stg.tanks);
                nEngines = numel(stg.engines);

                % X positions for tanks and engines (lateral spread)
                if(nTanks > 0)
                    if(nTanks == 1)
                        xTanks = 0;
                    else
                        xTanks = linspace(-1.6, 1.6, nTanks);
                    end
                else
                    xTanks = [];
                end

                if(nEngines > 0)
                    if(nEngines == 1)
                        xEngines = 0;
                    else
                        xEngines = linspace(-1.2, 1.2, nEngines);
                    end
                else
                    xEngines = [];
                end

                % Decide X extent for stage bounding box
                allX = [xTanks, xEngines];
                if(isempty(allX))
                    xMin = -1.5; xMax = 1.5;
                else
                    xMin = min(allX) - 1.0;
                    xMax = max(allX) + 1.0;
                end

                % Draw stage bounding box (transparent) — stacked vertically
                obj.drawStageBox(ax, stageBaseZ, xMin, xMax, stageColors(s, :));

                % Draw tanks (stacked at top of stage volume)
                for(t = 1:nTanks)
                    tnk = stg.tanks(t);
                    x = xTanks(t);
                    y = 0;
                    heightScale = 0.7 + 1.3 * (tnk.propMass_mT / maxPropMass);
                    % Tank center within stage
                    zCenter = stageBaseZ + 4.2;
                    fluidColor = obj.getFluidColor(tnk.fluidTypeName);
                    fluidColor = fluidColor * 0.9 + stageColors(s, :) * 0.1;
                    obj.drawTank(ax, x, y, zCenter, fluidColor, heightScale, 0.65);
                    tankKey = sprintf('%d_%d', s, t);
                    tankPositions(tankKey) = struct('x', x, 'y', y, 'zBottom', zCenter - 0.8*heightScale, 'zTop', zCenter + 0.8*heightScale, 'id', tnk.instanceID);
                    % Label grows outward, away from the stack centerline,
                    % so it never crosses the neighboring hardware; XLim is
                    % widened to leave room for the longest names.
                    if(x < 0)
                        text(ax, x-0.85, y, zCenter, strrep(tnk.name,'_','\_'), 'FontSize', 6, 'HorizontalAlignment', 'right', 'Color', [0.85 0.85 0.85]);
                    else
                        text(ax, x+0.85, y, zCenter, strrep(tnk.name,'_','\_'), 'FontSize', 6, 'HorizontalAlignment', 'left', 'Color', [0.85 0.85 0.85]);
                    end
                end

                % Draw engines (at bottom of stage volume)
                for(e = 1:nEngines)
                    eng = stg.engines(e);
                    x = xEngines(e);
                    y = 0;
                    zBase = stageBaseZ + 0.6;
                    engColor = [0.85 0.20 0.20];
                    engColor = engColor * 0.85 + stageColors(s, :) * 0.15;
                    obj.drawEngine(ax, x, y, zBase, engColor);
                    engKey = sprintf('%d_%d', s, e);
                    enginePositions(engKey) = struct('x', x, 'y', y, 'zTop', zBase+0.9, 'zBottom', zBase-0.6);
                    if(x < 0)
                        text(ax, x-0.85, y, zBase-0.6, strrep(eng.name,'_','\_'), 'FontSize', 6, 'HorizontalAlignment', 'right', 'Color', [1 0.7 0.7]);
                    else
                        text(ax, x+0.85, y, zBase-0.6, strrep(eng.name,'_','\_'), 'FontSize', 6, 'HorizontalAlignment', 'left', 'Color', [1 0.7 0.7]);
                    end
                end

                % Stage caption centered in the gap above the stage box so
                % it can never clip at the container edges.
                text(ax, 0, 0, stageBaseZ + 5.95, ...
                    sprintf('Stage %d  (dry %.2f mT)', s, stg.dryMass_mT), ...
                    'FontSize', 7, 'HorizontalAlignment', 'center', ...
                    'Color', stageColors(s, :)*0.55 + [0.35 0.35 0.35]);
            end

            % Draw engine-to-tank connections (within each stage) — vertical green lines
            for(s = 1:numStages)
                stg = spec.stages(s);
                for(c = 1:numel(stg.e2tConns))
                    conn = stg.e2tConns(c);
                    tKey = sprintf('%d_%d', s, conn.tankIdx);
                    eKey = sprintf('%d_%d', s, conn.engineIdx);
                    if(isKey(tankPositions, tKey) && isKey(enginePositions, eKey))
                        tPos = tankPositions(tKey);
                        ePos = enginePositions(eKey);
                        plot3(ax, [tPos.x, ePos.x], [tPos.y, ePos.y], [tPos.zBottom, ePos.zTop], 'Color', [0.2 0.85 0.25], 'LineWidth', 1.6, 'LineStyle', '-');
                        plot3(ax, tPos.x, tPos.y, tPos.zBottom, 'o', 'MarkerFaceColor', [0.2 0.85 0.25], 'MarkerEdgeColor', 'none', 'MarkerSize', 4);
                        plot3(ax, ePos.x, ePos.y, ePos.zTop, 'o', 'MarkerFaceColor', [0.85 0.2 0.2], 'MarkerEdgeColor', 'none', 'MarkerSize', 4);
                    end
                end
            end

            % Draw tank-to-tank connections (crossfeed/asparagus) — orange dashed arch between stages
            for(c = 1:numel(spec.t2tConns))
                conn = spec.t2tConns(c);
                srcKey = sprintf('%d_%d', conn.srcStageIdx, conn.srcTankIdx);
                tgtKey = sprintf('%d_%d', conn.tgtStageIdx, conn.tgtTankIdx);
                if(isKey(tankPositions, srcKey) && isKey(tankPositions, tgtKey))
                    sPos = tankPositions(srcKey);
                    tPos = tankPositions(tgtKey);
                    nPts = 24;
                    xs = linspace(sPos.x, tPos.x, nPts);
                    % Arch bulges outward in Y to stay visible outside the stack
                    ys = 0.9*sin(linspace(0, pi, nPts));
                    zs = linspace(sPos.zTop, tPos.zTop, nPts);
                    % Add slight outward bulge in X as well for diagonal crossfeed
                    plot3(ax, xs, ys, zs, 'Color', [0.95 0.55 0.05], 'LineWidth', 2.2, 'LineStyle', '--');
                    plot3(ax, tPos.x, tPos.y, tPos.zTop, '^', 'MarkerFaceColor', [0.95 0.55 0.05], 'MarkerEdgeColor', 'none', 'MarkerSize', 7);
                    % Flow label midpoint
                    midIdx = round(nPts/2);
                    text(ax, xs(midIdx), ys(midIdx)+0.3, zs(midIdx)+0.2, sprintf('%.3f mT/s', conn.flowRate_mTs), 'FontSize', 6, 'Color', [0.9 0.55 0.05], 'HorizontalAlignment', 'center');
                end
            end

            % Final axes setup — Z is vertical stage axis.
            % Generous limits on every axis: with axis vis3d the projected
            % 3D box must never touch the component edges, and MATLAB's
            % default 'outerposition' behavior reserves margin for the
            % title/tick labels inside the uiaxes.
            zTop = (numStages-1)*stageHeight + 6;
            ax.XLim = [-5.8, 5.8];
            ax.YLim = [-3.2, 3.2];
            ax.ZLim = [-3.6, zTop + 3.0];
            ax.XTick = [];
            ax.YTick = [];
            ax.ZTick = arrayfun(@(s) (s-1)*stageHeight + 2.2, 1:numStages);
            ax.ZTickLabel = arrayfun(@(s) sprintf('Stage %d', s), 1:numStages, 'UniformOutput', false);
            ax.ZLabel.String = 'Vehicle Stack (bottom = Stage 1)';
            ax.ZLabel.FontWeight = 'bold';
            ax.XLabel.String = '';
            ax.YLabel.String = '';

            % axis vis3d fits the projected plot box flush against the
            % component edges. Pull the camera back ~20% so the stack
            % floats with margin on all sides; this survives toolbar
            % rotation because the angle stays manually pinned.
            ax.CameraViewAngleMode = 'manual';
            ax.CameraViewAngle = ax.CameraViewAngle * 0.80;
            grid(ax, 'on');
            ax.Box = 'on';
            % Lighting
            try
                light(ax, 'Position', [5 5 8], 'Style', 'infinite');
                light(ax, 'Position', [-4 4 6], 'Style', 'infinite');
                lighting(ax, 'gouraud');
                material(ax, 'dull');
            catch
            end
            camzoom(ax, 0.85);
            hold(ax, 'off');

            % 1. Get the current automatically calculated limits
            xLimits = ax.XLim;
            yLimits = ax.YLim;
            zLimits = ax.ZLim;

            % 2. Calculate the center point of each axis
            xMid = mean(xLimits);
            yMid = mean(yLimits);
            zMid = mean(zLimits);

            % 3. Find the maximum range among the three axes
            maxRange = max([diff(xLimits), diff(yLimits), diff(zLimits)]);
            halfRange = maxRange / 2;

            % 4. Apply new limits to form a perfect cube
            ax.XLim = [xMid - halfRange, xMid + halfRange];
            ax.YLim = [yMid - halfRange, yMid + halfRange];
            ax.ZLim = [zMid - halfRange, zMid + halfRange];

            % 5. Finally, apply vis3d to lock the aspect ratio and camera
            view(ax, 28, 18);
            axis(ax, 'vis3d');
            ax.ClippingStyle = 'rectangle';
        end

        function analyzeCurrentCraft(obj)
            obj.statusLabel.Text = 'Analyzing...';
            drawnow();

            try
                dbPath = strtrim(obj.dbEdit.Value);
                if(strcmp(dbPath, ''))
                    partDB = lvd_import_getPartDatabase();
                else
                    try
                        partDB = lvd_import_getPartDatabase(dbPath);
                    catch ME
                        % Old bundled file (ksp_stock_parts_112.json) was removed;
                        % fall back to new stock DB if the saved path is stale.
                        if(contains(ME.message, 'ksp_stock_parts_112') || contains(ME.message, 'not found'))
                            partDB = lvd_import_getPartDatabase();
                        else
                            rethrow(ME);
                        end
                    end
                end

                [spec, report] = lvd_import_analyzeCraft( ...
                    obj.craftEdit.Value, partDB);

                obj.currentSpec = spec;
                obj.currentWarnings = spec.warnings;
                obj.previewTextArea.Value = obj.buildPreviewLines(spec, report);
                obj.warningsTextArea.Value = obj.formatWarnings(spec.warnings);
                obj.updateVisualization(spec, report);
                drawnow();
                obj.importButton.Enable = 'on';
                obj.statusLabel.Text = sprintf(['Analysis complete: %d ' ...
                    'stage(s), GLOW %.3f mT. Review, then click Import.'], ...
                    spec.stats.numStages, spec.stats.glow_mT);
            catch ME
                obj.currentSpec = [];
                obj.importButton.Enable = 'off';
                obj.previewTextArea.Value = {'Analysis failed.'};
                obj.warningsTextArea.Value = {ME.message};
                obj.clearVisualization();
                drawnow();
                obj.statusLabel.Text = 'Analysis failed - see the warnings pane.';
            end
        end

        function doImport(obj)
            if(isempty(obj.currentSpec))
                return;
            end

            try
                newLv = lvd_import_createLaunchVehicle(obj.lvdData, ...
                                                       obj.currentSpec);
                obj.lvdData = lvd_import_applyToLvdData(obj.lvdData, ...
                                                        newLv);

                fprintf(['Imported "%s" into LVD data: %d stage(s), ' ...
                         '%d engine(s), %d tank(s), GLOW = %.3f mT.\n'], ...
                        obj.currentSpec.name, ...
                        obj.currentSpec.stats.numStages, ...
                        obj.currentSpec.stats.numEngines, ...
                        obj.currentSpec.stats.numTanks, ...
                        obj.currentSpec.stats.glow_mT);

                obj.statusLabel.Text = 'Import complete. Vehicle installed.';
                obj.importButton.Enable = 'off';
            catch ME
                obj.statusLabel.Text = ['Import failed: ' ME.message];
            end
        end
    end

    methods (Access = private)
        function lines = buildPreviewLines(~, spec, report)
            lines = {};

            lines{end+1} = sprintf('Vessel: %s', spec.name); %#ok<AGROW>
            lines{end+1} = sprintf(['GLOW %.3f mT (dry %.3f + prop ' ...
                                    '%.3f)'], spec.stats.glow_mT, ...
                                   spec.stats.totalDryMass_mT, ...
                                   spec.stats.totalPropMass_mT); %#ok<AGROW>
            lines{end+1} = ''; %#ok<AGROW>

            for(s = 1:numel(spec.stages))
                stg = spec.stages(s);
                lines{end+1} = sprintf(... %#ok<AGROW>
                    '%s: dry %.3f mT, %d engine(s), %d tank(s)', ...
                    stg.name, stg.dryMass_mT, numel(stg.engines), ...
                    numel(stg.tanks));

                for(e = 1:numel(stg.engines))
                    eng = stg.engines(e);
                    lines{end+1} = sprintf(... %#ok<AGROW>
                        '    [E] %-34s %7.1f kN  Isp %4.0f/%4.0f s', ...
                        eng.name, eng.vacThrust_kN, eng.ispVac_s, ...
                        eng.ispSL_s);
                end

                for(t = 1:numel(stg.tanks))
                    tnk = stg.tanks(t);
                    lines{end+1} = sprintf(... %#ok<AGROW>
                        '    [T] %-34s %-16s %7.3f mT', ...
                        tnk.name, tnk.fluidTypeName, tnk.propMass_mT);
                end
                % Dry mass breakdown — which KSP parts were imported for this stage
                if(isfield(stg, 'parts') && ~isempty(stg.parts))
                    lines{end+1} = sprintf('    Dry parts (%.3f mT):', stg.dryMass_mT); %#ok<AGROW>
                    partMap = containers.Map('KeyType','char','ValueType','any');
                    for(pIdx = 1:numel(stg.parts))
                        pp = stg.parts(pIdx);
                        key = lower(pp.partName);
                        if(isKey(partMap, key))
                            entry = partMap(key);
                            entry.count = entry.count + 1;
                            entry.totalMass = entry.totalMass + pp.mass_t;
                            partMap(key) = entry;
                        else
                            partMap(key) = struct('displayName', pp.displayName, 'partName', pp.partName, 'count', 1, 'massEach', pp.mass_t, 'totalMass', pp.mass_t, 'roles', {pp.roles});
                        end
                    end
                    pKeys = keys(partMap);
                    for(kk = 1:numel(pKeys))
                        entry = partMap(pKeys{kk});
                        rolesStr = strjoin(entry.roles, ',');
                        if(entry.count == 1)
                            lines{end+1} = sprintf('      - %s (%s) %.3f mT [%s]', entry.displayName, entry.partName, entry.massEach, rolesStr); %#ok<AGROW>
                        else
                            lines{end+1} = sprintf('      - %s (%s) x%d  %.3f mT each, %.3f mT total [%s]', entry.displayName, entry.partName, entry.count, entry.massEach, entry.totalMass, rolesStr); %#ok<AGROW>
                        end
                    end
                end
            end

            for(c = 1:numel(spec.t2tConns))
                conn = spec.t2tConns(c);
                srcTank = spec.stages(conn.srcStageIdx).tanks(conn.srcTankIdx);
                tgtTank = spec.stages(conn.tgtStageIdx).tanks(conn.tgtTankIdx);
                lines{end+1} = sprintf(... %#ok<AGROW>
                    '    [X] Crossfeed: %s -> %s (%.4f mT/s)', ...
                    srcTank.name, tgtTank.name, conn.flowRate_mTs);
            end

            if(~isempty(report.unresolvedParts))
                lines{end+1} = ''; %#ok<AGROW>
                lines{end+1} = sprintf('Unknown parts: %s', ... %#ok<AGROW>
                    strjoin(unique(report.unresolvedParts), ', '));
            end
        end

        function out = formatWarnings(~, warningCell)
            if(isempty(warningCell))
                out = {'None.'};
            else
                out = warningCell;
            end
        end

        function color = getFluidColor(~, fluidTypeName)
            switch(fluidTypeName)
                case 'Solid Fuel'
                    color = [0.62 0.62 0.62];
                case 'Liquid Fuel/Ox'
                    color = [0.00 0.45 0.74];
                case 'Monopropellant'
                    color = [0.47 0.67 0.19];
                case 'Xenon'
                    color = [0.58 0.40 0.74];
                otherwise
                    color = [0.80 0.80 0.80];
            end
        end

        function drawTank(obj, ax, x0, y0, z0, faceColor, heightScale, radius)
            if(nargin < 7), heightScale = 1.0; end
            if(nargin < 8), radius = 0.6; end
            height = 1.6 * heightScale;
            nFacets = 18;
            [cx, cy, cz] = cylinder(radius, nFacets);
            cz = cz * height;
            % Translate
            X = cx + x0;
            Y = cy + y0;
            Z = cz + z0 - height/2;
            surf(ax, X, Y, Z, 'FaceColor', faceColor, 'EdgeColor', 'none', 'FaceAlpha', 0.92, 'FaceLighting', 'gouraud', 'AmbientStrength', 0.6, 'DiffuseStrength', 0.7);
            % Caps
            theta = linspace(0, 2*pi, nFacets+1);
            xt = radius*cos(theta) + x0;
            yt = radius*sin(theta) + y0;
            % Top cap
            patch(ax, 'XData', xt, 'YData', yt, 'ZData', ones(size(xt))*(z0+height/2), 'FaceColor', faceColor*0.85, 'EdgeColor', 'none', 'FaceAlpha', 0.92);
            % Bottom cap
            patch(ax, 'XData', xt, 'YData', yt, 'ZData', ones(size(xt))*(z0-height/2), 'FaceColor', faceColor*0.75, 'EdgeColor', 'none', 'FaceAlpha', 0.92);
            % Outline
            plot3(ax, xt, yt, ones(size(xt))*(z0+height/2), 'Color', faceColor*0.5, 'LineWidth', 0.5);
        end

        function drawEngine(obj, ax, x0, y0, z0, faceColor)
            % Simple engine: cylinder base + cone nozzle
            cylRadius = 0.28;
            cylHeight = 0.45;
            [cx, cy, cz] = cylinder(cylRadius, 16);
            cz = cz * cylHeight;
            surf(ax, cx+x0, cy+y0, cz+z0, 'FaceColor', faceColor, 'EdgeColor', 'none', 'FaceAlpha', 0.95, 'FaceLighting', 'gouraud');
            % Nozzle cone (tapering outward downward)
            [cx2, cy2, cz2] = cylinder([cylRadius*1.8, 0.15], 16);
            cz2 = cz2 * 0.85;
            % Place below cylinder
            surf(ax, cx2+x0, cy2+y0, cz2+z0 - 0.85, 'FaceColor', faceColor*0.7, 'EdgeColor', 'none', 'FaceAlpha', 0.95, 'FaceLighting', 'gouraud');
            % Engine top plate
            theta = linspace(0, 2*pi, 17);
            xt = cylRadius*cos(theta)+x0;
            yt = cylRadius*sin(theta)+y0;
            patch(ax, 'XData', xt, 'YData', yt, 'ZData', ones(size(xt))*(z0+cylHeight), 'FaceColor', faceColor*1.1, 'EdgeColor', 'none', 'FaceAlpha', 0.95);
        end

        function drawStageBox(obj, ax, stageBaseZ, xMin, xMax, baseColor)
            yMin = -1.1;
            yMax =  1.1;
            zMin = stageBaseZ - 0.8;
            zMax = stageBaseZ + 5.4;
            verts = [xMin yMin zMin; xMax yMin zMin; xMax yMax zMin; xMin yMax zMin; ...
                     xMin yMin zMax; xMax yMin zMax; xMax yMax zMax; xMin yMax zMax];
            faces = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 1 2 3 4; 5 6 7 8];
            lightColor = baseColor*0.15 + 0.85;
            patch(ax, 'Vertices', verts, 'Faces', faces, 'FaceColor', lightColor, 'FaceAlpha', 0.09, 'EdgeColor', baseColor*0.55, 'LineWidth', 0.9, 'LineStyle', '--');
            % Thin separator at stage boundary (decoupler plane)
            if(stageBaseZ > 0.5)
                sepZ = stageBaseZ - 0.4;
                sepVerts = [xMin yMin sepZ; xMax yMin sepZ; xMax yMax sepZ; xMin yMax sepZ];
                patch(ax, 'Vertices', sepVerts, 'Faces', [1 2 3 4], 'FaceColor', [0.3 0.3 0.3], 'FaceAlpha', 0.18, 'EdgeColor', 'none');
            end
        end
    end
end
