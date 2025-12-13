function star_cancellation_task()
commandwindow;
Screen('Preference', 'SkipSyncTests', 0);
% STAR_CANCELLATION_EXPERIMENT
%
% Author: Tommy Roberts
% Task : Star cancellation task that involves 3 conditons and a
% practice round. Conditions include a English matrix, a Hindi
% matrix and an arabic matrix. Collections of Quatitle omission
% data as well as click data is collected in seperate csv file.

    % === 1) GUI FOR PARTICIPANT / GROUP / ROUNDS ===
    prompts       = {'Participant ID:', 'Participant Group:', 'Rounds to run (e.g. "1,2,3"):'};
    dlg_title     = 'Experiment Setup';
    dims          = [1 50];
    default_input = {'', '', '1,2,3'};
    answer        = inputdlg(prompts, dlg_title, dims, default_input);

    if isempty(answer)
        disp('User cancelled. Exiting...');
        return;
    end

    participant_id    = str2double(answer{1});
    participant_group = strtrim(answer{2});
    if isnan(participant_id)
        disp('Participant ID must be numeric. Exiting...');
        return;
    end

    round_list    = strsplit(answer{3}, ',');
    round_list    = strtrim(round_list);
    valid_rounds  = ismember(round_list, {'1','2','3'});
    if ~all(valid_rounds)
        disp('Invalid input for rounds. Must be among "1","2","3". Exiting...');
        return;
    end

    % === 2) SETUP PSYCHTOOLBOX ===
    try
        PsychDefaultSetup(2);
        screens       = Screen('Screens');
        screen_number = max(screens);

        white = WhiteIndex(screen_number);
        black = BlackIndex(screen_number);
        grey  = GrayIndex(screen_number);

        bgColor     = grey;   % Background
        textColor   = black;  % Instruction text
        stimColor   = white;  % Star stimuli
        cursorColor = white;  % Custom circle cursor

        % Open the main window
        [window, window_rect] = PsychImaging('OpenWindow', screen_number, bgColor);
        [screen_x_pixels, screen_y_pixels] = Screen('WindowSize', window);
        [x_center, y_center] = RectCenter(window_rect);

        Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        Screen('TextFont', window, 'Arial');
        Screen('TextSize', window, 28);

        % Hide the normal system cursor
        HideCursor(window);

        % 2.1) Welcome Screen
        welcome_text = [
            'Welcome to the Star Cancellation Task!\n\n' ...
            'Press any key to begin.'
        ];
        DrawFormattedText(window, welcome_text, 'center','center', textColor);
        Screen('Flip', window);
        KbStrokeWait;

        % 2.2) Instructions
        info_text = [
            'In this task, you will see many stars and words on the screen.\n' ...
            'Your job is to click on all the SMALL star targets as quickly and accurately as possible.\n\n' ...
            'Press any key to start the Practice Round.'
        ];
        DrawFormattedText(window, info_text, 'center','center', textColor, 60);
        Screen('Flip', window);
        KbStrokeWait;

        % === 3) PRACTICE ROUND ===
        practice_duration = 10;  
        run_cancellation_round(window, ...
            bgColor, textColor, stimColor, cursorColor, ...
            screen_x_pixels, screen_y_pixels, x_center, y_center, ...
            participant_id, participant_group, ...
            'Practice Round', ...   
            8, 4, 4, ...            % small_stars, big_stars, words
            15, 40, 50, ...         % radii
            practice_duration, ...
            0, ...                  % round_index=0
            false, ...              % do_csv=false
            'practice');            % internal condition name

        % Brief screen before main rounds
        DrawFormattedText(window, ...
            'Practice complete!\n\nPress any key to begin the main rounds.', ...
            'center','center', textColor);
        Screen('Flip', window);
        KbStrokeWait;

        % === 4) MAIN ROUNDS (30 SECONDS EACH) ===
        main_duration = 30;
        round_count   = 0;

        for rr = 1:numel(round_list)
            round_count = round_count + 1;
            round_label = sprintf('Round %d', round_count);

            condition_code = round_list{rr};
            switch condition_code
                case '1'
                    internal_condition_name = 'english';
                case '2'
                    internal_condition_name = 'hindi';
                case '3'
                    internal_condition_name = 'arabic';
                otherwise
                    internal_condition_name = 'english'; 
            end

            run_cancellation_round(window, ...
                bgColor, textColor, stimColor, cursorColor, ...
                screen_x_pixels, screen_y_pixels, x_center, y_center, ...
                participant_id, participant_group, ...
                round_label, ...
                112, 104, 20, ...  % small_stars, big_stars, words
                15, 40, 50, ...    % radii
                main_duration, ...
                str2double(condition_code), ...
                true, ...          % do_csv=true
                internal_condition_name);
        end

        % === 5) END SCREEN ===
        DrawFormattedText(window, ...
            'All rounds complete.\n\nThank you for participating!\n\nPress any key to exit.', ...
            'center','center', textColor);
        Screen('Flip', window);
        KbStrokeWait;

        sca;
        ShowCursor;
        disp('Experiment complete. Goodbye!');

    catch err
        sca;
        ShowCursor;
        rethrow(err);
    end
end


%% =================== SUBFUNCTIONS ===================
function run_cancellation_round(window, bgColor, textColor, stimColor, cursorColor, ...
    screen_x, screen_y, x_center, y_center, ...
    participant_id, participant_group, round_label, ...
    num_targets, num_big_stars, num_words, ...
    small_star_radius, big_star_radius, word_radius, ...
    round_duration, round_index, do_csv, varargin)

    if nargin > 21
        internal_condition_name = varargin{1};
    else
        internal_condition_name = 'english';
    end

    intro_text = sprintf([ ...
        '%s\n\n' ...
        'You have %d seconds to find all SMALL star targets.\n' ...
        'Click on them with the mouse.\n\n' ...
        'Press any key to begin...' ], ...
        round_label, round_duration);
    DrawFormattedText(window, intro_text, 'center','center', textColor, 60);
    Screen('Flip', window);
    KbStrokeWait;
    
    % Prepare stimuli
    distractor_words  = pick_word_set(internal_condition_name);
    small_star_coords = create_star(small_star_radius);
    big_star_coords   = create_star(big_star_radius);
    word_textures     = create_words(num_words, distractor_words, window);
    
    % Generate positions
    [target_positions, big_star_positions, word_positions] = ...
        generate_non_overlapping_positions(screen_x, screen_y, ...
            num_targets, num_big_stars, num_words, ...
            small_star_radius, big_star_radius, word_radius);
            
    target_selected = false(num_targets,1);
    
    % For quadrant misses/hits (internal calculation only now)
    q_totals = zeros(1,4);  
    for tt = 1:num_targets
        q_num = get_quadrant(target_positions(tt,1), target_positions(tt,2), x_center, y_center);
        q_totals(q_num) = q_totals(q_num) + 1;
    end
    
    round_start_time = GetSecs;
    ListenChar(2);
    
    % =========================================================================
    % === PATH DEFINITION START ===
    % =========================================================================
    bids_csv_path = ''; % Initialize variable to empty
    
    if do_csv
        % 1. Define Root Directory (2 levels up from this script)
        scriptPath = fileparts(mfilename('fullpath'));
        rootDir    = fileparts(fileparts(scriptPath)); 
        
        % 2. Define Subject String
        subLabel = sprintf('sub-%03d', participant_id);
        
        % 3. Build Path: root / data / raw / sub-001 / beh
        behDir = fullfile(rootDir, 'data', 'raw', subLabel, 'beh');
        
        % 4. Create the Directory Structure if it doesn't exist
        if ~exist(behDir, 'dir')
            [status, msg] = mkdir(behDir);
            if ~status
                error(['[ERROR] Could not create directory: ' behDir '. Message: ' msg]);
            end
        end
        
        % 5. Define the File Path
        fileName = sprintf('%s_task-star_beh.csv', subLabel);
        bids_csv_path = fullfile(behDir, fileName);
        
        % 6. Write Header (only if file is new)
        if ~exist(bids_csv_path, 'file')
            fid = fopen(bids_csv_path, 'a');
            header_str = 'participant_id,group,round_index,onset,x,y,quadrant,was_target\n';
            fprintf(fid, header_str);
            fclose(fid);
        end
    end
    % =========================================================================
    
    %% ===== Main loop =====
    while true
        % --- Check for ESC key ---
        [key_down,~,key_code] = KbCheck;
        if key_down && key_code(KbName('ESCAPE'))
            disp('[DEBUG] ESC pressed. Ending round early.');
            break;
        end
        
        % --- Check time limit ---
        elapsed = GetSecs - round_start_time;
        if elapsed >= round_duration
            break;
        end
        
        % --- Get current mouse position ---
        [mx, my, buttons] = GetMouse(window);
        
        % --- Redraw the display ---
        draw_all_stimuli(window, bgColor, stimColor, cursorColor, ...
            target_positions, target_selected, small_star_coords, ...
            big_star_positions, big_star_coords, ...
            word_positions, word_textures, ...
            num_targets, num_big_stars, num_words);
        
        % --- If the mouse is pressed, check for target click ---
        if any(buttons)
            click_time     = GetSecs - round_start_time; % This is 'onset'
            click_quadrant = get_quadrant(mx, my, x_center, y_center);
            was_target      = 0;
            target_quadrant = 0;
            
            % Big star small star overlap check
            for t = 1:num_targets
                if ~target_selected(t)
                    dx = mx - target_positions(t,1);
                    dy = my - target_positions(t,2);
                    dist_val = sqrt(dx^2 + dy^2);
                    
                    if dist_val <= small_star_radius
                        was_target          = 1;
                        target_selected(t)  = true;
                        target_quadrant     = get_quadrant(...
                            target_positions(t,1), target_positions(t,2), ...
                            x_center, y_center);
                        
                        % Immediately redraw
                        draw_all_stimuli(window, bgColor, stimColor, cursorColor, ...
                            target_positions, target_selected, small_star_coords, ...
                            big_star_positions, big_star_coords, ...
                            word_positions, word_textures, ...
                            num_targets, num_big_stars, num_words);
                        break; 
                    end
                end
            end
            
            % --- Log CLICK to the single BIDS CSV ---
            if do_csv
                % *** FIX: USE bids_csv_path HERE ***
                fid = fopen(bids_csv_path, 'a'); 
                fprintf(fid, ...
                    '%d,%s,%d,%.3f,%.2f,%.2f,%d,%d\n', ...
                    participant_id, participant_group, round_index, ...
                    click_time, mx, my, ...
                    click_quadrant, was_target);
                fclose(fid);
            end
            
            % Wait until mouse release
            while any(buttons)
                [~,~,buttons] = GetMouse(window);
            end
        end
        
        % --- If all targets are found, end early ---
        if all(target_selected)
            break;
        end
        
        WaitSecs(0.01);
    end
    ListenChar(0);
    
    % --- Final Tally (Displayed on screen only) ---
    total_selected = sum(target_selected);
    time_used      = min(GetSecs - round_start_time, round_duration);
    
    % --- End-of-round screen ---
    if round_index == 0
        % Practice Round
        summary_txt = sprintf([
            'Practice Round Complete!\n\n' ...
            'Time used: %.1f s\n' ...
            'You found %d out of %d targets.\n\n' ...
            'Press any key to continue...'
        ], time_used, total_selected, num_targets);
        DrawFormattedText(window, summary_txt, 'center','center', textColor, 60);
        Screen('Flip', window);
        KbStrokeWait;
    else
        % Normal round
        end_text = 'Round complete!\n\nPress any key to continue...';
        DrawFormattedText(window, end_text, 'center','center', textColor, 60);
        Screen('Flip', window);
        KbStrokeWait;
    end
end

%% ================= HELPER FUNCTIONS =================
function words_cell = pick_word_set(condition_name)
    % 1. Get the path of this current script file
    scriptPath = fileparts(mfilename('fullpath'));
    
    % 2. Define the image directory relative to the script
    % fileparts(scriptPath) goes up one level (..)
    % Then we go down into 'assets' and 'word_images'
    imgDir = fullfile(fileparts(scriptPath), 'assets', 'word_images');

    % 3. Determine the file prefix based on language
    switch lower(condition_name)
        case 'english'
            prefix = 'Eng';
        case 'hindi'
            prefix = 'Hin';
        case 'arabic'
            prefix = 'Ara';
        otherwise
            % Fallback
            prefix = 'Eng';
    end
    
    % 4. Generate the 20 filenames automatically
    words_cell = cell(1, 20); % Pre-allocate
    for i = 1:20
        % Creates: /path/to/assets/word_images/Eng1.png
        fileName = sprintf('%s%d.png', prefix, i);
        words_cell{i} = fullfile(imgDir, fileName);
    end
end

function star_coords = create_star(radius_val)
% Creates a 5-point star.
    num_points   = 5;
    outer_rad    = radius_val;
    inner_rad    = radius_val / 2.5;
    theta        = linspace(0, 2*pi, 2*num_points+1);
    star_x = zeros(1, 2*num_points);
    star_y = zeros(1, 2*num_points);

    for i=1:2*num_points
        if mod(i,2)==1
            r = outer_rad;
        else
            r = inner_rad;
        end
        star_x(i) = r*cos(theta(i));
        star_y(i) = r*sin(theta(i));
    end
    star_coords = [star_x; star_y];
end

function texs = create_words(num_words, paths_cell, win_handle)
% CREATE_WORDS.
    texs = cell(1, num_words);
    for i=1:num_words
        [img,~,alpha] = imread(paths_cell{i});
        if ~isempty(alpha)
            img(:,:,4) = alpha;
        end
        img = double(img)/255;
        texs{i} = Screen('MakeTexture', win_handle, img);
    end
end

function [target_pos, big_star_pos, word_pos] = ...
    generate_non_overlapping_positions(scr_x, scr_y, ...
    n_targets, n_big_stars, n_words, rad_target, rad_big_star, rad_word)

    % Generate a grid of candidate positions
    n_rows = 200;
    n_cols = 200;
    xs = linspace(scr_x * 0.03, scr_x * 0.97, n_cols);
    ys = linspace(scr_y * 0.03, scr_y * 0.97, n_rows);

    [xx, yy] = meshgrid(xs, ys);
    all_positions = [xx(:), yy(:)];
    all_positions = all_positions(randperm(size(all_positions,1)), :);

    placed = [];
    radii  = [];

    [target_pos, all_positions, placed, radii] = ...
        pick_non_overlapping_positions(all_positions, n_targets, rad_target, placed, radii);
    [big_star_pos, all_positions, placed, radii] = ...
        pick_non_overlapping_positions(all_positions, n_big_stars, rad_big_star, placed, radii);
    [word_pos, ~, ~, ~] = ...
        pick_non_overlapping_positions(all_positions, n_words, rad_word, placed, radii);
end

function draw_all_stimuli(win, bgCol, stimCol, cursorCol, ...
    target_pos, target_sel, small_star_coords, ...
    big_star_pos, big_star_coords, ...
    word_pos, word_texs, ...
    n_targets, n_big_stars, n_words)

    % Fill screen with background colour
    Screen('FillRect', win, bgCol);

    % 1) Draw small target stars
    for t=1:n_targets
        cxy = target_pos(t,:);
        offset = [small_star_coords(1,:)+cxy(1); ...
                  small_star_coords(2,:)+cxy(2)];
        if target_sel(t)
            % Darken star to indicate it’s 'found'
            col = [0.2 0.2 0.2];
        else
            col = stimCol;
        end
        Screen('FillPoly', win, col, offset', 0); 
    end

    % 2) Draw large star distractors
    for b=1:n_big_stars
        cxy = big_star_pos(b,:);
        offset = [big_star_coords(1,:)+cxy(1); ...
                  big_star_coords(2,:)+cxy(2)];
        Screen('FillPoly', win, stimCol, offset', 0);
    end

    % 3) Draw word distractors
    for w=1:n_words
        cxy = word_pos(w,:);
        box_s = 50;
        dst_rect = [cxy(1)-box_s, cxy(2)-box_s, ...
                    cxy(1)+box_s, cxy(2)+box_s];
        Screen('DrawTexture', win, word_texs{w}, [], dst_rect);
    end

    % 4) Draw the custom cursor
    [mx, my, ~] = GetMouse(win);
    cursor_radius = 6;
    cursor_rect   = [mx - cursor_radius, my - cursor_radius, ...
                     mx + cursor_radius, my + cursor_radius];
    Screen('FillOval', win, cursorCol, cursor_rect);

    % Flip to the screen
    Screen('Flip', win);
end

function [chosen_pos, all_pos_out, placed_pos_out, placed_radii_out] = ...
    pick_non_overlapping_positions(all_pos_in, N, radius_val, placed_pos_in, placed_radii_in)
    
    chosen_pos       = zeros(N,2);
    placed_pos_out   = placed_pos_in;
    placed_radii_out = placed_radii_in;
    all_pos_out      = all_pos_in;

    idx   = 0;
    i_pos = 1;

    while idx < N && i_pos <= size(all_pos_out,1)
        cand = all_pos_out(i_pos,:);
        if is_non_overlapping(cand, radius_val, placed_pos_out, placed_radii_out)
            idx = idx + 1;
            chosen_pos(idx,:) = cand;
            placed_pos_out    = [placed_pos_out; cand];
            placed_radii_out  = [placed_radii_out; radius_val];
            all_pos_out(i_pos,:) = [];
        else
            i_pos = i_pos + 1;
        end
    end

    if idx < N
        error('Not enough non-overlapping positions found!');
    end
end

function is_ok = is_non_overlapping(candidate_xy, candidate_rad, placed_xy, placed_rads)
    is_ok = true;
    for pp = 1:size(placed_xy,1)
        dist_val = sqrt( (placed_xy(pp,1) - candidate_xy(1))^2 + ...
                         (placed_xy(pp,2) - candidate_xy(2))^2 );
        if dist_val < (placed_rads(pp) + candidate_rad)
            is_ok = false;
            return;
        end
    end
end

function q_num = get_quadrant(x_val, y_val, x_mid, y_mid)
% Quadrants:
%   Q1 = upper-left
%   Q2 = upper-right
%   Q3 = lower-left
%   Q4 = lower-right
    if x_val < x_mid && y_val < y_mid
        q_num = 1;
    elseif x_val >= x_mid && y_val < y_mid
        q_num = 2;
    elseif x_val < x_mid && y_val >= y_mid
        q_num = 3;
    else
        q_num = 4;
    end
end
