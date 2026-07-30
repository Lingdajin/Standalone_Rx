function tests = test_ldpc_decoder_sync
%TEST_LDPC_DECODER_SYNC Focused tests for the synchronized LDPC module.
tests = functiontests(localfunctions);
end

function setupOnce(test_case)
project_root = fileparts(mfilename('fullpath'));
test_case.TestData.original_path = path;
addpath(project_root);
addpath(genpath(fullfile(project_root, 'lib')));
end

function teardownOnce(test_case)
path(test_case.TestData.original_path);
end

function testTransportBlockSegmentation(test_case)
[C, CBS, filler, crc_length] = ldpc_tbseg_parameters(1000, 0.5);
verifyEqual(test_case, [C, CBS, filler, crc_length], [1, 1016, 0, 16]);

[C, CBS, filler, crc_length] = ldpc_tbseg_parameters(10000, 0.5);
verifyGreaterThan(test_case, C, 1);
verifyEqual(test_case, crc_length, 24);
verifyGreaterThanOrEqual(test_case, filler, 0);
verifyEqual(test_case, C * (CBS - 24) - filler, 10000 + 24);
end

function testDeinterleaver(test_case)
received = 1:12;
actual = ldpc_deinterleave(received, 4);
verifyEqual(test_case, actual, [1,5,9,2,6,10,3,7,11,4,8,12]);
verifyError(test_case, @() ldpc_deinterleave(1:11, 4), ...
    'ldpc_deinterleave:InvalidDimensions');
end

function testConfigInfersTransportCrc(test_case)
sim_param.liftZ = 2;
sim_param.momcodeLength = 20;
cfg_short = ldpc_decoder_config(1, 2, 1, 0, 1, 10, 0, 8, 16, ...
    {sim_param}, {1:8}, 'src_len', 1000);
cfg_long = ldpc_decoder_config(1, 2, 1, 0, 1, 10, 0, 8, 16, ...
    {sim_param}, {1:8}, 'src_len', 4000);
verifyEqual(test_case, cfg_short.crc_len, 16);
verifyEqual(test_case, cfg_long.crc_len, 24);
end

function testAutomaticConfigBuildsRateRecoveryMap(test_case)
cfg = ldpc_decoder_config_auto(1000, 0.5, 4, 1, 2000, 1, 10, 0, ...
    'iterationNumLDPC', 10);
verifyEqual(test_case, sum(cfg.len_Er_save), 2000);
verifyEqual(test_case, numel(cfg.rm_pos_list{1}), 2000);
verifyEqual(test_case, cfg.crc_len, 16);
verifyEqual(test_case, cfg.SimParam_list{1}.iterationNumLDPC, 10);
end

function testBaseGraphBoundaryAndExpansion(test_case)
[~, z] = genHd_base_decoder(192, 1000, 0.2);
verifyEqual(test_case, z, 32);

base = [0, -1; 1, 0];
expanded = full(expand_Hd_base(base, 2));
expected = [1,0,0,0; 0,1,0,0; 0,1,1,0; 1,0,0,1];
verifyEqual(test_case, expanded, expected);
end

function testSmallLdpcDecode(test_case)
parity_matrix = sparse([1, 1]);
decoded = LDPC_decoder([5, -1], parity_matrix, 2, 5);
verifyEqual(test_case, mod(parity_matrix * decoded', 2), 0);
verifyEqual(test_case, decoded, [0, 0]);
end
