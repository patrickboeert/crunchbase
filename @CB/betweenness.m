function bn = betweenness(obj, A, normalize)
% BETWEENNESS  The betweenness centrality number for each vertice of
% the graph.
%
% bc = betweenness(obj, A, normalize) is the betweenness centrality number
% for each vertice of the graph A.

% delete vertices with degree 0 from A
d   = obj.degree(A,0);
ind = find(d > 0);
A   = A(ind,ind);
n   = num_vertices(A);

% compute betweenness centrality
options.unweighted = {0};
options.ec_list    = {0};
betweenness = betweenness_centrality(A);

% map back to full network matrix
bn      = NaN(size(d));
if normalize
  bn(ind) = betweenness .* (2 / (n ^ 2 - 3 * n + 2));
else
  bn(ind) = betweenness;
end
    
end % BETWEENNESS

