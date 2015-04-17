%%  SetCLims
function SetCLims(~,~)

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    axes(Handles.MainAxes);

    PossibleMaps=cellstr(get(Handles.ColormapSetter,'String'));
    CurrentValue=get(Handles.ColormapSetter,'Value');
    CurrentMap=PossibleMaps{CurrentValue};
    NumCols=get(Handles.NCol,'String');
    CMin=get(Handles.CMin,'String');
    CMax=get(Handles.CMax,'String');
    caxis([str2double(CMin) str2double(CMax)])
    eval(sprintf('cmap=colormap(%s(%s));',CurrentMap,NumCols))    
    FlipCMap=get(Handles.FlipCMap,'Value');
    if FlipCMap,cmap=flipud(cmap);end
    colormap(cmap)
    
end
