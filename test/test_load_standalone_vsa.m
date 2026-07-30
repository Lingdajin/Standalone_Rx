function tests = test_load_standalone_vsa
% TEST_LOAD_STANDALONE_VSA 独立接收机多天线VSA加载回归测试。
tests = functiontests(localfunctions);
end

function testConvertsSampleByAntennaYToReceiverLayout(testCase)
inputPath = [tempname, '.mat'];
cleanupObj = onCleanup(@() delete(inputPath));
Y = [1+1j, 101-1j; 2+2j, 102-2j; 3+3j, 103-3j];
XDelta = 1 / 30.72e6;
InputCenter = 4e9;
save(inputPath, 'Y', 'XDelta', 'InputCenter');

[sigRxAll, fsVal, centerFreq, nr] = load_standalone_vsa(inputPath);

verifyEqual(testCase, sigRxAll, Y.');
verifyEqual(testCase, size(sigRxAll), [2, 3]);
verifyEqual(testCase, fsVal, 30.72e6);
verifyEqual(testCase, centerFreq, 4e9);
verifyEqual(testCase, nr, 2);

clear cleanupObj;
end

function testDefaultsMissingInputCenterToZero(testCase)
inputPath = [tempname, '.mat'];
cleanupObj = onCleanup(@() delete(inputPath));
Y = [1; 2; 3];
XDelta = 1 / 15.36e6;
save(inputPath, 'Y', 'XDelta');

[sigRxAll, ~, centerFreq, nr] = load_standalone_vsa(inputPath);

verifyEqual(testCase, sigRxAll, Y.');
verifyEqual(testCase, centerFreq, 0);
verifyEqual(testCase, nr, 1);

clear cleanupObj;
end