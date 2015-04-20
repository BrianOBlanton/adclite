function h=circles(xc,yc,rad,varargin)
%CIRCLES  plot circles at optionally input centers with required input radii.
% CIRCLES(RAD) draws circles at the origin with radii RAD.
% CIRCLES(XC,YC,RAD) draws circles with radii RAD and with
% centers at (XC,YC).
%  NOTES : 1) CIRCLES always overlays existing axes, regardless
%             of the state of 'hold'.
%          2) CIRCLES does not force the axis to be 'equal'.
%
%  Input : XC   - x-coord vector of circle centers  (required)
%          YC   - y-coord vector of circle centers  (required)
%          RAD  - vector of circle radii (required)
%          p1,v1... - parameter/value plotting pairs (optional, See below.)
%
% Output : HCIR - vector of handles to circles drawn.
%
%          See the Matlab Reference Guide entry on the LINE command for
%          a complete description of parameter/value pair specification.
%
% Call as: >> hcir=circles(xc,yc,rad,p1,v1,p2,v2,...);

%
% Written by : Brian O. Blanton
%         

% DEFINE ERROR STRINGS
err1=['Need atleast radii as input.'];
err2=['Too few input arguments specified.'];
err3=['Lengths of x,y,r must be equal.'];

% check arguments.
if nargin==0 & nargout==0
   disp('hcir=circles(xc,yc,rad,p1,v1,p2,v2,...);');
   error(err1);
elseif nargin<3
   error(err2);
elseif nargin==3
   if length(xc)~=length(yc)
      error(err3);
   elseif length(xc)~=length(rad)
      error(err3);
   end
end

% force xc, yc, and rad to be column vectors.
xc=xc(:);
yc=yc(:);
rad=rad(:);

% t must be a row vector
delt=pi/24;
t=0:delt:2*pi;
t=t(:)';

% compute (0,0) origin-based circles
x=(rad*cos(t))';
y=(rad*sin(t))';
[nrow,ncol]=size(x);

% translate circles to input centers (xc,yc)
xadd=(xc*ones(size(1:nrow)))';
yadd=(yc*ones(size(1:nrow)))';
x=x+xadd;
y=y+yadd;

% append NaN's so we get one handle.
x=[x;
   NaN*ones(size(1:ncol))];
y=[y;
   NaN*ones(size(1:ncol))];
x=x(:);
y=y(:);

% draw circles and return handle in hcir.
h=line(x,y,varargin{:});

%
%        Brian O. Blanton
%        Renaissance Computing Institute
%        University of North Carolna
%        Chapel Hill, NC
%
%        brian_blanton@renci.org
%
