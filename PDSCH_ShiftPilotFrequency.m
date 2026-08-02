function pilotParam = PDSCH_ShiftPilotFrequency(pilotParam, rbStart, ncPerRB)
%PDSCH_SHIFTPILOTFREQUENCY Shift pilot RE positions by the configured RB start.

offset = rbStart * ncPerRB;
if offset == 0
    return;
end

positionFields = {'CRS_position','DMRS_position','CSIRS_position'};
for fieldIndex = 1:numel(positionFields)
    fieldName = positionFields{fieldIndex};
    if isfield(pilotParam, fieldName) && ~isempty(pilotParam.(fieldName))
        positions = pilotParam.(fieldName);
        valid = ~isnan(positions);
        positions(valid) = positions(valid) + offset;
        pilotParam.(fieldName) = positions;
    end
end
end
