function obj = set_pe_fr_roundcode_tab(obj, save, varargin)
% PE_FR_ROUNDCODE_TAB tabulation of ba frs by round code
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
n     = 7;
name  = 'pe_fr_roundcode_tab';
descr = ' round code | # of people frs | % of people frs ';
input = {'pe_ninv',...
  'pe_fr_roundcode'};

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

%% compute, given: pe_ninv, pe_fr_roundcode

% find unique round codes
n_fr  = pe_ninv(pe_ninv>0);
for com = 1:length(pe_fr_roundcode)
  if com == 1
    code = pe_fr_roundcode{com}';
  elseif com > 1
    code = [code; pe_fr_roundcode{com}'];
  end
end
uni_code = unique(code);

% find number of rounds by unique round code
for i = 1:length(uni_code)
  abs(i)  = sum(strcmp(uni_code{i},code));
  perc(i) = abs(i)/sum(pe_ninv);
end
pe_fr_roundcode_tab = [{uni_code}, abs', perc'];

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function PE_FR_ROUNDCODE_TAB