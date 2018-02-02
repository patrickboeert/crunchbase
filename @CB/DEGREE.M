function d = degree(obj, A, normalize)
% DEGREE The degree number for each vertice of the graph.
%
% d = degree(A) returns the degree number for each vertice of the graph A.
%
% d = degree(A,1) returns the normalized degree number for each vertice of 
% the graph A.
%
% If 'normalize' is true, then the degree number is normalized by the
% maximum possible degree N-1 in an N actor network

% degree vector
degree = sum(A,2);

% normalize, if wanted
if normalize
  n = nnz(degree);
  d = full(degree)./(n-1);  
else
  d = full(degree);
end

end % DEGREE
  