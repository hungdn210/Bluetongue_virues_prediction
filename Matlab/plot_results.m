fileName = 'results_log.csv';

opts = detectImportOptions(fileName);

opts.VariableTypes([1, 6, 7, 8]) = {'char'};

data = readtable(fileName, opts);

target_data_id = 'France_level_3_final';
target_data = data(strcmp(data.data_id, target_data_id), :);
disp(target_data);

% plotting

figure;

models = unique(target_data.model);
months = {'Month+1','Month+2','Month+3','Month+4','Month+5','Month+6'};
hold on;
colors = lines(numel(models));

for i = 1:numel(models)
    this_model = models{i};

    model_data = target_data(strcmp(target_data.model, this_model), :);

    [~, idx] = ismember(model_data.month, months);
    [~, sort_idx] = sort(idx);
    model_data = model_data(sort_idx, :);

    plot(1:numel(months), model_data.F2, '-o', 'DisplayName', this_model, 'Color', colors(i, :), 'LineWidth', 1.5);
end 

xticks(1:numel(months));
xticklabels(months);
xlabel('Forecast Horizon');
ylabel('F2-score');
title('F2-score by Forecast Horizon for Each Model');
legend('Location', 'best');
grid on;
hold off;


% === Figure 1: F2 and MCC ===
figure;
metrics = {'F2', 'MCC'};
for i = 1:numel(metrics)
    subplot(2,1,i);
    hold on; grid on;

    for m = 1:numel(models)
        this_model = models{m};
        model_data = target_data(strcmp(target_data.model, this_model), :);

        % Align month order
        [~, idx] = ismember(model_data.month, months);
        y = nan(1, numel(months));
        y(idx) = model_data.(metrics{i});

        plot(1:numel(months), y, '-o', 'Color', colors(m,:), 'LineWidth', 1.5, 'DisplayName', this_model);
    end

    xticks(1:numel(months));
    xticklabels(months);
    ylabel(metrics{i});
    if i == 1
        title('Model Performance: F2 and MCC');
    end
    if i == numel(metrics)
        xlabel('Forecast Horizon');
    end
    legend('Location', 'bestoutside');
    hold off;
end

% === Figure 2: Precision and Recall ===

metrics = {'Precision', 'Recall'};
colors = lines(numel(models));

figure;
for i = 1:numel(metrics)
    subplot(2,1,i);
    hold on; grid on;
    
    for m = 1:numel(models)
        this_model = models{m};
        model_data = target_data(strcmp(target_data.model, this_model), :);
        
        [~, idx] = ismember(model_data.month, months);
        y = nan(1, numel(months));
        y(idx) = model_data.(metrics{i});
        
        plot(1:numel(months), y, '-o', 'Color', colors(m,:), ...
             'LineWidth', 1.5, 'DisplayName', this_model);
    end
    
    xticks(1:numel(months));
    xticklabels(months);
    ylabel(metrics{i});
    if i == 1
        title('Precision and Recall over Forecast Horizon');
    end
    if i == numel(metrics)
        xlabel('Forecast Horizon');
    end
    legend('Location', 'bestoutside');
    hold off;
end






% --- Multi-Line Plot for Comparing Performance Across Levels ---

filename = 'results_log.csv';
opts = detectImportOptions(filename);

% --- Fix for DATETIME warning ---
% Explicitly set the format for the timestamp column to avoid ambiguity.
% This prevents the warning message during import.
opts = setvaropts(opts, 'timestamp', 'InputFormat', 'MM/dd/uuuu HH:mm:ss');

% Treat the first column (the levels) as text
opts.VariableTypes{1} = 'char'; 

% Read the CSV file into a table
data = readtable(filename, opts);

% --- Fix for renamevars error ---
% Instead of assuming the first column is 'Var1', get its actual name
% from the table properties. This makes the code more robust.
original_first_col_name = data.Properties.VariableNames{1};
data = renamevars(data, original_first_col_name, "Level"); % Rename for clarity

% --- Robustly find column names for epoch and f2 ---
% This avoids errors if the CSV headers have spaces or different capitalization.
variable_names = data.Properties.VariableNames;
epoch_col_name = variable_names{contains(variable_names, 'epoch', 'IgnoreCase', true)};
f2_col_name = variable_names{contains(variable_names, 'f2', 'IgnoreCase', true)};

% Create a new figure
figure('Name', 'F2 Score Evolution', 'Color', 'w');
hold on; % Allow multiple plots on the same axes

% Get all unique levels from the data
levels = unique(data.Level);

% Define a set of colors and line styles for clarity in publication
colors = lines(numel(levels)); % Get a set of distinguishable colors
line_styles = {'-o', '-s', '-d', '-^', '-v', '-x'}; % Different markers

% Loop through each level and plot its F2 score over epochs
for i = 1:numel(levels)
    current_level = levels{i};
    level_data = data(strcmp(data.Level, current_level), :);
    
    % Sort by epoch to ensure lines are drawn correctly
    % Use the dynamically found epoch column name
    level_data = sortrows(level_data, epoch_col_name);
    
    % Use a different line style/marker for each level
    style_index = mod(i-1, numel(line_styles)) + 1;
    
    % Plot using the dynamically found column names
    plot(level_data.(epoch_col_name), level_data.(f2_col_name), line_styles{style_index}, ...
        'LineWidth', 1.5, ...
        'Color', colors(i,:), ...
        'DisplayName', strrep(current_level, '_', ' ')); % Use a clean name for the legend
end

hold off;

% --- Styling for Publication ---
title('Model F2 Score Evolution by Level', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Epoch', 'FontSize', 12);
ylabel('F2 Score', 'FontSize', 12);
legend('show', 'Location', 'southeast', 'FontSize', 10);
grid on;
box on;
set(gca, 'FontSize', 11); % Set axis font size

% For saving, use a high-resolution format
% print('f2_score_evolution', '-dpng', '-r300'); % Example for saving
