function numTiles = lvd_numObserveTiles(recorder)
%LVD_NUMOBSERVETILES Number of rows for the optimization observe-window layout.
%
%   numTiles = lvd_numObserveTiles(recorder) returns 4 when the recorder is
%   flagged to collect per-constraint history (variables, objective, max
%   violation, per-constraint violations) and 3 otherwise (the original
%   layout).  A TiledChartLayout cannot be resized once it holds axes, so the
%   optimizers call this when the layout is first created.

    arguments
        recorder(1,1) ma_OptimRecorder
    end

    if(recorder.expectConstraintHistory)
        numTiles = 4;
    else
        numTiles = 3;
    end
end
