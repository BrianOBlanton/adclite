%%  SetPanZoomFxns
%%% SetPanZoomFxns
%%% SetPanZoomFxns
function Handles=SetPanZoomFxns(Handles)

    if ~isfield(Handles,'panHandle'),
        Handles.panHandle=pan(Handles.MainFigure);
    end
    
    if ~isfield(Handles,'zoomHandle'),
        Handles.zoomHandle=zoom(Handles.MainFigure);
    end
    
    set(Handles.panHandle,'ActionPostCallback',@RecordAxisLimits);
    set(Handles.zoomHandle,'ActionPostCallback',@RecordAxisLimits);

end