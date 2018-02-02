function obj = set_pe_fr_comfr_baisinv(obj, save, varargin)
% PE_FR_COMFR_BAISINV  logical for business angel is coinvestor
% in company funding round
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
n     = 27;
name  = 'pe_fr_comfr_baisinv';
descr = 'ba -> ba fr -> com fr --> pe_fr_comfr_baisinv: logical for business angel is coinvestor in company funding round';
input = {'pe_fr_comfr',...                 % company funding rounds
  'pe_ninv',...                     % pe selection
  'pe_fr_comfr_ninv',...            % # of investors in com fr
  'pe_fr_comfr_inv_perma',...       % investor permalinks
  'people_permalink'};

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

%% compute (pe_fr_comfr, pe_ninv, pe_fr_comfr_ninv,...
%           pe_fr_comfr_inv_perma, permalink)

pe_fr_comfr_baisinv = cell(size(pe_ninv));   % preallocate

bas = find(pe_ninv>0);                      % all bas
for ba = 1:length(bas)                        % ba
  for bafr = 1:length(pe_fr_comfr{bas(ba)})      % ba fr
    for comfr = 1:length(pe_fr_comfr{bas(ba)}{bafr}) % com fr
      
      if pe_fr_comfr_ninv{bas(ba)}{bafr}(comfr) ~= 0 % there are investors
        
        % ba & investor names
        name_ba  = permalink{bas(ba)};
        name_inv = pe_fr_comfr_inv_perma{bas(ba)}{bafr}{comfr};
        
        % is ba (co)investor in this company round?
        pe_fr_comfr_baisinv{bas(ba)}{bafr}(comfr)...
          = any(strcmp(name_ba, name_inv));
        
      else                                           % there are no investors
        
        % .. then there can be no match
        pe_fr_comfr_baisinv{bas(ba)}{bafr}(comfr) = false;
        
      end
      
    end
  end
end

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function PE_FR_COMFR_BAISINV