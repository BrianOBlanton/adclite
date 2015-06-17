function varargout=StormSurgeViz(varargin)
%
% StormSurgeViz - Visualization Application for Storm Surge Model Output
% 
% Call as: StormSurgeViz(P1,V1,P2,V2,...)
%
% Allowed Parameter/Value pairs (default value listed first):
%
% Instance          - String ASGS instance to use;
%                       {'nodcorps','hfip','ncfs'} and others as needed.
% Storm             - String storm name; default='most recent storm in catalog';
% Advisory          - String advisory number; default='most recent storm in catalog';
% Grid              - String model gridname; default=[]; 
% Units             - String to set height units; {'Meters','Feet'}
% FontOffset        - Integer to increase (+) or decrease (-) fontsize in the app;
% LocalTimeOffset   - (0, i.e. UTC) Hour offset for displayed times ( < 0 for west of GMT).
% BoundingBox       - [xmin xmax ymin ymax] vector for initial axes zoom
% CatalogName       - Name of catalog file to search for
% ColorMax          - Maximum scalar value for color scaling
% ColorMin          - Minimum scalar value for color scaling
% ColorMap          - Color map to use; {'noaa_cmap','jet','hsv',...}
% DisableContouring - {false,true} logical disabling mex compiled code calls
% GoogleMapsApiKey  - Api Key from Google for extended map accessing
% PollingInterval   - (900) interval in seconds to poll for catalog updates.
% ThreddsServer     - specify alternative THREDDS server
% Mode              - Local | Url | Network
% Help              - Opens a help window with parameter/value details.
%                     Must be the first and only argument to StormSurgeViz.
% SendDiagnosticsToCommandWindow - {false,true}
%
% These parameters can be set in the MyStormSurgeViz_Init.m file.  This
% file can be put anywhere on the MATLAB path EXCEPT in the StormSurgeViz 
% directory.  A convenient place is in the user "matlab" directory, which
% is in <USERHOME>/matlab by default in Unix/OSX. Parameters passed in via  
% the command line will override any settings in MyStormSurgeViz_Init.m, as
% well as any loaded in from the remotely maintained InstanceDefaults.m.  
%
% Do not put StormSurgeViz parameters in startup.m since this 
% is called first by MATLAB at startup.
%
% Only one instance of StormSurgeViz is allowed concurrently.  Close existing
% instances first.
%
% Example:
%
% >> StormSurgeViz;
% or
% >> close all; StormSurgeViz('Instance','rencidaily','Units','feet')
% or 
% [Handles,Url,Connections,Options]=StormSurgeViz(P1,V1,P2,V2,...);
%
% Copyright (c) 2014  Renaissance Computing Institute. All rights reserved.
% Licensed under the RENCI Open Source Software License v. 1.0.
% This software is open source. See the bottom of this file for the 
% license.
% 
% Brian Blanton, Renaissance Computing Institute, UNC-CH, Brian_Blanton@Renci.Org
% Rick Luettich, Institute of Marine SCiences,    UNC-CH, Rick_Luettich@Unc.Edu
%

if nargin==1
    if strcmp(varargin{1},'help')
        fprintf('Call as: close all; StormSurgeViz(''Instance'',''gomex'',''Units'',''feet'')\n')
        return
    end
end

% check to see if another instance of StormSurgeViz is already running
tags=findobj(0,'Tag','MainVizAppFigure');
if ~isempty(tags)
    close(tags)

%    str={'Only one instance of StormSurgeViz can run simultaneously.'
%         'Press Continue to close other StormSurgeViz instances and start this one, or Cancel to abort the current instance.'};
%    ButtonName=questdlg(str,'Other StormSurgeViz Instances Found!!!','Continue','Cancel','Cancel');
%     switch ButtonName,
%         case 'Continue'
%             close(tags)
%         otherwise
%             fprintf('Aborting this instance of StormSurgeViz.\n')
%             return
%     end
end

% check java heap space size;  needs to be big for grids > ~1M nodes
if ~usejava('jvm')
    str={[mfilename ' requires Java to run.']
        'Make sure MATLAB is run with jvm.'};
    errordlg(str)
    return
end
% 
% if java.lang.Runtime.getRuntime.maxMemory/1e9  < 0.5
%     str={'Java Heap Space is < 1Gb.  For big model grids, this may '
%         'be too small.  Increase Java Heap Memory through the MATLAB '
%         'preferences.  This message is non-fatal, but if strange '
%         'behavior occurs, then increase the java memory available. ' 
%         ' '
%         'More info on MATLAB ahd Java Heap Memory can '
%         'be found at this URL:'
%         ' '
%         'http://www.mathworks.com/support/solutions/en/data/1-18I2C/'};
%     msgbox(str)
% end
%     
%% Initialize StormSurgeViz
fprintf('\nSSViz++ Initializing application.\n')
global ADCLOPTS
ADCLOPTS=StormSurgeViz_Init;

UrlBase='file://';
Url.ThisInstance='Local';
Url.ThisStorm=NaN;
Url.ThisAdv=NaN;
Url.ThisGrid=NaN;
Url.Basin=NaN;
Url.StormType='other';
Url.ThisStormNumber=NaN;
Url.FullDodsC= UrlBase;
Url.FullFileServer= UrlBase;
Url.CurrentSelection=NaN;
Url.Base=UrlBase;
Url.Units=ADCLOPTS.Units;

 
%% load the RSM model
global Model
global TheGrids TheGrid
fprintf('SSViz++ Loading RSM ... \n')
[Model,TheGrid]=LoadRsmModel(ADCLOPTS.ADCLHOME,ADCLOPTS.ModelDir,ADCLOPTS.ModelFile,ADCLOPTS.ModelURL,ADCLOPTS.ModelName,ADCLOPTS.GridName);

TheGrids{1}=TheGrid;


%% InitializeUI
Handles=InitializeUI(ADCLOPTS);

setappdata(Handles.MainFigure,'SSVizOpts',ADCLOPTS);
setappdata(Handles.MainFigure,'Url',Url);
setappdata(Handles.MainFigure,'DateStringFormatInput',ADCLOPTS.DateStringFormatInput);
setappdata(Handles.MainFigure,'DateStringFormatOutput',ADCLOPTS.DateStringFormatOutput);
setappdata(Handles.MainFigure,'TempDataLocation',ADCLOPTS.TempDataLocation);
setappdata(Handles.MainFigure,'TempDataLocation',ADCLOPTS.TempDataLocation);

set(Handles.MainFigure,'UserData',Handles);
    
% temporary fix for Jesse Feyen's contmex5 dll problem
if ADCLOPTS.DisableContouring
    set(Handles.DepthContours,'Enable','off','String','Disabled: no contmex5 binary')
    set(Handles.HydrographButton,'Enable','off','String','Hydrographs Disabled: no findelem binary')
end
    
if ADCLOPTS.UITest, return, end   

global EnableRendererKludge
EnableRendererKludge=false;

CurrentPointer=get(Handles.MainFigure,'Pointer');
set(Handles.MainFigure,'Pointer','watch');

%% MakeTheAxesMap
SetUIStatusMessage('Making default plot ... \n')
Handles=MakeTheAxesMap(Handles);  

latitudeInterceptionParallel1.lon = [-82, -70];
latitudeInterceptionParallel1.lat = [33.50, 33.50];
latitudeInterceptionParallel4.lon = [-82, -70];
latitudeInterceptionParallel4.lat = [36.00, 36.00];

line(latitudeInterceptionParallel1.lon,latitudeInterceptionParallel1.lat,'Color','b')
line(latitudeInterceptionParallel4.lon,latitudeInterceptionParallel4.lat,'Color','r')

% evaluate the default response, in the vector X of Model
P1=get(Handles.ParameterControlsParameter(1),'String');P1=str2double(P1);
P2=get(Handles.ParameterControlsParameter(2),'String');P2=str2double(P2);
P3=get(Handles.ParameterControlsParameter(3),'String');P3=str2double(P3);
P4=get(Handles.ParameterControlsParameter(4),'String');P4=str2double(P4);
P5=get(Handles.ParameterControlsParameter(5),'String');P5=str2double(P5);
P6=get(Handles.ParameterControlsParameter(6),'String');P6=str2double(P6);
X=[P1 P2 P3 P4 P5 P6]';
zhat = central_ckv(Model.P, Model.R, Model.c, Model.k, Model.weights, Model.n_d, Model.index, X);
ThisData=NaN*ones(TheGrid.nn,1);
ThisData(TheGrid.idx)=zhat;
Handles=DrawTriSurf(Handles,1,ADCLOPTS.Units,ThisData);
set(Handles.MainFigure,'UserData',Handles);

SetColors(Handles,min(ThisData),max(ThisData),ADCLOPTS.NumberOfColors,ADCLOPTS.ColorIncrement);

UpdateUI(Handles.MainFigure);

RendererKludge;  %% dont ask...

%temp=Connections.members{EnsIndex,VarIndex}.TheData{1};
%if ~isreal(temp),temp=abs(temp);end
%[MinTemp,MaxTemp]=GetMinMaxInView(TheGrids{1},temp);
%Max=min([MaxTemp ADCLOPTS.ColorMax]);
%Min=max([MinTemp ADCLOPTS.ColorMin]);
%SetColors(Handles,Min,Max,ADCLOPTS.NumberOfColors,ADCLOPTS.ColorIncrement);

SetUIStatusMessage('* Done.\n\n');

%% Finalize Initializations
set(Handles.UnitsString,'String',ADCLOPTS.Units);
%set(Handles.TimeOffsetString,'String',ADCLOPTS.LocalTimeOffset)
set(Handles.MainFigure,'UserData',Handles);

SetTitle(ADCLOPTS.AppName);

% Final UI tweaks; based on availible files
% if isempty(Connections.Tracks{1})
%     set(Handles.ShowTrackButton,'String','No Track to Show')
%     set(Handles.ShowTrackButton,'Enable','off')
% end

axes(Handles.MainAxes);

SetUIStatusMessage('Done Done.\n')
set(Handles.MainFigure,'Pointer',CurrentPointer);

if nargout>0, varargout{1}=Handles; end
if nargout>1, varargout{2}=ADCLOPTS; end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Private functions
%%% Private functions
%%% Private functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%  BrowseFileSystem
%%% BrowseFileSystem
%%% BrowseFileSystem
function BrowseFileSystem(~,~)
    global Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    if exist('hObj','var')
        FigThatCalledThisFxn=gcbf;
    else
        FigThatCalledThisFxn=findobj(0,'Tag','MainVizAppFigure');
    end
    Handles=get(FigThatCalledThisFxn,'UserData');
    Url=getappdata(FigThatCalledThisFxn,'Url');
    
    directoryname = uigetdir(LocalStartingDirectory,'Navigate to a dir containing a maxele.63.nc file');
    
    if directoryname==0 % cancel was pressed
       return
    end
    
    set(Handles.ServerInfoString,'String',['file://' directoryname]);
    ClearUI(FigThatCalledThisFxn);
    
end

%%  DrawDepthContours
%%% DrawDepthContours
%%% DrawDepthContours
function DrawDepthContours(hObj,~)
    
    global TheGrids Debug
   if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    MainFig=get(get(get(hObj,'Parent'),'Parent'),'Parent');
    Handles=get(MainFig,'UserData');
    DisableContouring=getappdata(Handles.MainFigure,'DisableContouring');

    axes(Handles.MainAxes);
    if ~(isempty(which('contmex5')) && DisableContouring)
        DepthContours=get(hObj,'String');
        SetUIStatusMessage('** Drawing depth contours ... \n')
        if isempty(DepthContours) || strcmp(DepthContours,'none')
           delete(findobj(Handles.MainAxes,'Tag','BathyContours'))
        else
            DepthContours=sscanf(DepthContours,'%d');
            Handles.BathyContours=lcontour(TheGrid,TheGrid.z,DepthContours,'Color','k');
            for i=1:length(Handles.BathyContours)
                nz=2*ones(size(get(Handles.BathyContours(i),'XData')));
                set(Handles.BathyContours(i),'ZData',nz)
            end
            set(Handles.BathyContours,'Tag','BathyContours');
        end
        SetUIStatusMessage('Done. \n')

    else
        SetUIStatusMessage(sprintf('Contouring routine contmex5 not found for arch=%s.  Skipping depth contours.\n',computer))
    end

end



%%  DrawTrack
%%% DrawTrack
%%% DrawTrack
function h=DrawTrack(track)
    
    global Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    f=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(f,'UserData');
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');              
        LocalTimeOffset=SSVizOpts.LocalTimeOffset;
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');

    %fmtstr=' mmmdd@HH PM';
    %fmtstr=' ddd HHPM';
    fmtstr='yyyy-mm-dd HH';
    txtcol=[0 0 0]*.8;
    lincol=[1 1 1]*0;
    
    [~,ii,~]=unique(track.hr);

    lon=track.lon2(ii);
    lat=track.lat2(ii);
    time=track.time(ii);
    
    try 
        
        h1=line(lon,lat,2*ones(size(lat)),'Marker','o','MarkerSize',6,'Color',lincol,...
            'LineWidth',2,'Tag','Storm_Track','Clipping','on');
        
        h2=NaN*ones(length(lon),1);
        for i=1:length(lon)-1
            heading=atan2((lat(i+1)-lat(i)),(lon(i+1)-lon(i)))*180/pi;
            h2(i)=text(lon(i),lat(i),2*ones(size(lat(i))),datestr(time(i)+LocalTimeOffset/24,fmtstr),...
                'FontSize',FontSizes(2),'FontWeight','bold','Color',txtcol,'Tag','Storm_Track','Clipping','on',...
                'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',heading-90);
        end
        
        h2(i+1)=text(lon(i+1),lat(i+1),2*ones(size(lat(i+1))),datestr(time(i+1)+LocalTimeOffset/24,fmtstr),...
            'FontSize',FontSizes(2),'FontWeight','bold','Color',txtcol,'Tag','Storm_Track','Clipping','on',...
            'HorizontalAlignment','left','VerticalAlignment','middle','Rotation',heading-90);
        h=[h1;h2(:)];
        
    catch ME

        fprintf('Could not draw the track.\n')
    
    end
    
    drawnow
end

%%  DrawVectors
%%% DrawVectors
%%% DrawVectors
function Handles=DrawVectors(Handles,Member,Field)

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end 
    
    TheGrid=TheGrids{Member.GridId};
    
    %VectorOptions=getappdata(Handles.MainFigure,'VectorOptions');
    Stride=get(Handles.VectorOptionsStride,'String');
    Stride=str2double(Stride);
    ScaleFac=get(Handles.VectorOptionsScaleFactor,'String');
    ScaleFac=str2double(ScaleFac);
    ScaleLabel=get(Handles.VectorOptionsScaleLabel,'String');
    if isempty(ScaleLabel) || strcmp(ScaleLabel,'no scale')
        ScaleLabel='no scale';
    else
        SetUIStatusMessage('place scale on plot with a mouse button.\n')
    end
    Color=get(Handles.VectorOptionsColor,'String');
    %ScaleOrigin=get(Handles.VectorOptionsScaleOrigin,'String');

    u=real(Field);
    v=imag(Field);
    axes(Handles.MainAxes);
    Handles.Vectors=vecplot(TheGrid.x,TheGrid.y,u,v,...
        'ScaleFac',ScaleFac,...
        'Stride',Stride,...
        'Color',Color,...
        'ScaleLabel',ScaleLabel); %,...
        %'ScaleType','floating');
    
    % depending on the args to vecplot, the handle may have >1 values.
    % but the first is the handle to the drawn vectors
    nz=2*ones(size(get(Handles.Vectors(1),'XData')));
    set(Handles.Vectors(1),'ZData',nz);
    setappdata(Handles.Vectors(1),'Field',Field);
    
    drawnow
    
end

%%  RedrawVectors
%%% RedrawVectors
%%% RedrawVectors
function RedrawVectors(varargin)

    global Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
   
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    
    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');

    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    VariableTypes=Connections.VariableTypes; 
    
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));
    VectorVarIndex=find(strcmp(VectorVariableClicked,VariableNames));

    % Delete the current vector set
    if isfield(Handles,'Vectors')
        if ishandle(Handles.Vectors)
            % get data to redraw before deleting the vector object
            Field=getappdata(Handles.Vectors(1),'Field');
            delete(Handles.Vectors);
        else
            SetUIStatusMessage('No vectors to redraw.\n')
            return
        end
    else
        SetUIStatusMessage('No vectors to redraw.\n')
        return
    end
    
    Member=Connections.members{EnsIndex,VectorVarIndex}; %#ok<FNDSB>
    
    %if ~isfield(Handles,'Vectors'),return,end
    %if ~ishandle(Handles.Vectors(1)),return,end
    
    Handles=DrawVectors(Handles,Member,Field);
    set(Handles.MainFigure,'UserData',Handles);

end

%%  DeleteVectors
%%% DeleteVectors
%%% DeleteVectors
function DeleteVectors(varargin)
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    
    if ~isfield(Handles,'Vectors'),return,end
    if ~ishandle(Handles.Vectors(1)),return,end
    
    % Delete the current vector set
    for i=1:length(Handles.Vectors)
        if ishandle(Handles.Vectors(i))
            delete(Handles.Vectors(i));
        end
    end
    
    Handles=rmfield(Handles,'Vectors');
    set(Handles.MainFigure,'UserData',Handles);

end



%%  ClearUI
%%% ClearUI
%%% ClearUI
function ClearUI(varargin)

    if nargin==1  % called as function
        FigHandle=varargin{1};     
    else  % called as callback
        %hObj=varargin{1};
        %event=varargin{2};
        FigHandle=gcbf;
    end
    Handles=get(FigHandle,'UserData');
    set(Handles.CMin,'String','0')
    set(Handles.CMax,'String','1')
    set(Handles.NCol,'String','32')
    set(Handles.InstanceName,'String','N/A')
    set(Handles.ModelName,'String','N/A')
    set(Handles.StormNumberName,'String','N/A')
    set(Handles.AdvisoryNumber,'String','N/A')
    set(Handles.ModelGridName,'String','N/A')
    %set(Handles.UnitsString,'String','N/A')
    %set(Handles.ForecastStartTime,'String','NaN')
    %set(Handles.ForecastEndTime,'String','NaN')
%     handlesToDelete={'EnsButtonHandles','VarButtonHandles',...
%                      'SnapshotButtonHandles','SnapshotSliderHandle',...
%                      'EnsButtonHandlesGroup','VarButtonHandlesGroup',...
%                      'SnapshotButtonHandlesPanel'};
%     for i=1:length(handlesToDelete)
%         h=sprintf('Handles.%s',handlesToDelete{i});
%         for j=1:length(h)
%             if ishandle(h(j))
%                 delete(h(j)); 
%             end
% 
%         end
%         Handles=rmfield(Handles,handlesToDelete{i});
%     end
%     
%     set(FigHandle,'UserData',Handles);
end


%%  SetEnsembleControls
%%% SetEnsembleControls
%%% SetEnsembleControls
function Handles=SetEnsembleControls(varargin)

    global Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Setting up Ensemble controls ...\n')

    FigHandle=varargin{1};     
    Handles=get(FigHandle,'UserData');  
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    panelColor = get(0,'DefaultUicontrolBackgroundColor');

    % delete previously instanced controls, if they exist
    if isfield(Handles,'EnsButtonHandlesGroup')
        if ishandle(Handles.EnsButtonHandles)
            delete(Handles.EnsButtonHandles);      
        end
        Handles=rmfield(Handles,'EnsButtonHandles');
        
        if ishandle(Handles.EnsButtonHandlesGroup)
            delete(Handles.EnsButtonHandlesGroup);      
        end
        Handles=rmfield(Handles,'EnsButtonHandlesGroup');
    end
    
    EnsembleNames=Connections.EnsembleNames;
    
    % build out ensemble member controls
    NEns=length(EnsembleNames);
    dy=.45;
    
    Handles.EnsButtonHandlesGroup = uibuttongroup(...
        'Parent',Handles.CenterContainerUpper,...
        'Title','Ensemble Members',...
        'FontSize',FontSizes(2),...
        'BackGroundColor',panelColor,...
        'Position',[.01 .975-dy .48 dy],...
        'Tag','EnsembleMemberRadioButtonGroup',...
        'SelectionChangeFcn',@SetNewField);
    dy=1/10;
    for i=1:NEns
        Handles.EnsButtonHandles(i)=uicontrol(...
            Handles.EnsButtonHandlesGroup,...
            'Style','Radiobutton',...
            'String',EnsembleNames{i},...
            'Units','normalized',...
            'FontSize',FontSizes(2),...
            'Position', [.1 .975-dy*i .9 dy],...
            'Tag','EnsembleMemberRadioButton');
  
            set(Handles.EnsButtonHandles(i),'Enable','on');
    end
    set(Handles.MainFigure,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')

end

%%  SetVariableControls
%%% SetVariableControls
%%% SetVariableControls
function Handles=SetVariableControls(varargin)
    

    global Connections Debug Vecs SSVizOpts
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Setting up Variable controls ...\n')

    FigHandle=varargin{1};     
    AxesHandle=varargin{2};  
    Handles=get(FigHandle,'UserData');
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    panelColor = get(0,'DefaultUicontrolBackgroundColor');
    KeepInSync=SSVizOpts.KeepScalarsAndVectorsInSync;

    VariableNames=Connections.VariableNames; 
    VariableTypes=Connections.VariableTypes; 

    % delete previously instanced controls, if they exist
    if isfield(Handles,'ScalarVarButtonHandlesGroup')
        delete(Handles.ScalarVarButtonHandles);        
        Handles=rmfield(Handles,'ScalarVarButtonHandles');
        delete(Handles.ScalarVarButtonHandlesGroup);
        Handles=rmfield(Handles,'ScalarVarButtonHandlesGroup');
    end
    if isfield(Handles,'VectorVarButtonHandlesGroup')
        delete(Handles.VectorVarButtonHandles);        
        Handles=rmfield(Handles,'VectorVarButtonHandles');
        delete(Handles.VectorVarButtonHandlesGroup);
        Handles=rmfield(Handles,'VectorVarButtonHandlesGroup');
    end
    
    Scalars= find(strcmp(VariableTypes,'Scalar'));
    Vectors= find(strcmp(VariableTypes,'Vector'));

    % build out variable member controls, scalars first
    NVar=length(Scalars);

    dy1=.45;
    Handles.ScalarVarButtonHandlesGroup = uibuttongroup(...
        'Parent',Handles.CenterContainerUpper,...
        'Title','Scalar Variables ',...
        'FontSize',FontSizes(2),...
        'BackGroundColor',panelColor,...
        'Position',[.51 .975-dy1 .48 dy1],...
        'Tag','ScalarVariableMemberRadioButtonGroup',...
        'SelectionChangeFcn',@SetNewField);
    
    dy2=1/11;
    for i=1:NVar
        Handles.ScalarVarButtonHandles(i)=uicontrol(...
            Handles.ScalarVarButtonHandlesGroup,...
            'Style','Radiobutton',...
            'String',VariableNames{Scalars(i)},...
            'Units','normalized',...
            'FontSize',FontSizes(2),...
            'Position', [.1 .975-dy2*i .9 dy2],...
            'Tag','ScalarVariableMemberRadioButton');
  
            set(Handles.ScalarVarButtonHandles(i),'Enable','on');
    end
    
    for i=1:length(Handles.ScalarVarButtonHandles)
        if isempty(Connections.members{1,Scalars(i)}.NcTBHandle)
            set(Handles.ScalarVarButtonHandles(i),'Value',0)
            %set(Handles.ScalarVarButtonHandles(i),'Value','off')
        end
    end
    for i=1:length(Handles.ScalarVarButtonHandles)
        if ~isempty(Connections.members{1,Scalars(i)}.NcTBHandle)
            set(Handles.ScalarVarButtonHandles(i),'Value',1)
            break
        end
    end
        
    % build out variable member controls, Vectors 
    NVar=length(Vectors);

    Handles.VectorVarButtonHandlesGroup = uibuttongroup(...
        'Parent',Handles.CenterContainerUpper,...
        'Title','Vector Variables',...
        'FontSize',FontSizes(2),...
        'BackGroundColor',panelColor,...
        'Position',[.51 .025 .48 dy1],...
        'Tag','VectorVariableMemberRadioButtonGroup',...
        'SelectionChangeFcn',@SetNewField);
    
    for i=1:NVar
        Handles.VectorVarButtonHandles(i)=uicontrol(...
            Handles.VectorVarButtonHandlesGroup,...
            'Style','Radiobutton',...
            'String',VariableNames{Vectors(i)},...
            'Units','normalized',...
            'FontSize',FontSizes(2),...
            'Position', [.1 .975-dy2*i .9 dy2],...
            'Tag','VectorsVariableMemberRadioButton');
  
            set(Handles.VectorVarButtonHandles(i),'Enable',Vecs);
    end
    
    for i=1:length(Handles.VectorVarButtonHandles)
        if isempty(Connections.members{1,Vectors(i)}.NcTBHandle)
            set(Handles.VectorVarButtonHandles(i),'Value',0)
            set(Handles.VectorVarButtonHandles(i),'Enable','off')
        end
    end
    for i=1:length(Handles.VectorVarButtonHandles)
        if ~isempty(Connections.members{1,Vectors(i)}.NcTBHandle)
            %set(Handles.VectorVarButtonHandles(i),'Value',1)
            break
        end
    end
   
    Handles.VectorKeepInSyncButton=uicontrol(...
        'Parent',Handles.VectorVarButtonHandlesGroup,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[.1 .24 .8 .1],...
        'Tag','OverlayVectorsButton',...
        'FontSize',FontSizes(2),...
        'String','Keep in Sync',...
        'Enable','off',...
        'Callback', @ToggleSync,...
        'Value',KeepInSync);
    
    Handles.VectorOptionsOverlayButton=uicontrol(...
        'Parent',Handles.VectorVarButtonHandlesGroup,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[.1 .12 .8 .1],...
        'Tag','OverlayVectorsButton',...
        'FontSize',FontSizes(2),...
        'String','Overlay Vectors',...
        'Enable',Vecs,...
        'CallBack','',...
        'Value',1);
    

    Handles.VectorAsScalarButton=uicontrol(...
        'Parent',Handles.VectorVarButtonHandlesGroup,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[.1 .02 .8 .1],...
        'Tag','VectorAsScalarButton',...
        'FontSize',FontSizes(2),...
        'String','Display as Speed',...
        'Enable',Vecs,...
        'CallBack','');
    
    set(Handles.MainFigure,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')

end

%%  SetSnapshotControls
%%% SetSnapshotControls
%%% SetSnapshotControls
function Handles=SetSnapshotControls(varargin)

    global Connections Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    SetUIStatusMessage('Setting up Snapshot Controls ... \n')

    FigHandle=varargin{1};     
    AxesHandle=varargin{2};  
    Handles=get(FigHandle,'UserData');
    SSVizOpts=getappdata(FigHandle,'SSVizOpts');
    LocalTimeOffset=SSVizOpts.LocalTimeOffset;

    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
        
    panelColor = get(0,'DefaultUicontrolBackgroundColor');
    DateStringFormatInput=getappdata(Handles.MainFigure,'DateStringFormatInput');
    DateStringFormatOutput=getappdata(Handles.MainFigure,'DateStringFormatOutput');

    ThreeDVars={'Water Level', 'Wind Velocity'};
    
    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    VariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    VarIndex=find(strcmp(VariableClicked,VariableNames));
   
    [a,b]=ismember(ThreeDVars,VariableNames);
    ThreeDvarsattached=false;
    for i=1:length(b)
        if ~isempty(Connections.members{EnsIndex,b(i)}.NcTBHandle)
            ThreeDvarsattached=true;
        end
    end
 
    % delete previously instanced controls, if they exist
    if isfield(Handles,'ScalarSnapshotButtonHandlePanel')
        if ishandle(Handles.ScalarSnapshotButtonHandlePanel)
            delete(Handles.ScalarSnapshotButtonHandlePanel);
        end
        Handles=rmfield(Handles,'ScalarSnapshotButtonHandle');
        Handles=rmfield(Handles,'ScalarSnapshotButtonHandlePanel');
        Handles=rmfield(Handles,'ScalarSnapshotSliderHandle');
    end
    
    if ~any(a) || ~ThreeDvarsattached
        
        set(Handles.HydrographButton,'enable','off')
        %disp('disable Find Hydrographbutton')
        snapshotlist={'Not Available'};
        m=2;
        
    else
               
        % base the times on the variables selected in the UI. 
        
        time=Connections.members{EnsIndex,b(1)}.NcTBHandle.geovariable('time');
        basedate=time.attribute('base_date');
        if isempty(basedate)
            s=time.attribute('units');
            p=strspl(s);
            basedate=datestr(datenum([p{3} ' ' p{4}],DateStringFormatInput));
        end
        timebase_datenum=datenum(basedate,DateStringFormatInput);
        t=cast(time.data(:),'double');
        snapshotlist=cell(length(t),1);
        time_datenum=time.data(:)/86400+timebase_datenum;
        for i=1:length(t)
            snapshotlist{i}=datestr(t(i)/86400+timebase_datenum+LocalTimeOffset/24,DateStringFormatOutput);
        end
        [m,~]=size(snapshotlist);
        
        % build out snapshot list controls
        
        Handles.ScalarSnapshotButtonHandlePanel = uipanel(...
            'Parent',Handles.CenterContainerUpper,...
            'Title','Scalar Snapshot List ',...
            'BorderType','etchedin',...
            'FontSize',FontSizes(2),...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.2 .49 .15],...
            'Tag','ScalarSnapshotButtonGroup');
              
        Handles.VectorSnapshotButtonHandlePanel = uipanel(...
            'Parent',Handles.CenterContainerUpper,...
            'Title','Vector Snapshot List ',...
            'BorderType','etchedin',...
            'FontSize',FontSizes(2),...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.02 .49 .15],...
            'Tag','VectorSnapshotButtonGroup');
        
        
        if m>0
            Handles.ScalarSnapshotButtonHandle=uicontrol(...
                Handles.ScalarSnapshotButtonHandlePanel,...
                'Style','popupmenu',...
                'String',snapshotlist,...
                'Units','normalized',...
                'FontSize',FontSizes(3),...
                'Position', [.05 .75 .9 .1],...
                'Tag','ScalarSnapshotButton',...
                'Callback',@ViewSnapshot);
            
            Handles.ScalarSnapshotSliderHandle=uicontrol(...
                Handles.ScalarSnapshotButtonHandlePanel,...
                'Style','slider',...
                'Units','normalized',...
                'FontSize',FontSizes(1),...
                'Position', [.05 0.25 .9 .1],...
                'value',1,'Min',1,...
                'Max',m,...
                'SliderStep',[1/(m-1) 1/(m-1)],...
                'Tag','ScalarSnapshotSlider',...
                'UserData',time_datenum,...
                'Callback',@ViewSnapshot);
            
            Handles.VectorSnapshotButtonHandle=uicontrol(...
                Handles.VectorSnapshotButtonHandlePanel,...
                'Style','popupmenu',...
                'String',snapshotlist,...
                'Units','normalized',...
                'FontSize',FontSizes(3),...
                'Position', [.05 .75 .9 .1],...
                'Tag','VectorSnapshotButton',...
                'Callback',@ViewSnapshot);
            
            Handles.VectorSnapshotSliderHandle=uicontrol(...
                Handles.VectorSnapshotButtonHandlePanel,...
                'Style','slider',...
                'Units','normalized',...
                'FontSize',FontSizes(1),...
                'Position', [.05 0.25 .9 .1],...
                'value',1,'Min',1,...
                'Max',m,...
                'SliderStep',[1/(m-1) 1/(m-1)],...
                'Tag','VectorSnapshotSlider',...
                'UserData',time_datenum,...
                'Callback',@ViewSnapshot); 
            
        end
        
%        if ~ThreeDvarsattached
            set(Handles.ScalarSnapshotButtonHandle,'Enable','off');
            set(Handles.ScalarSnapshotSliderHandle,'Enable','off');
            set(Handles.VectorSnapshotButtonHandle,'Enable','off');
            set(Handles.VectorSnapshotSliderHandle,'Enable','off');
%        else
%            set(Handles.ScalarSnapshotButtonHandle,'Enable','on');
%            set(Handles.ScalarSnapshotSliderHandle,'Enable','on');
%            set(Handles.VectorSnapshotButtonHandle,'Enable','on');
%            set(Handles.VectorSnapshotSliderHandle,'Enable','on');
%        end     
        
    end
    
    set(Handles.MainFigure,'UserData',Handles);
    SetUIStatusMessage('* Done.\n\n')

end
    

%%  RendererKludge
%%% RendererKludge
%%% RendererKludge
function RendererKludge
    global EnableRendererKludge
    if EnableRendererKludge
        delete(findobj(0,'Tag','RendererMarkerKludge'))
        axx=axis;
        line(axx(1),axx(3),'Clipping','on','Tag','RendererMarkerKludge');
    end
end

%%  SetGraphicOutputType
%%% SetGraphicOutputType
%%% SetGraphicOutputType
function SetGraphicOutputType(hObj,~)
     SelectedType=get(get(hObj,'SelectedObject'),'String');
     SetUIStatusMessage(['Graphic Output is set to the ' SelectedType] )
end

%%  ExportShapeFile
%%% ExportShapeFile
%%% ExportShapeFile
function ExportShapeFile(~,~)  

    global TheGrids Connections Debug 

    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    
    ScalarSnapshotClicked=floor(get(Handles.ScalarSnapshotSliderHandle,'Value')); 

    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames));
    ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));

    GridId=Connections.members{EnsIndex,ScalarVarIndex}.GridId;
    TheGrid=TheGrids{GridId};

    OutName=get(Handles.DefaultShapeFileName,'String'); 
    if isempty(OutName)
        SetUIStatusMessage('Set ExportShapeFileName to something reasonable.... \n')
        return
    end
        
    ThisData=Connections.members{EnsIndex,ScalarVarIndex}.TheData{ScalarSnapshotClicked};
    temp=get(Handles.ShapeFileBinCenterIncrement,'String'); 
    BinCenters=sscanf(temp,'%d');
    e0=ceil(min(ThisData/BinCenters))*BinCenters;
    e1=floor(max(ThisData/BinCenters))*BinCenters;
    bin_centers=e0:BinCenters:e1;
    
    SetUIStatusMessage('Making shape file object.  Stand by ... \n')
    try 
        [SS,edges,spec]=MakeAdcircShape(TheGrid,ThisData,bin_centers,'FeatureName',VariableNames{ScalarVarIndex});
    catch ME
        SetUIStatusMessage('Error generating shapefile.  Email the current url, scalar field name, and bin settings to Brian_Blanton@Renci.Org\n')
        disp('Error generating shapefile.  Email the current url, scalar field name, and bin settings to Brian_Blanton@Renci.Org')
        throw(ME);
    end
    
    figure
    geoshow(SS,'SymbolSpec',spec)
    caxis([edges(1) edges(end)])
    colormap(jet(length(bin_centers)))
    colorbar
    title(sprintf('GeoShow view of exported Shape File in %s',strrep(OutName,'_','\_')))
    axes(Handles.MainAxes);

    shapewrite(SS,sprintf('%s.shp',OutName))
    SetUIStatusMessage(sprintf('Done. Shape File = %s/%s\n',pwd,OutName))

end

%%  GraphicOutputPrint
%%% GraphicOutputPrint
%%% GraphicOutputPrint
function GraphicOutputPrint(~,~) 

    global Connections

    %prepare for a new figure
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');

    EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
    ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');
    VectorAsScalar=get(Handles.VectorAsScalarButton,'Value');

    if VectorAsScalar
        VariableClicked=VectorVariableClicked;
    else
        VariableClicked=ScalarVariableClicked;
    end
      
    EnsembleNames=Connections.EnsembleNames; 
    
    SelectedType=get(get(Handles.GraphicOutputHandlesGroup,'SelectedObject'),'string');
    SelectedType=strtrim(SelectedType(end-3:end));
       
    EnsembleNames=Connections.EnsembleNames; 
    VariableNames=Connections.VariableNames; 
    EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
    VarIndex=find(strcmp(VariableClicked,VariableNames));
    
    Units=Connections.members{EnsIndex,VarIndex}.Units;    %#ok<FNDSB>
    
    list={'painter','zbuffer','OpenGL'};
    val = get(Handles.FigureRenderer,'Value');
    Renderer=lower(list{val});
    
    titlestr=get(get(Handles.MainAxes,'Title'),'String');
    if iscell(titlestr)
        titlestr=titlestr{1};
    end
    titlestr=strrep(deblank(titlestr),' ','_'); 
    titlestr=strrep(titlestr,'=','');
   
    % get colormap and limits from the user-altered axes, not the defaults! 
    axes(Handles.MainAxes);
    cmap=colormap;
    cax=caxis;
    
    if strfind(VariableClicked,'snapshot')
       SnapshotClickedID=get(Handles.SnapshotButtonHandles,'value');
       SnapshotClicked=get(Handles.SnapshotButtonHandles,'string');
       SnapshotClicked=SnapshotClicked(SnapshotClickedID,:);
       SnapshotClicked=datestr(SnapshotClicked,30);
       filenamedefault=strcat(titlestr,'_',EnsembleClicked,'_',VariableClicked,'_',SnapshotClicked,'_',SelectedType );
       SetUIStatusMessage(['Ensemble = ' EnsembleClicked ', Variable = ' VariableClicked])
       SetUIStatusMessage(['Snapshot = ' SnapshotClicked])
    else
       filenamedefault=strcat(titlestr,'_',EnsembleClicked,'_',VariableClicked,'_',SelectedType);
       SetUIStatusMessage(['Ensemble = ' EnsembleClicked ', Variable = ' VariableClicked '\n'])
    end
    
    %filename=strcat(filename,filterorder{filterindex,:});
    set(gcf,'PaperPositionMode','auto')
    % copy MainAxes into separate figure
    if strfind(SelectedType,'Axes')
        temp=figure('Visible','on');
        h1=copyobj(Handles.MainAxes,temp);
        set(h1,'Units','normalized')
        set(h1,'Position',[.1 .1 .8 .8])
        set(h1,'Box','on')
        set(h1,'FontSize',16)
        %h2=copyobj(Handles.ColorBar,temp);
        h2=colorbar;
        set(get(h2,'ylabel'),...
            'String',sprintf('%s',Units),'FontSize',FontSizes(4));
        CLim([cax(1) cax(2)])
        colormap(cmap)
        set(temp,'Renderer',Renderer)
        %close(temp);
    end
    
    filenamedefault=[TempDataLocation '/' filenamedefault];
    %    filterorder={'.png';'.pdf';'.jpg';'.tif';'.bmp'};
    printopt={'-dpng';'-dpdf';'-djpeg';'-dtiff';'-dbmp'};
    [filename, pathname, filterindex]=uiputfile(...
        {'*.png','Portable Network Graphic file (*.png)';...
        '*.pdf','Portable Document Format (*.pdf)';...
        '*.jpg','JPEG image (*.jpg)';...
        '*.tif','TIFF image (*.tif)';...
        '*.bmp','Bitmap file (*.bmp)';...
        '*.*','All Files' },'Save Image',...
        filenamedefault);
    
    Renderer=['-' Renderer];
    
    if ~(isequal(filename,0) || isequal(pathname,0) || isequal(filterindex,0))
        if strfind(SelectedType,'Axes')
            print(temp,printopt{filterindex,:},'-r200',Renderer,fullfile(pathname,filename));
        elseif strfind(SelectedType, 'GUI')
            print(Handles.MainFigure,printopt{filterindex,:},'-r200',Renderer,fullfile(pathname,filename));
        end
    else
        %disp('User Cancelled...')
    end  
      
end

%%  SetTransparency
%%% SetTransparency
%%% SetTransparency
function SetTransparency(hObj,~)

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    AlphaVal = get(hObj,'Value');
    set(Handles.TriSurf,'FaceAlpha',AlphaVal);
    % need to set renderer to OpenGL
    set(Handles.FigureRenderer,'Value',3)
    axes(Handles.MainAxes);
    parent=get(get(Handles.MainAxes,'Parent'),'Parent');
    set(parent,'Renderer','OpenGL');  
    
end

%%  SetFigureRenderer
%%% SetFigureRenderer
%%% SetFigureRenderer
function SetFigureRenderer(hObj,~) 

    list={'painter','zbuffer','OpenGL'};
    val = get(hObj,'Value');
    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    parent=get(get(Handles.MainAxes,'Parent'),'Parent');

    set(parent,'Renderer',list{val});

end

%%  ResetAxes
%%% ResetAxes
%%% ResetAxes
function ResetAxes(~,~)
    global Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    SSVizOpts=getappdata(FigThatCalledThisFxn,'SSVizOpts');

    axes(Handles.MainAxes);
    
    axx=SSVizOpts.DefaultBoundingBox;
    
    axis(axx)
    set(Handles.AxisLimits,'String',sprintf('%.2f  ',axx));
    setappdata(Handles.MainFigure,'BoundingBox',axx);

end

%%  ShowTrack
%%% ShowTrack
%%% ShowTrack
function ShowTrack(hObj,~) 

    global Connections Debug 
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
  
    CurrentPointer=get(Handles.MainFigure,'Pointer');
    set(Handles.MainFigure,'Pointer','watch');
    
    temp=findobj(Handles.MainAxes,'Tag','Storm_Track');
    temp2=findobj(Handles.MainAxes,'Tag','AtcfTrackShape');
    if isempty(temp)
        SetUIStatusMessage('Drawing Track ... \n')

        % get the current ens member
        temp=get(Handles.EnsButtonHandles,'Value');
        if length(temp)==1
            CurrentEnsMember=1;
        else
            CurrentEnsMember=find([temp{:}]);
        end
        
        if isfield(Connections,'Tracks')
            track=Connections.Tracks{CurrentEnsMember};
            axes(Handles.MainAxes);
            Handles.Storm_Track=DrawTrack(track);
            if isfield(Connections,'AtcfShape')
               Handles.AtcfTrack=PlotAtcfShapefile(Connections.AtcfShape);
            end
            set(hObj,'String','Hide Track')
        end
    else
        SetUIStatusMessage('Hiding Track ... \n')
        delete(temp);
        delete(temp2);
        Handles.Storm_Track=[];
        set(FigThatCalledThisFxn,'UserData',Handles);
        set(hObj,'String','Show Track')
    end
    drawnow
    set(Handles.MainFigure,'Pointer','arrow');
    SetUIStatusMessage('Done. \n')

end

%%  ShowMapThings
%%% ShowMapThings
%%% ShowMapThings
function ShowMapThings(hObj,~) 

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    temp1=findobj(Handles.MainAxes,'Tag','SSVizShapesCounties');
    temp2=findobj(Handles.MainAxes,'Tag','SSVizShapesRoadways');
    temp3=findobj(Handles.MainAxes,'Tag','SSVizShapesStateLines');
    temp4=findobj(Handles.MainAxes,'Tag','SSVizShapesCities');
    temp=[temp1(:);temp2(:);temp3(:);temp4(:)];
    axes(Handles.MainAxes);
    
    if any([isempty(temp1)  isempty(temp2) isempty(temp3) isempty(temp4)])  % no objs found; need to draw
        SetUIStatusMessage('Loading shapes...')
        Shapes=LoadShapes;
        setappdata(Handles.MainAxes,'Shapes',Shapes);
        %SetUIStatusMessage('Done.')
        h=plotroads(Shapes.major_roads,'Color',[1 1 1]*.4,'Tag','SSVizShapesRoadways','LineWidth',2);
        h=plotcities(Shapes.cities,'Tag','SSVizShapesCities'); 
        h=plotroads(Shapes.counties,'Tag','SSVizShapesCounties'); 
        h=plotstates(Shapes.states,'Color','b','LineWidth',1,'Tag','SSVizShapesStateLines'); 
        %Shapes=getappdata(Handles.MainAxes,'Shapes');
        set(hObj,'String','Hide Roads/Counties')
    else
        if strcmp(get(temp(1),'Visible'),'off')
            set(temp,'Visible','on');
            set(hObj,'String','Hide Roads/Counties')
        else
            set(temp,'Visible','off');
            set(hObj,'String','Show Roads/Counties')
        end
    end
    
end

%%  ShowMinimum
%%% ShowMinimum
%%% ShowMinimum
function ShowMinimum(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
    
    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    Field=getappdata(Handles.TriSurf,'Field');

    temp=findobj(Handles.MainAxes,'Tag','MinMarker');
    axes(Handles.MainAxes);
    if isempty(temp)
        idx=GetNodesInView(TheGrid);
        [Min,idx2]=min(Field(idx));
        idx=idx(idx2);
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','o','Color',[1 0 0],...
            'MarkerSize',20,'Tag','MinMarker','LineWidth',3,'Clipping','on');
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','x','Color',[0 1 1],...
            'MarkerSize',20,'Tag','MinMarker','Clipping','on');
        
        SetUIStatusMessage(sprintf('Minimum in view = %.2f\n',Min))
        
        set(hObj,'String','Hide Minimum')
    else
        delete(temp);
        set(hObj,'String','Show Minimum in View')
    end
    
end

%%  ShowMaximum
%%% ShowMaximum
%%% ShowMaximum
function ShowMaximum(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    Field=getappdata(Handles.TriSurf,'Field');

    temp=findobj(Handles.MainAxes,'Tag','MaxMarker');
    if isempty(temp)
        axes(Handles.MainAxes);
        idx=GetNodesInView(TheGrid);
        [Max,idx2]=max(Field(idx));
        idx=idx(idx2);
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','o','Color',[0 0 1],...
            'MarkerSize',20,'Tag','MaxMarker','LineWidth',3,'Clipping','on');
        line(TheGrid.x(idx),TheGrid.y(idx),1,'Marker','x','Color',[1 1 0],...
            'MarkerSize',20,'Tag','MaxMarker','Clipping','on');
        
        SetUIStatusMessage(sprintf('Maximum in view = %.2f\n',Max))

        set(hObj,'String','Hide Maximum')
    else
        delete(temp);
        set(hObj,'String','Show Maximum in View')
    end
    
end

%%  FindFieldValue
%%% FindFieldValue
%%% FindFieldValue
function FindFieldValue(hObj,~) 

    FigToSet=gcbf;
    Handles=get(FigToSet,'UserData');
    %MarkerHandles=findobj(Handles.MainAxes,'Tag','NodeMarker');
    %TextHandles=findobj(Handles.MainAxes,'Tag','NodeText');

    if isfield(Handles,'MainFigureSub')
        FigToSet=Handles.MainFigureSub;
    end
    
    button_state=get(hObj,'Value');
    if button_state==get(hObj,'Max')
        pan off
        zoom off
        set(FigToSet,'WindowButtonDownFcn',@InterpField)
        SetUIStatusMessage('Click on map to get field value ...')
    elseif button_state==get(hObj,'Min')
        %if ~isempty(MarkerHandles),delete(MarkerHandles);end
        %if ~isempty(TextHandles),delete(TextHandles);end
        set(FigToSet,'WindowButtonDownFcn','')
        SetUIStatusMessage('Done.')
    end

end

%%  InterpField
%%% InterpField
%%% InterpField
function InterpField(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    MainVizAppFigure=findobj(FigThatCalledThisFxn,'Tag','MainVizAppFigure');
    SSVizOpts=getappdata(FigThatCalledThisFxn,'SSVizOpts');
    
    Handles=get(MainVizAppFigure,'UserData');
    cax=Handles.MainAxes; 
    xli=xlim(cax);
    yli=ylim(cax);
    dx=(xli(2)-xli(1))*0.012;
    dy=(yli(2)-yli(1))*0.02;
    Units=get(Handles.UnitsString,'String');
    Field=getappdata(Handles.TriSurf,'Field');
    %MarkerHandles=findobj(Handles.MainAxes,'Tag','NodeMarker');
    %TextHandles=findobj(Handles.MainAxes,'Tag','NodeText');
    if strcmp(get(hObj,'SelectionType'),'normal')

        %  if ~isempty(MarkerHandles),delete(MarkerHandles);end
        %  if ~isempty(TextHandles),delete(TextHandles);end
        axes(Handles.MainAxes);
        findlocation=get(Handles.MainAxes,'CurrentPoint');
        x=findlocation(1,1);
        y=findlocation(1,2);
        InView=IsInView(x,y);
        if InView
            %line(x,y,'Marker','o','Color','k','MarkerFaceColor','k','MarkerSize',5,'Tag','NodeMarker');
            % find element & interpolate scalar
            if SSVizOpts.UseStrTree && isfield(TheGrid,'strtree') && ~isempty(TheGrid.strtree)
                j=FindElementsInStrTree(TheGrid,x,y);
            else
                j=findelem(TheGrid,x,y);
            end
            if ~isnan(j)
                InterpTemp=interp_scalar(TheGrid,Field,x,y,j);
            else
                InterpTemp='OutsideofDomain';
            end
            if isnan(InterpTemp)
                text(x+dx,y-dy,2,'Dry','Color','k','Tag','NodeText','FontWeight','bold','Clipping','on')
                SetUIStatusMessage(['Selected Location (',num2str(x, '% 10.2f'),' , ',num2str(y, '% 10.2f'),') is dry'])
            elseif strcmp(InterpTemp,'OutsideofDomain')
                %text(x+dx,y-dy,'NaN','Color','k','Tag','NodeText','FontWeight','bold')
                %SetUIStatusMessage(['Selected Location (',num2str(x, '% 10.2f'),' , ',num2str(y, '% 10.2f'),') is outside of grid domain'])
                SetUIStatusMessage('Selected Location is outside of grid.')
            else
                line(x,y,2,'Marker','o','Color','k','MarkerFaceColor','k','MarkerSize',5,'Tag','NodeMarker','Clipping','on');
                text(x+dx,y-dy,2,num2str(InterpTemp,'%5.2f'),'Color','k','Tag','NodeText','FontWeight','bold','Clipping','on')
                SetUIStatusMessage(['Field Value at (',num2str(x, '% 10.2f'),' , ',num2str(y, '% 10.2f'),') is ', num2str(InterpTemp, '%5.2f'),' ',Units])
            end
        end
    end
    
end



%%% Utility functions
%%% Utility functions
%%% Utility functions



%%  RecordAxisLimits
function RecordAxisLimits(~,arg2)
  
    MainFig=get(get(arg2.Axes,'Parent'),'Parent');
    Handles=get(MainFig,'UserData');
    axx=axis;
    setappdata(Handles.MainFigure,'BoundingBox',axx);
    set(Handles.AxisLimits,'String',sprintf('%.2f  ',axx))
    RendererKludge;

end

%%  GetNodesInView
function idx=GetNodesInView(TheGrid)

    axx=axis;
    idx=find(TheGrid.x<axx(2) & TheGrid.x>axx(1) & ...
        TheGrid.y<axx(4) & TheGrid.y>axx(3));

end

%%  IsInView
function idx=IsInView(x,y)

    axx=axis;
    idx=(x<axx(2) & x>axx(1) & ...
        y<axx(4) & y>axx(3));

end

%%  GetMinMaxInView
function [Min,Max]=GetMinMaxInView(TheGrid,TheField)

    idx=GetNodesInView(TheGrid);
    Min=min(TheField(idx));
    Max=max(TheField(idx));

end

%%  CLim
function CLim(clm)
    if clm(2)>clm(1)
        set(gca,'CLim',clm)
    else
        SetUIStatusMessage('Error: Color Min > Color Max.  Check values.')
    end
end





%%  GetColors
% function [minThisData,maxThisData,NumberOfColors]=GetColors(Handles)
%      maxThisData=str2double(get(Handles.CMax));
%      minThisData=str2double(get(Handles.CMin));
%      NumberOfColors=str2int(get(Handles.NCol));
% end

%%  SetTitle
function SetTitle(str)
    title(str,'FontWeight','bold') 
end
function SetTitleOld(RunProperties)
    
    % SetTitle MUST be called AFTER the Handle struct is set back in the
    % caller:  I.e., it must be placed after
    % "set(Handles.MainFigure,'UserData',Handles);"
    
    f=findobj(0,'Tag','MainVizAppFigure');
    Handles=get(f,'UserData');
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');              
        
    LocalTimeOffset=SSVizOpts.LocalTimeOffset;
    DateStringFormat=getappdata(Handles.MainFigure,'DateStringFormatOutput');
    
    advisory=GetRunProperty(RunProperties,'advisory');
    if strcmp(advisory,'0'),advisory=[];end
    
    stormname=GetRunProperty(RunProperties,'stormname');
    
    if strcmp(stormname,'STORMNAME')
        stormname='Nam-Driven';
        NowcastForecastOffset=0;
    else
        NowcastForecastOffset=3;
    end
    
    if isempty(get(Handles.TriSurf,'UserData'))
    
        ths=str2double(GetRunProperty(RunProperties,'InitialHotStartTime'));
        tcs=GetRunProperty(RunProperties,'ColdStartTime');
        tcs=datenum(tcs,'yyyymmddHH');
        t=tcs+ths/86400;
        t=t+LocalTimeOffset/24;
        t=t+NowcastForecastOffset/24;

    else
    
        t=get(Handles.TriSurf,'UserData');
        %t=datenum(t,DateStringFormat);
    
    end
    
    
%    LowerString=datestr((datenum(currentdate,'yymmdd')+...
%        (NowcastForecastOffset)/24+LocalTimeOffset/24),'ddd, dd mmm, HH PM');
    LowerString=datestr(t,DateStringFormat);

    
    if ~isempty(advisory)
        %titlestr={sprintf('%s  Advisory=%s  ',stormname, advisory),[LowerString ' ']};
        titlestr=[sprintf('%s  Advisory=%s  ',stormname, advisory),[' ' LowerString ' ']];
    else    
        %titlestr={sprintf('%s',stormname),[LowerString ' ']};
        titlestr=[sprintf('%s',stormname),[' ' LowerString ' ']];
    end
    title(titlestr,'FontWeight','bold') 
end




%{
# ***************************************************************************
# 
# RENCI Open Source Software License
# The University of North Carolina at Chapel Hill
# 
# The University of North Carolina at Chapel Hill (the "Licensor") through 
# its Renaissance Computing Institute (RENCI) is making an original work of 
# authorship (the "Software") available through RENCI upon the terms set 
# forth in this Open Source Software License (this "License").  This License 
# applies to any Software that has placed the following notice immediately 
# following the copyright notice for the Software:  Licensed under the RENCI 
# Open Source Software License v. 1.0.
# 
# Licensor grants You, free of charge, a world-wide, royalty-free, 
# non-exclusive, perpetual, sublicenseable license to do the following to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# . Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimers.
# 
# . Redistributions in binary form must reproduce the above copyright 
# notice, this list of conditions and the following disclaimers in the 
# documentation and/or other materials provided with the distribution.
# 
# . Neither You nor any sublicensor of the Software may use the names of 
# Licensor (or any derivative thereof), of RENCI, or of contributors to the 
# Software without explicit prior written permission.  Nothing in this 
# License shall be deemed to grant any rights to trademarks, copyrights, 
# patents, trade secrets or any other intellectual property of Licensor 
# except as expressly stated herein.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE CONTIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
# OTHER DEALINGS IN THE SOFTWARE.
# 
# You may use the Software in all ways not otherwise restricted or 
# conditioned by this License or by law, and Licensor promises not to 
# interfere with or be responsible for such uses by You.  This Software may 
# be subject to U.S. law dealing with export controls.  If you are in the 
# U.S., please do not mirror this Software unless you fully understand the 
# U.S. export regulations.  Licensees in other countries may face similar 
# restrictions.  In all cases, it is licensee's responsibility to comply 
# with any export regulations applicable in licensee's jurisdiction.
# 
# ***************************************************************************# 
%}
