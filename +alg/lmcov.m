function [params, cov_params] = lmcov(f_calc_res_and_jacob, params, cov, idx_update, lambda, lambda_factor, it_cutoff, norm_cutoff, verbose_level, opts)
    % Generic Levenberg Marquardt with covariance estimate optimizer
    %
    % Inputs:
    %   f_calc_res_and_jacob - function handle; returns residuals and
    %       jacobian of residuals when params is input
    %   params - array; Nx1 array of parameters
    %   cov - array; covariance of residuals
    %   idx_update - array; Nx1 indices which indicate parameters to
    %       optimize
    %   lambda - scalar; initial lambda
    %   lambda_factor - scalar; multiplicative lambda factor
    %   it_cutoff - int; number of iterations to perform
    %   norm_cutoff - scalar; cutoff for the norm of difference of params
    %   verbose_level - int; verbosity cutoff
    %   opts - struct;
    %       .verbosity - int; level of verbosity
    %
    % Outputs:
    %   params - array; Nx1 array of optimized parameters
    %   cov_params - array; NxN coveriance array of optimized parameters

    % Precompute inverse of covariance
    cov_inv = alg.safe_inv(cov);

    % Perform Levenberg–Marquardt iteration(s)
    % Get initial cost
    cost = calc_cost(f_calc_res_and_jacob, params, cov_inv);
    for it = 1:it_cutoff
        % Store previous params and cost
        params_prev = params;
        cost_prev = cost;

        % Compute delta_params
        delta_params = calc_delta_params(f_calc_res_and_jacob, ...
                                         params_prev, ...
                                         idx_update, ...
                                         lambda, ...
                                         cov_inv);

        % update params and cost
        params(idx_update) = params_prev(idx_update) + delta_params;
        cost = calc_cost(f_calc_res_and_jacob, params, cov_inv);

        % If cost decreases, decrease lambda and store results; if cost
        % increases, then increase lambda until cost decreases
        if cost < cost_prev
            % Decrease lambda and continue to next iteration
            lambda = lambda/lambda_factor;
        else
            while cost >= cost_prev
                % Increase lambda and recompute params
                lambda = lambda_factor*lambda;

                if lambda >= realmax('single')
                    % This will already be a very, very small step, so just
                    % exit
                    delta_params(:) = 0;
                    params = params_prev;
                    cost = cost_prev;
                    break
                end

                % Compute delta_params
                delta_params = calc_delta_params(f_calc_res_and_jacob, ...
                                                 params_prev, ...
                                                 idx_update, ...
                                                 lambda, ...
                                                 cov_inv);

                % update params and cost
                params(idx_update) = params_prev(idx_update) + delta_params;
                cost = calc_cost(f_calc_res_and_jacob, params, cov_inv);
            end
        end

        % Exit if change in distance is small
        diff_norm = norm(delta_params);

        % Print iteration stats
        res = f_calc_res_and_jacob(params);
        util.verbose_disp(['It #: ' sprintf('% 3u', it) '; ' ...
                           'Mean res: ' sprintf('% 12.8f', mean(res)) '; ' ...
                           'Stddev res: ' sprintf('% 12.8f', std(res)) '; ' ...
                           'Norm of delta_p: ' sprintf('% 12.8f', diff_norm) '; ' ...
                           'Cost: ' sprintf('% 12.8f', cost) '; ' ...
                           'lambda: ' sprintf('% 12.8f', lambda)], ...
                           verbose_level, ...
                           opts);

        if diff_norm < norm_cutoff
            break
        end
    end
    if it == it_cutoff
        util.verbose_warning('iterations hit cutoff before converging!!!', verbose_level, opts);
    end

    % Get covariance of parameters
    [res, jacob] = f_calc_res_and_jacob(params);
    [~, ~, ~, cov_params_update] = alg.safe_lscov(jacob(:, idx_update), res, cov);

    % Expand covariance array to same size as params. Note that any
    % non-updated parameters are assumed to have a covariance of zero.
    cov_params = zeros(numel(params));
    cov_params(logical(idx_update*idx_update')) = cov_params_update;
end

function cost = calc_cost(f_calc_res_and_jacob, params, cov_inv)
    % Get residuals
    res = f_calc_res_and_jacob(params);

    % Apply weights
    cost = res'*cov_inv*res;
end

function delta_params = calc_delta_params(f_calc_res_and_jacob, params, idx_update, lambda, cov_inv)
    % Get residual and jacobian
    [res, jacob] = f_calc_res_and_jacob(params);

    % Apply idx_update
    jacob = jacob(:, idx_update);

    % Get gradient
    grad = jacob'*cov_inv*res;

    % Get hessian
    hess = jacob'*cov_inv*jacob;

    % Add Levenberg–Marquardt damping
    hess = hess + lambda*eye(sum(idx_update));

    % Get change in params
    delta_params = -alg.safe_lscov(hess, grad);
end
