%%  SetColors
function SetColors(Handles,minThisData,maxThisData,NumberOfColors,ColorIncrement)

     FieldMax=ceil(maxThisData/ColorIncrement)*ColorIncrement;
     FieldMin=floor(minThisData/ColorIncrement)*ColorIncrement;
%     [FieldMin FieldMax]

     set(Handles.CMax,'String',sprintf('%.2f',FieldMax))
     set(Handles.CMin,'String',sprintf('%.2f',FieldMin))
     set(Handles.NCol,'String',sprintf('%d',NumberOfColors))
     PossibleMaps=cellstr(get(Handles.ColormapSetter,'String'));
     CurrentValue=get(Handles.ColormapSetter,'Value');
     CurrentMap=PossibleMaps{CurrentValue};
     cmap=eval(sprintf('%s(%d)',CurrentMap,NumberOfColors));
     CLim([FieldMin FieldMax])
     colormap(cmap)
     
end
