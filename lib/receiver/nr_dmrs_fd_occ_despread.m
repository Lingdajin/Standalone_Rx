function rxDmrsForCe = nr_dmrs_fd_occ_despread(rxDmrs, dmrsSignal, dmrsPosition, numPorts)
% NR_DMRS_FD_OCC_DESPREAD Separate Type-1 DMRS ports sharing one comb.
% Two-port groups use a 2-RE FD-OCC solve per symbol. Four-port groups use
% two adjacent REs across two adjacent symbols for a 4-by-4 FD/TD-OCC solve.

rxDmrsForCe = rxDmrs;
numPorts = min([numPorts, size(rxDmrs, 2), size(dmrsSignal, 1)]);
visited = false(1, numPorts);
numSymbols = min(size(rxDmrs, 4), size(dmrsSignal, 3));

for port = 1:numPorts
    if visited(port)
        continue;
    end

    group = port;
    for otherPort = port+1:numPorts
        if isequaln(dmrsPosition(port, :, :), dmrsPosition(otherPort, :, :))
            group(end+1) = otherPort; %#ok<AGROW>
        end
    end
    visited(group) = true;

    if isscalar(group)
        continue;
    end
    groupSize = numel(group);
    if groupSize == 2
        symbolsPerSolve = 1;
    elseif groupSize == 4
        symbolsPerSolve = 2;
        if mod(numSymbols, symbolsPerSolve) ~= 0
            error('nr_dmrs_fd_occ_despread:OddDmrsSymbolCount', ...
                'Four-port CDM groups require adjacent DMRS symbol pairs.');
        end
    else
        error('nr_dmrs_fd_occ_despread:UnsupportedGroupSize', ...
            'Type-1 DMRS CDM groups must contain 1, 2, or 4 ports; got %d.', ...
            groupSize);
    end

    representativePort = group(1);
    numDmrsRe = size(rxDmrs, 3);
    if mod(numDmrsRe, 2) ~= 0
        error('nr_dmrs_fd_occ_despread:OddDmrsReCount', ...
            'Type-1 DMRS requires an even RE count per symbol; got %d.', numDmrsRe);
    end

    for symbolStart = 1:symbolsPerSolve:numSymbols
        symbolBlock = symbolStart:symbolStart+symbolsPerSolve-1;
        for reStart = 1:2:numDmrsRe
            rePair = reStart:reStart+1;
            pilotMatrix = zeros(2 * symbolsPerSolve, groupSize);
            rowIndex = 0;
            for symbolIndex = symbolBlock
                for reIndex = rePair
                    rowIndex = rowIndex + 1;
                    pilotMatrix(rowIndex, :) = reshape( ...
                        dmrsSignal(group, reIndex, symbolIndex), 1, []);
                end
            end
            if rcond(pilotMatrix) < 1e-12
                error('nr_dmrs_fd_occ_despread:SingularPilotMatrix', ...
                    ['The CDM pilot matrix is singular for ports [%s], ' ...
                     'symbol block %d, and RE pair %d.'], ...
                    num2str(group), symbolStart, reStart);
            end

            for receiveAntenna = 1:size(rxDmrs, 1)
                receivedBlock = zeros(2 * symbolsPerSolve, 1);
                rowIndex = 0;
                for symbolIndex = symbolBlock
                    for reIndex = rePair
                        rowIndex = rowIndex + 1;
                        receivedBlock(rowIndex) = rxDmrs(receiveAntenna, ...
                            representativePort, reIndex, symbolIndex);
                    end
                end
                channelEstimate = pilotMatrix \ receivedBlock;

                rowIndex = 0;
                for symbolIndex = symbolBlock
                    for reIndex = rePair
                        rowIndex = rowIndex + 1;
                        for groupIndex = 1:groupSize
                            rxDmrsForCe(receiveAntenna, group(groupIndex), ...
                                reIndex, symbolIndex) = pilotMatrix(rowIndex, groupIndex) * ...
                                channelEstimate(groupIndex);
                        end
                    end
                end
            end
        end
    end
end
end
