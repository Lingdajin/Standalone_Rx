function systemParam = PDSCH_ApplyProfile(profile, systemParam)
%PDSCH_APPLYPROFILE Apply resource, symbol, and DMRS fields to SystemParam.

if profile.RBStart + profile.NumOfRB > systemParam.MaxNumOfRB
    error('PDSCH_ApplyProfile:RBAllocationOutOfRange', ...
        'Profile %s allocates RB [%d,%d], outside the %d-RB carrier grid.', ...
        profile.Name, profile.RBStart, ...
        profile.RBStart + profile.NumOfRB - 1, systemParam.MaxNumOfRB);
end

ncUsed = profile.NumOfRB * systemParam.Nc_RB;
gridStart = (systemParam.FFT_size - systemParam.Nc) / 2 + ...
    profile.RBStart * systemParam.Nc_RB;

systemParam.CFI = profile.PDSCH_StartSymbol - 1;
systemParam.Nd_data = profile.PDSCH_NumSymbols;
systemParam.PDSCH_StartSymbol = profile.PDSCH_StartSymbol;
systemParam.PDSCH_NumSymbols = profile.PDSCH_NumSymbols;
systemParam.PDSCH_EndSymbol = profile.PDSCH_StartSymbol + ...
    profile.PDSCH_NumSymbols - 1;
systemParam.NumOfRB = profile.NumOfRB;
systemParam.RBStart = profile.RBStart;
systemParam.Nc_used = ncUsed;
systemParam.Nc_Index = gridStart + (1:ncUsed);
systemParam.DMRS_port = profile.DMRS_port;
systemParam.NL = profile.DMRS_port;
systemParam.NumOfAddDMRS = profile.NumOfAddDMRS;
systemParam.DMRSLength = profile.DMRSLength;
systemParam.DMRS_Type = profile.DMRS_Type;
systemParam.DMRS_ScramblingID0 = profile.DMRS_ScramblingID0;
systemParam.DMRS_ScramblingID1 = profile.DMRS_ScramblingID1;
systemParam.DMRS_nSCID = profile.DMRS_nSCID;
systemParam.dmrs_TypeA_Position = profile.dmrs_TypeA_Position;
systemParam.Nc_used_CRS = 2 * profile.NumOfRB;
systemParam.Nc_used_DMRS = 6 * profile.NumOfRB;
systemParam.Nc_used_CSIRS = 3 * profile.NumOfRB;
systemParam.NRB_forEBB = profile.NumOfRB;
systemParam.ActivePDSCHProfile = profile.Name;
end
