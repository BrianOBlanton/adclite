function ADCLOPTS=AdcircLite_Init(varargin)

PWD=pwd;

HOME=fileparts(which(mfilename));

USERHOME=HOME;
if isdeployed
    if ispc
        USERHOME=getenv('USERPROFILE');
    else
        USERHOME=getenv('HOME');
    end
end

addpath([HOME '/extern'])

if isempty(which('detbndy'))
    cd([HOME '/util'])
    ssinit
end

cd(PWD)

%global ADCLOPTS

%if ~exist('varargin','var')
%    error([mfilename ' cannot be called directly. Call AdcircLite instead.'])
%end

set(0,'DefaultUIControlFontName','Courier')
set(0,'DefaultAxesTickDir','out')
set(0,'DefaultFigureRenderer','zbuffer');

LocalDirectory='./';
AdclDirectory='.adclite';
ADCLHOME=HOME;
if isdeployed
    ADCLHOME=fullfile(USERHOME, AdclDirectory);
end
TempDataDirectory='TempData';
TempDataLocation=fullfile(PWD, TempDataDirectory); 
if isdeployed
    TempDataLocation=fullfile(ADCLHOME, TempDataDirectory);
end
DateStringFormatInput='yyyy-mm-dd HH:MM:SS';
DateStringFormatOutput='ddd, dd mmm, HH:MM PM';
ModelName='pre_00_CV_DB_two_prime_HS';
GridName='nc_inundation_v9.81_adjVAB_MSL';
ModelDir='Model';
ModelFile='Model.tar';
ModelURL='http://people.renci.org/~bblanton/data/Model.tar';

% name of Java Topology Suite file
jts='jts-1.9.jar';

%% Default PN/PVs
fprintf('AdcL++ Processing Input Parameter/Value Pairs...\n')
opts=AdcircLiteOptions;
opts=parseargs(opts);

% now process varargins
opts=parseargs(opts,varargin{:});

ADCLOPTS=opts;
ADCLOPTS.Storm=lower(ADCLOPTS.Storm);

%scc=get(0,'ScreenSize');
%DisplayWidth=scc(3);

ADCLOPTS.AppName=blank(fileread('ThisVersion'));
fprintf('AdcL++ %s\n',ADCLOPTS.AppName')

ADCLOPTS.HOME = HOME;
%cd(ADCLOPTS.HOME)

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

if isdeployed
    if ~exist(ADCLHOME, 'dir')
        fprintf(sprintf('\nAdcL++ Creating ADCLHOME at %s.\n', ADCLHOME))
        mkdir(ADCLHOME)
    end
end

if ~exist(TempDataLocation,'dir')
    fprintf(sprintf('\nAdcL++ Creating TempData at %s.\n', TempDataLocation))
    mkdir(TempDataLocation)
end

%%
if isunix
    mvcom='mv';
    cpcom='cp';
else
    mvcom='move';
    cpcom='copy';
end

if ~isempty(ADCLOPTS.BoundingBox),ADCLOPTS.DefaultBoundingBox=ADCLOPTS.BoundingBox;end

%SetVectorOptions('Stride',100,'ScaleFac',25,'Color','k')
%VectorOptions.Stride=100;
%VectorOptions.ScaleFac=25;
%VectorOptions.Color='k';

%%% clean up after initialization
clear jts
global Debug

Debug=ADCLOPTS.Debug;

ADCLOPTS.HOME=HOME;
ADCLOPTS.USERHOME=USERHOME;
ADCLOPTS.ADCLHOME=ADCLHOME;
ADCLOPTS.LocalDirectory=LocalDirectory;
ADCLOPTS.TempDataLocation=TempDataLocation; 
ADCLOPTS.DateStringFormatInput=DateStringFormatInput;
ADCLOPTS.DateStringFormatOutput=DateStringFormatOutput;
ADCLOPTS.ModelName=ModelName;
ADCLOPTS.GridName=GridName;
ADCLOPTS.ModelDir=ModelDir;
ADCLOPTS.ModelFile=ModelFile;
ADCLOPTS.ModelURL=ModelURL;

