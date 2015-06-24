%%  SetColorMap
function SetColorMap(hObj,~) 

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    axes(Handles.MainAxes);

    nc=size(colormap,1);
    cmaps=Handles.ColormapSetter.String;
    val = get(hObj,'Value');
    com=sprintf('colormap(%s(%d));',cmaps{val},nc);
    eval(com);

end
