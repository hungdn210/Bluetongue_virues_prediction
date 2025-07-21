%% Load CSV
filename = 'results_log.csv';
opts = detectImportOptions(filename);

% Fix date ambiguity
opts = setvaropts(opts, 'timestamp', 'InputFormat', 'MM/dd/uuuu HH:mm');
opts = setvaropts(opts, 'start_date', 'InputFormat', 'MM/dd/uuuu');
opts = setvaropts(opts, 'end_date', 'InputFormat', 'MM/dd/uuuu');
opts = setvaropts(opts, 'data_split_date', 'InputFormat', 'MM/dd/uuuu');

T = readtable(filename, opts);

% Add month_num column
T.month_num = str2double(extractAfter(T.month, 'Month+'));

%% List of countries to compare
countries = {'France', 'Greece', 'Italy'}; 

%% Extract data per country
T_all = cell(size(countries));
levels_all = cell(size(countries));
total_levels = 0;

for c = 1:numel(countries)
    country = countries{c};
    pattern = sprintf('%s_level_(\\d+)_final', country);
    tokens = regexp(T.data_id, pattern, 'tokens');
    
    isMatch = false(height(T), 1);
    level = strings(height(T), 1);

    for i = 1:height(T)
        if ~isempty(tokens{i})
            level(i) = sprintf('%s Level %d', country, str2double(tokens{i}{1}));
            isMatch(i) = true;
        end
    end

    T_country = T(isMatch, :);
    T_country.level = level(isMatch);

    T_all{c} = T_country;
    levels_all{c} = unique(T_country.level);
    total_levels = total_levels + numel(levels_all{c});
end

%% Plotting
figure;
hold on;

colors = lines(total_levels);
markers = {'o', 's', 'd', '^', 'v', 'p', '*', 'x', 'h'};

level_offset = 0;
for c = 1:numel(countries)
    T_country = T_all{c};
    levels = levels_all{c};

    for i = 1:numel(levels)
        this_level = levels{i};
        idx = strcmp(T_country.level, this_level);
        tbl = groupsummary(T_country(idx,:), 'month_num', 'mean', 'F2');

        marker = markers{mod(i-1 + level_offset, numel(markers)) + 1};
        linestyle = '-'; % default for first country

        % Give dashed line to 2nd, dotted to 3rd, etc.
        if c == 2
            linestyle = '--';
        elseif c == 3
            linestyle = ':';
        end

        plot(tbl.month_num, tbl.mean_F2, [linestyle marker], ...
            'DisplayName', this_level, ...
            'Color', colors(i + level_offset,:), ...
            'MarkerFaceColor', colors(i + level_offset,:), ...
            'LineWidth', 2, ...
            'MarkerSize', 7);
    end
    level_offset = level_offset + numel(levels);
end

hold off;
title('F2 Score Evolution per Level: Country Comparison');
xlabel('Forecast Horizon (Months Ahead)');
ylabel('F2 Score');
legend('Location', 'eastoutside');
ylim([0 1]);
grid on;


%% -----------------------------------------
% Model Comparison Across Countries (Average F2 per Model)
% -----------------------------------------

% Get list of all unique models across all countries
all_models = unique(T.model);

% Initialize results matrix
country_model_f2 = nan(numel(all_models), numel(countries));

% Loop through each country and calculate average F2 per model
for c = 1:numel(countries)
    T_country = T_all{c};
    for m = 1:numel(all_models)
        model_name = all_models{m};
        idx = strcmp(T_country.model, model_name);
        country_model_f2(m, c) = mean(T_country.F2(idx), 'omitnan');
    end
end

% Plot grouped bar chart
figure;
bar(country_model_f2, 'grouped');
xticks(1:numel(all_models));
xticklabels(all_models);
xtickangle(45);
ylabel('Average F2 Score');
title('Model Comparison Across Countries (F2 Score)');
legend(countries, 'Location', 'northwest');
grid on;

%% -----------------------------------------
% 7. Best Model per Country
% -----------------------------------------

fprintf('\n=== Best Models per Country ===\n');

for c = 1:numel(countries)
    T_country = T_all{c};

    % Get average F2 and Balanced Accuracy per model
    avg_f2 = groupsummary(T_country, 'model', 'mean', 'F2');
    avg_balacc = groupsummary(T_country, 'model', 'mean', 'BalancedAccuracy');

    % Sort by F2
    [sorted_f2, idx_f2] = sort(avg_f2.mean_F2, 'descend');
    sorted_models_f2 = avg_f2.model(idx_f2);

    % Sort by Balanced Accuracy
    [sorted_balacc, idx_balacc] = sort(avg_balacc.mean_BalancedAccuracy, 'descend');
    sorted_models_balacc = avg_balacc.model(idx_balacc);

    % Print top results
    fprintf('\nCountry: %s\n', countries{c});
    fprintf('Top models by F2:\n');
    for k = 1:min(3, numel(sorted_models_f2))
        fprintf('  %d. %s (%.3f)\n', k, sorted_models_f2{k}, sorted_f2(k));
    end

    fprintf('Top models by Balanced Accuracy:\n');
    for k = 1:min(3, numel(sorted_models_balacc))
        fprintf('  %d. %s (%.3f)\n', k, sorted_models_balacc{k}, sorted_balacc(k));
    end
end