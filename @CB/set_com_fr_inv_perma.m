function obj = set_com_fr_inv_perma(obj, save, varargin)
% COM_FR_INV_PERMA  permalink of investors in company funding round
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
n     = 25;
name  = 'com_fr_inv_perma';
descr = 'com --> fr --> inv --> com_fr_inv_perma: permalink of investor in company funding rounds';
input = {'companies_funding_rounds',...     % company funding rounds
          'pe_ninv',...                     % pe selection
          'com_fr_ninv',...                 % # of investors in com fr
          'com_fr_inv_type'};               % investor type

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
comfr = funding_rounds;      % com frs
com_fr_inv_perma = cell(size(comfr));   % preallocate

for com = 1:length(comfr)
  for fr = 1:length(comfr{com})                 % com fr
    
    if com_fr_ninv{com}(fr) ~= 0      % there are investors
      
      for inv = 1:com_fr_ninv{com}(fr) % for each investor
        
        % investor type for dynamic indexing
        field = com_fr_inv_type{com}{fr}{inv};
        
        % set permalink
        com_fr_inv_perma{com}{fr}{inv}...
          = comfr{com}(fr).investments{inv}.(field).permalink;
        
      end
      
    else
      
      com_fr_inv_perma{com}{fr}{inv} = '';
      
    end
    
  end
end

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function COM_FR_INV_PERMA