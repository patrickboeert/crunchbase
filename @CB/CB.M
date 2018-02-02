classdef cb
  
  % DB  CrunchBase class for data acquisition, variable creation and data
  % analysis of CrunchBase data, using the CrunchBase API v1
  
  properties
    
   %% data acquisition: parameters
           url = {};
          file = {};           
        nfiles = [];
       basedir = '';
       dir_raw = '';
     dir_clean = '';
       dir_var = '';
           
   %% variable creation: description
           var = [];       
       
   %% data acquisition: raw data check       
         empty = {};
    downloaded = {};
         clean = {};
         
   %% data analysis: interface   
        entity = {};   
         field = {};
     fieldtype = {};         
       nfields = [];
          nobs = [];
        u_nobs = [];          
                 
  end % properties
  
  methods
    
    %% CONSTRUCTOR
    function obj      = cb(basedir) 
     % CB  create a new CrunchBase class       
      
      % data base directories
      obj.basedir = strcat(basedir,'\');
      obj.dir_raw = strcat(obj.basedir,'raw\');      
      obj.dir_clean = strcat(obj.basedir,'cleaned\');
      obj.dir_var = strcat(obj.basedir,'var\');      
      if ~exist(obj.basedir)
        mkdir(obj.basedir);
      elseif ~exist(obj.dir_raw)
        mkdir(obj.dir_raw);
      elseif ~exist(obj.dir_clean)
        mkdir(obj.dir_clean);        
      elseif ~exist(obj.dir_var)
        mkdir(obj.dir_var);          
      end
      
      % crunchbase entity names
      obj.entity = ...
        {'companies', 'people', 'financials', 'products', 'providers'};
      
      % crunchbase entity urls
      obj.url = ...
      {'http://api.crunchbase.com/v/1/companies.js',...
       'http://api.crunchbase.com/v/1/people.js',...
       'http://api.crunchbase.com/v/1/financial-organizations.js',...
       'http://api.crunchbase.com/v/1/products.js',...
       'http://api.crunchbase.com/v/1/service-providers.js'};
      
      % preallocate variable creation
      obj.var = struct('name', '',...
                       'descr', '');   
  
    end % function CB
    
    %% DATA ACQUISITION
    function obj      = get_list(obj, read) 
      % GET_LIST  query CrunchBase in 'list' mode, JSON-parse the 
      % list results and store observation names in 'list' file in 
      % main data directory
      %
      % INPUT
      %
      %  read = 5x1 entity logical (companies, people, financials,
      %         products, providers); do you want to get the list for the
      %         entity?
              
      for var = 1:5        
        if read(var)          
          
          tic          
          
            % query and parse data
            query = urlread(obj.url{var});
            list  = parse_json(obj, query);
            eval([obj.entity{var} '= list;']);
          
            % check for directory
            if ~exist(obj.dir_raw)
              mkdir(obj.dir_raw);               
            end
            
            % save (if 'list' does not exist) or append (if exists)
            if exist(strcat(obj.basedir, 'list.mat'))
              save(strcat(obj.basedir, 'list'), obj.entity{var}, '-append');
            else
              save(strcat(obj.basedir, 'list'), obj.entity{var});
            end          
            
          t(var) = toc;          
          
        end        
      end
      
    end % function GET_LIST
    function obj      = get_obs(obj, read, init, N, Nobs) 
      % GET_OBS  query Crunchbase in 'show' mode, JSON-parse 
      % observations into structures and save observations to raw data
      % directory
      %
      % INPUT
      %   
      %  What entities do you want to query?
      %  read = 5x1 entity logical for companies, people, financials,
      %         products, providers      
      %  
      %  At what observation do you want the query to start?
      %  init = 5x1 entity integers for companies, people, financials,
      %         products, providers; e.g. [38000,53000,3000,11000,1000];
      %
      %  Up to how many observations do you want to query?
      %  N    = cell(5,1) of 'all' or 5x1 entity integers; e.g.
      %         N = {'all','all','all','all','all'};
      %
      %  How many observations do you want in each file?
      %  Nobs = 5x1 entity integers for companies, people, financials,
      %         products, providers; e.g. [1000,1000,1000,1000,1000];
           
      %% parse observations      
      t    = cell(5,1);              % time  
      file = cell(5,1);              % file names
      
      for var = 1:5        
        if read(var)          
          
          % load data
          switch var
            case 1
              load(strcat(obj.basedir,'list.mat'), 'companies');
              list = companies;
              baseurl = 'http://api.crunchbase.com/v/1/company/';
            case 2
              load(strcat(obj.basedir,'list.mat'), 'people');
              list = people;
              baseurl = 'http://api.crunchbase.com/v/1/person/';
            case 3
              load(strcat(obj.basedir,'list.mat'), 'financials');
              list = financials;
              baseurl = 'http://api.crunchbase.com/v/1/financial-organization/';
            case 4
              load(strcat(obj.basedir,'list.mat'), 'products');
              list = products;
              baseurl = 'http://api.crunchbase.com/v/1/product/';
            case 5
              load(strcat(obj.basedir,'list.mat'), 'providers');
              list = providers;
              baseurl = 'http://api.crunchbase.com/v/1/service-provider/';
          end
          
          % set loop parameter
          if isnumeric(N{var})
            max = N{var};
          elseif strcmpi(N{var},'all')
            max = length(list);
          else error('Wrong parameter!');
          end
          
          % set variable names for storage
          nfiles(var) = ceil(length(list)/Nobs(var));
          suffix      = strtrim(cellstr(int2str((1:nfiles(var))')));
          
          filelist = ...
          {'company_','person_','financial_','product_','provider_'};          
          vars        = strcat(filelist{var}, suffix);
          
          % loop over list
          obs = cell(Nobs(var),1);
          j   = 0;                           % # obs
          f   = floor(init(var)/Nobs(var));  % # files
          
          for i = ((f*Nobs(var))+1):max
            
            try
              
              % build query & get data
              j = j+1;
              tic
              
              % query data
              url    = strcat(baseurl, list{i}.permalink, '.js');
              query  = urlread(url);
              
            catch ME1  % catch if error
              disp(i);
              t{var}(i) = toc;
              
              if j == Nobs(var) && f ~= nfiles(var)-2      % regular save after #=Nobs obs
                f = f+1;
                save(strcat(obj.dir_raw, char(vars{f})), 'obs', 'f', 'max');
                j = 0;
                obs = cell(Nobs(var),1);
                
              elseif j == Nobs(var) && f == nfiles(var)-2  % save before starting last file
                f = f+1;
                save(strcat(obj.dir_raw, char(vars{f})), 'obs', 'f', 'max');
                j = 0;
                obs = cell(length(list)-((nfiles(var)-1)*Nobs(var)),1);
                
              elseif j == (length(list)-((nfiles(var)-1)*Nobs(var))) && f == nfiles(var)-1  % save last file
                f = f+1;
                save(strcat(obj.dir_raw, char(vars{f})), 'obs', 'f', 'max');
                obs = cell(length(list)-((nfiles(var)-1)*Nobs(var)),1);
                
              end
              
              continue
              
            end
            
            % parse data
            obs{j} = parse_json(obj, query);
            disp(i);
            t{var}(i) = toc;
            
            % save & clear data
            if j == Nobs(var) && f ~= nfiles(var)-2     % regular save after #=Nobs obs
              f = f+1;
              save(strcat(obj.dir_raw, char(vars{f})), 'obs', 'f', 'max');
              j = 0;
              obs = cell(Nobs(var),1);
              
            elseif j == Nobs(var) && f == nfiles(var)-2 % save before starting last file
              f = f+1;
              save(strcat(obj.dir_raw, char(vars{f})), 'obs', 'f', 'max');
              j = 0;
              obs = cell(length(list)-((nfiles(var)-1)*Nobs(var)),1);
              
            elseif j == (length(list)-((nfiles(var)-1)*Nobs(var))) && f == nfiles(var)-1 % save last file
              f = f+1;
              save(strcat(obj.dir_raw, char(vars{f})), 'obs', 'f', 'max');
              obs = cell(length(list)-((nfiles(var)-1)*Nobs(var)),1);
              
            end
          end
          
          % keep file names
          file(var)= vars;
          save(strcat(obj.dir_raw, 't'), 't');
          clear list obs
          
        end
      end
      
      % rearrange file names
      for ent = 1:5, l(ent) = max(size(file(ent))); end
      file = cell(max(l),5);
      for ent = 1:5, file(1:l(ent),ent) = file(ent); end
      
      % return values      
      obj.nfiles = nfiles;
      obj.file   = file;  
      
    end % function GET_OBS
    function obj      = check_obs(obj, read) 
      % CHECK_OBS  find missing observations in raw data, try to
      % download again, transform raw data into cleaned structure array
      % & save data to directory of clean data
      %
      % INPUT
      % 
      %  read = 5x1 entity logical (companies, people, financials,
      %         products, providers); what entities do you want to check?
      
      %% loop over entities      
      for var = 1:5
        
        if read(var)                    
          
          %% load list data
          import = load(strcat(obj.basedir,'list'),obj.entity{var});
          list   = import.(obj.entity{var});
          clear import
            
          %% loop over files
          for f = 1:obj.nfiles(var) 
            
            %% load single block of data
            import = load(strcat(obj.dir_raw,obj.file{f,var}));
            obs    = import.obs;
            nobs   = import.max;
            clear import
            
            %% identify missing observations in raw data
            empty = false(size(obs));
            for i = 1:length(obs)
              if isempty(obs{i})
                empty(i) = true;
              else
                empty(i) = false;
              end
            end
            
            %% try to download missing observation again
            ind        = find(empty);
            downloaded = false(size(obs));
            if ~isempty(ind)
              for i = 1:length(ind)
                
                try
                  % query data
                  url_query = strcat(obj.url{var}, list{ind(i)}.permalink, '.js');
                  query     = urlread(url_query);
                  
                  % parse data
                catch ME1  % catch if error
                  continue
                end
                
                obs{ind(i)}        = parse_json(obj,query);
                downloaded(ind(i)) = true;
                disp(ind(i));
                
              end
            end
            
            %% build structure of clean observations (& remove missing
            %% data)
            ind_clean   = find(~empty | (empty & downloaded));
            ind_deleted = find(empty & ~downloaded);
            
            for i = 1:length(ind_clean)
              obs_c(i) = obs{ind_clean(i)};
            end
            
            % check for clean directory
            if ~exist(strcat(obj.basedir,'cleaned\'))
              obj.dir_clean = strcat(obj.basedir,'cleaned\');            
              mkdir(obj.dir_clean);               
            end            
            
            % save cleaned data to file
            save(strcat(obj.dir_clean, obj.file{f,var}), 'obs_c');
            clear obs_c
            
            % database info
            st      = (1:1000:(obj.nfiles(var)*1000))';
            fi      = st + length(obs) - 1;
            fi(end) = nobs;
            
            obj.empty{var}(st(f):fi(f))      = empty;
            obj.downloaded{var}(st(f):fi(f)) = downloaded;
            obj.clean{var}(st(f):fi(f))      = (~empty | (empty & downloaded));
          end          
          
        end
      end
    end % function CHECK_OBS    
    
    %% DATA INTERFACE
    function obs       = load_file(obj, entity, file) 
      % LOAD_FILE  load a file of clean observations into workspace
      %
      % INPUT     entity string, integer number of file
       
      import = load(strcat(obj.dir_clean,obj.file{file,entity}));
      obs    = import.obs_c;
      
    end % function LOAD_FILE     
    function obj       = set_fields(obj) 
      % SET_FIELDS  add field names of observation records (field), 
      % class type of each field (fieldtype) &  number of fields by entity
      % (nfields) to database object
      
      % preallocate
      obj.field     = cell(39,5);
      obj.fieldtype = cell(39,5);
      
      for ent = 1:5                
        
        % set obj field names (field)
        import        = load(strcat(obj.dir_clean,obj.file{1,ent}));
        obs           = import.obs_c; clear import
        obj.field(1:length(fieldnames(obs)),ent) = fieldnames(obs);
        
        % set obj number of fields (nfields)
        obj.nfields(ent) = length(fieldnames(obs));
        
        % set obj fieldtype
        switch ent
          case 1 % for companies
            obj.fieldtype(1:obj.nfields(ent),ent) = {'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'double',...
              'double',...
              'double',...
              'double',...
              'double',...
              'double',...
              'double',...
              'double',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'struct',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'struct',...
              'cell',...
              'cell',...
              'cell'};
            
          case 2 % for people
            obj.fieldtype(1:obj.nfields(ent),ent) = {'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'double',...
              'double',...
              'double',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'struct',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell'};
            
          case 3 % for financials
            obj.fieldtype(1:obj.nfields(ent),ent) = {'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'double',...
              'double',...
              'double',...
              'double',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'struct',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell',...
              'cell'};
            
          case 4 % for products
            obj.fieldtype(1:obj.nfields(ent),ent) = {'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'double',...
              'double',...
              'double',...
              'double',...
              'double',...
              'double',...
              'char',...
              'char',...
              'char',...
              'struct',...
              'struct',...
              'cell',...
              'cell',...
              'cell'};
            
          case 5 % for providers
            obj.fieldtype(1:obj.nfields(ent),ent) = {'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'char',...
              'struct',...
              'cell',...
              'cell',...
              'cell'};
        end        
      end      
    end % function SET_FIELDS        
    function fielddata = load_field(obj, field, entity) 
      % LOAD_FIELD  load field data from variable data directory into the
      % workspace
      %
      % INPUT   field string (one of obj.field)
      %         entity string (one of obj.entity)
      
      % reconstruct file name of field data
      ent       = find(strcmp(entity,obj.entity));
      ind_field = strmatch(field, obj.field(1:obj.nfields(ent),ent), 'exact');
      matfile   = strcat(obj.entity{ent},'_', obj.field{ind_field,ent});
      
      % import data
      import = load(strcat(obj.dir_var, matfile));
      fielddata    = import.(field);
      
    end % function LOAD_FIELD
    function save_field(obj, fielddata, field, entity) 
      % SAVE_FIELD  save field data to variable data directory
      %
      % INPUT   fieldata  : field data variable in workspace
      %         field     : string (one of obj.field)
      %         entity    : string (one of obj.entity)
      
      % construct file name
      ent       = find(strcmp(entity,obj.entity));
      ind_field = strmatch(field, obj.field(1:obj.nfields(ent),ent), 'exact');
      matfile   = strcat(obj.entity{ent},'_', obj.field{ind_field,ent});
      
      % evaluate var name = fieldname
      fieldname = genvarname(field);
      eval(strcat(field,'= fielddata;'));      
           
      % save
      save(strcat(obj.dir_var, matfile), field);
      
    end % function SAVE_FIELD        
    function vardata   = load_var(obj, varname) 
      % LOAD_VAR  load variable data from variable data directory into the
      % workspace
      %
      % INPUT   varname (one of obj.var.name)
      
      % load variable data
      import    = load(strcat(obj.dir_var, varname));
      vardata   = import.(varname);      
      
    end % function LOAD_VAR 
    function save_var(obj, vardata, varname)
      % SAVE_VAR  save variable data to variable data
      %
      % INPUT   vardata (variable data in workspace)
      %         varname (one of obj.var.name)
      
      % evaluate var name = vardata      
      eval(strcat(varname,'= vardata;')); 
      
      % save variable data
      save(strcat(obj.dir_var,varname),varname);    
      
    end % function SAVE_VAR      
    
    %% FIELD DATA CONSTRUCTION
    function fielddata = get_field(obj, field, entity) 
      % GET_FIELD  construct field data of all observations of a given
      % entity from a loop over all cleaned data files, code missing values
      % & store into variable directory
      %
      % INPUT   field string (one of obj.field)
      %         entity string (one of obj.entity)
      %
      % OUTPUT  field data variable
      
      %% error checking
     
      % is entity string an entity?
      ent = find(strcmp(entity,obj.entity));      
      if ~ischar(entity) || ~any(strcmp(entity,obj.entity))
        error('get_field: entity needs to be correct!');
      end
      
      % is field a fieldname?
      if ~any(strcmp(field, obj.field(:,ent)))
        error('get_field: field needs to be a valid field name!');
      end
      
      %% preallocate 
      
      % find out class(field)
      ind  = strmatch(field, obj.field(1:obj.nfields(ent),ent), 'exact');
      type = obj.fieldtype{ind,ent};     
      
      %% loop over files
      for f = 1:obj.nfiles(ent)
        
        % load block of data
        tic
        obs = load_file(obj, ent, f);
        
        % build variable
        switch type
          case 'char'                           % becomes cell string / [];
            data = {obs.(field)}';
            
          case 'double'                         % becomes double array / NaN;
            input = {obs.(field)}';
            data  = zeros(length(input),1);
            for i = 1:length(input)
              if isempty(input{i}), data(i) = NaN;
              else data(i) = input{i};
              end
            end
            clear input
            
          case 'struct'                         % becomes cell array of struct / [];
            data = {obs.(field)}';
            
          case 'cell'                           % becomes cell array of struct / [];
            data  = cell(length(obs),1);
            input = {obs.(field)}';
            for i = 1:length(input)
              data{i} = cell2mat(input{i});
            end
        end
        
        % concatenate
        if f==1
          fielddata = data;
        elseif f>1
          fielddata = [fielddata; data];
        end
        clear data input obs
        disp(f)
        toc
        
      end
      
      %% save field data
      save_field(obj, fielddata, field, entity);
      
    end % end GET_FIELD    
    
    %% VARIABLE DATA CONSTRUCTION
    function obj = set_vars(obj, index, save)
      % SET_VARS  newly computes variable data for index values 'index'
      % and saves it to disk if requested; index is index value n of 
      % obj.var(n).name

      % create variable names for dynamic function evaluation
      var_names = {'pe_ninv',...
                  'nba',...
                  'nbafr',...
                  'nbafr_tab',...
                  'pe_fr_comperma',...
                  'pe_fr_roundcode',...
                  'pe_fr_roundcode_tab',...
                  'pe_fr_amount',...
                  'pe_fr_curr',...
                  'pe_fr_dtfr',...
                  'pe_fr_isdt',...
                  'pe_fr_comind',...
                  'pe_fr_ipo',...
                  'pe_fr_isipo',...
                  'pe_fr_dtipo',...
                  'pe_fr_ma',...
                  'pe_fr_isma',...
                  'pe_fr_dtma',...
                  'pe_fr_industrycode',...
                  'co_dtdead',...
                  'pe_fr_comfr',...
                  'pe_fr_comfr_nfr',...
                  'com_fr_ninv',...
                  'com_fr_inv_type',...
                  'com_fr_inv_perma',...
                  'com_fr_dtcomfr',...
                  'pe_fr_comfr_baisinv',...
                  'pe_fr_comfr_roundcodematch',...
                  'pe_fr_comfr_dtfrmatch',...
                  'pe_fr_comfr_isbafr',...
                  'pe_fr_bafrind',...
                  'pe_fr_comfr_sqn',...
                  'pe_fr_sqn',...
                  'pe_fr_selsurvival',...
                  'pe_fr_survival',...
                  'A_perma',...
                  'A_ind',...
                  'A_isco',...
                  'A_ispe',...
                  'A_isfi',...
                  'pe_fr_sqnbafr',...
                  'pe_invind',...
                  'co_invind',...
                  'fi_invind',...
                  'com_fr_amount'};                             
                
      % run variables via dynamic function evaluation
      prefix = 'set_';
      for i = 1:length(index)
        eval(strcat('obj = ',prefix,var_names{index(i)},'(obj,save)',';'));
      end
                                                         
    end % function SET_VARS
    function obj = set_allas(obj, save)
      % SET_ALLAS  compute network matrices A(month,year) for all month,
      % year combinations

      % create loop values (year, month)      
      years  = (1997:2010)';
      months = (1:12)';
      
      % compute
      for y = 1:length(years)
        for m = 1:length(months)
          
          month = months(m);
          year  = years(y);          
          obj   = set_A(obj, year, month, save);
          
        end
      end
                                                         
    end % function SET_ALLAS 
    function obj = set_alld(obj, save)
      % SET_ALLD  compute degree centrality measure for all network
      % matrices

      % create loop values (year, month)      
      years  = (1997:2010)';
      months = (1:12)';
      
      % compute
      for y = 1:length(years)
        for m = 1:length(months)
          
          month = months(m);
          year  = years(y);          
          obj   = set_d(obj, year, month, save);
          
        end
      end
                                                         
    end % function SET_ALLD       
    function obj = set_allbn(obj, save)
      % SET_ALLBN  compute betweenness centrality measure for all network
      % matrices

      % create loop values (year, month)      
      years  = (1997:2010)';
      months = (1:12)';
      
      % compute
      for y = 1:length(years)
        for m = 1:length(months)
          
          month = months(m);
          year  = years(y);          
          obj   = set_bn(obj, year, month, save);
          
        end
      end
                                                         
    end % function SET_ALLBN
    function obj = set_allbo(obj, a, b, save)
      % SET_ALLBO  compute Bonacich centrality measure for all network
      % matrices based on parameter values a,b

      % create loop values (year, month)      
      years  = (1997:2010)';
      months = (1:12)';

      % compute
      for y = 1:length(years)
        for m = 1:length(months)
          
          month = months(m);
          year  = years(y);          
          obj   = set_bo(obj, year, month, a, b, save);
          
        end
      end
                                                         
    end % function SET_ALLBO     
                  
    %% REGRESSION DATA
    function YX = regression(obj)
      % REGRESSION  compute dependent & independent variable data for all
      % business angel funding rounds in the regression
      
      %% load data
      pe_fr_selsurvival  = load_var(obj, 'pe_fr_selsurvival'); 
      pe_fr_sqnbafr      = load_var(obj, 'pe_fr_sqnbafr');       % for first, npreviousinvests
      pe_fr_survival     = load_var(obj, 'pe_fr_survival');      % for survival      
      pe_invind          = load_var(obj, 'pe_invind');           % for degree, betweenness, bonacich 
      pe_fr_dtfr         = load_var(obj, 'pe_fr_dtfr');          % for nmonths      
      pe_fr_isma         = load_var(obj, 'pe_fr_isma');          % for exit
      pe_fr_isipo        = load_var(obj, 'pe_fr_isipo');         % for exit
      pe_fr_industrycode = load_var(obj, 'pe_fr_industrycode');  % for industry dummies
      com_fr_dtcomfr     = load_var(obj, 'com_fr_dtcomfr');      % for funding
      com_fr_amount      = load_var(obj, 'com_fr_amount');       % for funding
      
      pe_ninv           = load_var(obj, 'pe_ninv');
      bas  = find(pe_ninv > 0);                                 % all bas      
                   
      %% survival
      label{1} = 'survival';
      descr{1} = '(0/1): acquisition of next funding round with a strategic or financial investor';
      
      j = 0;
      for ba = 1:length(bas)
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})
          if pe_fr_selsurvival{bas(ba)}(fr)               % selection of bafr            
            
            j = j+1;            
            survival(j,1) = +pe_fr_survival{bas(ba)}(fr);            
            
          end
        end
      end                                
      
      %% first investment ('first', on ba level, dummy)      
      label{2} = 'first';
      descr{2} = '(0/1): first investment into a company as a business angel';
      
      first = NaN(size(survival));      
      j = 0;
      for ba = 1:length(bas)
        for fr = 1:length(pe_fr_sqnbafr{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)      % selection of bafr
            
            j = j+1;
            if pe_fr_sqnbafr{bas(ba)}(fr) == 1
              first(j,1) = 1;
            else
              first(j,1) = 0;   
            end
            
          end
        end
      end
              
      %% # of month since 1. investment ('nmonths', on ba level, double)
      label{3} = 'nmonths';
      descr{3} = 'integer: # of months since first investment into a company as a business angel'; 
      
      nmonths = NaN(size(survival));            
      j = 0;
      for ba = 1:length(bas)
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)      % selection of bafr
            
            j = j+1;            
            
            % dt for 1) first ba fr & 2) this loop's ba fr
            f = find((pe_fr_sqnbafr{bas(ba)} == 1));
            dt{1} = pe_fr_dtfr{bas(ba)}(f,:);   % dt of first ba fr
            dt{2} = pe_fr_dtfr{bas(ba)}(fr,:);  % dt of this ba fr            
            
            % replace missing values with identical values 
            if isempty(dt{2}{1,2}) && isempty(dt{1}{1,2})
              continue
            elseif isempty(dt{1}{1,2})
              dt{1}{1,2} = dt{2}{1,2};
            elseif isempty(dt{2}{1,2})
              dt{2}{1,2} = dt{1}{1,2};
            end

            % compute difference in month   
            if f == pe_fr_sqnbafr{bas(ba)}(fr)               
             nmonths(j,1) = 0;
            elseif dt{1}{1,1} == dt{2}{1,1}                       % same year
             nmonths(j,1) = dt{2}{1,2} - dt{1}{1,2};
            else
             nmonths(j,1) = (dt{2}{1,1} - dt{1}{1,1} - 1) * 12 + (12 - dt{1}{1,2}) + dt{2}{1,2};
            end
                                    
          end
        end
      end      
      
      %% # of investments to date ('npreviousinvests', on ba level, double)
      label{4} = 'npreviousinvests';
      descr{4} = 'integer: # of investments of the business angel before this funding round';
      
      npreviousinvests = NaN(size(survival));       
      
      j = 0;
      for ba = 1:length(bas)                                      
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)                  % selection of bafr
            
            j = j+1;                        
            npreviousinvests(j,1) = pe_fr_sqnbafr{bas(ba)}(fr) - 1;
                                    
          end
        end
      end 
             
      %% degree: network measure
      label{5} = 'degree';
      descr{5} = 'degree centrality for business angel for coinvestment network previous to investment round';
      
      degree = NaN(size(survival));        
      
      j = 0;
      for ba = 1:length(bas)
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})                    
          if pe_fr_selsurvival{bas(ba)}(fr)      % selection of bafr
            
            % construct file name for degree data file (month, year)
            year  = pe_fr_dtfr{bas(ba)}{fr,1};
            month = pe_fr_dtfr{bas(ba)}{fr,2};
            if isempty(month)
              month = 6;
            end
            
            % load degree data file             
            fname = strcat('d','_',num2str(month),'_',num2str(year));
            d     = load_var(obj, fname);                                    
            
            % set 'degree'
            j = j+1;
            degree(j,1) = d(pe_invind(bas(ba)));           
            
          end
        end
      end        
      
      %% betweenness centrality: network measure
      label{6} = 'betweenness';
      descr{6} = 'betweenness centrality for business angel for coinvestment network previous to investment round';
      
      betweenness = NaN(size(survival));         
      
      j = 0;
      for ba = 1:length(bas)
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})                    
          if pe_fr_selsurvival{bas(ba)}(fr)      % selection of bafr
            
            % construct file name for betweenness data file (month, year)
            year  = pe_fr_dtfr{bas(ba)}{fr,1};
            month = pe_fr_dtfr{bas(ba)}{fr,2};
            if isempty(month)
              month = 6;
            end
            
            % load betweenness data file
            fname = strcat('bn','_',num2str(month),'_',num2str(year));            
            bn    = load_var(obj, fname);                                    
            
            % set 'degree'
            j = j+1;
            betweenness(j,1) = bn(pe_invind(bas(ba)));
            
          end
        end
      end 
      
      %% betweenness centrality: network measure
      label{7} = 'bonacich';
      descr{7} = 'bonacich centrality for business angel for coinvestment network previous to investment round';
      
      bonacich = NaN(size(survival));         
      
      j = 0;
      for ba = 1:length(bas)
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})                    
          if pe_fr_selsurvival{bas(ba)}(fr)      % selection of bafr
            
            % construct file name for bonacich data file (month, year)
            year  = pe_fr_dtfr{bas(ba)}{fr,1};
            month = pe_fr_dtfr{bas(ba)}{fr,2};
            if isempty(month)
              month = 6;
            end
            
            % load bonacich data file
            fname = strcat('bo','_',num2str(month),'_',num2str(year));            
            bo    = load_var(obj, fname);                                    
            
            % set 'degree'
            j = j+1;
            bonacich(j,1) = bo(pe_invind(bas(ba)));
            
          end
        end
      end        
      
      %% superangel      
      label{8} = 'superangel';
      descr{8} = 'dummy: business angel has made more than 5 investments prior to this funding round';
      
      superangel = NaN(size(survival));       
      
      j = 0;
      for ba = 1:length(bas)                                      
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)                  % selection of bafr
            
            j = j+1;                        
            superangel(j,1) = +(npreviousinvests(j)>5);
                                    
          end
        end
      end    
      
      %% exit      
      label{9} = 'exit';
      descr{9} = 'business angel company has either gone IPO or has gone on to a trade sale';
      
      exit = NaN(size(survival));       
      
      j = 0;
      for ba = 1:length(bas)                                      
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)                  % selection of bafr
            
            j = j+1;                                    
            if pe_fr_isma{bas(ba)}(fr) || pe_fr_isipo{bas(ba)}(fr)
               exit(j,1) = 1;
            else
               exit(j,1) = 0;
            end
                                    
          end
        end
      end       
   
      %% industry dummies   
     
      % get industry codes
      industry = cell(size(survival));             
      j = 0;
      for ba = 1:length(bas)                                      
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)                  % selection of bafr            
            
            j = j+1;
            if isempty(pe_fr_industrycode{bas(ba)}{fr})
              industry{j,1} = 'NaN';
            else
              industry{j,1} = pe_fr_industrycode{bas(ba)}{fr};                        
            end
            
          end
        end
      end        
      
      % get dummy values
      u_industry = unique(industry);
      dummies    = zeros(length(u_industry),length(survival));
      
      for j = 1:length(survival)        
        industry_ind = strmatch(industry{j}, u_industry, 'exact');
        dummies(industry_ind,j) = 1;
      end
      
      % set dummy variables
      dname = strcat('industry_', u_industry);   % variable names
      for v = 1:length(u_industry)
        
        % set dummy
        eval(strcat(dname{v},' = transpose(dummies(',num2str(v),',:));'));
        
        % set labels
        label{9+v} = dname{v};
        descr{9+v} = strcat('business angel company is from',u_industry{v});
        
      end                              
            
      %% year dummies  
     
      % get year of fr
      year = NaN(size(survival));             
      j = 0;
      for ba = 1:length(bas)                                      
        for fr = 1:length(pe_fr_selsurvival{bas(ba)})          
          if pe_fr_selsurvival{bas(ba)}(fr)                  % selection of bafr                        
            j = j+1;
            year(j,1) = pe_fr_dtfr{bas(ba)}{fr,1};            
          end
        end
      end        
      
      % get dummy values
      u_year  = unique(year);
      dummies = zeros(length(u_year),length(survival));
      
      for j = 1:length(survival)
        year_ind = find(year(j) == u_year);
        dummies(year_ind,j) = 1;
      end
      
      % set dummy variables
      for v = 1:length(u_year)

        % set dummy var name
        dname{v} = strcat('y_', num2str(u_year(v)));   % variable names
        
        % set dummy values
        eval(strcat(dname{v},' = transpose(dummies(',num2str(v),',:));'));
        
        % set labels
        label{27+v} = dname{v};
        descr{27+v} = strcat('funding round took place in ',num2str(u_year(v)));
        
      end        
      
      %% funding 
     
      % set labels
      label{40} = 'funding';
      descr{40} = 'cumulated amount of VC investment in the year of the business angel funding round';
      
      % get funding
      amount = zeros(size(u_year));
      
      for com = 1:length(com_fr_amount)                      % com
        for fr = 1:length(com_fr_amount{com})                 % com fr   
          
          % find year & set amount
          if isempty(com_fr_dtcomfr{com}{fr,1})
            continue
          else
            
            ind = find(com_fr_dtcomfr{com}{fr,1} == u_year);
            if isempty(ind)
              continue
            else
              if isempty(com_fr_amount{com}{fr})
                continue
              else
                amount(ind) = amount(ind) + com_fr_amount{com}{fr};
              end
            end
            
          end
          
        end
      end
      
      % set funding vector
      funding = NaN(size(survival));
      
      for j = 1:length(survival)
        ind = find(dummies(:,j) == 1);
        funding(j,1) = amount(ind);
      end
      
      %% save
      YX = [survival,...
            first,...
            nmonths,...
            npreviousinvests,...
            degree,...
            betweenness,...
            bonacich,...
            superangel,...
            exit,...
            industry_NaN,...
            industry_advertising,...
            industry_biotech,...
            industry_cleantech,...
            industry_consulting,...
            industry_ecommerce,...
            industry_enterprise,...
            industry_games_video,...
            industry_hardware,...
            industry_mobile,...
            industry_network_hosting,...
            industry_other,...
            industry_public_relations,...
            industry_search,...
            industry_security,...
            industry_semiconductor,...
            industry_software,...
            industry_web,...
            y_1997,...
            y_1998,...
            y_1999,...
            y_2000,...
            y_2001,...
            y_2002,...
            y_2003,...
            y_2004,...
            y_2005,...
            y_2006,...
            y_2007,...
            y_2008,...
            funding];
      
      save(strcat(obj.dir_var,'export.mat'), 'YX', 'label', 'descr', '-V6');
                                 
      
    end % function REGRESSION

                                                                                                                         
  end % methods
    
  methods (Static)
    
    %% DB
    function obj = load(path)
     % LOAD  load CrunchBase database from basedir
     % e.g. load('J:\crunchbase\test')
     
     import = load(strcat(path,'\db'));
     obj    = import.obj;  
            
    end % function LOAD
    function save(obj)
      save(strcat(obj.basedir, 'db'), 'obj');
    end % function SAVE     
    
  end % methods (Static)
        
end % class CB