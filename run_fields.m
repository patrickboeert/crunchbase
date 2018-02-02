% get field values from files

% load cb
db = cb.load('J:\crunchbase\11-5-2010');

% get company entity variables
db.get_field('acquisition','companies');
db.get_field('acquisitions','companies');
db.get_field('category_code','companies');
db.get_field('competitions','companies');
db.get_field('deadpooled_month','companies');
db.get_field('deadpooled_year','companies');
db.get_field('founded_month','companies');
db.get_field('founded_year','companies');
db.get_field('funding_rounds','companies');
db.get_field('investments','companies');
db.get_field('ipo','companies');
db.get_field('milestones','companies');
db.get_field('name','companies');
db.get_field('number_of_employees','companies');
db.get_field('offices','companies');
db.get_field('permalink','companies');
db.get_field('relationships','companies');

% get people entity variables
db.get_field('permalink','people');
db.get_field('relationships','people');
db.get_field('investments','people');
db.get_field('affiliation_name','people');

