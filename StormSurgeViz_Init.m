function ADCLOPTS=StormSurgeViz_Init(varargin)

PWD=pwd;

HOME=fileparts(which(mfilename));
addpath([HOME '/extern'])

% need to set up main java path before setting any global variables
if isempty(which('ncgeodataset')) || isempty(javaclasspath('-dynamic'))
    cd([HOME '/extern/nctoolbox'])
    setup_nctoolbox;
end

if isempty(which('detbndy'))
    cd([HOME '/util'])
    ssinit
end

cd(PWD)

%global SSVizOpts


%if ~exist('varargin','var')
%    error([mfilename ' cannot be called directly. Call StormSurgeViz instead.'])
%end

set(0,'DefaultUIControlFontName','Courier')
set(0,'DefaultAxesTickDir','out')
set(0,'DefaultFigureRenderer','zbuffer');

LocalDirectory='./';
TempDataLocation=[PWD '/TempData']; 
DateStringFormatInput='yyyy-mm-dd HH:MM:SS';
DateStringFormatOutput='ddd, dd mmm, HH:MM PM';

% name of Java Topology Suite file
jts='jts-1.9.jar';

%% Default PN/PVs
fprintf('SSViz++ Processing Input Parameter/Value Pairs...\n')
opts=StormSurgeVizOptions;
opts=parseargs(opts);



% now process varargins, which will override any parameters set in
% MyStormSurge_Init.m
opts=parseargs(opts,varargin{:});

ADCLOPTS=opts;
ADCLOPTS.Storm=lower(ADCLOPTS.Storm);

%scc=get(0,'ScreenSize');
%DisplayWidth=scc(3);

ADCLOPTS.AppName=blank(fileread('ThisVersion'));
fprintf('SSViz++ %s\n',ADCLOPTS.AppName')

ADCLOPTS.HOME = HOME;
%cd(SSVizOpts.HOME)

if ADCLOPTS.UseStrTree
    f=[ADCLOPTS.HOME '/extern/' jts];
    if exist(f,'file')
        javaaddpath(f);
    else
        disp('Can''t add jts file to javaclasspath.   Disabling strtree searching.')
        ADCLOPTS.UseStrTree=false;
    end
end

ADCLOPTS.HasMapToolBox=false;
if ~isempty(which('almanac'))
    ADCLOPTS.HasMapToolBox=true;
    %set(0,'DefaultFigureRenderer','opengl');
end

if isempty(which('shaperead'))
    ADCLOPTS.UseShapeFiles=false;
end

if isempty(which('shapewrite'))
    disp('Can''t locate MATLAB''s shapewrite.  Disabling shape file output.')
    ADCLOPTS.CanOutputShapeFiles=false;
end

if ~exist(TempDataLocation,'dir')
    mkdir(TempDataLocation)
end

%%
% get remote copy of InstanceDefaults.m
if isunix
    mvcom='mv';
    cpcom='cp';
else
    mvcom='move';
    cpcom='copy';
end


if ~isempty(ADCLOPTS.BoundingBox),ADCLOPTS.DefaultBoundingBox=ADCLOPTS.BoundingBox;end

%SetVectorOptions('Stride',100,'ScaleFac',25,'Color','k')
VectorOptions.Stride=100;
VectorOptions.ScaleFac=25;
VectorOptions.Color='k';

%%% clean up after initialization
clear jts
global Debug

Debug=ADCLOPTS.Debug;

ADCLOPTS.HOME=HOME;
ADCLOPTS.LocalDirectory='./';
ADCLOPTS.TempDataLocation=[PWD '/TempData']; 
ADCLOPTS.DateStringFormatInput='yyyy-mm-dd HH:MM:SS';
ADCLOPTS.DateStringFormatOutput='ddd, dd mmm, HH:MM PM';
ADCLOPTS.ModelName='pre_00_CV_DB_two_prime_HS';
ADCLOPTS.GridName='nc_inundation_v9.81_adjVAB_MSL';

