function [times, rvVects] = lvd_readEphemerisCsv(filePath)
%LVD_READEPHEMERISCSV Reads a time-tagged Cartesian ephemeris table from a text file.
%
%   [times, rvVects] = lvd_readEphemerisCsv(filePath) parses a file whose
%   data lines hold seven numbers: UT (sec), x, y, z (km), vx, vy, vz
%   (km/s).  Values may be separated by commas, semicolons, tabs or
%   spaces.  Lines that are blank, start with '#' or '%', or do not
%   contain seven numeric values (for example a header line) are skipped.
%   Extra trailing columns beyond the seventh are ignored so files written
%   by lvd_exportEphemeris (which append mass and event number) read back.
%
%   times   - 1xN double, strictly increasing (duplicate epochs keep the
%             first occurrence)
%   rvVects - 6xN double, [x;y;z;vx;vy;vz] aligned with times
%
%   An error is raised when the file cannot be read or holds no data rows.

    arguments
        filePath(1,:) char
    end

    if(not(isfile(filePath)))
        error('lvd_readEphemerisCsv:fileNotFound', 'Ephemeris file not found: %s', filePath);
    end

    txt = fileread(filePath);
    lines = regexp(txt, '\r\n|\n|\r', 'split');

    rows = zeros(0, 7);
    for(i=1:numel(lines)) %#ok<*NO4LP>
        line = strtrim(lines{i});

        if(isempty(line) || line(1) == '#' || line(1) == '%')
            continue;
        end

        tokens = regexp(line, '[,;\t ]+', 'split');
        tokens = tokens(not(cellfun(@isempty, tokens)));

        if(numel(tokens) < 7)
            continue;
        end

        vals = str2double(tokens(1:7));
        if(any(isnan(vals)))
            continue;
        end

        rows(end+1, :) = vals; %#ok<AGROW>
    end

    if(isempty(rows))
        error('lvd_readEphemerisCsv:noData', 'No ephemeris rows (UT, x, y, z, vx, vy, vz) were found in %s', filePath);
    end

    [times, I] = unique(rows(:,1)', 'sorted');
    rvVects = rows(I, 2:7)';
end
