function tests = test_nr_dmrs_fd_occ_despread
tests = functiontests(localfunctions);
end

function testSeparatesFourPortsAcrossTwoReceiveAntennas(testCase)
rng(31);
numRx = 2;
numPorts = 4;
numRe = 8;
numSymbols = 2;
baseSignal = exp(1j * 2*pi*rand(2, numRe, numSymbols));
dmrsSignal = zeros(numPorts, numRe, numSymbols);
dmrsSignal(1, :, :) = baseSignal(1, :, :);
dmrsSignal(3, :, :) = baseSignal(1, :, :) .* repmat([1, -1], 1, numRe/2);
dmrsSignal(2, :, :) = baseSignal(2, :, :);
dmrsSignal(4, :, :) = baseSignal(2, :, :) .* repmat([1, -1], 1, numRe/2);

dmrsPosition = zeros(numPorts, numRe, numSymbols);
dmrsPosition([1, 3], :, :) = repmat(reshape(1:2:2*numRe, 1, numRe, 1), 2, 1, numSymbols);
dmrsPosition([2, 4], :, :) = repmat(reshape(2:2:2*numRe, 1, numRe, 1), 2, 1, numSymbols);

channel = randn(numRx, numPorts, numRe/2, numSymbols) + ...
    1j * randn(numRx, numPorts, numRe/2, numSymbols);
rxDmrs = zeros(numRx, numPorts, numRe, numSymbols);
groups = {[1, 3], [2, 4]};
for groupIndex = 1:numel(groups)
    group = groups{groupIndex};
    for symbolIndex = 1:numSymbols
        for pairIndex = 1:numRe/2
            rePair = 2*pairIndex-1:2*pairIndex;
            pilotMatrix = squeeze(dmrsSignal(group, rePair, symbolIndex)).';
            for receiveAntenna = 1:numRx
                received = pilotMatrix * squeeze(channel(receiveAntenna, group, pairIndex, symbolIndex)).';
                rxDmrs(receiveAntenna, group, rePair, symbolIndex) = ...
                    repmat(reshape(received, 1, 1, 2, 1), 1, 2, 1, 1);
            end
        end
    end
end

separated = nr_dmrs_fd_occ_despread(rxDmrs, dmrsSignal, dmrsPosition, numPorts);

for port = 1:numPorts
    for pairIndex = 1:numRe/2
        rePair = 2*pairIndex-1:2*pairIndex;
        estimate = squeeze(separated(:, port, rePair, :) ./ ...
            reshape(dmrsSignal(port, rePair, :), 1, 1, 2, numSymbols));
        expected = repmat(squeeze(channel(:, port, pairIndex, :)), 1, 1, 2);
        expected = permute(expected, [1, 3, 2]);
        verifyEqual(testCase, estimate, expected, 'AbsTol', 1e-12);
    end
end
end

function testSeparatesEightPortsWithFrequencyAndTimeOcc(testCase)
rng(47);
numRx = 3;
numPorts = 8;
numRe = 6;
numSymbols = 4;
numPositions = numSymbols / 2;
wf = [1, 1; 1, -1; 1, 1; 1, -1];
wt = [1, 1; 1, 1; 1, -1; 1, -1];
groups = {[1, 3, 5, 7], [2, 4, 6, 8]};

dmrsSignal = zeros(numPorts, numRe, numSymbols);
dmrsPosition = zeros(numPorts, numRe, numSymbols);
for groupIndex = 1:numel(groups)
    group = groups{groupIndex};
    positions = groupIndex:2:2*numRe;
    dmrsPosition(group, :, :) = repmat(reshape(positions, 1, numRe, 1), ...
        numel(group), 1, numSymbols);
    for symbolIndex = 1:numSymbols
        timeIndex = mod(symbolIndex-1, 2) + 1;
        base = exp(1j * 2*pi*rand(1, numRe));
        for localPort = 1:numel(group)
            frequencyCode = repmat(wf(localPort, :), 1, numRe/2);
            dmrsSignal(group(localPort), :, symbolIndex) = ...
                base .* frequencyCode * wt(localPort, timeIndex);
        end
    end
end

channel = randn(numRx, numPorts, numRe/2, numPositions) + ...
    1j * randn(numRx, numPorts, numRe/2, numPositions);
rxDmrs = zeros(numRx, numPorts, numRe, numSymbols);
for groupIndex = 1:numel(groups)
    group = groups{groupIndex};
    for positionIndex = 1:numPositions
        symbolBlock = 2*positionIndex-1:2*positionIndex;
        for pairIndex = 1:numRe/2
            rePair = 2*pairIndex-1:2*pairIndex;
            for receiveAntenna = 1:numRx
                for symbolIndex = symbolBlock
                    for reIndex = rePair
                        pilots = reshape(dmrsSignal(group, reIndex, symbolIndex), 1, []);
                        gains = reshape(channel(receiveAntenna, group, pairIndex, positionIndex), [], 1);
                        received = pilots * gains;
                        rxDmrs(receiveAntenna, group, reIndex, symbolIndex) = received;
                    end
                end
            end
        end
    end
end

separated = nr_dmrs_fd_occ_despread(rxDmrs, dmrsSignal, dmrsPosition, numPorts);

for port = 1:numPorts
    for positionIndex = 1:numPositions
        symbolBlock = 2*positionIndex-1:2*positionIndex;
        for pairIndex = 1:numRe/2
            rePair = 2*pairIndex-1:2*pairIndex;
            for receiveAntenna = 1:numRx
                estimate = squeeze(separated(receiveAntenna, port, rePair, symbolBlock) ./ ...
                    reshape(dmrsSignal(port, rePair, symbolBlock), 1, 1, 2, 2));
                verifyEqual(testCase, estimate, ...
                    repmat(channel(receiveAntenna, port, pairIndex, positionIndex), 2, 2), ...
                    'AbsTol', 1e-12);
            end
        end
    end
end
end
