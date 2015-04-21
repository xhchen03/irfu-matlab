classdef mms_db < handle
  %MMS_DB Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    databases
  end
  
  methods
    function obj=mms_db()
      obj.databases = [];
    end
    function obj = add_db(obj,dbInp)
      if ~isa(dbInp,'mms_file_db')
        error('expecting MMS_FILE_DB input')
      end
      if any(arrayfun(@(x) strcmpi(x.id,dbInp.id), obj.databases))
        irf.log('warning',['Database [' dbInp.id '] already added'])
        return
      end
      obj.databases = [obj.databases dbInp];
    end
    
   function fileList = list_files(obj,filePrefix,tint)
     fileList =[];
     for iDb = 1:length(obj.databases)
       fileList = [fileList obj.databases(iDb).list_files(filePrefix,tint)]; %#ok<AGROW>
     end
   end
   
   function res = get_variable(obj,filePrefix,varName,tint)
     narginchk(4,4)
     res = [];
     
     fileList = list_files(obj,filePrefix,tint);
     if isempty(fileList), return, end
     
     loadedFiles = obj.load_list(fileList,varName);
     if numel(loadedFiles)==0, return, end
     
     flagDataobj = isa(loadedFiles{1},'dataobj');
     for iFile = 1:length(loadedFiles)
       if flagDataobj, append_sci_var(loadedFiles{iFile})
       else append_ancillary_var(loadedFiles{iFile});
       end
     end
     
     function append_ancillary_var(ancData)
       if isempty(ancData), return, end
       if ~isstruct(ancData) || ~(isfield(ancData,varName) ...
           && isfield(ancData,'time'))
         error('Data does not contain %s or time',varName)
       end
       time = ancData.time; data = ancData.(varName);
       if isempty(res), res = struct('time',time,varName,data); return, end
       res.time = [res.time; time];
       res.(varName) = [res.(varName); data];
       % check for overlapping time records
       [~,idxUnique] = unique(res.time); 
       idxDuplicate = setdiff(1:length(res.time), idxUnique);
       res.time(idxDuplicate) = []; res.(varName)(idxDuplicate) = [];
       irf.log('warning',...
         sprintf('Discarded %d data points',length(idxDuplicate)))
     end
     
     function append_sci_var(sciData)
       if isempty(sciData), return, end
       if ~isa(sciData,'dataobj')
         error('Expecting DATAOBJ input')
       end
       v = get_variable(sciData,varName);
       if isempty(v)
         irf.log('waring','Empty return from get_variable()')
         return
       end
       if ~isstruct(v) || ~(isfield(v,'data') && isfield(v,'DEPEND_0'))
         error('Data does not contain DEPEND_0 or DATA')
       end
       
       if isempty(res), res = v; return, end
       if iscell(res), res = [res {v}]; return, end
       if ~comp_struct(res,v), res = [{res}, {v}]; return, end
       
       res.DEPEND_0.data = [res.DEPEND_0.data; v.DEPEND_0.data];
       res.data = [res.data; v.data];
       % check for overlapping time records
       [~,idxUnique] = unique(res.DEPEND_0.data); 
       idxDuplicate = setdiff(1:length(res.DEPEND_0.data), idxUnique);
       res.DEPEND_0.data(idxDuplicate) = []; res.data(idxDuplicate) = [];
       res.nrec = length(res.DEPEND_0.data); res.DEPEND_0.nrec = res.nrec;
       nDuplicate = length(idxDuplicate);
       if nDuplicate
         irf.log('warning',sprintf('Discarded %d data points',nDuplicate))
       end
       [res.DEPEND_0.data,idxSort] = sort(res.DEPEND_0.data);
       res.data = res.data(idxSort);
       function res = comp_struct(s1,s2)
       % Compare structures
         narginchk(2,2), res = false;
         
         if ~isstruct(s1) ||  ~isstruct(s2), error('expecting STRUCT input'), end
         if isempty(s1) && isempty(s2), res = true; return
         elseif xor(isempty(s1),isempty(s2)), return
         end
         
         fields1 = fields(s1); fields2 = fields(s2);
         if ~comp_cell(fields1,fields2), return, end
         
         for iField=1:length(fields1)
           f = fields1{iField};
           if ~isempty(intersect(f,{'data','nrec','DEPEND_0'})), continue, end
           if isnumeric(s1.(f)) || ischar(s1.(f))
             if ~all(all(all(s1.(f)==s2.(f)))), return, end
           elseif isstruct(s1.(f)), if ~comp_struct(s1.(f),s2.(f)), return, end
           elseif iscell(s1.(f)), if ~comp_cell(s1.(f),s2.(f)), return, end
           else
             error('cannot compare : %s',f)
           end
         end
         res = true;
       end % COMP_STRUCT
       function res = comp_cell(c1,c2)
         %Compare cells
         narginchk(2,2), res = false;
         
         if ~iscell(c1) ||  ~iscell(c2), error('expecting CELL input'), end
         if isempty(c1) && isempty(c2), res = true; return
         elseif xor(isempty(c1),isempty(c2)), return
         end
         if ~all(size(c1)==size(c2)), return, end
         
         [n,m] = size(c1);
         for iN = 1:n,
           for iM = 1:m
             if ischar(c1{iN, iM}) && ischar(c2{iN,iM})
               if ~strcmp(c1{iN, iM},c2{iN,iM}), return , end
             elseif iscell(c1{iN, iM}) && iscell(c2{iN,iM})
               if ~comp_cell(c1{iN, iM},c2{iN,iM}), return , end
             else
               irf.log('warining','can only compare chars')
               res = true; return
             end
             
           end
         end
         res = true;
       end % COMP_CELL
     end % APPEND_SCI_VAR
   end % GET_VARIABLE
   
   function res = load_list(obj,fileList,mustHaveVar)
     narginchk(2,3), res = {};
     if isempty(fileList), return, end
     if nargin==2, mustHaveVar = ''; end
     
     for iFile=1:length(fileList)
       fileToLoad = fileList(iFile);
       db = obj.get_db(fileToLoad.dbId);  
       if isempty(db) || ~db.file_has_var(fileToLoad.name,mustHaveVar)
         continue
       end
       res = [res {db.load_file(fileToLoad.name)}]; %#ok<AGROW>
     end
   end
   
   function res = get_db(obj,id)
     idx = arrayfun(@(x) strcmp(x.id,id),obj.databases);
     res = obj.databases(idx);
   end
  end
  
end
