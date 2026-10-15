classdef LvdMarkdownNotesEditor
    %LvdMarkdownNotesEditor Markdown notes editing via uihtml.
    %   Shared by the LVD mission-notes dialog and the event edit dialog.
    %   Storage stays plain char markdown (LvdData.notes, LaunchVehicleEvent.notes),
    %   so old missions load unchanged.
    %
    %   MATLAB owns the text cache in figure appdata ('LvdMarkdownNotesText');
    %   the uihtml pane renders/previews with a vendored marked.min.js (no CDN,
    %   works offline and in compiled deploys). Preview toggling is pure JS.
    %   Save paths must read getText(), never the JS DOM (async race).

    methods(Static)
        function html = ensure(textarea, initialText)
            %ensure Hide a legacy uitextarea, create the uihtml editor once.
            arguments
                textarea(1,1) matlab.ui.control.TextArea
                initialText(1,:) char = ''
            end

            fig = ancestor(textarea, 'figure');
            html = LvdMarkdownNotesEditor.getHtml(fig);
            if(~isempty(html))
                LvdMarkdownNotesEditor.setText(fig, initialText);
                return;
            end

            textarea.Visible = 'off';
            html = uihtml('Parent', textarea.Parent, ...
                'HTMLSource', LvdMarkdownNotesEditor.htmlFile(), ...
                'Data', struct('markdown', char(initialText), 'rev', int32(1)), ...
                'DataChangedFcn', @(src,evt) LvdMarkdownNotesEditor.onDataChanged(src, evt));
            try %#ok<TRYNC>
                html.Layout.Row = textarea.Layout.Row;
                html.Layout.Column = textarea.Layout.Column;
            end
            html.Tag = 'notesMarkdownHtml';

            setappdata(fig, 'LvdMarkdownNotesHtml', html);
            setappdata(fig, 'LvdMarkdownNotesText', char(initialText));
            setappdata(fig, 'LvdMarkdownNotesRev', int32(1));
        end

        function setText(fig, txt)
            %setText Push markdown source to the cache and the JS pane.
            arguments
                fig(1,1) matlab.ui.Figure
                txt(1,:) char = ''
            end

            txt = char(txt);
            html = LvdMarkdownNotesEditor.getHtml(fig);
            rev = int32(1);
            if(isappdata(fig, 'LvdMarkdownNotesRev'))
                rev = getappdata(fig, 'LvdMarkdownNotesRev') + int32(1);
            end
            setappdata(fig, 'LvdMarkdownNotesText', txt);
            setappdata(fig, 'LvdMarkdownNotesRev', rev);
            if(~isempty(html))
                html.Data = struct('markdown', txt, 'rev', rev);
            end
        end

        function txt = getText(fig)
            %getText Cached markdown source (what Save must write).
            arguments
                fig(1,1) matlab.ui.Figure
            end

            txt = '';
            if(isappdata(fig, 'LvdMarkdownNotesText'))
                txt = char(getappdata(fig, 'LvdMarkdownNotesText'));
            end
            if(isempty(txt))
                txt = '';
            end
        end

        function html = getHtml(fig)
            %getHtml The uihtml editor, or empty if not created/closed.
            arguments
                fig(1,1) matlab.ui.Figure
            end

            html = matlab.ui.control.HTML.empty(1,0);
            if(isappdata(fig, 'LvdMarkdownNotesHtml'))
                h = getappdata(fig, 'LvdMarkdownNotesHtml');
                if(~isempty(h) && isvalid(h))
                    html = h;
                end
            end
        end

        function tf = isEditorFocused(fig, textarea)
            %isEditorFocused True while typing notes (legacy box or uihtml).
            arguments
                fig(1,1) matlab.ui.Figure
                textarea(1,1) matlab.ui.control.TextArea
            end

            cur = fig.CurrentObject;
            html = LvdMarkdownNotesEditor.getHtml(fig);
            tf = isequal(cur, textarea) || (~isempty(html) && isequal(cur, html));
        end

        function f = htmlFile()
            %htmlFile Absolute path to the editor page (dev or deployed).
            thisDir = fileparts(mfilename('fullpath'));
            projRoot = fileparts(fileparts(fileparts(thisDir)));
            f = fullfile(projRoot, 'kspTOT_LaunchVehicleDesigner', 'resources', 'lvdMarkdownNotesEditor.html');
            if(~isfile(f))
                f = fullfile(ctfroot, 'kspTOT_LaunchVehicleDesigner', 'resources', 'lvdMarkdownNotesEditor.html');
            end
        end

        function onDataChanged(src, evt)
            %onDataChanged JS -> MATLAB push; caches text, no re-entrant set.
            try
                d = evt.Data;
                if(isstruct(d) && isfield(d, 'markdown'))
                    txt = char(string(d.markdown));
                    fig = ancestor(src, 'figure');
                    if(~isempty(fig) && isvalid(fig))
                        setappdata(fig, 'LvdMarkdownNotesText', txt);
                        if(isfield(d, 'rev'))
                            setappdata(fig, 'LvdMarkdownNotesRev', d.rev);
                        end
                    end
                end
            catch %#ok<CTCH>
                % Malformed push from JS; keep the last good cache.
            end
        end
    end
end
