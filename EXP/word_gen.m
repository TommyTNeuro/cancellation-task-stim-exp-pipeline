clc;
clear;
close all;

% Define 20 three-letter words in English, Hindi, and Arabic
english_words = {'cat', 'dog', 'bat', 'pen', 'cup', 'hat', 'sun', 'box', 'fox', 'jam', ...
                 'map', 'run', 'bug', 'van', 'net', 'leg', 'arm', 'zip', 'bed', 'tap'};

hindi_words = {'घर', 'जल', 'दीप', 'पंख', 'पथ', 'शेर', 'मठ', 'वन', 'संग', 'घट', ...
               'माँ', 'बच', 'रथ', 'नट', 'डाक', 'मत', 'जग', 'धन', 'शक्ति', 'हवा'};

arabic_words = {'بيت', 'قمر', 'شمس', 'دود', 'قلم', 'باب', 'نور', 'فنج', 'ورد', 'غيم', ...
                'سيف', 'لعب', 'حبر', 'ظل', 'ملح', 'طير', 'جبل', 'نهر', 'كتب', 'سور'};

% Define font settings (adjust as needed)
english_font = 'Arial';  % Default English font
hindi_font = 'Nirmala UI'; % Hindi/Devanagari script
arabic_font = 'Arial';  % Default Arabic font (change if needed)
font_size = 30;

% Create output folder
output_folder = 'word_images';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Define categories and separate counters
categories = {'Eng', 'Hin', 'Ara'};
words_list = {english_words, hindi_words, arabic_words};
fonts = {english_font, hindi_font, arabic_font};

% Image size
img_width = 200;
img_height = 100;

% Generate images
for c = 1:length(categories)
    category = categories{c};
    words = words_list{c};
    font_name = fonts{c};
    
    for i = 1:length(words)
        word = words{i};
        filename = sprintf('%s%d.png', category, i); % e.g., Eng1.png, Hin1.png, Ara1.png

        % Create a figure (off-screen) for text rendering
        fig = figure('Visible', 'off', 'Position', [0, 0, img_width, img_height], ...
            'Color', 'none');
        ax = axes(fig, 'Position', [0 0 1 1], 'Color', 'none');
        axis off;

        % Render text centered in the image
        text(0.5, 0.5, word, 'Units', 'normalized', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', font_size, 'FontName', font_name, 'Color', 'w');

        % Capture text as an image
        frame = getframe(ax);
        text_img = frame.cdata;  % Extract RGB image

        % Convert text image to grayscale for alpha mask
        alpha_channel = rgb2gray(text_img);
        alpha_channel(alpha_channel > 0) = 255;  % Ensure full opacity for text

        % Save as PNG with transparency
        imwrite(text_img, fullfile(output_folder, filename), 'png', 'Alpha', alpha_channel);

        fprintf("✅ Saved with transparency: %s\n", filename);

        % Close figure
        close(fig);
    end
end

fprintf("✅ All transparent images generated in '%s' folder.\n", output_folder);
