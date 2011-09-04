classdef gr_edgelist
    % The class to represent a graph with edge list
    %
    
    % Created by Dahua Lin, on Nov 12, 2010
    %
    
    properties(GetAccess='public', SetAccess='protected')        
        dtype;      % the direction type ('d': directed, 'u': undirected)
        nv = 0;     % the number of vertices
        ne = 0;     % the number of edges
        
        es;     % the source vertices of all edges [ne x 1 int32 zero-based]
        et;     % the target vertices of all edges [ne x 1 int32 zero-based]
        ew;     % the edge weights [empty or m x 1 numeric]        
    end                    
    
    
    methods
        %% Getters
        
        function b = is_directed(G)
            % Get whether the graph is directed
            %
            %   s = G.is_directed;
            %
            
            b = G.dtype == 'd';
        end        
        
        function s = source_vs(G)
            % Get the source vertices of all edges
            %
            %   s = G.source_vs;
            %       returns an ne x 1 array of source vertices
            %       [int32 one-based]
            
            s = G.es + 1;            
        end
        
        function t = target_vs(G)
            % Get the target vertices of all edges
            %
            %   t = G.target_vs;
            %       returns an ne x 1 array of target vertices
            %       [int32 one-based]
            %
            
            t = G.et + 1;            
        end
        
        function w = weights(G)
            % Get the weights of all edges
            %
            %   w = G.weights;
            %       returns an ne x 1 array of edge weights (for
            %       weighted graph), or empty (for non-weighted)
            %
            
            w = G.ew;
        end
                
        function E = edges(G)
            % Get all edges
            %
            %   E = G.edges;
            %       returns an ne x 2 array of edges, of which
            %       each row corresponds to an edge.
            %
            
            E = [G.es G.et] + 1;
        end        
        
        function b = is_weighted(G)
            % Tests whether the graph has weighted edges
            %
            %   G.is_weighted;
            %
            
            b = ~isempty(G.ew);
        end

    end
    
        
    methods(Static)
    
        %% Constructor
        
        function G = from_amat(dty, A)
            % Construct a graph object from affinity matrix
            %
            %   G = gr_edgelist.from_amat('d', A);
            %   G = gr_edgelist.from_amat('u', A);
            %       constructs an edge list graph from an adjacency 
            %       matrix.
            %
            %       The first argument indicates whether the graph is
            %       directed ('d'), or undirected ('u').
            %
            %       A here can be either a logical or numeric array. 
            %       If A is logical, then the function creates an edge 
            %       list with unweighted edges, otherwise it creates an 
            %       edge list with weighted edges.
            %
            %       For undirected graph, only those edges (s, t) with 
            %       s < t are preserved.
            %
            
            % verify input
            
            if ~(ischar(dty) && isscalar(dty) && (dty == 'u' || dty == 'd'))
                error('gr_edgelist:invalidarg', 'dty is invalid.');
            end
            
            n = size(A, 1);
            if ~(isnumeric(A) && ndims(A) == 2 && n == size(A,2))
                error('gr_edgelist:invalidarg', ...
                    'A should be a square numeric matrix.');
            end
            
            % extract edges
            
            if isnumeric(A)
                [s, t, w] = find(A);
            else
                [s, t] = find(A);
                w = [];
            end
            
            if dty == 'u'
                se = find(s < t);
                s = s(se);
                t = t(se);
                
                if ~isempty(w)
                    w = w(se);
                end
            end
            
            m = numel(s);
            
            % construct object
            
            G = gr_edgelist();
            G.dtype = dty;
            G.nv = n;
            G.ne = m;
            G.es = int32(s) - 1;
            G.et = int32(t) - 1;
            G.ew = w;            
            
        end
        
        
        function G = from_edges(dty, n, varargin)
            % Construct a graph object from given edges
            %
            %   G = gr_edgelist.from_edges(dty, n, [s, t]);
            %   G = gr_edgelist.from_edges(dty, n, [s, t, w]);
            %   G = gr_edgelist.from_edges(dty, n, s, t);
            %   G = gr_edgelist.from_edges(dty, n, s, t, w);
            %       constructs an edge list graph from explicitly given
            %       edges. 
            %
            %       dty here can be either 'd' or 'u' indicating
            %       directed and undirected graph, respectively.
            %
            %       Here, s, t are source and target node indices, and 
            %       w are corresponding edge weights.
            %
            
            % verify input
            
            if ~(ischar(dty) && isscalar(dty) && (dty == 'u' || dty == 'd'))
                error('gr_edgelist:invalidarg', 'dty is invalid.');
            end
            if ~(isnumeric(n) && isscalar(n) && n >= 0)
                error('gr_edgelist:invalidarg', ...
                    'n should be a non-negative scalar.');
            end
            n = double(n);
            
            % check edges
            
            if nargin == 3
                
                E = varargin{1};
                if ~(ndims(E) == 2 && isnumeric(E))
                    error('gr_edgelist:invalidarg', ...
                        'The 2nd argument should be a numeric matrix.');
                end
                                
                if isempty(E)
                    m = 0;
                    s = [];
                    t = [];
                    w = [];
                    
                elseif size(E,2) == 2
                    m = size(E, 1);
                    s = E(:,1);
                    t = E(:,2);
                    w = [];
                    
                elseif size(E,2) == 3
                    m = size(E, 1);
                    s = E(:,1);
                    t = E(:,2);
                    w = E(:,3);                                        
                    
                else
                    error('gr_edgelist:invalidarg', ...
                        'The 2nd argument should have 2 or 3 columns.');
                end                
                
            elseif nargin == 4 || nargin == 5
                
                s = varargin{1};
                t = varargin{2};
                
                if nargin < 5
                    w = [];
                else
                    w = varargin{3};
                end
                
                if ~(isnumeric(n) && isscalar(n) && n >= 0)
                    error('gr_edgelist:invalidarg', ...
                        'n should be a non-negative scalar.');
                end
                n = double(n);                
                
                % verify s , t, and w
                if ~(isnumeric(s) && isreal(s) && (isvector(s) || isempty(s)))
                    error('gr_edgelist:invalidarg', 's should be a real vector.');
                end
                
                if ~(isnumeric(t) && isreal(t) && (isvector(t) || isempty(t)))
                    error('gr_edgelist:invalidarg', 't should be a real vector.');
                end
                
                m = numel(s);
                
                if issparse(s); s = full(s); end
                if issparse(t); t = full(t); end
                
                if size(s,2) > 1; s = s.'; end
                if size(t,2) > 1; t = t.'; end
                
                if ~isempty(w)
                    if ~(isnumeric(w) && isreal(w) && isvector(w) && numel(w) == m)
                        error('gr_edgelist:invalidarg', ...
                            'w should be a real vector of length m.');
                    end
                    
                    if issparse(w); w = full(w); end
                    if size(w,2) > 1; w = w.'; end
                end
                
                
            else
                error('gr_edgelist:invalidarg', ...
                    'The number of input arguments are invalid.');
            end
            
            
            % construct object
            
            G = gr_edgelist();
            G.dtype = dty;
            G.nv = n;
            G.ne = m;
            G.es = int32(s) - 1;
            G.et = int32(t) - 1;
            G.ew = w;  
            
        end
    end
            
        
    
    methods
        %% Info dump
        
        function dump(G)
            % dump information about the graph
            %
            %   dump(G);
            %
            
            n = G.nv;
            m = G.ne;
            
            if G.is_directed
                fprintf('Directed Edge List: \n');
            else
                fprintf('Undirected Edge List: \n');
            end
            fprintf('------------------------\n');
            fprintf('    # nodes = %d\n', n);
            fprintf('    # edges = %d\n', m);            
            fprintf('\n');
                        
            fprintf('  edges: \n');
            s = G.source_vs;
            t = G.target_vs;
            if ~G.is_weighted                
                for i = 1 : m
                    fprintf('    [%d]: (%d, %d)\n', i, s(i), t(i));
                end
            else
                w = G.weights;
                for i = 1 : m
                    fprintf('    [%d]: (%d, %d) = %g\n', i, s(i), t(i), w(i));
                end
            end
            fprintf('\n');
            
        end
        
        
        %% convert to adjlist
        
        function Ga = to_adjlist(G)
            % convert to adjacency list
            %
            %   G.to_adjlist();
            %
            
            if ~isa(G, 'gr_adjlist')
                Ga = gr_adjlist.from_base(G);
            else
                Ga = G;
            end
        end
        
        
        %% convert to adjmat
        
        function A = to_amat(G, op)
            % Converts an edge list to an adjacency matrix
            %
            %   A = to_amat(G);
            %   A = to_amat(G, 'full');          
            %
            %       The function creates an n x n matrix A, with
            %       A(G.s(i), G.t(i)) = G.w(i) (for weighted graph) or 
            %       true (for unweighed graph). If dtype is 'u', then
            %       A(G.t(i), G.s(i)) are also set to the same value.
            %       All other entries in A are set to zero.
            %
            %       By default, a sparse matrix is created. If ones wants 
            %       to create a full matrix, then set the 2nd argument 
            %       to 'full'.
            %
                        
            n = G.nv;
            
            add_re = ~isa(G, 'gr_adjlist') && G.dtype == 'u';
            use_full = nargin >= 2 && strcmp(op, 'full');

            if use_full
                
                s = G.es;
                t = G.et;
                w = G.ew;
                
                if isempty(w)
                    A = false(n, n);
                    A(s + t * n + 1) = 1;
                    if add_re
                        A(t + s * n + 1) = 1;
                    end
                else
                    A = zeros(n, n, class(w));
                    A(s + t * n + 1) = w;
                    if add_re
                        A(t + s * n + 1) = w;
                    end
                end
                
            else
                
                s = double(G.es+1);
                t = double(G.et+1);
                w = G.ew;
                
                if ~add_re
                    if isempty(w)
                        A = sparse(s, t, true, n, n);
                    else
                        A = sparse(s, t, double(w), n, n);
                    end
                else
                    if isempty(w)
                        A = sparse([s; t], [t; s], true, n, n);
                    else
                        A = sparse([s; t], [t; s], double([w; w]), n, n);
                    end
                end
            end
        end
        
        
    end    
    
end


