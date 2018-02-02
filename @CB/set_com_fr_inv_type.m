function obj = set_com_fr_inv_type(obj, save, varargin)
% COM_FR_INV_TYPE  type of investor in company funding round
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
n     = 24;
name  = 'com_fr_inv_type';
descr = 'com --> fr --> inv --> com_fr_inv_type: type of investor in company funding rounds of business angel companies';
input = {'companies_funding_rounds',...    % company funding rounds
         'com_fr_ninv'};                   % # of investors in com fr

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
comfr           = funding_rounds;      % com frs
com_fr_inv_type = cell(size(comfr));   % preallocate

for com = 1:length(comfr)
  for fr = 1:length(comfr{com})                 % com fr
    
    if com_fr_ninv{com}(fr) ~= 0   % there are investors
      
      for inv = 1:com_fr_ninv{com}(fr) % for each investor
        
        if ~isempty(comfr{com}(fr).investments{inv}.company)
          com_fr_inv_type{com}{fr}{inv} = 'company';
          
        elseif ~isempty(comfr{com}(fr).investments{inv}.financial_org)
          com_fr_inv_type{com}{fr}{inv} = 'financial_org';
          
        elseif ~isempty(comfr{com}(fr).investments{inv}.person)
          com_fr_inv_type{com}{fr}{inv} = 'person';
          
        else
          error('no match!');
          
        end
        
      end
      
    else
      
      com_fr_inv_type{com}{fr}{inv} = '';
      
    end
    
  end
end


%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function COM_FR_INV_TYPE