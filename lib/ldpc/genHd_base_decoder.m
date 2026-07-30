function [Hd_base, z, SimParam] = genHd_base_decoder(K, N, R)
%GENHD_BASE_DECODER Select and prepare the NR LDPC decoder base matrix.

lifting_sets = { ...
    [2,4,8,16,32,64,128,256], ...
    [3,6,12,24,48,96,192,384], ...
    [5,10,20,40,80,160,320], ...
    [7,14,28,56,112,224], ...
    [9,18,36,72,144,288], ...
    [11,22,44,88,176,352], ...
    [13,26,52,104,208], ...
    [15,30,60,120,240]};
lifting_values = sort([lifting_sets{:}]);

function_dir = fileparts(mfilename('fullpath'));
if K <= 308 || (K <= 3840 && R <= 0.67) || R <= 0.25
    graph_data = load(fullfile(function_dir, 'BG2.mat'), 'BG2');
    graph = graph_data.BG2;
    graph_type = 'BG2';
    maximum_rows = 42;
    mother_columns = 52;
    if K <= 192
        information_columns = 6;
    elseif K <= 560
        information_columns = 8;
    elseif K <= 640
        information_columns = 9;
    else
        information_columns = 10;
    end
else
    graph_data = load(fullfile(function_dir, 'BG1.mat'), 'BG1');
    graph = graph_data.BG1;
    graph_type = 'BG1';
    maximum_rows = 46;
    mother_columns = 68;
    information_columns = 22;
end

minimum_lifting = ceil(K / information_columns);
lifting_index = find(lifting_values >= minimum_lifting, 1, 'first');
if isempty(lifting_index)
    error('genHd_base_decoder:UnsupportedBlockLength', ...
        'No lifting factor supports K=%d.', K);
end
z = lifting_values(lifting_index);

set_index = find(cellfun(@(values) any(values == z), lifting_sets), 1, 'first');
base_graph = graph(:, :, set_index);
row_count = min(ceil((N + 2 * z - K) / z), maximum_rows);
if strcmp(graph_type, 'BG2')
    column_count = 10 + row_count;
else
    column_count = 22 + row_count;
end
Hd_base = base_graph(1:row_count, 1:column_count);
positive_positions = Hd_base > 0;
Hd_base(positive_positions) = mod(Hd_base(positive_positions), z);

SimParam.liftZ = z;
SimParam.BGtype = graph_type;
SimParam.momcodeLength = mother_columns * z;
SimParam.momK = information_columns * z;
SimParam.l_padding = SimParam.momK - K;
SimParam.iterationNumLDPC = 50;
SimParam.decType = 'FloodingBP';
end
