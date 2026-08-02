function [profiles, slotProfileIndex, dlSlotMask] = PDSCH_NormalizeProfiles( ...
    configuredProfiles, defaults, slotsPerFrame, symbolsPerSlot)
%PDSCH_NORMALIZEPROFILES Validate profiles and build the per-slot mapping.

requiredDefaults = {'NumOfRB','MCS_TABLE_PDSCH','MCS', ...
    'PDSCH_StartSymbol','NumOfAddDMRS','DMRSLength','DMRS_Type', ...
    'DMRS_port','DMRS_ScramblingID0','DMRS_ScramblingID1', ...
    'DMRS_nSCID','dmrs_TypeA_Position','RNTI','nID','q','RV', ...
    'MaxLDPCIterations','UseCppLDPCDecoder','DL_Slot_Mask'};
for fieldIndex = 1:numel(requiredDefaults)
    if ~isfield(defaults, requiredDefaults{fieldIndex})
        error('PDSCH_NormalizeProfiles:MissingDefault', ...
            'Missing default field %s.', requiredDefaults{fieldIndex});
    end
end

base = rmfield(defaults, 'DL_Slot_Mask');
base.Name = 'legacy';
base.SlotIndices = find(logical(defaults.DL_Slot_Mask)) - 1;
base.RBStart = 0;
base.PDSCH_NumSymbols = symbolsPerSlot - base.PDSCH_StartSymbol + 1;

canonicalFields = fieldnames(base);
if isempty(configuredProfiles)
    profiles = base;
else
    if ~isstruct(configuredProfiles)
        error('PDSCH_NormalizeProfiles:InvalidProfiles', ...
            'PDSCH_Profiles must be a struct array.');
    end
    profiles = repmat(base, 1, numel(configuredProfiles));
    for profileIndex = 1:numel(configuredProfiles)
        supplied = configuredProfiles(profileIndex);
        suppliedFields = fieldnames(supplied);
        unknownFields = setdiff(suppliedFields, canonicalFields);
        if ~isempty(unknownFields)
            error('PDSCH_NormalizeProfiles:UnknownField', ...
                'Profile %d contains unknown field %s.', ...
                profileIndex, unknownFields{1});
        end
        for fieldIndex = 1:numel(suppliedFields)
            fieldName = suppliedFields{fieldIndex};
            profiles(profileIndex).(fieldName) = supplied.(fieldName);
        end
        if ~isfield(supplied, 'Name') || isempty(supplied.Name)
            profiles(profileIndex).Name = sprintf('pdsch%d', profileIndex-1);
        end
        if ~isfield(supplied, 'SlotIndices')
            error('PDSCH_NormalizeProfiles:MissingSlots', ...
                'Profile %s must define zero-based SlotIndices.', ...
                char(string(profiles(profileIndex).Name)));
        end
        if ~isfield(supplied, 'PDSCH_NumSymbols')
            profiles(profileIndex).PDSCH_NumSymbols = symbolsPerSlot - ...
                profiles(profileIndex).PDSCH_StartSymbol + 1;
        end
    end
end

slotProfileIndex = zeros(1, slotsPerFrame);
for profileIndex = 1:numel(profiles)
    profile = profiles(profileIndex);
    profileName = char(string(profile.Name));
    if isempty(profileName)
        error('PDSCH_NormalizeProfiles:InvalidName', ...
            'Profile %d has an empty Name.', profileIndex);
    end
    profiles(profileIndex).Name = profileName;
    validate_integer_vector(profile.SlotIndices, 0, slotsPerFrame-1, ...
        profileName, 'SlotIndices');
    profiles(profileIndex).SlotIndices = unique(reshape(profile.SlotIndices,1,[]), ...
        'stable');
    if isempty(profiles(profileIndex).SlotIndices)
        error('PDSCH_NormalizeProfiles:EmptySlots', ...
            'Profile %s has no SlotIndices.', profileName);
    end

    validate_integer_scalar(profile.NumOfRB, 1, inf, profileName, 'NumOfRB');
    validate_integer_scalar(profile.RBStart, 0, inf, profileName, 'RBStart');
    validate_integer_scalar(profile.PDSCH_StartSymbol, 1, symbolsPerSlot, ...
        profileName, 'PDSCH_StartSymbol');
    validate_integer_scalar(profile.PDSCH_NumSymbols, 1, symbolsPerSlot, ...
        profileName, 'PDSCH_NumSymbols');
    if profile.PDSCH_StartSymbol + profile.PDSCH_NumSymbols - 1 > symbolsPerSlot
        error('PDSCH_NormalizeProfiles:SymbolAllocationOutOfRange', ...
            'Profile %s PDSCH symbols exceed the slot.', profileName);
    end
    validate_integer_scalar(profile.MCS_TABLE_PDSCH, 1, 3, ...
        profileName, 'MCS_TABLE_PDSCH');
    validate_integer_scalar(profile.MCS, 0, 28, profileName, 'MCS');
    if profile.MCS_TABLE_PDSCH == 2 && profile.MCS > 27
        error('PDSCH_NormalizeProfiles:McsOutOfRange', ...
            'Profile %s MCS table 2 only supports indices 0 through 27.', ...
            profileName);
    end
    validate_integer_scalar(profile.DMRS_port, 1, 8, profileName, 'DMRS_port');
    validate_integer_scalar(profile.NumOfAddDMRS, 0, 3, ...
        profileName, 'NumOfAddDMRS');
    validate_integer_scalar(profile.DMRSLength, 1, 2, ...
        profileName, 'DMRSLength');
    validate_integer_scalar(profile.DMRS_Type, 1, 2, ...
        profileName, 'DMRS_Type');
    validate_integer_scalar(profile.DMRS_ScramblingID0, 0, 65535, ...
        profileName, 'DMRS_ScramblingID0');
    validate_integer_scalar(profile.DMRS_ScramblingID1, 0, 65535, ...
        profileName, 'DMRS_ScramblingID1');
    validate_integer_scalar(profile.DMRS_nSCID, 0, 1, ...
        profileName, 'DMRS_nSCID');
    if ~ismember(string(profile.dmrs_TypeA_Position), ["pos2","pos3"])
        error('PDSCH_NormalizeProfiles:InvalidDmrsTypeAPosition', ...
            'Profile %s dmrs_TypeA_Position must be pos2 or pos3.', profileName);
    end
    profiles(profileIndex).dmrs_TypeA_Position = ...
        char(string(profile.dmrs_TypeA_Position));
    validate_integer_scalar(profile.RNTI, 0, 65535, profileName, 'RNTI');
    validate_integer_scalar(profile.nID, 0, 1023, profileName, 'nID');
    validate_integer_scalar(profile.q, 0, 1, profileName, 'q');
    validate_integer_scalar(profile.RV, 0, 3, profileName, 'RV');
    validate_integer_scalar(profile.MaxLDPCIterations, 1, inf, ...
        profileName, 'MaxLDPCIterations');
    if ~islogical(profile.UseCppLDPCDecoder) || ...
            ~isscalar(profile.UseCppLDPCDecoder)
        error('PDSCH_NormalizeProfiles:InvalidDecoderSelection', ...
            'Profile %s UseCppLDPCDecoder must be a logical scalar.', profileName);
    end

    matlabSlots = profiles(profileIndex).SlotIndices + 1;
    occupied = slotProfileIndex(matlabSlots);
    if any(occupied ~= 0)
        conflictSlot = profiles(profileIndex).SlotIndices(find(occupied ~= 0,1));
        error('PDSCH_NormalizeProfiles:OverlappingSlots', ...
            'Slot %d is assigned to more than one PDSCH profile.', conflictSlot);
    end
    slotProfileIndex(matlabSlots) = profileIndex;
end

dlSlotMask = slotProfileIndex > 0;
if ~any(dlSlotMask)
    error('PDSCH_NormalizeProfiles:NoPdschSlots', ...
        'No PDSCH slots are configured.');
end
end

function validate_integer_vector(value, minimum, maximum, profileName, fieldName)
if ~isnumeric(value) || ~isreal(value) || any(~isfinite(value)) || ...
        any(value ~= floor(value)) || any(value < minimum) || any(value > maximum)
    error('PDSCH_NormalizeProfiles:InvalidIntegerVector', ...
        'Profile %s field %s must contain integers in [%g, %g].', ...
        profileName, fieldName, minimum, maximum);
end
end

function validate_integer_scalar(value, minimum, maximum, profileName, fieldName)
if ~isnumeric(value) || ~isscalar(value) || ~isreal(value) || ...
        ~isfinite(value) || value ~= floor(value) || ...
        value < minimum || value > maximum
    error('PDSCH_NormalizeProfiles:InvalidIntegerScalar', ...
        'Profile %s field %s must be an integer in [%g, %g].', ...
        profileName, fieldName, minimum, maximum);
end
end
