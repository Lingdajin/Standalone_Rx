function tests = test_partial_cb_decode
%TEST_PARTIAL_CB_DECODE Focused tests for partial-CB result support.
tests = functiontests(localfunctions);
end

function setupOnce(test_case)
project_root = fileparts(fileparts(mfilename('fullpath')));
test_case.TestData.original_path = path;
addpath(project_root);
addpath(genpath(fullfile(project_root, 'lib')));
end

function teardownOnce(test_case)
path(test_case.TestData.original_path);
end

function testCrc24bCheck(test_case)
payload = mod(0:79, 2);
block = [payload, crc_calc_212(payload, 'CRC24B')];

verifyTrue(test_case, crc24b_check(block));

block(7) = 1 - block(7);
verifyFalse(test_case, crc24b_check(block));
verifyFalse(test_case, crc24b_check(zeros(1, 24)));
end

function testCcutValidation(test_case)
cfg.Ns = 1;
cfg.C_save = 3;

verifyError(test_case, @() ldpc_llr_to_bits([], cfg, 1, -1), ...
    'ldpc_llr_to_bits:CcutOutOfRange');
verifyError(test_case, @() ldpc_llr_to_bits([], cfg, 1, 1.5), ...
    'ldpc_llr_to_bits:InvalidCcut');
verifyError(test_case, @() ldpc_llr_to_bits([], cfg, 1, 4), ...
    'ldpc_llr_to_bits:CcutOutOfRange');
end
