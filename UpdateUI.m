%%  UpdateUI
%%% UpdateUI
%%% UpdateUI
function UpdateUI(varargin)

    global Debug TheGrids
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Updating GUI ... \n')

    if nargin==1
        disp('UpdateUI called as a function')
        FigHandle=varargin{1};     
    else
        disp('UpdateUI called as a callback')
        hObj=varargin{1};
        event=varargin{2};
        FigHandle=gcbf;
    end

    Handles=get(FigHandle,'UserData');

    ADCLOPTS=getappdata(FigHandle,'AdcLOpts');

    LocalTimeOffset=ADCLOPTS.LocalTimeOffset;
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

    P1=get(Handles.ParameterControlsParameter(1),'String');
    P1=str2double(P1);
    r=km2deg(P1);

    P5=get(Handles.ParameterControlsParameter(5),'String');
    P6=get(Handles.ParameterControlsParameter(6),'String');
    P5=str2double(P5);
    P6=str2double(P6);

    latitudeInterceptionParallel1.lon = [-82, -70];
    latitudeInterceptionParallel1.lat = [33.50, 33.50];
    latitudeInterceptionParallel4.lon = [-82, -70];
    latitudeInterceptionParallel4.lat = [36.00, 36.00];
    delete(findobj(Handles.MainAxes,'Tag','L1Marker'))
    delete(findobj(Handles.MainAxes,'Tag','L4Marker'))
    delete(findobj(Handles.MainAxes,'Tag','L1L2Path'))

    line(latitudeInterceptionParallel1.lon(1)+P5,latitudeInterceptionParallel1.lat(1),'Color','b','Marker','*','MarkerSIze',20,'Tag','L1Marker')
    line(latitudeInterceptionParallel4.lon(1)+P6,latitudeInterceptionParallel4.lat(1),'Color','r','Marker','*','MarkerSIze',20,'Tag','L2Marker')

    h=line([latitudeInterceptionParallel1.lon(1)+P5 latitudeInterceptionParallel4.lon(1)+P6],...
         [latitudeInterceptionParallel1.lat(1)    latitudeInterceptionParallel4.lat(1)],'Color','y','LineWidth',2,'Tag','L1L2Path');
    h.ZData=ones(size(h.XData));

    delete(findobj(Handles.MainAxes,'Tag','RMW_Circle'))
    h=circles(latitudeInterceptionParallel1.lon(1)+P5,latitudeInterceptionParallel1.lat(1),r,'Tag','RMW_Circle','Color','y','LineWidth',2);
    h.ZData=ones(size(h.XData));

    set(FigHandle,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')
    set(Handles.MainFigure,'Pointer','arrow');

end

