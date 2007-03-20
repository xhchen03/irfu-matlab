function c=irf_plot(x,varargin)
%IRF_PLOT   Flexible plotting routine for time series
%
% c=irf_plot(X,[arguments...]);
%   X is one of:
%      - matrix in AV Cluster format
%      - cell array data, each of cells containing a matrix in AV Cluster
%      format
%      - string defining variable
%
%   arguments can be:
%     'subplot' - plot all x values in separate subplots
%     'comp'    - plot vector component in separate subplots
%     ['dt', [dt1, dt2, dt3, dt4]] - specify time shifts, new time = old time - dt
%     ['yy',factor_to_multiply] - add second axis on right, miltiply by factor_to_multiply
%     ['linestyle',LineStyle] - define line style. Simple LineStyle can be be
%     given as last argument, 'linestyle' keyword is not necessary in this
%     case. LineStyle can be given as cell array to specify style for different variables/subplots. 
%
% irf_plot, to improve zooming, will sometimes set t_start_epoch within the
% 'userdata' field of the figure and internally use it as origo but in most cases you should not care about this.
% 
% Examples:
%   irf_plot(B1) - plot variable B1 (all components), assuming that the 
%                    first column is time
%   irf_plot('B1') - plot variable B1, if it does not exist try to load it
%                    with c_load('B1') and try to put ylabel from c_desc('B1')
%   irf_plot('B?') - Cluser oriented, plot B1.. B4 in separate subplots
%   irf_plot({B1,B2}) - plot B1 and B2 in separate subplots
%   irf_plot('B1 B2') - -"- but if B1,B2 do not exist try to load them and
%                    put labels according to c_desc
%   irf_plot({B1,B2},'comp') - plot in 1. subplot B1_X and B2_X, in second
%                    subplot B1_Y and B2_Y etc. 
%   irf_plot({B1,B2},'dt',[dt1 dt2]) - separate subplots with B1 and B2, 
%                    but in addition B1 and B2 time axis are shifted by dt1 
%                    and dt2 correspondingly
%
% See also C_PL_TX, C_DESC
%
% $Id$


% flag_subplot 0 - one plot
%              1 - separate subplots for every component
%              2 - separate subplots for all variables in the cell array
%              3 - components of vectors in separate panels

var_desc{1}='';
flag_subplot=0;
have_options = 0;
args = varargin; 
if nargin > 1, have_options = 1; end


% default values that can be override by options
dt=0;
flag_yy=0;scaleyy=1;
plot_type='';
marker='-';

while have_options
	l = 1;
	switch(args{1})
	case 'subplot'
		plot_type = 'subplot';
	case 'comp'
		plot_type = 'comp';
	case 'dt'
		if length(args)>1
			if isnumeric(args{2})
				dt = args{2};
				l = 2;
            else irf_log('fcal,','wrongArgType : dt must be numeric')
			end
        else irf_log('fcal,','wrongArgType : dt value is missing')
		end
	case 'yy'
		if length(args)>1
			if isnumeric(args{2})
				flag_yy = 1;
        scaleyy = varargin{j+2};
				l = 2;
            else irf_log('fcal,','wrongArgType : yy must be numeric')
			end
        else irf_log('fcal,','wrongArgType : yy value is missing')
		end
		case 'linestyle'
			marker = args{2};
			l = 2;
	otherwise
		irf_log('fcal',['Assuming ''' args{1} ''' is a LineStyle'])
		marker = args{1};
		args = args(2:end);
		break
	end
	args = args(l+1:end);
	if isempty(args), break, end
end

% plot separate subplots for all x components
if strcmp(plot_type,'subplot') && isnumeric(x),flag_subplot=1;end

if ischar(x), % try to get variable labels etc.
    var_nam=tokenize(x); % white space separates variables
    jj=1;
    for ii=1:length(var_nam),
        if regexp(var_nam{ii},'?'),
            c_eval(['var_names{jj}=''' var_nam{ii} ''';jj=jj+1;']);
        else
            var_names{jj}=var_nam{ii};jj=jj+1;
        end
    end
    x={};ix=1;
    for ii=1:length(var_names)
        try % try to get variable from calling workspace
            x{ix}=evalin('caller',var_names{ii});
        catch
            try % if there is none try to load variable
                c_load(var_names{ii});eval(['x{ix}=' var_names{ii} ';']);
            catch % if nothing works give up
                irf_log('load',['skipping, do not know where to get variable >' var_names{ii}]);
            end
        end
        if length(x)==ix,
          try
              var_desc{ix} = c_desc(var_names{ii});
          catch
              var_desc{ix} = {};
          end
          ix = ix+1;
        end
    end
end


if iscell(x), % plot several variables
    if size(var_desc,2)<size(x,2), % no ylabels are given
        for ii=1:length(x);var_desc{ii}={};end % no way to now the name of variables
    end
	
	if dt==0, dt(1:size(x,2))=0; end
	
    switch plot_type
        case ''
            plot_type='subplot';
            flag_subplot=2;
            if length(x)==1, x=x{1}; flag_subplot=0;end
        case 'comp'
            flag_subplot=3;
        case 'subplot'
            flag_subplot=2;
    end
else
    try
        var_desc{1} = c_desc(inputname(1));
    catch
        var_desc{1} = {};
    end
end

% for zooming to work even in cases of wide band it is important that time
% axis is not big number. isdat epoch is too big. therefore if time is
% isdat epoch we choose reference time the first point of first variable
% (in practices it does not matter).
%  

if flag_subplot==0,  % one subplot
	if isstruct(x)
		% plot a spectrogram
		ts = t_start_epoch(x.t);
		
		caa_spectrogram(x);
		hcbar = colorbar;
		if ~isempty(var_desc{1})
			for v = 1:length(var_desc{1}.size)
				lab{v} = [var_desc{1}.labels{v} '[' var_desc{1}.units{v} ...
					'] sc' var_desc{1}.cl_id];
			end
			ylabel(hcbar, lab);
		end
		
		tt = x.t(~isnan(x.t),1);
		tt = tt(1);
	else
		% t_start_epoch is saved in figures user_data variable
		% check first if it exist otherwise assume zero
		ts = t_start_epoch(x(:,1));
		ii = 2:length(x(1,:));
		if flag_yy == 0, h=plot((x(:,1)-ts-dt),x(:,ii),marker);grid on;
		else h=plotyy((x(:,1)-ts),x(:,ii),(x(:,1)-ts),x(:,ii).*scaleyy);grid on;
		end

		% put ylimits so that no labels are at the end (disturbing in
		% multipanel plots)
		set(gca,'ylim',mean(get(gca,'ylim'))+diff(get(gca,'ylim'))*[-.499999 .499999])

		if ~isempty(var_desc{1})
			for v = 1:length(var_desc{1}.size)
				lab{v} = [var_desc{1}.labels{v} '[' var_desc{1}.units{v} ...
					'] sc' var_desc{1}.cl_id];
			end
			ylabel(lab);
		end

		c = get(h(1),'Parent');

		tt = x(~isnan(x(:,1)),1);
		tt = tt(1);
	end
    
elseif flag_subplot==1, % separate subplot for each component 
	%   t_start_epoch is saved in figures user_data variable
	if isstruct(x), error('cannot plot spectra in COMP mode'), end
	ts=t_start_epoch(x(:,1));
	npl=size(x,2)-1;
	for ipl=1:npl
		c(ipl)=subplot(npl,1,ipl);

		if iscell(marker)
			if length(marker)==npl, marker_cur = marker{ipl};
			else marker_cur = marker{1};
			end
		else marker_cur = marker;
		end

		plot((x(:,1)-ts-dt),x(:,ipl+1),marker_cur); grid on;

		% put ylimits so that no labels are at the end (disturbing in
		% multipanel plots)
		set(gca,'YLim', ...
			mean(get(gca,'YLim'))+diff(get(gca,'YLim'))*[-.499999 .499999])
		
		if ~isempty(var_desc)
			scu = cumsum(var_desc{1}.size);
			isz = find(scu==min(scu(ipl<=scu)));
			sz = var_desc{1}.size(isz); % Size of a data vector
			if sz == 1 % Scalar data
				lab = [var_desc{1}.labels{isz} ' [' var_desc{1}.units{isz} ...
					'] sc' var_desc{1}.cl_id];
			else % Vector data
				% Vector component
				if isz==1, comp = ipl;
				else comp = ipl-scu(isz-1);
				end
				lab = [var_desc{1}.labels{isz} ...
					'_{' var_desc{1}.col_labels{isz}{comp}...
					'} [' var_desc{1}.units{isz} '] sc' var_desc{1}.cl_id ];
			end
			ylabel(lab);
		end
	end

	tt = x(~isnan(x(:,1)),1);
	tt = tt(1);
    
elseif flag_subplot==2, % separate subplot for each variable
	%   t_start_epoch is saved in figures user_data variable
	if isempty(x), return, end
	if isstruct(x{1}), ts = t_start_epoch(x{1}.t);
	else ts = t_start_epoch(x{1}(:,1));
	end

	t_st = []; t_end = [];
	xlen = [];

	npl=size(x,2);
	for ipl=1:npl
		c(ipl) = irf_subplot(npl,1,-ipl);

		y=x{ipl};
		if isstruct(y), t_tmp = (y.t-double(ts)-double(dt(ipl)));
		else t_tmp = (y(:,1)-double(ts)-double(dt(ipl)));
		end
		tt = t_tmp(~isnan(t_tmp));
		if isempty(t_st), t_st = tt(1);
		else if tt(1)<t_st, t_st = tt(1); end
		end
		if isempty(t_end), t_end = tt(end);
		else if tt(end)>t_end, t_end = tt(end); end
		end
		clear tt

		if isstruct(y)
			caa_spectrogram(c(ipl),y.t-dt(ipl), y.p, y.f);
			hcbar = colorbar;
			if ~isempty(var_desc{ipl})
				for v = 1:length(var_desc{ipl}.size)
					lab{v} = [var_desc{ipl}.labels{v} '[' var_desc{ipl}.units{v} ...
						'] sc' var_desc{ipl}.cl_id];
				end
				ylabel(hcbar, lab);
				disp(lab)
			end
			tt = y.t(~isnan(y.t),1);
			% save palel width to resize the rest of the panels accordingly
			if isempty(xlen)
				xlen = get(c(ipl),'Position');
				xlen = xlen(3);
			end
		else
			if iscell(marker)
				if length(marker)==npl, marker_cur = marker{ipl};
				else marker_cur = marker{1};
				end
			else marker_cur = marker;
			end
			plot(t_tmp,y(:,2:end),marker_cur);grid on;

			% put ylimits so that no labels are at the end (disturbing in
			% multipanel plots)
			set(gca,'ylim',mean(get(gca,'ylim'))+diff(get(gca,'ylim'))*[-.499999 .499999])

			if ~isempty(var_desc) && ~isempty(var_desc{ipl})
				for v = 1:length(var_desc{ipl}.size)
					lab{v} = [var_desc{ipl}.labels{v} '[' ...
						var_desc{ipl}.units{v} '] sc' var_desc{ipl}.cl_id];
				end
				ylabel(lab);
			end
			tt = y(~isnan(y(:,1)),1);
		end
	end
	% Set common XLim
	for ipl=1:npl
		set(c(ipl),'XLim',[t_st t_end])
		if ~isempty(xlen)
			p = get(c(ipl),'Position');
			set(c(ipl),'Position',[p(1) p(2) xlen p(4)])
		end
	end
	clear t_st t_end

	tt = tt(1);
    
elseif flag_subplot==3,  % components of vectors in separate panels
	if isstruct(x), error('cannot plot spectra in COMP mode'), end
	%t_start_epoch is saved in figures user_data variable
	ts=t_start_epoch(x{1}(:,1));

	npl=size(x{1},2)-1;
	for ipl=1:npl,

		% We make subplot only if wee need it
		if npl==1, c(ipl) = gca;
		else c(ipl) = irf_subplot(npl,1,-ipl);
		end

		line_colors=get(gca,'ColorOrder');
		for jj=1:size(x,2)
			if iscell(marker)
				if length(marker)==size(x,2), marker_cur = marker{jj};
				else marker_cur = marker{1};
				end
			else marker_cur = marker;
			end

			y=x{jj};
			plot((y(:,1)-ts-dt(jj)), y(:,ipl+1), 'Color', line_colors(jj,:),'LineStyle', marker_cur)
			grid on; hold on;
		end

		% put ylimits so that no labels are at the end (disturbing in
		% multipanel plots)
		set(gca,'ylim',mean(get(gca,'ylim'))+diff(get(gca,'ylim'))*[-.499999 .499999])

	end
	tt = y(~isnan(y(:,1)),1);
	tt = tt(1);
end

irf_figmenu;

% add t_start_epoch, used by add_timeaxis and subplot handles
user_data=get(gcf,'userdata');
if flag_subplot>0, 
    user_data.subplot_handles=c;
%    user_data.t_start_epoch=t_start_epoch;
end % add information about subplot handles to userdata of figure
set(gcf,'userdata',user_data);


% in case time is in isdat_epoch add time_axis 
if ((tt > 1e8) && (tt < 1e10))
    if flag_subplot == 0, add_timeaxis(gca);
    else add_timeaxis(c);
    end
end

if nargout==0, clear c; end % do not give axis handle as answer if not asked for

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function t_start_epoch=t_start_epoch(t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gives back the value of t_start_epoch of the figure
% if not  set, sets t_start_epoch of the figure
ud=get(gcf,'userdata');
ii = find(~isnan(t));
if ii,
  valid_time_stamp=t(ii(1));
else
  valid_time_stamp=[];
end

if isfield(ud,'t_start_epoch'),
  t_start_epoch=ud.t_start_epoch;
elseif valid_time_stamp,
  if valid_time_stamp > 1e8, % set start_epoch if time is in isdat epoch, warn about changing t_start_epoch
    t_start_epoch=valid_time_stamp;
    ud.t_start_epoch=t_start_epoch;
    set(gcf,'userdata',ud);
    irf_log('proc',['user_data.t_start_epoch is set to ' epoch2iso(t_start_epoch,1)]);
  else
    t_start_epoch=0;
  end
else
  t_start_epoch=0;
end

end

