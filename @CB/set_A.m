function obj = set_A(obj, year, month, save, varargin)
% A  sparse network matrix of coinvestment links between investors for all
% company funding rounds before (year, month)

%% parameters

% construct varnames
years  = (1997:2010)';
months = (1:12)';
for i = 1:length(years)
  if i == 1
    index = [repmat(years(i),12,1),months];
  else
    stack = [repmat(years(i),12,1),months];
    index = [index; stack];
  end
end

% match n, set varname
nind  = find(year == index(:,1) & month == index(:,2));
n     = nind + 44;
name  = strcat('A','_',num2str(index(nind,2)),'_',num2str(index(nind,1)));

% set parameters
descr = strcat(name,': sparse network matrix of coinvestment links between investors for all company funding rounds before ( ', num2str(year) , ', ', num2str(month),') ');
input = {'A_perma',...
         'fi_invind',...
         'pe_invind',...
         'co_invind',...
         'com_fr_dtcomfr',...
         'com_fr_inv_type',...
         'com_fr_inv_perma',...
         'com_fr_ninv'};

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

%% compute

% preallocate
dim = length(A_perma);
A   = sparse(dim,dim);

% load permalinks
co = load_field(obj, 'permalink', 'companies');
pe = load_field(obj, 'permalink', 'people');
fi = load_field(obj, 'permalink', 'financials');

% compute
for com = 1:length(com_fr_inv_type)
  for fr = 1:length(com_fr_inv_type{com})
    
    % (year, date) of com fr
    yfr = com_fr_dtcomfr{com}{fr,1};
    mfr = com_fr_dtcomfr{com}{fr,2};
    
    if isempty(yfr) && isempty(mfr)               % no data at all
      continue      
    else
      
      % check that com fr is earlier than ba fr
      if isempty(yfr) || isempty(mfr)             % data is missing                
        if year > yfr
          goon = true;
        else
          goon = false;
        end        
      else                                        % data is there        
        y = (year >= yfr);                        % criterion year
        if (year == yfr)
          m = (month > mfr);                      % cond. criterion month
        else
          m = true;
        end
        goon = y && m;
      end
       
      % set A(i,f) ...
      if goon  && (com_fr_ninv{com}(fr) ~=0)   % ...if: 1) com fr is earlier than ba fr, 2) there are identifiable investors
        
        for inv = 1:length(com_fr_inv_type{com}{fr})
          
          % set investor type & permalink
          inv_perma = com_fr_inv_perma{com}{fr}{inv};
          inv_type  = com_fr_inv_type{com}{fr}{inv};
          
          for coinv = 1:length(com_fr_inv_type{com}{fr})
            
            % set coinvestor type & permalink
            coinv_perma = com_fr_inv_perma{com}{fr}{coinv};
            coinv_type  = com_fr_inv_type{com}{fr}{coinv};
            
            if strcmp(inv_perma,coinv_perma) && strcmp(inv_type,coinv_type)  % diagonal, self-reference
              continue
            else
              
              % identify i of A(i,j) for investor
              if strcmp(inv_type, 'company')
                invind = find(strcmp(inv_perma, co));
                i = co_invind(invind);
              elseif strcmp(inv_type, 'person')
                invind = find(strcmp(inv_perma, pe));
                i = pe_invind(invind);
              elseif strcmp(inv_type, 'financial_org')
                invind = find(strcmp(inv_perma, fi));
                i = fi_invind(invind);
              end
              
              % identify j of A(i,j) for coinvestor
              if strcmp(coinv_type, 'company')
                invind = find(strcmp(coinv_perma, co));
                j = co_invind(invind);
              elseif strcmp(coinv_type, 'person')
                invind = find(strcmp(coinv_perma, pe));
                j = pe_invind(invind);
              elseif strcmp(coinv_type, 'financial_org')
                invind = find(strcmp(coinv_perma, fi));
                j = fi_invind(invind);
              end
              
              % set A(i,j)
              A(i,j) = 1;
              
            end % if: self-referential
          end % for: coinvestors
        end % for: investors
        
      end % check date & inv data
    end % no date
    
  end % for: fr
end% for: com

% evaluate
eval(strcat(obj.var(n).name,'= A;'));


%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

clear A A_perma pe co fi fi_invind pe_invind co_invind com_fr_dtcomfr com_fr_inv_type com_fr_inv_perma com_fr_ninv index input stack years months

end % function A