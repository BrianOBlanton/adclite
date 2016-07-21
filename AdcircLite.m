function varargout=AdcircLite(varargin)
%
% AdcircLite - Visualization Application for Adcirc Lite RSM
% 
% Call as: AdcircLite(P1,V1,P2,V2,...)
%
% Allowed Parameter/Value pairs (default value listed first):
%
% Units             - String to set height units; {'Meters','Feet'}
% FontOffset        - Integer to increase (+) or decrease (-) fontsize in the app;
% LocalTimeOffset   - (0, i.e. UTC) Hour offset for displayed times ( < 0 for west of GMT).
% BoundingBox       - [xmin xmax ymin ymax] vector for initial axes zoom
% ColorMax          - Maximum scalar value for color scaling
% ColorMin          - Minimum scalar value for color scaling
% ColorMap          - Color map to use; {'noaa_cmap','jet','hsv',...}
% DisableContouring - {false,true} logical disabling mex compiled code calls
% GoogleMapsApiKey  - Api Key from Google for extended map accessing
%
% Only one instance of AdcircLite is allowed concurrently.  Close existing
% instances first.
%
% Example:
%
% >> AdcircLite;
% or
% >> close all; AdcircLite('Units','feet',...)
% or 
% [Handles,Options]=AdcircLite(P1,V1,P2,V2,...);
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
        fprintf('Call as (e.g.): close all; AdcircLite(''FontOffset'',-2,''Units'',''feet'')\n')
        return
    end
end

% check to see if another instance of AdcircLite is already running
tags=findobj(0,'Tag','MainAdcLVizAppFigure');
if ~isempty(tags)
    close(tags)

%    str={'Only one instance of AdcircLite can run simultaneously.'
%         'Press Continue to close other AdcircLite instances and start this one, or Cancel to abort the current instance.'};
%    ButtonName=questdlg(str,'Other AdcircLite Instances Found!!!','Continue','Cancel','Cancel');
%     switch ButtonName,
%         case 'Continue'
%             close(tags)
%         otherwise
%             fprintf('Aborting this instance of AdcircLite.\n')
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

%% Initialize AdcircLite
HOME=fileparts(which(mfilename));
javaaddpath([HOME '/DoubleJSlider.jar']);
% try 
%     net.sf.genomeview.gui.components.DoubleJSlider
%     loadflag=false;
% catch
%     javaaddpath([HOME '/DoubleJSlider.jar']);
%     loadflag=true;
% end

fprintf('\nAdcL++ Initializing application.\n')
global ADCLOPTS
ADCLOPTS=AdcircLite_Init(varargin{:});

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
fprintf('AdcL++ Loading RSM ... \n')
if ~ADCLOPTS.UseInMemoryModel
   [Model,TheGrid]=LoadRsmModel(ADCLOPTS.ADCLHOME,ADCLOPTS.ModelDir,ADCLOPTS.ModelFile,ADCLOPTS.ModelURL,ADCLOPTS.ModelName,ADCLOPTS.GridName);
end

TheGrids{1}=TheGrid;


%% InitializeUI
Handles=InitializeUI(ADCLOPTS);

setappdata(Handles.MainFigure,'AdcLOpts',ADCLOPTS);
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
set(Handles.MainFigure,'UserData',Handles);

% evaluate the default response, in the vector X of Model
EvaluateModel(Handles.MainFigure);
Handles=get(Handles.MainFigure,'UserData');

RendererKludge;  %% dont ask...

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

%%  DrawDepthContours
%%% DrawDepthContours
%%% DrawDepthContours
function DrawDepthContours(hObj,~)
    
    global TheGrids Debug
   if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

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

%%%%%%%%%%%%%%%%
%%  DrawTrack
%%% DrawTrack
%%% DrawTrack
%%%%%%%%%%%%%%%%
function h=DrawTrack(track)
    
    global Debug
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    f=findobj(0,'Tag','MainAdcLVizAppFigure');
    Handles=get(f,'UserData');
    ADCLOPTS=getappdata(Handles.MainFigure,'AdcLOpts');              
    LocalTimeOffset=ADCLOPTS.LocalTimeOffset;
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

%%%%%%%%%%%%%%%%
%%  ClearUI
%%% ClearUI
%%% ClearUI
%%%%%%%%%%%%%%%%
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


%%%%%%%%%%%%%%%%
%%  MakeTheAxesMap
%%% MakeTheAxesMap
%%% MakeTheAxesMap
%%%%%%%%%%%%%%%%
function Handles=MakeTheAxesMap(Handles)

    global TheGrids Debug
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end
   
    TheGrid=TheGrids{1};

    axes(Handles.MainAxes);
    
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');    
    ADCLOPTS=getappdata(Handles.MainFigure,'AdcLOpts');              
    ColorBarLocation=ADCLOPTS.ColorBarLocation;
    HOME=ADCLOPTS.HOME;
    DisableContouring=ADCLOPTS.DisableContouring;

    axx=ADCLOPTS.BoundingBox;
    if isnan(axx),axx=[min(TheGrid.x) max(TheGrid.x) min(TheGrid.y) max(TheGrid.y)];end
    cla
    
    Handles.GridBoundary=plotbnd(TheGrid,'Color','k');
    set(Handles.GridBoundary,'Tag','GridBoundary');
    nz=2*ones(size(get(Handles.GridBoundary,'XData')));
    set(Handles.GridBoundary,'ZData',nz)

    axis('equal')
    axis(axx)
    %ar=(1.0./cos(mean(axx(3:4)) * pi / 180.0));
    %set(gca,'DataAspectRatio',[ar 1 1])
    
    grid on
    box on
    hold on
    view(2)
    
    if ~isempty(which('contmex5'))  && ~DisableContouring
        SetUIStatusMessage('** Drawing depth contours ... \n')
        DepthContours=get(Handles.DepthContours,'String');
        DepthContours=sscanf(DepthContours,'%d');
        Handles.BathyContours=lcontour(TheGrid,TheGrid.z,DepthContours,'Color','k');
        
        Handles.BathyContours=Handles.BathyContours(Handles.BathyContours~=0);
        
        for i=1:length(Handles.BathyContours)
            nz=2*ones(size(get(Handles.BathyContours(i),'XData')));
            set(Handles.BathyContours(i),'ZData',nz)
        end
        set(Handles.BathyContours,'Tag','BathyContours');
    else
        SetUIStatusMessage(sprintf('Contouring routine contmex5 not found for arch=%s.  Skipping depth contours.\n',computer))
        set(Handles.DepthContours,'Enable','off')
    end
 
%     if exist([HOME '/private/gomex_wdbII.cldat'],'file')
%         load([HOME '/private/gomex_wdbII.cldat'])
%         Handles.Coastline=line(gomex_wdbII(:,1),gomex_wdbII(:,2),...
%             'Tag','Coastline');
%     end
    if exist([HOME '/private/states.cldat'],'file')
        load([HOME '/private/states.cldat'])
        Handles.States=line(states(:,1),states(:,2),'Tag','States');
    end
    
    % add colorbar
    pms=Handles.ColormapSetter.String;
    idx=Handles.ColormapSetter.Value;
    cmap=eval(pms{idx});
    colormap(cmap)
    Handles.ColorBar=colorbar('Location',ColorBarLocation);
    set(Handles.ColorBar,'FontSize',FontSizes(2))
    set(get(Handles.ColorBar,'ylabel'),'FontSize',FontSizes(1));
    set(Handles.AxisLimits,'String',sprintf('%6.1f ',axx))

    SetUIStatusMessage('** Done.\n')

end

%%%%%%%%%%%%%%%%
%%  UpdateUI
%%% UpdateUI
%%% UpdateUI
%%%%%%%%%%%%%%%%
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
    
    fc=get(Handles.FixCMap,'Value');
    if ~fc
        SetColors(Handles,CMin,CMax,ADCLOPTS.NumberOfColors,ADCLOPTS.ColorIncrement);
    end
    
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

%%%%%%%%%%%%%%%%
%%  RendererKludge
%%% RendererKludge
%%% RendererKludge
%%%%%%%%%%%%%%%%
function RendererKludge
    global EnableRendererKludge
    if EnableRendererKludge
        delete(findobj(0,'Tag','RendererMarkerKludge'))
        axx=axis;
        line(axx(1),axx(3),'Clipping','on','Tag','RendererMarkerKludge');
    end
end

%%%%%%%%%%%%%%%%
%%  SetGraphicOutputType
%%% SetGraphicOutputType
%%% SetGraphicOutputType
%%%%%%%%%%%%%%%%
function SetGraphicOutputType(hObj,~)
     SelectedType=get(get(hObj,'SelectedObject'),'String');
     SetUIStatusMessage(['Graphic Output is set to the ' SelectedType] )
end

%%%%%%%%%%%%%%%%
%%  ExportShapeFile
%%% ExportShapeFile
%%% ExportShapeFile
%%%%%%%%%%%%%%%%
function ExportShapeFile(~,~)  

%    global TheGrids Connections Debug 
    global TheGrids Debug 

    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end
    
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');
    
%     ScalarSnapshotClicked=floor(get(Handles.ScalarSnapshotSliderHandle,'Value')); 
% 
%     EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
%     ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
%     
%     EnsembleNames=Connections.EnsembleNames; 
%     VariableNames=Connections.VariableNames; 
%     EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames));
%     ScalarVarIndex=find(strcmp(ScalarVariableClicked,VariableNames));

    GridId=1; % Connections.members{EnsIndex,ScalarVarIndex}.GridId;
    TheGrid=TheGrids{GridId};

    OutName=get(Handles.DefaultShapeFileName,'String'); 
    if isempty(OutName)
        SetUIStatusMessage('Set ExportShapeFileName to something reasonable.... \n')
        return
    end
        
    %ThisData=Connections.members{EnsIndex,ScalarVarIndex}.TheData{ScalarSnapshotClicked};
    ThisData=Handles.TriSurf.FaceVertexCData;
    temp=get(Handles.ShapeFileBinCenterIncrement,'String'); 
    BinCenters=sscanf(temp,'%d');
    e0=ceil(min(ThisData/BinCenters))*BinCenters;
    e1=floor(max(ThisData/BinCenters))*BinCenters;
    bin_centers=e0:BinCenters:e1;
    
    SetUIStatusMessage('Making shape file object.  Stand by ... \n')
    try 
        [SS,edges,spec]=MakeAdcircShape(TheGrid,ThisData,bin_centers,'FeatureName','WaterLevel');
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

    OutFullName = fullfile(TempDataLocation,OutName);
    OutFullSpec = sprintf('%s.shp',OutFullName);
    shapewrite(SS,OutFullSpec)
    SetUIStatusMessage(sprintf('Done. Shape File = %s\n',OutFullSpec))

end

%%%%%%%%%%%%%%%%
%%  GraphicOutputPrint
%%% GraphicOutputPrint
%%% GraphicOutputPrint
%%%%%%%%%%%%%%%%
function GraphicOutputPrint(~,~) 

%    global Connections

    %prepare for a new figure
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');
    TempDataLocation=getappdata(Handles.MainFigure,'TempDataLocation');

%     EnsembleClicked=get(get(Handles.EnsButtonHandlesGroup,'SelectedObject'),'string');
%     ScalarVariableClicked=get(get(Handles.ScalarVarButtonHandlesGroup,'SelectedObject'),'string');
%     VectorVariableClicked=get(get(Handles.VectorVarButtonHandlesGroup,'SelectedObject'),'string');
%     VectorAsScalar=get(Handles.VectorAsScalarButton,'Value');
% 
%     if VectorAsScalar
%         VariableClicked=VectorVariableClicked;
%     else
%         VariableClicked=ScalarVariableClicked;
%     end
%       
%     EnsembleNames=Connections.EnsembleNames; 
    
    SelectedType=get(get(Handles.GraphicOutputHandlesGroup,'SelectedObject'),'string');
    SelectedType=strtrim(SelectedType(end-3:end));
       
%     EnsembleNames=Connections.EnsembleNames; 
%     VariableNames=Connections.VariableNames; 
%     EnsIndex=find(strcmp(EnsembleClicked,EnsembleNames)); 
%     VarIndex=find(strcmp(VariableClicked,VariableNames));
%     
%     Units=Connections.members{EnsIndex,VarIndex}.Units;    %#ok<FNDSB>
    Units=Handles.UnitsString.String;
    
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
    
%     if strfind(VariableClicked,'snapshot')
%        SnapshotClickedID=get(Handles.SnapshotButtonHandles,'value');
%        SnapshotClicked=get(Handles.SnapshotButtonHandles,'string');
%        SnapshotClicked=SnapshotClicked(SnapshotClickedID,:);
%        SnapshotClicked=datestr(SnapshotClicked,30);
%        filenamedefault=strcat(titlestr,'_',EnsembleClicked,'_',VariableClicked,'_',SnapshotClicked,'_',SelectedType );
%        SetUIStatusMessage(['Ensemble = ' EnsembleClicked ', Variable = ' VariableClicked])
%        SetUIStatusMessage(['Snapshot = ' SnapshotClicked])
%     else
%        filenamedefault=strcat(titlestr,'_',EnsembleClicked,'_',VariableClicked,'_',SelectedType);
%        SetUIStatusMessage(['Ensemble = ' EnsembleClicked ', Variable = ' VariableClicked '\n'])
%     end

    filenamedefault=titlestr;

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

%%%%%%%%%%%%%%%%
%%  SetTransparency
%%% SetTransparency
%%% SetTransparency
%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%
%%  SetFigureRenderer
%%% SetFigureRenderer
%%% SetFigureRenderer
%%%%%%%%%%%%%%%%
function SetFigureRenderer(hObj,~) 

    list={'painter','zbuffer','OpenGL'};
    val = get(hObj,'Value');
    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    parent=get(get(Handles.MainAxes,'Parent'),'Parent');

    set(parent,'Renderer',list{val});

end

%%%%%%%%%%%%%%%%
%%  ResetAxes
%%% ResetAxes
%%% ResetAxes
%%%%%%%%%%%%%%%%
function ResetAxes(~,~)
    global Debug
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    ADCLOPTS=getappdata(FigThatCalledThisFxn,'AdcLOpts');

    axes(Handles.MainAxes);
    
    axx=ADCLOPTS.DefaultBoundingBox;
    
    axis(axx)
    set(Handles.AxisLimits,'String',sprintf('%6.1f ',axx));
    setappdata(Handles.MainFigure,'BoundingBox',axx);

end

%%%%%%%%%%%%%%%%
%%  ShowTrack
%%% ShowTrack
%%% ShowTrack
%%%%%%%%%%%%%%%%
function ShowTrack(hObj,~) 

    global Connections Debug 
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end
    
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
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    TheGrid=TheGrids{1};

    FigThatCalledThisFxn=gcbf;
    MainAdcLVizAppFigure=findobj(FigThatCalledThisFxn,'Tag','MainAdcLVizAppFigure');
    ADCLOPTS=getappdata(FigThatCalledThisFxn,'AdcLOpts');
    
    Handles=get(MainAdcLVizAppFigure,'UserData');
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
            if ADCLOPTS.UseStrTree && isfield(TheGrid,'strtree') && ~isempty(TheGrid.strtree)
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

%%  InitializeUI
%%% InitializeUI
%%% InitializeUI
function Handles=InitializeUI(Opts)

%%% This function sets up the gui and populates several UserData and
%%% ApplicationData properties with data needed by other functions and ui
%%% callbacks, some of which is set in other functions
%%%
%%% MainFigure : UserData contains the application handle list
%%% MainFigure : ApplicationData contains initialization parameters, etc...
%%% MainAxes   : UserData 
%%% MainAxes   : ApplicationData 

global Debug
global Model

fprintf('AdcL++ Setting up GUI ... \n')
if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

FontOffset=Opts.FontOffset;
AppName=Opts.AppName;
BoundingBox=Opts.BoundingBox;
DepthContours=Opts.DepthContours;
ColorMap=Opts.ColorMap;
UseGoogleMaps=Opts.UseGoogleMaps;
ForkAxes=Opts.ForkAxes;
HOME=Opts.HOME;
KeepInSync=Opts.KeepScalarsAndVectorsInSync;

panelColor = get(0,'DefaultUicontrolBackgroundColor');

ratio_x=get(0,'ScreenPixelsPerInch')/72;
fs3=floor(get(0,'DefaultAxesFontSize')/ratio_x)+FontOffset;
fs4=fs3-2;
fs2=fs3+2;
fs1=fs3+4;
fs0=fs3+6;
%global Vecs
%Vecs='on';
AxesBackgroundColor=[1 1 1]*.6;

%LeftEdge=.01;

colormaps={'parula','noaa_cmap','jet','hsv','hot','cool','gray'};
cmapidx=find(strcmp(ColorMap,colormaps));

Lon_South_Offset = Model.CrossingLines.LatSouth.lon(1); 
Lon_North_Offset = Model.CrossingLines.LatNorth.lon(1); 
   
% normalized positions of container panels depend on ForkAxes
if ~ForkAxes
    
    Handles.MainFigure=figure(...
        'Units','normalized',...
        'Color',panelColor,...
        'OuterPosition',[0.05 .2 Opts.AppWidthPercent/100 .877*Opts.AppWidthPercent/100],...
        'ToolBar','figure',...
        'DeleteFcn',@ShutDownUI,...
        'Tag','MainAdcLVizAppFigure',...
        'NumberTitle','off',...
        'Name',AppName,...
        'Resize','on');
        Handles.panHandle=pan(Handles.MainFigure); %#ok<*NASGU>
        Handles.zoomHandle=zoom(Handles.MainFigure);
        
    Positions.CenterContainerUpper      = [.50 .45 .24 .54];
    Positions.CenterContainerMiddle     = [.50 .21 .12 .23];
    Positions.CenterContainerLowerLeft  = [.50 .10 .12 .11];
    Positions.CenterContainerLowerRight = [.63 .10 .12 .21];
    Positions.FarRightContainer         = [.75 .10 .24 .79];
    Positions.LogoContainer             = [.75 .90 .24 .09];
    Positions.StatusUrlBarContainer     = [.50 .01 .49 .09];
                   
else
    
    Handles.MainFigure=figure(...
        'Units','normalized',...
        'Color',panelColor,...
        'OuterPosition',[0.52 .2 .45 .79],...
        'ToolBar','figure',...
        'DeleteFcn',@ShutDownUI,...
        'Tag','MainAdcLVizAppFigure',...
        'NumberTitle','off',...
        'Name',AppName,...
        'Resize','on');
    
    Handles.MainFigureSub=figure(...  % this contains the drawing axes if forked
        'Units','normalized',...
        'Color',panelColor,...
        'OuterPosition',[0.05 .2 .9 .8],...
        'ToolBar','figure',...
        'DeleteFcn','',...
        'Tag','MainAdcLVizAppFigureSub',...
        'NumberTitle','off',...
        'Name',AppName,...
        'CloseRequestFcn','');
    
    Handles.panHandle=pan(Handles.MainFigureSub);
    Handles.zoomHandle=zoom(Handles.MainFigureSub);
    
    Positions.CenterContainerUpper       = [.01 .45 .48 .54];
    Positions.CenterContainerMiddle      = [.01 .21 .48 .23];
    Positions.CenterContainerLowerLeft   = [.01 .10 .48 .11];
    Positions.CenterContainerLowerRight  = [.01 .10 .48 .11];
    Positions.FarRightContainer          = [.50 .10 .48 .79];
    Positions.LogoContainer              = [.50 .90 .48 .09];
    Positions.StatusUrlBarContainer      = [.01 .01 .98 .09];
    
end

Handles=SetPanZoomFxns(Handles);

% set(Handles.panHandle,'ActionPostCallback',@RecordAxisLimits);
% set(Handles.zoomHandle,'ActionPostCallback',@RecordAxisLimits);

setappdata(Handles.MainFigure,'FontSizes',[fs0 fs1 fs2 fs3]);

%% containers for figure content
%%%%%%%%
% StatusUrlBar Container
% StatusUrlBar Container
%%%%%%%%
StatusUrlBarContainer = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Position',Positions.StatusUrlBarContainer);

%%%%%%%%
% MainAxes Container
% MainAxes Container
%%%%%%%%
if ~ForkAxes
    MainAxesPanel = uipanel(...
        'Parent',Handles.MainFigure,...
        'BorderType','etchedin',...
        'BackgroundColor',panelColor,...
        'Units','normalized',...
        'Position',[.01 .01 .49 .98]);
else
    MainAxesPanel = uipanel(...
        'Parent',Handles.MainFigureSub,...
        'BorderType','etchedin',...
        'BackgroundColor',panelColor,...
        'Units','normalized',...
        'Position',[.01 .01 .98 .98]);
end

%%%%%%%%
% Center Container Upper
% Center Container Upper
%%%%%%%%
Handles.CenterContainerUpper = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'HitTest','off',...
    'title','',...
    'Position',Positions.CenterContainerUpper);

%%%%%%%%
% Center Container Middle
% Center Container Middle
%%%%%%%%
Handles.CenterContainerMiddle = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','beveledin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Title','Background Maps',...
    'FontSize',fs0,...
    'HitTest','off',...
    'Position',Positions.CenterContainerMiddle);

%%%%%%%%
% Center Container Lower Left
% Center Container Lower Left
%%%%%%%%
Handles.CenterContainerLowerLeft = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','beveledin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Title','Print',...
    'FontSize',fs0,...
    'HitTest','off',...
    'Position',Positions.CenterContainerLowerLeft);

%%%%%%%%
% Center Container Lower Right
% Center Container Lower Right
%%%%%%%%
Handles.CenterContainerLowerRight = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','beveledin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Title','ShapeFiles',...
    'FontSize',fs0,...
    'HitTest','off',...
    'Position',Positions.CenterContainerLowerRight);

%%%%%%%%
% FarRight Containers 
% FarRight Containers 
%%%%%%%%

LogoContainer = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Visible','off',...
    'Position',Positions.LogoContainer);

FarRightContainer = uipanel(...
    'Parent',Handles.MainFigure,...
    'BorderType','etchedin',...
    'BackgroundColor',panelColor,...
    'Units','normalized',...
    'Position',Positions.FarRightContainer);

Handles.InformationPanel = uipanel(...
    'Parent',FarRightContainer,...
    'Title','Information',...
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Position',[.01 .60 .98 .39]);

Handles.VectorOptionsPanel = uipanel(...
    'Parent',FarRightContainer,...
    'Title','Vector Options',...
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Visible','off',...
    'Position',[.01 .60 .98 .39]);

Handles.ControlPanel = uipanel(...
    'Parent',FarRightContainer,...
    'Title','Controls',...
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Visible','off',...
    'Position',[.01 .01 .98 .58]);

Handles.ParameterControlPanel = uipanel(...
    'Parent',Handles.CenterContainerUpper,...
    'Title','Storm Parameters',...  
    'BackgroundColor',panelColor,...
    'FontSize',fs0,...
    'bordertype','etchedin',...
    'Visible','on',...
    'Position',[.01 .01 .98 .98]);

% Place Logos
 
h=axes('Parent',LogoContainer,'Position',[0.20 0.01 .25 .898]);
im=imread([HOME '/private/RENCI-Logo.tiff']);
axes(h)
imshow(im(:,:,1:3))
axis off
set(h,'HandleVisibility','off');

h=axes('Parent',LogoContainer,'Position',[0.575 0.01 .36 .898]); 
im=imread([HOME '/private/unc_ims_logo.jpeg']);
axes(h)
imshow(im)
axis off
set(h,'HandleVisibility','off');
set(LogoContainer,'Visible','on')

%%
%%%%%%%%
% Container Contents
% Container Contents
%%%%%%%%

% MainAxes
Handles.MainAxes=axes(...
    'Parent',MainAxesPanel,...
    'Units','normalized',...
    'Position',[.05 .05 .9 .9],...
    'Box','on',...
    'FontSize',fs0,...
    'Color',AxesBackgroundColor,...
    'Tag','AdcircLiteMainAxes',...
    'Layer','top');


StatusUrlBarContainerContainerContents;
ControlPanelContainerContents;
%VectorOptionsPanelContainerContents;
InformationPanelContainerContents;
GraphicOutputControlContainerContents;
BackgroundMapsContainerContents;
SetParameterContainerContents;

%%% only nested functions below here...

%%  SetParameterControls
%%% SetParameterControls
%%% SetParameterControls
    function SetParameterContainerContents
        
        voffset=.95;
        dy=.17;
        
        labels=Model.v2;
        slider.width=.9;
        slider.height=.05;
        X=Model.X;
        X(5)=Lon_South_Offset+X(5);
        X(6)=Lon_North_Offset+X(6);

        minP=min(Model.P);
        maxP=max(Model.P);
        
%        minP=minP+minP/20;
%        maxP=maxP-maxP/20;
        
        minP(5)=Lon_South_Offset+minP(5);
        minP(6)=Lon_North_Offset+minP(6);

        maxP(5)=Lon_South_Offset+maxP(5);
        maxP(6)=Lon_North_Offset+maxP(6);
        
        font=java.awt.Font('Courier', java.awt.Font.BOLD,10);

        for i=1:6
            uicontrol(...
                'Parent',Handles.ParameterControlPanel,...
                'Style','text',...
                'Units','normalized',...
                'Position',[.01 voffset-(i-1)*dy .50 .05],...
                'HorizontalAlignment','center',...
                'FontSize',fs1,...
                'FontWeight','bold',...
                'String',labels{i});
            
            tagval=sprintf('ParameterControlsParameter%d',i);
            dp=maxP(i)-minP(i);
            
            slider.max=maxP(i);
            slider.min=minP(i);
            slider.start=X(i);
            slider.oom=floor(log10(max(abs([slider.max-slider.min]))))-2;
            slider.step=10^slider.oom;
            slider.imin=ceil(slider.min/slider.step);
            slider.imax=floor(slider.max/slider.step);
            slider.nticksteps=5;
            slider.tickstep=(slider.max-slider.min)/slider.nticksteps;
            slider.ticklocations=linspace(slider.min,slider.max,slider.nticksteps+1);
            slider.tickilocations=round(slider.ticklocations/slider.step);
            slider.tickilocations(1)=slider.tickilocations(1)+1;
            slider.tickilocations(end)=slider.tickilocations(end)-1;
            slider.ticktext=num2str(slider.ticklocations',slider.oom+4);

            [doublejSlider,hdoublejSlider] = javacomponent(...
                net.sf.genomeview.gui.components.DoubleJSlider(...
                slider.min,slider.max,slider.start,slider.step));
            
            doublejSlider.setDoubleMajorTickSpacing(slider.tickstep)
            doublejSlider.setPaintTicks(true);
            doublejSlider.setPaintLabels(true);          
            doublejSlider.setToolTipText('');          
            
            % set labels according to slider content
            labelTable = java.util.Hashtable;
            for ii=1:length(slider.tickilocations)
                label=javax.swing.JLabel(slider.ticktext(ii,:));
                label.setFont(font);
                labelTable.put(java.lang.Integer(slider.tickilocations(ii)),label);
            end
            doublejSlider.setLabelTable(labelTable)

            set(hdoublejSlider,'Parent',Handles.ParameterControlPanel,'units','normalized','position',[.05 voffset-(i-1)*dy-slider.height*2  slider.width slider.height*2]);
            set(hdoublejSlider,'UserData',slider,'Tag',tagval)

            hdoublejSlider = handle(doublejSlider, 'CallbackProperties');
            %hdoublejSlider.MouseReleasedCallback = @setslidervaltext;
            Handles.ParameterControlsParameter(i)=hdoublejSlider;

        end
       
      Handles.EvaluateModel=uicontrol(...
            'Parent',Handles.ParameterControlPanel,...
            'Style','pushbutton',...
            'Units','normalized',...
            'Position',[.65 .95 .3 .05],...
            'HorizontalAlignment','center',...
            'BackGroundColor','w',...
            'Tag','EvaluateModel',...
            'FontSize',fs2,...
            'FontWeight','bold',...
            'String','Evaluate Model',...
            'CallBack',@EvaluateModel);
        
    end

    function setslidervaltext(hObj,~)
        v=num2str(hObj.getDoubleValue,slider.oom+3);
        hObj.setToolTipText(v);
        disp(v)
    end


%%  StatusUrlBarContainerContainerContents
%%% StatusUrlBarContainerContainerContents
%%% StatusUrlBarContainerContainerContents

    function StatusUrlBarContainerContainerContents
        
        % StatusBar
        % StatusBar
        % StatusBar
        uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .55 .09 .44],...
            'HorizontalAlignment','right',...
            'FontSize',fs1,...
            'String','Status :');
        Handles.StatusBar=uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.11 .55 .77 .40],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','StatusBar',...
            'FontSize',fs2,...
            'String','Initializing UI ...');
        
        % UserEnteredText Box
        % UserEnteredText Box
        % UserEnteredText Box
        Handles.UserEnteredText=uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.89 .55 .10 .40],...
            'HorizontalAlignment','center',...
            'BackGroundColor','w',...
            'Tag','UserEnteredText',...
            'FontSize',fs2,...
            'String','');
        %    'Enable','Inactive',...
        %    'Min',0,'Max',3,...
        % ServerBar
        % ServerBar
        % ServerBar
        uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .01 .09 .44],...
            'HorizontalAlignment','right',...
            'Tag','ServerInfo',...
            'FontSize',fs1,...
            'String','URL :');
        Handles.ServerInfoString=uicontrol(...
            'Parent',StatusUrlBarContainer,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.11 .01 .88 .48],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','ServerInfoString',...
            'FontSize',fs2,...
            'String',{'<>'},...
            'CallBack',@InstanceUrl);
        
        %    'BackGroundColor','w',...
        %    'HorizontalAlignment','left',...
       
    end

 %%  Graphic Output Control Container Contents
 %%% Graphic Output Control Container Contents
 %%% Graphic Output Control Container Contents
 
    function GraphicOutputControlContainerContents
        
        printobj={'Current Axes';'Current GUI'};
        Handles.GraphicOutputHandlesGroup = uibuttongroup(...
            'Parent',Handles.CenterContainerLowerLeft,...
            'BorderType','etchedin',...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.1 .96 0.8],...
            'Tag','GraphicOutputHandlesGroup',...
            'SelectionChangeFcn',@SetGraphicOutputType);
        
        for i=1:2
            Handles.GraphicOutputHandles(i)=uicontrol(...
                Handles.GraphicOutputHandlesGroup,...
                'Style','Radiobutton',...
                'String',printobj{i},...
                'Units','normalized',...
                'FontSize',fs2,...
                'Position', [.1 1-0.47*i .9 0.42],...
                'Tag','GraphicOutputHandles');
            
            set(Handles.GraphicOutputHandles(i),'Enable','on');
        end
        
        if ForkAxes,
            set(Handles.GraphicOutputHandles(2),'Enable','off');
        end
        
        Handles.GraphicOutputPrint=uicontrol(...
            Handles.GraphicOutputHandlesGroup,...
            'Style','pushbutton',...
            'String','Print',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.65 0.25 .3 0.5],...
            'CallBack',@GraphicOutputPrint,...
            'Enable','on',...
            'Tag','GraphicOutputPrint');
        
        %%% Shape Files
        %%% Shape Files
        %%% Shape Files
        Handles.ExportShapeFilesHandlesGroup = uibuttongroup(...
            'Parent',Handles.CenterContainerLowerRight,...
            'BorderType','etchedin',...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Position',[.01 0.1 .98 0.8],...
            'Tag','ExportShapeFilesHandlesGroup',...
            'SelectionChangeFcn',@SetGraphicOutputType);
        
        Handles.ExportShape=uicontrol(...
            Handles.ExportShapeFilesHandlesGroup,...
            'Style','pushbutton',...
            'String','Export',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 0.75 .5 0.2],...
            'CallBack',@ExportShapeFile,...
            'Enable','on',...
            'Tag','ExportShapeFile');
        
     temp=uicontrol(...
            'Parent',Handles.ExportShapeFilesHandlesGroup,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .55 .95 .2],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','',...
            'FontSize',fs4,...
            'String','Enter shape file name below:');
        
     Handles.DefaultShapeFileName=uicontrol(...
            Handles.ExportShapeFilesHandlesGroup,...
            'Style','edit',...
            'String','FileName',...
            'Units','normalized',...
            'HorizontalAlignment','left',...
            'FontSize',fs2,...
            'Position', [.01 .35 .95 .2],...
            'CallBack',@ExportShapeFile,...
            'Enable','on',...
            'Tag','DefaultShapeFileName');
        
     temp=uicontrol(...
            'Parent',Handles.ExportShapeFilesHandlesGroup,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 0.05 .49 0.2],...
            'HorizontalAlignment','left',...
            'BackGroundColor','w',...
            'Tag','',...
            'FontSize',fs3,...
            'String','Bin Centers:');
               
        Handles.ShapeFileBinCenterIncrement=uicontrol(...
            Handles.ExportShapeFilesHandlesGroup,...
            'Style','edit',...
            'String','1',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.71 0.05 .2 0.2],...
            'CallBack',@ExportShapeFile,...
            'Enable','on',...
            'Tag','ShapeFileBinCenterIncrement');
        
        if ~getappdata(Handles.MainFigure,'CanOutputShapeFiles')
            set([Handles.ExportShape Handles.ExportShapeFileName],'Enable','off')
        end
    
    end

%%  Background Maps Container Contents
%%% Background Maps Container Contents
%%% Background Maps Container Contents

    function BackgroundMapsContainerContents
        
        %%% UpdateUI
        %%% UpdateUI
        %%% UpdateUI
        % Handles.UpdateUIButton=uicontrol(...
        %     'Parent',Handles.CenterContainerLower,...
        %     'Style','Pushbutton',...
        %     'String', 'Update UI Contents',...
        %     'Units','normalized',...
        %     'BackGroundColor','w',...
        %     'FontSize',fs0,...
        %     'Position', [.01 .01 Width .1],...
        %     'Tag','UpdateUIButton',...
        %     'Callback', @UpdateUI);
        
        
        if ~UseGoogleMaps,return,end
        
        NVar=5;
        % dy=NVar*.08;
        % y=0.9-NVar*.075;
        
        Handles.BaseMapButtonGroup = uibuttongroup(...
            'Parent',Handles.CenterContainerMiddle,...
            'Title','Map Type ',...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Position',[.01 .45 .98 .52],...
            'Tag','BaseMapButtonGroup',...
            'SelectionChangeFcn',@SetBaseMap);
        
        %         dy=.9/(NVar+1);
        buttonnames={'none','roadmap','satellite','terrain','hybrid'};
        ytemp=linspace(4/5,1/5-1/10,5);
        for i=1:NVar
            Handles.BaseMapButtonHandles(i)=uicontrol(...
                'Parent',Handles.BaseMapButtonGroup,...
                'Style','Radiobutton',...
                'String',buttonnames{i},...
                'Units','normalized',...
                'Value',0,...
                'FontSize',fs2,...
                'Position', [.1 ytemp(i) .9 .15],...
                'Tag','BaseMapRadioButton');
        end
        
        uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style','text',...
            'String','Transparency',...
            'Units','normalized',...
            'BackGroundColor',panelColor,...
            'FontSize',fs2,...
            'Position', [.01 0.3 .8 .15]);
        
        Handles.TransparencySlider=uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style','Slider',...
            'Min', .1,...
            'Max',.99,...
            'Value',.9,...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs1,...
            'Position', [.01 0.2 .8 .15],...
            'Tag','TransparencySlider',...
            'Callback', @SetTransparency);
        
        %     %jShandle=findjobj(Handles.TransparencySlider);
        %     %set(jShandle,'AdjustmentValueChangedCallback',@SetTransparency)
        
        uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style', 'text',...
            'String', 'Figure Renderer',...
            'Units','normalized',...
            'BackGroundColor',panelColor,...
            'FontSize',fs2,...
            'Position', [.01 .13 .8 .1]);
        
        % get the current renderer setting
        list={'painter','zbuffer','OpenGL'};
        curren=get(gcf,'Renderer');
        val=find(strcmp(curren,list));
        Handles.FigureRenderer=uicontrol(...
            'Parent',Handles.CenterContainerMiddle,...
            'Style', 'popup',...
            'String', list,...
            'Value',val,...
            'Units','normalized',...
            'BackGroundColor',panelColor,...
            'FontSize',fs2,...
            'Position', [.01 .06 .8 .1],...
            'Tag','SetFigureRendererPopup',...
            'Callback', @SetFigureRenderer);
        
    end

%%  InformationPanelContainerContents
%%% InformationPanelContainerContents
%%% InformationPanelContainerContents
        
    function InformationPanelContainerContents
             
        Width=.48;
        Height=.09;
              
        % ModelName
        % ModelName
        % ModelName
        uicontrol(...
            'Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.01 .9 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Model = ');
        Handles.ModelName=uicontrol(...
            'Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'Position',[.50 .9 Width Height],...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','ModelName',...
            'String','N/A');
        
        % StormSurgeGridName
        % StormSurgeGridName
        % StormSurgeGridName
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .8 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Model Grid = ');
        Handles.ModelGridName=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .8 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','ModelGridName',...
            'String','N/A');
        
        % ModelName
        % ModelName
        % ModelName
%         uicontrol(...
%             'Parent',Handles.InformationPanel,...
%             'Style','text',...
%             'Units','normalized',...
%             'BackGroundColor','w',...
%             'Position',[.01 .8 Width Height],...
%             'FontSize',fs2,...
%             'HorizontalAlignment','right',...
%             'String','Model = ');
%         Handles.ModelName=uicontrol(...
%             'Parent',Handles.InformationPanel,...
%             'Style','text',...
%             'Units','normalized',...
%             'BackGroundColor','w',...
%             'Position',[.50 .8 Width Height],...
%             'FontSize',fs2,...
%             'HorizontalAlignment','left',...
%             'Tag','ModelName',...
%             'String','N/A');
        
        % StormNumberName
        % StormNumberName
        % StormNumberName
%         uicontrol('Parent',Handles.InformationPanel,...
%             'Style','text',...
%             'Units','normalized',...
%             'Position',[.01 .7 Width Height],...
%             'BackGroundColor','w',...
%             'FontSize',fs2,...
%             'HorizontalAlignment','right',...
%             'String','Storm Number/Name = ');
%         Handles.StormNumberName=...
%             uicontrol('Parent',Handles.InformationPanel,...
%             'Style','text',...
%             'Units','normalized',...
%             'Position',[.50 .7 Width Height],...
%             'BackGroundColor','w',...
%             'FontSize',fs2,...
%             'HorizontalAlignment','left',...
%             'Tag','StormNumberName',...
%             'String','N/A');
        
        % AdvisoryNumber
        % AdvisoryNumber
        % AdvisoryNumber
%         uicontrol('Parent',Handles.InformationPanel,...
%             'Style','text',...
%             'Units','normalized',...
%             'BackGroundColor','w',...
%             'Position',[.01 .6 Width Height],...
%             'FontSize',fs2,...
%             'HorizontalAlignment','right',...
%             'String','Advisory Number = ');
%         Handles.AdvisoryNumber=...
%             uicontrol('Parent',Handles.InformationPanel,...
%             'Style','text',...
%             'Units','normalized',...
%             'BackGroundColor','w',...
%             'Position',[.50 .6 Width Height],...
%             'FontSize',fs2,...
%             'HorizontalAlignment','left',...
%             'Tag','AdvisoryNumber',...
%             'String','N/A');
%         
 
        
       Handles.ModelGridNums=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .6 Width Height*1.9],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','ModelGridNums',...
            'String','N/A');
        
        % UnitsString
        % UnitsString
        % UnitsString
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .21 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Units = ');
        Handles.UnitsString=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .21 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','UnitsString',...
            'String','N/A');
        
        
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .11 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Field Max = ');
        Handles.FieldMax=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .11 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','UnitsString',...
            'String','N/A');
        
        uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .01 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Field Min = ');
        Handles.FieldMin=...
            uicontrol('Parent',Handles.InformationPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.50 .01 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'Tag','UnitsString',...
            'String','N/A');
        
    end

%%  ControlPanelContainerContents
%%% ControlPanelContainerContents
%%% ControlPanelContainerContents

    function ControlPanelContainerContents
        
        Width=.48;
        Height=.07;
        
        % ColormapSetter
        % ColormapSetter
        % ColormapSetter
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .9 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Set Colormap : ');
        
        Handles.ColormapSetter=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style', 'popup',...
            'String', colormaps,...
            'Value',cmapidx,...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'Position', [.5 .88 Width/2 Height],...
            'Tag','ColormapSetter',...
            'Callback', @SetColorMap);
        
        Handles.FlipCMap=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','checkbox',...
            'Units','normalized',...
            'Position',[.76 .90 Width/2 Height],...
            'FontSize',fs2,...
            'BackGroundColor','w',...
            'Value',0,...
            'HorizontalAlignment','left',...
            'String','Flip CMap',...
            'Tag','FlipCMap',...
            'CallBack',@SetCLims);
        
        Handles.FixCMap=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','checkbox',...
            'Units','normalized',...
            'Position',[.76 .80  Width/2 Height],...
            'FontSize',fs2,...
            'BackGroundColor',panelColor,...
            'Value',0,...
            'HorizontalAlignment','left',...
            'String','Fix CMap',...
            'Tag','FixCMap');
        
        % Number of Colors
        % Number of Colors
        % Number of Colors
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'FontSize',fs2,...
            'BackGroundColor','w',...
            'Position',[.01 .8 Width Height],...
            'HorizontalAlignment','right',...
            'String','Number of Colors : ');
        Handles.NCol=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.5 .8 Width/2 Height],...
            'FontSize',fs2,...
            'BackGroundColor','w',...
            'String','32',...
            'HorizontalAlignment','left',...
            'Tag','NCol',...
            'CallBack',@SetCLims);
        
        
        % Color Minimum
        % Color Minimum
        % Color Minimum
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'Position',[.01 .7 Width Height],...
            'String','Color Minimum : ');
        Handles.CMin=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','edit',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'Position',[.5 .7 Width/2 Height],...
            'HorizontalAlignment','left',...
            'String','0',...
            'Tag','CMin',...
            'CallBack',@SetCLims);
        
        % Color Maximum
        % Color Maximum
        % Color Maximum
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'Position',[.01 .6 Width Height],...
            'String','Color Maximum : ');
        Handles.CMax=...
            uicontrol('Parent',Handles.ControlPanel,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.5 .6 Width/2 Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','left',...
            'String','1',...
            'Tag','CMax',...
            'CallBack',@SetCLims);
        
        % DepthContours
        % DepthContours
        % DepthContours
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .5 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Depth Contours : ');
        Handles.DepthContours=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style', 'edit',...
            'String', DepthContours,...
            'Units','normalized',...
            'BackGroundColor','w',...
            'HorizontalAlignment','left',...
            'FontSize',fs2,...
            'Position', [.5 .5 Width Height],...
            'Tag','DepthContours',...
            'Callback', @DrawDepthContours);
        
        % AxisLimits
        % AxisLimits
        % AxisLimits
        uicontrol('Parent',Handles.ControlPanel,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.01 .4 Width Height],...
            'BackGroundColor','w',...
            'FontSize',fs2,...
            'HorizontalAlignment','right',...
            'String','Axis Limits : ');
        Handles.AxisLimits=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style', 'edit',...
            'String',sprintf('%6.1f ',BoundingBox),...
            'Units','normalized',...
            'BackGroundColor','w',...
            'HorizontalAlignment','left',...
            'FontSize',fs2,...
            'Enable','off',...
            'Position', [.5 .4 Width Height],...
            'Tag','AxisLimits');
        
        
        % ShowMaximum
        % ShowMaximum
        % ShowMaximum
        Handles.ShowMaxButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', {'Show Maximum in View'},...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .32 Width Height],...
            'Callback', @ShowMaximum,...
            'Tag','ShowMaxButton');
        
        % ShowMapThings
        % ShowMapThings
        % ShowMapThings
        Handles.ShowMapButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', {'Show Roads/Counties'},...
            'Units','normalized',...
            'Position', [0.51 .32 Width Height],...
            'FontSize',fs2,...
            'Callback', @ShowMapThings,...
            'Tag','ShowMapThings');
        
        % ShowMinimum
        % ShowMinimum
        % ShowMinimum
        Handles.ShowMinButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', {'Show Minimum in View'},...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .25 Width Height],...
            'Callback', @ShowMinimum,...
            'Tag','ShowMinButton');
        
        % FindFieldValue
        % FindFieldValue
        % FindFieldValue
        Handles.FindFieldValueButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', 'Get Field Values',...
            'Units','normalized',...
            'Position', [.51 .25 Width Height],...
            'FontSize',fs2,...
            'Callback', @FindFieldValue,...
            'Tag','FindFieldValueButton');
        
        % ShowTrack
        % ShowTrack
        % ShowTrack
%         Handles.ShowTrackButton=uicontrol(...
%             'Parent',Handles.ControlPanel,...
%             'Style','pushbutton',...
%             'String', 'Show Track',...
%             'FontSize',fs2,...
%             'Units','normalized',...
%             'Position', [.01 .18 Width Height],...
%             'Tag','ShowTrackButton',...
%             'Callback', @ShowTrack);
        
        % ResetAxes
        % ResetAxes
        % ResetAxes
        Handles.ResetAxesButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','pushbutton',...
            'String', 'Reset Axes',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.51 .18 Width Height],...
            'Tag','ResetAxesButton',...
            'Callback', @ResetAxes);
        
        % Toggle surf edge color
        % Toggle surf edge color
        % Toggle surf edge color
        Handles.ElementsToggleButton=uicontrol(...
            'Parent',Handles.ControlPanel,...
            'Style','togglebutton',...
            'String', 'Show Elements',...
            'Units','normalized',...
            'FontSize',fs2,...
            'Position', [.01 .11 Width Height],...
            'Tag','ElementsToggleButton',...
            'Callback', @ToggleElements);
        
        % Show Full Domain AXes Extents
        % Show Full Domain AXes Extents
        % Show Full Domain AXes Extents
%         Handles.ShowFullDomainToggleButton=uicontrol(...
%             'Parent',Handles.ControlPanel,...
%             'Style','togglebutton',...
%             'String', 'Show Full Domain',...
%             'Units','normalized',...
%             'Enable','off',...
%             'FontSize',fs2,...
%             'Position', [.51 .11 Width Height],...
%             'Tag','ShowFullDomainToggleButton',...
%             'Callback', @ShowFullDomain);
        
        % FindHydrograph
        % FindHydrograph
        % FindHydrograph
%         Handles.HydrographButton=uicontrol(...
%             'Parent',Handles.ControlPanel,...
%             'Style','togglebutton',...
%             'String', 'Plot Hydrographs',...
%             'Units','normalized',...
%             'FontSize',fs2,...
%             'Position', [.51 .04 Width Height],...
%             'Tag','HydrographButton',...
%             'Callback', @FindHydrograph,...
%             'Enable','on');
%         
        % Water Level as Inundation
        % Water Level as Inundation
        % Water Level as Inundation
%         Handles.WaterLevelAsInundation=uicontrol(...
%             'Parent',Handles.ControlPanel,...
%             'Style','togglebutton',...
%             'String', {'Show Water Level As Inundation'},...
%             'Units','normalized',...
%             'FontSize',fs2,...
%             'Position', [.01 .04 Width Height],...
%             'Tag','WaterLevelAsInundation',...
%             'Callback', @WaterLevelAsInundation);
             
        set(Handles.ControlPanel,'Visible','on');

%         function WaterLevelAsInundation(~,~)
%             v=get(Handles.WaterLevelAsInundation,'Value');
%             if v
%                 set(Handles.WaterLevelAsInundation,'String','Turn Off Inundation')
%             else
%                 set(Handles.WaterLevelAsInundation,'String','Turn On Inundation')
%             end
%         end
%         
%         
%         % if ~UseShapeFiles
        %     set(Handles.ShowMapButton,'Enable','off')
        % end
    end

end

%%% Utility functions
%%% Utility functions
%%% Utility functions

%%  ShowMaximum
%%% ShowMaximum
%%% ShowMaximum
function ShowMaximum(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

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

%%  ShowMinimum
%%% ShowMinimum
%%% ShowMinimum
function ShowMinimum(hObj,~) 

    global TheGrids Debug
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end
    
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


%%  RecordAxisLimits
function RecordAxisLimits(~,arg2)
  
    MainFig=get(get(arg2.Axes,'Parent'),'Parent');
    Handles=get(MainFig,'UserData');
    axx=axis;
    setappdata(Handles.MainFigure,'BoundingBox',axx);
    set(Handles.AxisLimits,'String',sprintf('%6.1f ',axx))
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


%%  ShowMapThings
%%% ShowMapThings
%%% ShowMapThings
function ShowMapThings(hObj,~) 

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    temp1=findobj(Handles.MainAxes,'Tag','AdcLShapesCounties');
    temp2=findobj(Handles.MainAxes,'Tag','AdcLShapesRoadways');
    temp3=findobj(Handles.MainAxes,'Tag','AdcLShapesStateLines');
    temp4=findobj(Handles.MainAxes,'Tag','AdcLShapesCities');
    temp=[temp1(:);temp2(:);temp3(:);temp4(:)];
    axes(Handles.MainAxes);
    
    if any([isempty(temp1)  isempty(temp2) isempty(temp3) isempty(temp4)])  % no objs found; need to draw
        SetUIStatusMessage('Loading shapes...')
        Shapes=LoadShapes;
        setappdata(Handles.MainAxes,'Shapes',Shapes);
        %SetUIStatusMessage('Done.')
        h=plotroads(Shapes.major_roads,'Color',[1 1 1]*.4,'Tag','AdcLShapesRoadways','LineWidth',2);
        h=plotcities(Shapes.cities,'Tag','AdcLShapesCities'); 
        h=plotroads(Shapes.counties,'Tag','AdcLShapesCounties'); 
        h=plotstates(Shapes.states,'Color','b','LineWidth',1,'Tag','AdcLShapesStateLines'); 
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

%%   GetColors
%%%  GetColors
%%%  GetColors
% function [minThisData,maxThisData,NumberOfColors]=GetColors(Handles)
%      maxThisData=str2double(get(Handles.CMax));
%      minThisData=str2double(get(Handles.CMin));
%      NumberOfColors=str2int(get(Handles.NCol));
% end

%%   SetTitle
%%%  SetTitle
%%%  SetTitle
function SetTitle(str)
    title(str,'FontWeight','bold') 
end
function SetTitleOld(RunProperties)
    
    % SetTitle MUST be called AFTER the Handle struct is set back in the
    % caller:  I.e., it must be placed after
    % "set(Handles.MainFigure,'UserData',Handles);"
    
    f=findobj(0,'Tag','MainAdcLVizAppFigure');
    Handles=get(f,'UserData');
    ADCLOPTS=getappdata(Handles.MainFigure,'AdcLOpts');              
        
    LocalTimeOffset=ADCLOPTS.LocalTimeOffset;
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
