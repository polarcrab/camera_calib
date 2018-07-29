function write_single_calib_four_points(calib,file_path,suffix,append_calib)
    % Writes outputs of four point single calibration to a file, so it can
    % be read again later.
    % 
    % Inputs:
    %   calib - struct; contains:
    %       .config - struct; this is the struct returned by
    %           util.read_calib_config()
    %       .intrin.A - array; optimized camera matrix
    %       .intrin.distortion - array; optimized distortions (radial and
    %           tangential) stored as: 
    %           [beta1; beta2; beta3; beta4]  
    %       .extrin(i).cb_img - class.img; ith calibration board image
    %       .extrin(i).rotation - array; ith optimized rotation
    %       .extrin(i).translation - array; ith optimized translation
    %       .extrin(i).four_points_p - array; ith array of four points
    %           around calibration board in pixel coordinates.
    %       .extrin(i).board_points_p - array; ith array of optimized 
    %           subpixel calibration board points in pixel coordinates.
    %       .extrin(i).debug.homography_refine - array; ith homography used
    %           for subpixel target refinement.
    %   file_path - string; path to file to write calibration to
    %   suffix - string; optional suffix to add to names.
    %   append_calib - logical; optional parameter to append another
    %       calibration to output file. If defined and set to true, this
    %       will append the calibration but skip calib.config, as it is
    %       assumed it is getting appended to another calibration output 
    %       and that the calib.config's are the same.
    
    if ~exist('suffix','var')
        suffix = '';
    end
    
    if ~exist('append_calib','var') || ~append_calib
        % This will clear the file
        fclose(fopen(file_path,'w'));

        % Write calib_config
        util.write_comment('calib_config',file_path);
        calib_config_fields = fields(calib.config);
        for i = 1:length(calib_config_fields)
            param = calib.config.(calib_config_fields{i});
            if ischar(param) % TODO: this could cause problems if the string is a number...
                % Must be string
                util.write_string(param,calib_config_fields{i},file_path);
            elseif util.is_num(param)
                % Must be number
                util.write_num(param,calib_config_fields{i},file_path);
            else
                error(['A param was found in calib.config that was not ' ...
                       'a string or a supported number']);
            end
        end
        util.write_newline(file_path);
    end
        
    % Write A    
    util.write_array(calib.intrin.A,['A' suffix],file_path);
    util.write_newline(file_path);
    
    % Write distortion
    util.write_array(calib.intrin.distortion,['distortion' suffix],file_path);
    util.write_newline(file_path);
    
    % Write stuff per calibration image; transpose anything with points so
    % they do not take a lot of vertical space.
    for i = 1:length(calib.extrin)
        util.write_comment(['Calibration' suffix ' ' num2str(i)],file_path);
        util.write_string(calib.extrin(i).cb_img.get_path(),['cb_img' suffix],file_path);
        util.write_array(calib.extrin(i).rotation,['rotation' suffix],file_path);
        util.write_array(calib.extrin(i).translation,['translation' suffix],file_path);
        util.write_array(calib.extrin(i).four_points_p',['four_points_p' suffix],file_path);
        util.write_array(calib.extrin(i).board_points_p',['board_points_p' suffix],file_path);
        util.write_array(calib.extrin(i).debug.homography_refine,['homography_refine' suffix],file_path);
        util.write_newline(file_path);
    end
end