classdef invgammad
    % The class to represent Inverse Gamma distributions
    %
    %   Each object of this class can contain one or multiple Gamma
    %   distributions. An inverse gamma distribution is characterized by 
    %   two parameters:
    %
    %   - alpha:    the shape parameter 
    %   - beta:     the scale parameter (inverse of scale)   
    %  
    %   For an object with n distributions over d-dimensional space:    
    %
    %   alpha and beta can be in respectively in either of the following
    %   sizes: 1 x 1, d x 1, 1 x n, d x n.    
    %
    
    %   History
    %   -------
    %       - Created by Dahua Lin, on Sep 1, 2011
    %       - Modified by Dahua Lin, on Sep 28, 2011
    %
    
    %% properties
    
    properties(GetAccess='public', SetAccess='private')
        
        dim;    % the dimension of the underlying space
        num;    % the number of distributions contained in the object
        
        alpha;  % the shape parameter(s)
        beta;   % the scale parameter(s)
        
        lpconst;   % a constant term in logpdf
                   % = sum( alpha * log(beta) - gammaln(alpha) )
                   % 1 x n row vector or 0, or empty (if not computed)
    end
        
    methods
        
        function v = mean(obj)
            % Evaluates the mean(s) of the distribution
            %
            %   v = mean(obj);
            %
            %       v will be an d x n matrix, with v(:,i) corresponding 
            %       to the i-th distribution in obj.
            %
            %   Note this function applies only to the case with 
            %   alpha > 1.
            %
        
            d = obj.dim;
            
            v = bsxfun(@times, obj.beta, 1 ./ (obj.alpha - 1));
            if size(v, 1) < d
                v = v(ones(d, 1), :);
            end               
        end
                
        function v = var(obj)
            % Evaluates the variance(s) of the distribution
            %
            %   v = var(obj);
            %
            %       v will be an d x n matrix, with v(:,i) corresponding 
            %       to the i-th distribution in obj.
            %
            %   Note this function applies only to the case with
            %   alpha > 2.
            %
            
            d = obj.dim;
            a = obj.alpha;
            b = obj.beta;
            
            v = bsxfun(@times, b.^2, 1 ./ ((a - 1).^2 .* (a - 2)));
            if size(v, 1) < d
                v = v(ones(d, 1), :);
            end 
        end
                
        function v = mode(obj)
            % Gets the mode of the distribution
            %
            %   v = mode(obj);
            %
            %       v will be an d x n matrix, with v(:,i) corresponding 
            %       to the i-th distribution in obj.
            %
            
            d = obj.dim;
            
            v = bsxfun(@times, obj.beta, 1 ./ (obj.alpha + 1));
            if size(v, 1) < d
                v = v(ones(d, 1), :);
            end 
        end
            
        
        function v = entropy(obj)
            % Evaluates the entropy value(s) of the distribution
            %
            %   v = entropy(obj);
            %
            %       v will be a 1 x n matrix, with v(:,i) corresponding 
            %       to the i-th distribution in obj.
            %            
            
            d = obj.dim;
            a = obj.alpha;
            b = obj.beta;
            
            t1 = a + gammaln(a) - (1 + a) .* psi(a);
            if d > 1
                if size(t1, 1) == 1
                    t1 = d * t1;
                else
                    t1 = sum(t1, 1);
                end
            end            
            
            t2 = log(b);
            if d > 1
                if size(t2, 1) == 1
                    t2 = d * t2;
                else
                    t2 = sum(t2, 1);
                end
            end
            
            v = t1 + t2;
        end
        
    end
    
    %% Construction
    
    methods 
        
        function obj = invgammad(d, alpha, beta, op)
            % Constructs a inverse gamma distribution object
            %
            %   obj = invgammad(d, alpha);
            %   obj = invgammad(d, alpha, beta);
            %
            %       constructs a inverse Gamma distribution object given 
            %       the parameters.
            %
            %       Inputs:
            %       - alpha:    the shape parameter.
            %
            %       - beta:     the scale parameter. 
            %                   (If omitted, beta is set to 1)
            %
            %   obj = invgammad(d, alpha, beta, 'pre');
            %
            %       Do pre-computation of the term 
            %       sum( alpha * log(beta) - gammaln(alpha) ), which 
            %       might speed-up the evaluation of logpdf or pdf later.
            %
                        
            % verify inputs
            
            if ~(isnumeric(d) && isscalar(d) && d == fix(d) && d >= 1)
                error('invgammad:invalidarg', ...
                    'd should be a positive integer scalar.');
            end           
            
            if ~(isfloat(alpha) && isreal(alpha) && ndims(alpha) == 2)
                error('invgammad:invalidarg', ...
                    'alpha should be a real scalar/vector/matrix.');
            end
            [ma, na] = size(alpha);
            if ~(ma == 1 || ma == d)
                error('invgammad:invalidarg', 'The size of alpha is invalid.');
            end
            
            if nargin < 3
                beta = 1;
                nb = 1;
            else
                if ~(isfloat(beta) && isreal(alpha) && ndims(beta) == 2)
                    error('invgammad:invalidarg', ...
                        'beta should be a numeric scalar/vector/matrix.');
                end
                [mb, nb] = size(beta);
                if ~(mb == 1 || mb == d)
                    error('invgammad:invalidarg', 'The size of beta is invalid.');
                end
                
                if ~(na == nb || na == 1 || nb == 1)
                    error('invgammad:invalidarg', ...
                        'The sizes of alpha and beta are inconsistent.');
                end
            end
            
            if nargin < 4
                lpc = [];
            else
                if ~(ischar(op) && strcmpi(op, 'pre'))
                    error('invgammad:invalidarg', ...
                        'The 4th argument can only be ''pre''.');
                end
                lpc = invgammad.calc_lpconst(d, alpha, beta);
            end
                                    
            % create object
            
            obj.dim = d;
            obj.num = max(na, nb);
            obj.alpha = alpha;
            obj.beta = beta;
            obj.lpconst = lpc;
        end            
    end
    
    
    %% Evaluation
    
    methods
       
        function L = logpdf(obj, X, si)
            % Evaluates log-pdf of given samples
            %
            %   L = obj.logpdf(X);
            %
            %       computes the logarithm of pdf at the samples given
            %       as columns of X.
            %
            %       Suppose there are m distributions in obj, and n 
            %       columns in X, then L is a matrix of size m x n, 
            %       where L(k, i) is the log-pdf of the i-th sample
            %       with respect to the k-th distribution.
            %
            %   L = obj.logpdf(X, si);
            %
            %       computes the logarithm of pdf with respect to the
            %       distributions selected by si.
            %
            
            d = obj.dim;
            if ~(isfloat(X) && ndims(X) == 2 && size(X,1) == d)
                error('invgammad:invalidarg', ...
                    'X should be a numeric matrix with size(X,1) == dim.');
            end
            
            a = obj.alpha;
            b = obj.beta;                        
            lpc = obj.lpconst;
            
            if nargin >= 3 && ~isempty(si)
                if size(a, 2) > 1
                    a = a(:, si);
                end
                if size(b, 2) > 1
                    b = b(:, si);
                end
                if ~isempty(lpc)
                    lpc = lpc(1, si);
                end
            end
            
            if isempty(lpc)
                lpc = invgammad.calc_lpconst(d, a, b);                
            end
                                    
            if size(a, 1) == d
                T1 = (a + 1)' * log(X);
            else
                T1 = (a + 1)' * sum(log(X), 1);
            end
                            
            if size(b, 1) == 1
                if d == 1
                    srX = 1 ./ X;
                else
                    srX = sum(1 ./ X, 1);
                end
                if isscalar(b)
                    if b == 1
                        T2 = srX;
                    else
                        T2 = srX * b;
                    end
                else
                    T2 = b' * srX; 
                end
            else
                T2 = b' * (1 ./ X);
            end           
            
            L = - bsxfun(@plus, T1, T2);
                
            if ~isequal(lpc, 0)
                L = bsxfun(@plus, L, lpc.');                                
            end                        
        end
        
        
        function L = pdf(obj, X, si)
            % Evaluates log-pdf of given samples
            %
            %   L = obj.pdf(X);
            %
            %       computes the pdf values at the samples given
            %       as columns of X.
            %
            %       Suppose there are m distributions in obj, and n
            %       columns in X, then L is a matrix of size m x n,
            %       where L(k, i) is the log-pdf of the i-th sample
            %       with respect to the k-th distribution.
            %
            %   L = obj.pdf(X, si);
            %
            %       computes the pdf values with respect to the
            %       distributions selected by si.
            %
            
            if nargin < 3
                L = exp(logpdf(obj, X));
            else
                L = exp(logpdf(obj, X, si));
            end            
        end
                
    end    
    
    
    methods(Static, Access='private')
        
        function v = calc_lpconst(d, a, b)
            % Calculates the log-pdf constant term
            %
            % sum( alpha * log(beta) - gammaln(alpha) )
            %
            
            if isequal(b, 1)
                c1 = 0;
            else
                c1 = calc_sumprod(1, d, a, log(b));
            end
            
            if isequal(a, 1)
                c2 = 0;
            else
                c2 = gammaln(a);
                if d > 1
                    if size(a, 1) == 1
                        c2 = c2 * d;
                    else
                        c2 = sum(c2, 1);
                    end
                end
            end
                
            v = c1 - c2;                        
        end    
    end
    
    
    %% Sampling
    
    methods
        
        function X = sample(obj, n, i) 
            % Samples from the Gamma distribution
            %            
            %   X = obj.sample();
            %   X = obj.sample(n);
            %       draws n samples from the Gamma distribution. 
            %       (It must be obj.num == 1 for this syntax).
            %
            %       When n is omitted, it is assumed to be 1.
            %
            %   X = obj.sample(n, i);
            %       draws n samples from the i-th Gamma distribution.            
            %
            %       When i is a vector, then n can be a vector of the 
            %       same size. In this case, it draws n(j) samples from
            %       the i(j)-th distribution.                     
            %
            
            if nargin < 2; n = 1; end
            
            a = obj.alpha;
            b = 1 ./ obj.beta;
            d = obj.dim;
            
            % Sample ~ Gamma(a, 1/b)
            
            if nargin < 3 || isempty(i)
                if obj.num > 1
                    error('invgammad:sample:invalidarg', ...
                        'i is needed when obj contains multiple models.');
                end
                
                X = gamma_sample(a, b, n, d);
                
            else
                if ~(isvector(n) && isnumeric(n))
                    error('invgammad:pos_sample:invalidarg', ...
                        'n must be a numeric vector');
                end
                if ~(isvector(i) && isnumeric(i))
                    error('invgammad:pos_sample:invalidarg', ...
                        'i must be a numeric vector');
                end
                if numel(n) ~= numel(i)
                    error('invgammad:pos_sample:invalidarg', ...
                        'The sizes of n and i are inconsistent.');
                end
                K = numel(n);
                
                if size(a, 2) > 1
                    a = a(:, i);
                elseif K > 1
                    a = a(:, ones(1, K));
                end

                if size(b, 2) > 1
                    b = b(:, i);
                elseif K > 1
                    b = b(:, ones(1, K));
                end
                
                if K == 1
                    X = gamma_sample(a, b, n, d);
                else
                    
                    N = sum(n);
                    X = zeros(d, N, class(a));
                    ek = 0;
                    if isscalar(b)
                        b = b(ones(1, K));
                    end
                    
                    for k = 1 : K
                        sk = ek + 1;
                        ek = ek + n(k);
                        X(:, sk:ek) = gamma_sample(a(:,k), b(:,k), n(k), d);
                    end
                end
                
            end % end if there are n & i
            
            % Inverse X
            
            X = 1 ./ X;
            
        end % end sample function
    
    end
    
end
