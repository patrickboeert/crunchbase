function bc = bonacich(obj, A, a, b)
% BONACICH  The bonacich centrality number for each vertice of the graph.
%
% bc = bonacich(A, a, b) is the bonacich centrality number for each 
% vertice of the graph A with scalar parameter values a > 0  und b > 0.
% See also Social and Economic Networks (Jackson, p. 68)

% check
if (a <= 0) || (b <= 0)
  error('cb.bonacich: a and b must be positive scalar values');
end

% delete vertices with degree 0 from A
d   = obj.degree(A,0);
ind = find(d > 0);
A   = A(ind,ind);

% compute bonacich centrality number
bonacich = (speye(size(A)) - b .* A) \ (a .* A * ones(length(A),1));

% map back to full network matrix
bc      = NaN(size(d));
bc(ind) = bonacich;

end % BONACICH
