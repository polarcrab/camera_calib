function validate_f_p_p_d_args(f_p_p_d)
    % Makes sure input function handle is a valid distortion function
    %
    % Inputs:
    %   f_p_p_d - function handle; describes mapping between ideal 
    %       pixel coordinates (with principle point subtracted) and 
    %       distorted pixel coordinates.
    %
    % Outputs:
    %   none
    
    if ~startsWith(func2str(f_p_p_d),'@(x_p_bar,y_p_bar,a,x_o,y_o')
        error('Invalid distortion function handle; must start with "x_p_bar,y_p_bar,a,x_o,y_o"');
    end
end