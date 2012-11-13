function [apar,aperp]=irf_dec_parperp(b0,a,flagspinplane)
%IRF_DEC_PARPERP   Decompose a vector into par/perp to B components
%
% [apar,aperp]=irf_dec_parperp(B0,a,[flagSpinPlane])
%
%	Decomposes A to parallel and perpendicular to BO components
%
%	b0,a - martixes A=(t,Ax,Ay,Az) // AV Cluster format
%
%   if flagSpinPlane=1 is given, perform the computation in the XY plabne
%   only.
%
% $Id$

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Yuri Khotyaintsev, 1997
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<3 || flagspinplane==0
    btot = irf_abs(b0,1);
    
    ii = find(btot<1e-3);
    if ~isempty(ii), btot(ii) = ones(size(ii))*1e-3; end
    normb = [b0(:,1) b0(:,2)./btot b0(:,3)./btot b0(:,4)./btot];
    normb = irf_resamp(normb,a);
    
    apar = irf_dot(normb,a);
    aperp = a;
    aperp(:,2:4) = a(:,2:4) - normb(:,2:4).*(apar(:,2)*[1 1 1]);
else
    irf_log('proc','Decomposing in the XY plane')
    b0(:,4) = [];
    b0 = irf_resamp(b0,a(:,1));
    btot = sqrt(b0(:,2).^2 + b0(:,3).^2);
    b0(:,2) = b0(:,2)./btot; b0(:,3) = b0(:,3)./btot;
    
    apar = a(:,1:2); aperp = apar;
    apar(:,2) = a(:,2).*b0(:,2) + a(:,3).*b0(:,3);
    aperp(:,2) = a(:,2).*b0(:,3) - a(:,3).*b0(:,2);
end
return
