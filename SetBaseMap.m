%%  SetBaseMap
%%% SetBaseMap
%%% SetBaseMap
function SetBaseMap(~,~,~)

    global Debug
   if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    GoogleMapsApiKey=getappdata(Handles.MainFigure,'GoogleMapsApiKey');
    %EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    MapTypeClicked=get(get(Handles.BaseMapButtonGroup,'SelectedObject'),'string');
    
    if strcmp(MapTypeClicked,'none')
        delete(findobj(Handles.MainAxes,'Type','image','Tag','gmap'))
    else
        axes(Handles.MainAxes);
        plot_google_map('MapType',MapTypeClicked,'ApiKey',GoogleMapsApiKey,'AutoAxis',0)
    end

end
