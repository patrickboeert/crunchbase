function obj = set_pe_fr_selsurvival(obj, save, varargin)
% PE_FR_SELSURVIVAL  selection criterion for dependent variable for
% business angel rounds
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
n     = 34;
name  = 'pe_fr_selsurvival';
descr = 'ba -> ba fr -> pe_fr_selsurvival: selection criterion for dependent variable for business angel rounds';
input = {'pe_ninv',...                 % pe selection
         'pe_fr_sqn',...               % ba fr sequence number
         'pe_fr_comfr',...             % company funding rounds
         'pe_fr_comfr_dtcomfr',...     % com fr date
         'pe_fr_bafrind'};             % map: ba fr -> com fr

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
pe_fr_selsurvival = cell(size(pe_ninv));   % preallocate

bas = find(pe_ninv>0);                      % all bas
for ba = 1:length(bas)                        % ba
  for bafr = 1:length(pe_fr_comfr{bas(ba)})      % ba fr
    
    % get date bafrdt of ba fr
    dt  = pe_fr_comfr_dtcomfr{bas(ba)}{bafr}(pe_fr_bafrind{bas(ba)}(bafr),:);
    sqn = pe_fr_sqn{bas(ba)}(bafr);
    y   = dt{1};
    m   = dt{2};
    
    % 1. criterion: check whether bafrdt < 5/2008
    if isempty(y) || isempty(m)                       % data is missing
      
      if y < 2008
        crit(1) = true;
      else
        crit(1) = false;
      end
      
    else                                              % all data is there
      
      % check 1. criterion
      yl = (y <= 2008);                            % criterion year
      
      if (y == 2008)                               % cond. criterion month
        ml = (m < 5);
      else
        ml = true;
      end
      
      if yl && ml
        crit(1) = true;
      else
        crit(1) = false;
      end
      
    end
    
    % 2. criterion: check whether sqn == 1
    if sqn == 1
      crit(2) = true;
    else
      crit(2) = false;
    end
    
    % set pe_fr_selsurvival
    if crit(1) && crit(2)
      pe_fr_selsurvival{bas(ba)}(bafr) = true;
    else
      pe_fr_selsurvival{bas(ba)}(bafr) = false;
    end
    
 end
end

  %% save
  if save
    save_var(obj, eval(obj.var(n).name), obj.var(n).name);
  end
  
end % function PE_FR_SELSURVIVAL