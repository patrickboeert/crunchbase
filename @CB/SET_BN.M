function obj = set_bn(obj, year, month, save, varargin)
% BN  betweenness centrality of (year, month) network matrix of 
% coinvestment links

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
n     = nind + 380;
name  = strcat('bn','_',num2str(index(nind,2)),'_',num2str(index(nind,1)));
Aname  = strcat('A','_',num2str(index(nind,2)),'_',num2str(index(nind,1)));

% set parameters
descr = strcat(name,': betweenness centrality of (', num2str(year), ',', num2str(year), ') network matrix of coinvestment links');
input = {};

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
import = load(strcat(obj.dir_var,Aname));
A      = import.(Aname);
bn     = betweenness(obj, A, 1);

% evaluate
eval(strcat(obj.var(n).name,'= bn;'));

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function BN