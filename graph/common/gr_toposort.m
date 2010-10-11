function vs = gr_toposort(G)
% Performs topological sort of a directed graph
%
%   vs = gr_toposort(G);
%       it performs topological sorting of the vertices in graph G,
%       and outputs the vertices in order.
%
%       Topological sorting is only valid when G is acylic, otherwise,
%       it returns -1.
%

% Created by Dahua Lin, on Oct 10, 2010
%

%% verify input

G = gr_adjlist(G);

%% main

vs = gr_toposort_cimp(G);
