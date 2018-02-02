function obj = set_A_perma(obj, save)
% A_perma   permalinks of investors in coinvestment network matrix

%% parameters
n     = 36;
name  = 'A_perma';
descr = 'A_perma: permalink of investor in network matrix of coinvestor network';

% set name & description
obj.var(n).name   = name; clear name
obj.var(n).descr  = descr; clear descr

%% compute

% load permalinks
co_perma = load_field(obj, 'permalink', 'companies');
pe_perma = load_field(obj, 'permalink', 'people');
fi_perma = load_field(obj, 'permalink', 'financials');

A_perma  = cat(1, co_perma, pe_perma, fi_perma);

%% save
if save
  save_var(obj, eval(obj.var(n).name), obj.var(n).name);
end

end % function A_perma