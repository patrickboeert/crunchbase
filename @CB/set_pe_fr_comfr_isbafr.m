function obj = set_pe_fr_comfr_isbafr(obj, save, varargin)
% PE_FR_COMFR_ISBAFR  logical for: business angel funding round
% data matches the company funding round data (permalink investor,
% year and date, round code)
%
% DESCR
%   - varargin is optional, variable number of (string, value) pairs
%   of the required field data input arguments of the function
%
%   - if varargin does not specficy the required (string, value) pair
%   for one of the required field data input arguments, then the
%   field value data from the cleaned data directory is loaded
%   instead

%% parameters
n     = 30;
name  = 'pe_fr_comfr_isbafr';
descr = 'ba -> ba fr -> com fr --> pe_fr_comfr_isbafr: logical for: business angel funding round data matches the company funding round data (permalink investor, year and date, round code)';
input = {'pe_fr_comfr',...                 % company funding rounds
  'pe_ninv',...                     % pe selection
  'pe_fr_comfr_baisinv',...         % business angel matches investor
  'pe_fr_comfr_roundcodematch',...  % round code matches
  'pe_fr_comfr_dtfrmatch'};         % year & date of round match

%% load data

% set name & description
obj.var(n).name   = name; clear name
obj.var(n).descr  = descr; clear descr

% parse varargin into workspace
for opt = 1:(length(varargin)/2)
  name{opt}  = varargin{opt};
  value{opt} = varargin{opt+1};
  eval(strcat(name{opt},'= value{opt};'));
end
clear opt varargin

% load data, if not put into call
for i = 1:length(input)
  
  % data is there from varargin
  if exist(input{i},'var')==1    % checks if input variable is already in workspace
    continue
    
    % data is not there, figure out if field or variable data & load
  else
    
    if any(strncmp(input{i}, obj.entity, 6))  % is field data
      
      % find entity
      entity = obj.entity{find(strncmp(input{i}, obj.entity, 6))};
      % find field
      cutoff = strcat(entity,'_');
      field  = regexprep(input{i}, cutoff, '');
      % load field data
      fielddata = load_field(obj, field, entity);
      eval(strcat(field,'= fielddata;'));
      clear fielddata cutoff entity field
      
    else                                      % is variable data
      
      % load data
      vardata = load_var(obj, input{i});
      eval(strcat(input{i},'= vardata;'));
      clear vardata
      
    end
  end
end
clear i

%% compute
pe_fr_comfr_isbafr = cell(size(pe_ninv));   % preallocate

j=0;
bas = find(pe_ninv>0);                      % all bas
for ba = 1:length(bas)                        % ba
  for bafr = 1:length(pe_fr_comfr{bas(ba)})      % ba fr
    for comfr = 1:length(pe_fr_comfr{bas(ba)}{bafr}) % com fr
      
      % 1. rule: if ba permalink & round code match, set match as true
      if pe_fr_comfr_baisinv{bas(ba)}{bafr}(comfr)...
          && pe_fr_comfr_roundcodematch{bas(ba)}{bafr}(comfr)
        pe_fr_comfr_isbafr{bas(ba)}{bafr}(comfr) = true;
      else
        pe_fr_comfr_isbafr{bas(ba)}{bafr}(comfr) = false;
      end
      
      % end of comfr loop reached, check for unique solution
      endofloop = (comfr == length(pe_fr_comfr{bas(ba)}{bafr}));
      if endofloop
        
        % no previous unique match
        if length(find(pe_fr_comfr_isbafr{bas(ba)}{bafr}(:))) ~=1
          
          for comfr=1:length(pe_fr_comfr{bas(ba)}{bafr})
            
            % 2. cond. rule: if ba permalink, round code & data
            % match, set as true
            if pe_fr_comfr_baisinv{bas(ba)}{bafr}(comfr)...
                && pe_fr_comfr_roundcodematch{bas(ba)}{bafr}(comfr)...
                && pe_fr_comfr_dtfrmatch{bas(ba)}{bafr}(comfr)
              pe_fr_comfr_isbafr{bas(ba)}{bafr}(comfr) = true;
            else
              pe_fr_comfr_isbafr{bas(ba)}{bafr}(comfr) = false;
            end
            
          end
          
        end
      end
      
      % check for previous unique match
      if comfr == length(pe_fr_comfr{bas(ba)}{bafr})...
          && length(find(pe_fr_comfr_isbafr{bas(ba)}{bafr}(:))) ~= 1
        j=j+1;
      end
      
    end
  end
end

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function PE_FR_COMFR_ISBAFR