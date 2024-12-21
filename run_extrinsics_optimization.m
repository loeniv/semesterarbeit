function [s, fval] = run_extrinsics_optimization(s0, poses)
%RUN_EXTRINSICS_OPTIMI Summary of this function goes here
%   Detailed explanation goes here
    options = optimoptions('fmincon');
    options.Algorithm = 'interior-point';
    options.ConstraintTolerance = 1.0000e-06;
    options.Display = 'off';
    options.MaxFunctionEvaluations = Inf;
    options.MaxIterations = 1000;
    options.ObjectiveLimit = -1.0000e+20;
    options.OptimalityTolerance = 1.0000e-09;
    options.OutputFcn = [];
    options.PlotFcn = [];
    options.StepTolerance = 1.0000e-15;
    options.SubproblemAlgorithm = 'factorization';
    [s, fval] = fmincon(@(x) cost_function(x, poses), s0, [], [], [], [], [], [], @constraints, options);

    %% Nested function for constraint definition
    function [c, ceq] = constraints(s)
        % Constraints for solver
        %
        % fmincon attempts to satisfy c(x) <= 0 for all entries of c
        % fmincon attempts to satisfy ceq(s) = 0 for all entries of ceq
    
        % (1) Perpendicular constraint: w1'*w2 = 0
        ceq(1) = s(1)*s(4) + s(2)*s(5) + s(3)*s(6);
    
        % (2) & (3) Unit length constraints: |w1| = 1; |w2| = 1;
        ceq(2) = s(1)^2 + s(2)^2 + s(3)^2 - 1;
        ceq(3) = s(4)^2 + s(5)^2 + s(6)^2 - 1;
    
    
        % Unused
        c = 0;
    end
end

