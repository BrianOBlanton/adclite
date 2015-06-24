%%  DrawTriSurf
%%% DrawTriSurf
%%% DrawTriSurf 
function Handles=DrawTriSurf(Handles,GridId,Units,Field)

    global TheGrids Debug
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end
    
    SetUIStatusMessage('Drawing Trisurf ... \n')

    TheGrid=TheGrids{GridId};

    MarkerHandles=findobj(Handles.MainAxes,'Tag','NodeMarker');
    TextHandles=findobj(Handles.MainAxes,'Tag','NodeText');
    if ~isempty(MarkerHandles),delete(MarkerHandles);end
    if ~isempty(TextHandles),delete(TextHandles);end
    
    if isfield(Handles,'TriSurf')
        if ishandle(Handles.TriSurf)
            delete(Handles.TriSurf);
        end
    end
    
    Handles.TriSurf=trisurf(TheGrid.e,TheGrid.x,TheGrid.y,...
        ones(size(TheGrid.x)),Field,'EdgeColor','none',...
        'FaceColor','interp','Tag','TriSurf');

    setappdata(Handles.TriSurf,'Field',Field);
    setappdata(Handles.TriSurf,'FieldMax',max(Field));
    setappdata(Handles.TriSurf,'FieldMin',min(Field));
    setappdata(Handles.TriSurf,'Name',[]);

    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    set(get(Handles.ColorBar,'ylabel'),'String',Units,'FontSize',FontSizes(1));

    %drawnow 
end
