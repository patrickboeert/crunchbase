function obj = set_pe_fr_survival(obj, save, varargin)
% PE_FR_SURVIVAL  binary, dependent variable for intermediate
% measure of business angel investment success
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
n     = 35;
name  = 'pe_fr_survival';
descr = 'ba -> ba fr -> pe_fr_survival: binary, dependent variable for intermediate measure of business angel investment success';
input = {'pe_ninv',...                 % pe selection
  'pe_fr_selsurvival',...       % ba fr selection
  'pe_fr_comfr',...             % company funding rounds
  'pe_fr_comfr_sqn',...         % com fr sequence number
  'pe_fr_comfr_inv_type',...    % investor type
  'pe_fr_comfr_dtcomfr',...     % com fr date
  'pe_fr_bafrind'};             % map: com fr -> ba fr


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
pe_fr_survival = cell(size(pe_ninv));   % preallocate

bas = find(pe_ninv>0);                      % find bas
for ba = 1:length(bas)                       % ba
  bafrs = find(pe_fr_selsurvival{bas(ba)});    % find bafrs
  for bafr = 1:length(bafrs)                    % ba fr
    
    % set loop var
    ncomfrs = length(pe_fr_comfr{bas(ba)}{bafrs(bafr)}); % # comfrs
    
    % compute pe_fr_survival
    if ncomfrs > 1      % more than 1 com fr, move to 1. com fr after ba fr
      
      % investor types for 1. com fr after ba fr
      nfr   = 2;
      comfr = find(pe_fr_comfr_sqn{bas(ba)}{bafrs(bafr)}==nfr);
      type  = pe_fr_comfr_inv_type{bas(ba)}{bafrs(bafr)}{comfr};
      co    = any(strcmp('company',type));
      pe    = any(strcmp('person',type));
      fi    = any(strcmp('financial_org',type));
      
      if co || fi                                          % there is co or fi investor, assign true
        pe_fr_survival{bas(ba)}(bafrs(bafr)) = true;
        
      else                                                 % only ba investor
        
        if ncomfrs > 2  % more than 2 com fr, move to 2. com fr after ba fr
          
          % investor types in 2. com fr after ba fr
          nfr   = 3;
          comfr = find(pe_fr_comfr_sqn{bas(ba)}{bafrs(bafr)}==nfr);
          type  = pe_fr_comfr_inv_type{bas(ba)}{bafrs(bafr)}{comfr};
          co  = any(strcmp('company',type));
          pe  = any(strcmp('person',type));
          fi  = any(strcmp('financial_org',type));
          
          if co || fi                                        % there is co or fi investor, assign true
            pe_fr_survival{bas(ba)}(bafrs(bafr)) = true;
            
          else                                                 % only ba investor
            
            if ncomfrs > 3  % more than 3 com fr, move to 3. com fr after ba fr
              
              % investor types in 4. com fr after ba fr
              nfr   = 4;
              comfr = find(pe_fr_comfr_sqn{bas(ba)}{bafrs(bafr)}==nfr);
              type  = pe_fr_comfr_inv_type{bas(ba)}{bafrs(bafr)}{comfr};
              co  = any(strcmp('company',type));
              pe  = any(strcmp('person',type));
              fi  = any(strcmp('financial_org',type));
              
              if co || fi                                        % there is co or fi investor, assign true
                pe_fr_survival{bas(ba)}(bafrs(bafr)) = true;
              else
                pe_fr_survival{bas(ba)}(bafrs(bafr)) = false;    % only ba, assign false
              end
              
            else
              pe_fr_survival{bas(ba)}(bafrs(bafr)) = false;    % no 3. com fr after ba fr
            end
            
          end
          
        else
          pe_fr_survival{bas(ba)}(bafrs(bafr)) = false;    % no 2. com fr after ba fr
        end
        
      end
      
    else
      pe_fr_survival{bas(ba)}(bafrs(bafr)) = false;    % no 1. com fr after ba fr
    end
    
  end
end


%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function PE_FR_SURVIVAL