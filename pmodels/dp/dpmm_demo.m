function sol = dpmm_demo(op)
% A program to demonstrate the use of DPMM
%
%   sol = dpmm_demo;             with visualization
%   sol = dpmm_demo('novis');    no visualization
%

% Created by Dahua Lin, on Sep 21, 2011
%

%% parse input

novis = nargin == 1 && strcmpi(op, 'novis');

%% Prepare data

d = 2;
Cx = pdmat('s', d, 1);
Cu = pdmat('s', d, 5^2);

centers = [-1 0; 1 0; 0 1]' * 5;
K0 = size(centers, 2);

n = 1000;

Xs = cell(1, K0);
for k = 1 : K0
    Xs{k} = gsample(centers(:,k), Cx, n);
end
X = [Xs{:}];

%% Construct underlying model

gbase = gaussd.from_mp(0, Cu, 'ip');
amodel = gauss_atom_model(gbase, Cx);

%% Construct DPMM

Kp = 2;
assert(Kp <= K0);

pri_atoms = cell(1, Kp);
for i = 1 : Kp
    pri_atoms{i} = centers(:,i);
end
pri_counts = 1000 * ones(1, Kp);

inherits = dpmm_inherits(1:Kp, Kp, pri_atoms, pri_counts, 0.5, @gtransit);

alpha = 1;
prg = dpmm(amodel, alpha);

S0.inherits = inherits;

[sol, Sc] = prg.initialize(X, S0, 'sample');

T = 10;
for t = 1 : T
    [sol, Sc] = prg.update(sol, Sc);
end


%% Visualize

if novis; return; end

figure;
title('DPMM (Gauss) Demo');
plot(X(1,:), X(2,:), '.');
axis equal;

A = sol.atoms;
A = [A{:}];
cnts = sol.atom_counts;

A = A(:, cnts > n / 2);

hold on;
plot(A(1,:), A(2,:), 'r+', 'MarkerSize', 20, 'LineWidth', 2);
hold off;


%% Probabilistic transition

function g = gtransit(a)

g = gaussd.from_mp(a, pdmat('s', 2, 1e-8), 'ip');



