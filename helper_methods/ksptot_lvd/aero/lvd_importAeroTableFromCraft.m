function result = lvd_importAeroTableFromCraft(model, craftPath, opts)
%lvd_importAeroTableFromCraft Generates aero tables and installs one into a model.
%
%   result = lvd_importAeroTableFromCraft(model, craftPath, opts)
%
%   MODEL is either a KosDragCoeffientModel (drag UI context) or a
%   UserTabulatedLiftModel (lift UI context); the matching CSV from the
%   sweep is installed directly (dataFile + reloaded interpolant), which
%   is the programmatic half of the "import table from craft file" dialog
%   buttons. The sibling CSV is still written to disk next to it, so the
%   other UI can pick it up ("both options": generate+install AND export).
%   OPTS forwards to lvd_generateAeroTablesFromCraft (grid, outDir,
%   buildOpts, ...).
%
%   RESULT is the lvd_generateAeroTablesFromCraft result plus
%   .installedCsv (the file loaded into the model).
%
%   Errors when the model class is neither supported type.
%
%   See also: lvd_generateAeroTablesFromCraft, KosDragCoeffientModel,
%   UserTabulatedLiftModel.

    if(nargin < 3)
        opts = struct();
    end

    result = lvd_generateAeroTablesFromCraft(craftPath, opts);

    if(isa(model, 'KosDragCoeffientModel'))
        csv = result.dragCsv;
    elseif(isa(model, 'UserTabulatedLiftModel'))
        csv = result.liftCsv;
    else
        error('lvd_importAeroTableFromCraft:badModel', ...
            ['Model must be a KosDragCoeffientModel (drag) or ' ...
             'UserTabulatedLiftModel (lift); got %s.'], class(model));
    end

    model.dataFile = csv;
    model.clearData();
    try
        model.createGriddedInterpFromFile();
    catch ME
        error('lvd_importAeroTableFromCraft:loadFailed', ...
            'Generated table failed to load into %s: %s', class(model), ME.message);
    end

    result.installedCsv = csv;
end
