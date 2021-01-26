function TSout = psp_coordinate_transform(TSin,flag)
%PSP_COORDINATE_TRANSFORM  Transfrom between PSP coordinate systems
%
% PSP_COORDINATE_TRANSFORM(TSeries,flagConversion) convert TSeries to
% another reference frame defined by flagConversion. flagCVonversion can be
% one of: 'E>sc','sc>E', 'sc>SCM', 'SCM>sc' (capitalization not important)
%
% Example: 
%
%  TS_SC = psp_coordinate_transform(TS_E,'E>sc')
%
% Transforms dV12 and dV34 measurements to spacecraft reference frame

narginchk(2,2);
doRotateOnlyXY = false; % default to rotate vector with 3 comoponents

switch lower(flag)
  case 'e>sc'
    M = [[0.645 -0.822 0];[0.769 0.576 0]];
    doRotateOnlyXY = true;
  case 'sc>e'
    M = [cosd(55) sind(55) 0;-cosd(40) sind(40) 0; 0 0 1];
    doRotateOnlyXY = true;
  case 'sc>scm'
    M = [[ 0.81654 -0.40827 -0.40827];...
         [ 0       -0.70715  0.70715];...
         [-0.57729 -0.57729 -0.57729]];
  case 'scm>sc'
    M = [[ 0.81654 0        -0.57729];...
         [-0.40827 -0.70715 -0.57729];...
         [-0.40827 -0.70715 -0.57729]];
  otherwise
    irf.log('critical','transformation not defined'); return;
end

if isa(TSin,'TSeries')
  dataInp = TSin.data;
else
  dataInp = TSin;
end
nDimInputMatrix = numel(size(dataInp));
nComponents = size(dataInp,2);

if nDimInputMatrix > 2 % check if input is matrix or higher dimension objhect
  irf.log('critical','input should be vector'); return;
elseif nComponents == 1 % scalar input
  irf.log('critical','input cannot be scalar'); return;
elseif nComponents == 2 % 2 D vector
  doRotateOnlyXY = true;
end

% nDimensionsToApplyM = min([size(M,2) nComponents]);


if doRotateOnlyXY
  dataOut = dataInp*0;
  for iCompOut = 1:2
    for iCompInp = 1:2
      dataOut(:,iCompOut)=dataOut(:,iCompOut) + ...
        M(iCompOut,iCompInp) * dataInp(:,iCompInp);
    end
  end
  TSout=TSin.clone(TSin.time,dataOut);
else
  irf.log('critical','not implemented');
end


TSout.units = TSin.units;
TSout.siConversion = TSin.siConversion;

end

