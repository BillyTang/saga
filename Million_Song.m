clc
clearvars
try
   load('data.mat')
catch
    A = load('YearPredictionMSD.txt');
    b = A(:,1);
    A(:,1) = [];
end
A = normr(A);
d = size(A,2);
n = 1e4; %463715
A_tr = A(1:n,:);
A_te = A(n+1:end,1);
b_tr = b(1:n);
b_te = b(n+1:end);
mu = min(eig(A_tr'*A_tr));
L  = norm(A_tr'*A_tr);
parameter.epoch_max = 10;
parameter.gamma = 1/(3*(mu*n+L));
parameter.x0 = zeros(1, d);
parameter.lambda = 1e-3;
parameter.m = 8;
%% Define the gradient/function.
cvx_begin 
    cvx_precision best
    cvx_solver sedumi
    variable x_cvx(d)
    minimize( 0.5 * sum_square(A_tr*x_cvx - b_tr) + parameter.lambda/2 * x_cvx'*x_cvx )
cvx_end
cvx_optval = 0.5 * sum_square(A_tr*x_cvx - b_tr);
param.fMin = cvx_optval;
param.xMin = x_cvx;
%% SAGA
[x1, info1] = SAGA_lstsq(A_tr, b_tr, parameter);
%% SAGA-Distributed
[x2, info2] = SAGA_lstsq_par(A_tr, b_tr, parameter);
%% plot
figure;
semilogy(info1.fx); hold on
semilogy(info2.fx);
xlabel('# of iterations')
ylabel('cost value')
legend('SAGA','Distributed SAGA');