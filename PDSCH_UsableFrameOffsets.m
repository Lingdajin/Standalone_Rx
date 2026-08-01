function frame_start_offsets = PDSCH_UsableFrameOffsets(candidate_frame_starts, ...
    num_samples, samples_per_slot, samples_per_frame, DL_Slot_Mask, NumFrames_cfg)
%PDSCH_USABLEFRAMEOFFSETS Keep detected frames containing all configured DL slots.
% Frame starts are zero-based sample offsets and may be negative. This
% function only filters detected frames; it never extrapolates missing ones.

validateattributes(candidate_frame_starts, {'numeric'}, ...
    {'real', 'finite', 'vector', 'integer'});
validateattributes(num_samples, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'nonnegative', 'integer'});
validateattributes(samples_per_slot, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive', 'integer'});
validateattributes(samples_per_frame, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive', 'integer'});
validateattributes(NumFrames_cfg, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'nonnegative', 'integer'});

dl_slots = find(DL_Slot_Mask);
if isempty(dl_slots)
    error('PDSCH_UsableFrameOffsets:NoDLSlots', ...
        'DL_Slot_Mask must select at least one DL slot.');
end
if numel(DL_Slot_Mask) * samples_per_slot ~= samples_per_frame
    error('PDSCH_UsableFrameOffsets:FrameLengthMismatch', ...
        'DL_Slot_Mask length does not match samples_per_frame.');
end

first_required_sample = (dl_slots(1) - 1) * samples_per_slot;
last_required_boundary = dl_slots(end) * samples_per_slot;

candidate_frame_starts = unique(candidate_frame_starts(:).', 'sorted');
complete_slots = ...
    candidate_frame_starts + first_required_sample >= 0 & ...
    candidate_frame_starts + last_required_boundary <= num_samples;
frame_start_offsets = candidate_frame_starts(complete_slots);
if NumFrames_cfg > 0
    frame_start_offsets = frame_start_offsets(1:min(NumFrames_cfg, ...
        numel(frame_start_offsets)));
end
end
