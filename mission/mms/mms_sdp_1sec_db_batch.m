% Script for processing one moth of data

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

yymm = '201511'; 
%yymmList = {'201511','201512','201601','201602'}
mmsId = 'mms1'; dataPath = '/data/mms';
%for yy=2015
%%
db.files = {}; db.tint = {}; db.data = []; db.mmsId = mmsId;
for dd=1:31
  day = sprintf('%02d',dd)
  dataDir = [dataPath '/' mmsId '/edp/fast/l2a/dce2d/' yymm(1:4) '/' yymm(5:6) '/'];
  fName = mms_find_latest_version_cdf(...
    [dataDir '*' yymm day '*.cdf'])
  if isempty(fName), continue, end

  disp(['Processing: ' fName.name])
  [out,Tint] = mms_sdp_1sec_db(fName.name,dataDir);
  
  if isempty(db.data), db.data = out;
  else
    % Append data
    fi = fields(out);
    for idx = 1:length(fi)
      db.data.(fi{idx}) = [db.data.(fi{idx}); out.(fi{idx})];
    end
  end
  % Save file names for Bookkeeping and possible reprocessing
  db.files = [db.files fName.name]; db.tint = [db.tint Tint];
end
save([mmsId '__' yymm], 'db');

