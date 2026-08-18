function util_logAppend(logFile, txt)
%UTIL_LOGAPPEND  Append text to a run log, flushing immediately.
%   adamnlopt.util_logAppend(logFile, txt) appends TXT to the file LOGFILE,
%   opening and closing the file on every call so the bytes are on disk before
%   the function returns. LOGFILE empty is a no-op, which is how callers disable
%   file logging.
%
%   Opening per call (rather than holding a handle open for the whole solve) is
%   deliberate: a long solve that is interrupted with Ctrl-C, killed, or errors
%   out still leaves a complete log up to the last line written. Holding a
%   handle and relying on a close at the end loses everything on interrupt --
%   the failure mode that made earlier long runs undiagnosable. The fopen/fclose
%   cost is negligible against a solver iteration.
%
%   A failure to open the log warns ONCE per session rather than on every
%   iteration, so a bad path cannot bury the solver's own output.
%
%   Inputs:
%     logFile - char path to the log file, or '' to disable logging.
%     txt     - char text to append, written verbatim (no newline is added).
%
%   Outputs:
%     (none) text is appended to LOGFILE.
%
%   See also UTIL_LOGGER, DIAGNOSE.

persistent warned
if isempty(logFile) || isempty(txt)
    return;
end
fid = fopen(logFile, 'a');
if fid < 0
    if isempty(warned)
        warned = true;
        warning('adamnlopt:logOpenFailed', ...
                'Could not open log file ''%s''; continuing without file logging.', logFile);
    end
    return;
end
closer = onCleanup(@() fclose(fid));  % closes even if fwrite errors
fwrite(fid, txt);
end
