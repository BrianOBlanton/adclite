%%  UpdateUI
%%% UpdateUI
%%% UpdateUI
function UpdateUI(varargin)

    global Debug TheGrids
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Updating GUI ... \n')

    if nargin==1
        %disp('UpdateUI called as a function')
        FigHandle=varargin{1};     
    else
        %disp('UpdateUI called as a callback')
        %hObj=varargin{1};
        %event=varargin{2};
        FigHandle=gcbf;
    end

    Handles=get(FigHandle,'UserData');

    SSVizOpts=getappdata(FigHandle,'SSVizOpts');

    LocalTimeOffset=SSVizOpts.LocalTimeOffset;
    GridName=SSVizOpts.GridName;
    ModelName=SSVizOpts.ModelName;

%     VariableNames=Connections.VariableNames; 
%     VariableTypes=Connections.VariableTypes; 
%     Scalars= find(strcmp(VariableTypes,'Scalar'));
%     Vectors= find(strcmp(VariableTypes,'Vector'));
%     
%     % disable variable buttons according to NcTBHandle
%     EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
%     EnsembleNames=Connections.EnsembleNames; 
%     EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    
%     for i=1:length(Handles.ScalarVarButtonHandles)
%         if ~isfield(Connections.members{EnsIndex,Scalars(i)},'NcTBHandle') || ... 
%                 isempty(Connections.members{EnsIndex,Scalars(i)}.NcTBHandle)
%             set(Handles.ScalarVarButtonHandles(i),'Enable','off')
%         end
%     end
%     for i=1:length(Handles.ScalarVarButtonHandles)
%         if ~isempty(Connections.members{EnsIndex,Scalars(i)}.NcTBHandle)
%             set(Handles.ScalarVarButtonHandles(i),'Value',1)
%             break
%         end
%     end
    
%     for i=1:length(Handles.VectorVarButtonHandles)
%         if isempty(Connections.members{EnsIndex,Vectors(i)}.NcTBHandle) || ... 
%                 isempty(Connections.members{EnsIndex,Vectors(i)}.NcTBHandle)
%             set(Handles.VectorVarButtonHandles(i),'Enable','off')
%         end
%     end
%     for i=1:length(Handles.VectorVarButtonHandles)
%         if ~isempty(Connections.members{EnsIndex,Vectors(i)}.NcTBHandle)
%             set(Handles.VectorVarButtonHandles(i),'Value',1)
%             break
%         end
%     end
    
   
%    ColorIncrement=getappdata(FigHandle,'ColorIncrement');
%     Field=getappdata(Handles.TriSurf,'Field');
%     %FontSizes=getappdata(Handles.MainFigure,'FontSizes');
%     
% %     set(Handles.Field_Maximum,'String',sprintf('Maximum = %f',max(Field)))
% %     set(Handles.Field_Minimum,'String',sprintf('Minimum = %f',min(Field)))
%     
%     CMax=max(Field);
%     CMax=ceil(CMax/ColorIncrement)*ColorIncrement;
%     CMin=min(Field);
%     CMin=floor(CMin/ColorIncrement)*ColorIncrement;
%     ncol=(CMax-CMin)/ColorIncrement;
%     
%     set(Handles.CMax,'String',sprintf('%f',CMax))
%     set(Handles.CMin,'String',sprintf('%f',CMin))
%     set(Handles.NCol,'String',sprintf('%d',ncol))
%     setappdata(FigHandle,'NumberOfColors',ncol);

    str=sprintf('# Elements = %d\n# Nodes    = %d',size(TheGrids{1}.e,1), size(TheGrids{1}.x,1));


%     if isfield(Connections,'RunProperties')
%        rp=Connections.RunProperties;
%        stormnumber=GetRunProperty(rp,'stormnumber');
%        stormname=GetRunProperty(rp,'stormname');
%        advnumber=GetRunProperty(rp,'advisory');
%        ModelGrid=GetRunProperty(rp,'ADCIRCgrid');
%        ModelName=GetRunProperty(rp,'Model');
%        %Instance=GetRunProperty(rp,'instance');
%        Instance=getappdata(FigHandle,'Instance');
%        if strcmp(stormname,'STORMNAME')
%            stormname='Nam-Driven';
%            stormnumber='00';
%            advnumber='N/A';
%        end

%        set(Handles.StormNumberName,'String',sprintf('%s/%s',stormnumber,stormname));
%        set(Handles.AdvisoryNumber, 'String',advnumber)
       set(Handles.ModelGridName,  'String',GridName)
       set(Handles.ModelGridNums,  'String',str)
       set(Handles.ModelName,      'String',ModelName)
%        set(Handles.InstanceName,   'String',Instance)

%        temp=GetRunProperty(rp,'RunStartTime');
%        yyyy=str2double(temp(1:4));
%        mm=str2double(temp(5:6));
%        dd=str2double(temp(7:8));
%        hr=str2double(temp(9:10));
%        t1=datenum(yyyy,mm,dd,hr,0,0);
%        set(Handles.ForecastStartTime,'String',sprintf('%s',datestr(t1+LocalTimeOffset/24,0)))
%        
%        temp=GetRunProperty(rp,'RunEndTime');
%        yyyy=str2double(temp(1:4));
%        mm=str2double(temp(5:6));
%        dd=str2double(temp(7:8));
%        hr=str2double(temp(9:10));
%        t2=datenum(yyyy,mm,dd,hr,0,0);
%        set(Handles.ForecastEndTime,'String',sprintf('%s',datestr(t2+LocalTimeOffset/24,0)))
%     end
    

%    set(Handles.UnitsString,   'String',Units)
%    set(Handles.TimeOffsetString,   'String',LocalTimeOffset)
% 
%     if isempty(Connections.Tracks{1})
%         set(Handles.ShowTrackButton,'String','No Track to Show')
%         set(Handles.ShowTrackButton,'Enable','off')
%     else
%         set(Handles.ShowTrackButton,'String','Show Track')
%         set(Handles.ShowTrackButton,'Enable','on')
%     end


     P5=get(Handles.ParameterControlsParameter(5),'String');P5=str2double(P5);
     P6=get(Handles.ParameterControlsParameter(6),'String');P6=str2double(P6);
   
latitudeInterceptionParallel1.lon = [-82, -70];
latitudeInterceptionParallel1.lat = [33.50, 33.50];
latitudeInterceptionParallel4.lon = [-82, -70];
latitudeInterceptionParallel4.lat = [36.00, 36.00];
delete(findobj(gca,'Tag','L1Marker'))
delete(findobj(gca,'Tag','L4Marker'))
line(latitudeInterceptionParallel1.lon(1)+P5,latitudeInterceptionParallel1.lat(1),'Color','b','Marker','*','MarkerSIze',20,'Tag','L1Marker')
line(latitudeInterceptionParallel4.lon(1)+P6,latitudeInterceptionParallel4.lat(1),'Color','r','Marker','*','MarkerSIze',20,'Tag','L2Marker')
     
    set(FigHandle,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')
    set(Handles.MainFigure,'Pointer','arrow');

end

