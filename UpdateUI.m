%%  UpdateUI
%%% UpdateUI
%%% UpdateUI
function UpdateUI(varargin)

    global Debug TheGrids
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Updating GUI ... \n')

    if nargin==1
        if Debug,fprintf('AdcL++ %s called as a function\n',ThisFunctionName);end
        FigHandle=varargin{1};     
    else
        if Debug,fprintf('AdcL++ %s called as a callback\n',ThisFunctionName);end
        hObj=varargin{1};
        event=varargin{2};
        FigHandle=gcbf;
    end

    Handles=get(FigHandle,'UserData');

    ADCLOPTS=getappdata(FigHandle,'AdcLOpts');

    %LocalTimeOffset=ADCLOPTS.LocalTimeOffset;
    GridName=ADCLOPTS.GridName;
    ModelName=ADCLOPTS.ModelName;    
   
%    ColorIncrement=getappdata(FigHandle,'ColorIncrement');
    ColorIncrement=ADCLOPTS.ColorIncrement;
     Field=getappdata(Handles.TriSurf,'Field');
%     %FontSizes=getappdata(Handles.MainFigure,'FontSizes');
%     
% %     set(Handles.Field_Maximum,'String',sprintf('Maximum = %f',max(Field)))
% %     set(Handles.Field_Minimum,'String',sprintf('Minimum = %f',min(Field)))
%     
    CMax=max(Field);
    CMax=ceil(CMax/ColorIncrement)*ColorIncrement;
    CMin=min(Field);
    CMin=floor(CMin/ColorIncrement)*ColorIncrement;
  
    set(Handles.FieldMax,'String',sprintf('%f',max(Field)))
    set(Handles.FieldMin,'String',sprintf('%f',min(Field)))
    
    set(Handles.CMax,'String',sprintf('%f',CMax))
    set(Handles.CMin,'String',sprintf('%f',CMin))
    %set(Handles.NCol,'String',sprintf('%d',ncol))
    %setappdata(FigHandle,'NumberOfColors',ncol);
    
    SetColors(Handles,CMin,CMax,ADCLOPTS.NumberOfColors,ADCLOPTS.ColorIncrement);

    str=sprintf('# Elements = %d\n# Nodes    = %d',size(TheGrids{1}.e,1), size(TheGrids{1}.x,1));

    set(Handles.ModelGridName,  'String',GridName)
    set(Handles.ModelGridNums,  'String',str)
    set(Handles.ModelName,      'String',ModelName)

    DrawModel(FigHandle);
    
    set(FigHandle,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')
    if Debug,fprintf('AdcL++    Done.\n');end
    set(Handles.MainFigure,'Pointer','arrow');

end