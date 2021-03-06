function [x, info] = saga_lstsq_dist(A, b, parameter)
    % Parameter setting
    [n, d]       = size(A);                          
    epoch_max    = parameter.epoch_max;           % Max epoch number
    gamma        = parameter.gamma;               % Learning rate
    x            = parameter.x0;                  % Initial condition
    m            = parameter.m;                   % # of cores
    lambda       = parameter.lambda;              % l2 regularization
    
    % Output initialization    
    info         = struct('iter_time',[],'fx',[],'epoch',[]);
    % Initialization
    g_phi = zeros(n,d);
    for i = 1 : n
        g_phi(i,:) = A(i,:)* (A(i,:)*x' - b(i));
    end
%     g_phi_av = mean(g_phi,1);
    for epoch = 1 : epoch_max     
        perm = randperm(n);
        A = A(perm,:);
        b = b(perm,:);
        g_phi = g_phi(perm,:);
        g_phi_tmp = cell(m,1);
        x_tmp = zeros(m,d);
        tic
        parfor k = 1 : m
            offset = (k-1)*fix(n/m);
            A_sub = A(offset+1:offset+fix(n/m),:);
            b_sub = b(offset+1:offset+fix(n/m));
            g_phi_sub = g_phi(offset+1:offset+fix(n/m),:);
            g_phi_av_sub = mean(g_phi_sub,1);
            x_sub = x;
            for j = 1 : fix(n/m)
                i = randi(fix(n/m));
                gx         = A_sub(i,:)* (A_sub(i,:)*x_sub' - b_sub(i));
                x_next     =  1 / (1+lambda*gamma) * x_sub - gamma * (gx - g_phi_sub(i,:) + g_phi_av_sub);
                g_phi_sub(i,:) = gx;
                g_phi_av_sub = mean(g_phi_sub,1);
                x_sub = x_next;
            end
            g_phi_tmp{k} = g_phi_sub;
            x_tmp(k,:) = x_sub;
        end
        info.iter_time(end+1) = toc;
        g_phi = zeros(size(g_phi));
        for k = 1 : m
            g_phi((k-1)*fix(n/m)+1:(k)*fix(n/m),:) = g_phi_tmp{k};
        end
        x = mean(x_tmp,1);
%         g_phi_av = mean(g_phi,1);
        disp([0.5 * norm(A*x'-b,2)^2])
        info.fx(end+1) = 0.5 * norm(A*x'-b,2)^2;
    end        
    info.epoch = epoch;
end