% generate 1) A(year,month)
%          2) d(year,month) 
%          3) bn(year,month)
%          4) bo(year,month)
%
% for all (y,m) combinations

% loop parameters
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

% compute
for y = 1:length(years)
  for m = 1:length(months)
    
    month = months(m);
    year = years(y);
    
    % db = set_A(db,year,month,1);    
    % db = set_d(db,year,month,1);     
    % db = set_bn(db, year, month, 1);
    a = 1;
    b = 0.5;
    db = set_bo(db, year, month, a, b, 1);    

  end
end