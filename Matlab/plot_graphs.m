%% Load CSV
filename = 'results_log.csv';
opts = detectImportOptions(filename);

% Fix date ambiguity
opts = setvaropts(opts, 'timestamp', 'InputFormat', 'MM/dd/uuuu HH:mm');
opts = setvaropts(opts, 'start_date', 'InputFormat', 'MM/dd/uuuu');
opts = setvaropts(opts, 'end_date', 'InputFormat', 'MM/dd/uuuu');
opts = setvaropts(opts, 'data_split_date', 'InputFormat', 'MM/dd/uuuu');

T = readtable(filename, opts);

TARGET_COUNTRY = 'Italy';

%% Extract France level safely — ignore non-matching rows
pattern = sprintf('%s_level_(\\d+)_final', TARGET_COUNTRY);
tokens = regexp(T.data_id, pattern, 'tokens');

% Preallocate a logical index for matching rows
isMatch = false(height(T), 1);
level = strings(height(T), 1);

for i = 1:height(T)
    if ~isempty(tokens{i})
        level(i) = sprintf("%s Level ", TARGET_COUNTRY) + str2double(tokens{i}{1});
        isMatch(i) = true;
    end
end

% Keep only matching rows
T = T(isMatch, :);
T.level = level(isMatch);

% Add month_num column
T.month_num = str2double(extractAfter(T.month, 'Month+'));

% Get unique levels and set up styling
levels = unique(T.level);
colors = lines(numel(levels));
markers = {'o', 's','h', '^', 'v', 'p'};

%% -----------------------------
% 1️⃣ F2 vs Forecast Horizon by France Level
figure;
hold on;
for i = 1:numel(levels)
    this_level = levels{i};
    marker = markers{mod(i-1, numel(markers)) + 1};
    idx = strcmp(T.level, this_level);
    tbl = groupsummary(T(idx,:), 'month_num', 'mean', 'F2');
    plot(tbl.month_num, tbl.mean_F2, ['-' marker], ...
        'DisplayName', this_level, ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'LineWidth', 2, ...
        'MarkerSize', 7);
end
hold off;

xlabel('Forecast Horizon (Months Ahead)', 'FontWeight', 'bold');
ylabel('Average F2 Score', 'FontWeight', 'bold');
title('F2 vs Forecast Horizon by France Level (averaged over models)');
legend('Location', 'best');
grid on;

%% -----------------------------
% 2️⃣ F2 vs Forecast Horizon by Model (with styles)
figure;
models = unique(T.model);
colors = lines(numel(models));

hold on;
for i = 1:numel(models)
    this_model = models{i};
    idx = strcmp(T.model, this_model);
    tbl = groupsummary(T(idx,:), 'month_num', 'mean', 'F2');
    marker = markers{mod(i-1, numel(markers)) + 1};

    plot(tbl.month_num, tbl.mean_F2, ['-' marker], ...
        'DisplayName', this_model, ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'LineWidth', 2, ...
        'MarkerSize', 7);
end
hold off;

xlabel('Forecast Horizon (Months Ahead)', 'FontWeight', 'bold');
ylabel('Average F2 Score', 'FontWeight', 'bold');
title('F2 vs Forecast Horizon by Model (averaged over all levels)');
legend('Location', 'bestoutside');
grid on;

%% -----------------------------
% 3️⃣ Precision & Recall vs Forecast Horizon by France Level
figure;
hold on;
for i = 1:numel(levels)
    this_level = levels{i};
    marker = markers{mod(i-1, numel(markers)) + 1};
    idx = strcmp(T.level, this_level);
    tbl = groupsummary(T(idx,:), 'month_num', 'mean', {'Precision', 'Recall'});

    plot(tbl.month_num, tbl.mean_Precision, ['-' marker], ...
        'DisplayName', this_level + " - Precision", ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'LineWidth', 2, ...
        'MarkerSize', 7);

    plot(tbl.month_num, tbl.mean_Recall, ['--' marker], ...
        'DisplayName', this_level + " - Recall", ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'LineWidth', 2, ...
        'MarkerSize', 7);
end
hold off;

xlabel('Forecast Horizon (Months Ahead)', 'FontWeight', 'bold');
ylabel('Score', 'FontWeight', 'bold');
title('Precision & Recall vs Forecast Horizon by Level');
legend('Location', 'eastoutside');
grid on;

%% -----------------------------
% 4️⃣ MCC vs Forecast Horizon by France Level
figure;
hold on;
for i = 1:numel(levels)
    this_level = levels{i};
    marker = markers{mod(i-1, numel(markers)) + 1};
    idx = strcmp(T.level, this_level);
    tbl = groupsummary(T(idx,:), 'month_num', 'mean', 'MCC');
    plot(tbl.month_num, tbl.mean_MCC, ['-' marker], ...
        'DisplayName', this_level, ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'LineWidth', 2, ...
        'MarkerSize', 7);
end
hold off;

xlabel('Forecast Horizon (Months Ahead)', 'FontWeight', 'bold');
ylabel('Matthews Correlation Coefficient (MCC)', 'FontWeight', 'bold');
title('MCC vs Forecast Horizon by Level');
legend('Location', 'best');
grid on;

%% -----------------------------
% 5️⃣ Balanced Accuracy vs Forecast Horizon by France Level
figure;
hold on;
for i = 1:numel(levels)
    this_level = levels{i};
    marker = markers{mod(i-1, numel(markers)) + 1};
    idx = strcmp(T.level, this_level);
    tbl = groupsummary(T(idx,:), 'month_num', 'mean', 'BalancedAccuracy');
    plot(tbl.month_num, tbl.mean_BalancedAccuracy, ['-' marker], ...
        'DisplayName', this_level, ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'LineWidth', 2, ...
        'MarkerSize', 7);
end
hold off;

xlabel('Forecast Horizon (Months Ahead)', 'FontWeight', 'bold');
ylabel('Balanced Accuracy', 'FontWeight', 'bold');
title('Balanced Accuracy vs Forecast Horizon by Level');
legend('Location', 'best');
grid on;
