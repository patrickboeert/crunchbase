function obj = set_pe_fr_amount(obj, save, varargin)
% PE_FR_AMOUNT amount of investment in business angel funding round
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
n     = 8;
name  = 'pe_fr_amount';
descr = 'people fr --> pe_fr_amount: amount of investment in funding round';
input = {'pe_ninv',...
  'people_investments'};

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
pe_fr        = investments;              % all pe frs
pe_fr_amount = cell(size(investments));  % preallocate

bas = find(pe_ninv>0);                     % all bas
for ba = 1:length(bas)
  for fr = 1:length(pe_fr{bas(ba)})
    pe_fr_amount{bas(ba)}{fr} = pe_fr{bas(ba)}(fr).funding_round.raised_amount;
  end
end

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function PE_FR_AMOUNT