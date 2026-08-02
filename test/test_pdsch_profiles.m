function tests = test_pdsch_profiles
tests = functiontests(localfunctions);
end

function testMapsMultipleProfilesToZeroBasedSlots(testCase)
defaults = profile_defaults();
p0 = struct('Name','pdsch0','SlotIndices',2:4, ...
    'MCS_TABLE_PDSCH',1,'MCS',20,'PDSCH_StartSymbol',2, ...
    'PDSCH_NumSymbols',13,'RNTI',1,'nID',0);
p1 = p0;
p1.Name = 'pdsch1';
p1.SlotIndices = 6:9;
p1.MCS = 12;
p1.RNTI = 2;
p1.nID = 10;

[profiles, slotMap, mask] = PDSCH_NormalizeProfiles([p0,p1], ...
    defaults, 20, 14);

verifyEqual(testCase, slotMap(3:5), ones(1,3));
verifyEqual(testCase, slotMap(7:10), 2*ones(1,4));
verifyEqual(testCase, find(mask)-1, [2:4,6:9]);
verifyEqual(testCase, profiles(2).RNTI, 2);
verifyEqual(testCase, profiles(2).nID, 10);
verifyEqual(testCase, profiles(2).RV, 0);
end

function testBuildsLegacyProfileWhenProfilesAreOmitted(testCase)
defaults = profile_defaults();
[profiles, slotMap, mask] = PDSCH_NormalizeProfiles(struct([]), ...
    defaults, 20, 14);

verifyEqual(testCase, numel(profiles), 1);
verifyEqual(testCase, profiles.Name, 'legacy');
verifyEqual(testCase, profiles.SlotIndices, 2:4);
verifyEqual(testCase, slotMap(3:5), ones(1,3));
verifyEqual(testCase, mask, logical(defaults.DL_Slot_Mask));
end

function testRejectsOverlappingSlots(testCase)
defaults = profile_defaults();
p0 = struct('Name','pdsch0','SlotIndices',2:4);
p1 = struct('Name','pdsch1','SlotIndices',4:6);

verifyError(testCase, @() PDSCH_NormalizeProfiles([p0,p1], ...
    defaults, 20, 14), 'PDSCH_NormalizeProfiles:OverlappingSlots');
end

function testAppliesRbAndDmrsProfile(testCase)
defaults = profile_defaults();
p = struct('Name','offset','SlotIndices',12:19,'RBStart',10, ...
    'NumOfRB',20,'DMRS_port',2,'PDSCH_StartSymbol',2, ...
    'PDSCH_NumSymbols',12);
[profiles,~,~] = PDSCH_NormalizeProfiles(p, defaults, 20, 14);

systemParam = struct('MaxNumOfRB',273,'Nc_RB',12,'FFT_size',4096, ...
    'Nc',3276);
systemParam = PDSCH_ApplyProfile(profiles(1), systemParam);

verifyEqual(testCase, systemParam.Nc_used, 240);
verifyEqual(testCase, systemParam.Nc_Index(1), (4096-3276)/2 + 121);
verifyEqual(testCase, systemParam.DMRS_port, 2);
verifyEqual(testCase, systemParam.Nd_data, 12);
end

function testLimitsDataIndicesToAllocatedSymbols(testCase)
global SystemParam
oldSystemParam = SystemParam;
cleanup = onCleanup(@() restore_system_param(oldSystemParam)); %#ok<NASGU>
SystemParam = struct('TM','NR');

indices = PDSCH_DataPilotIndexParamInit(2,16,14,1:4,0,0,0, ...
    [],[],[],[],[],[],5);

verifyEqual(testCase, numel(indices.Data_Index), 20);
verifyEqual(testCase, numel(indices.Data_Index_DataRegion), 20);
end

function testRejectsDmrsOutsidePdschSymbols(testCase)
verifyError(testCase, @() PDSCH_PilotParamInit('NR',4,2,6,3,12, ...
    32,12,0,1,0,14,10,1,1,1,0,1,0,'pos2',0,10), ...
    'PDSCH_PilotParamInit:DmrsOutsidePdsch');
end

function testShiftsPilotPositionsByRbStart(testCase)
pilot = struct('DMRS_position',[1,3,5], ...
    'CRS_position',[],'CSIRS_position',[]);
shifted = PDSCH_ShiftPilotFrequency(pilot, 2, 12);
verifyEqual(testCase, shifted.DMRS_position, [25,27,29]);
end

function defaults = profile_defaults()
defaults = struct( ...
    'NumOfRB',273,'MCS_TABLE_PDSCH',2,'MCS',20, ...
    'PDSCH_StartSymbol',1,'NumOfAddDMRS',0,'DMRSLength',1, ...
    'DMRS_Type',1,'DMRS_port',1,'DMRS_ScramblingID0',0, ...
    'DMRS_ScramblingID1',1,'DMRS_nSCID',0, ...
    'dmrs_TypeA_Position','pos2','RNTI',1,'nID',0,'q',0,'RV',0, ...
    'MaxLDPCIterations',50,'UseCppLDPCDecoder',true, ...
    'DL_Slot_Mask',[false(1,2),true(1,3),false(1,15)]);
end

function restore_system_param(value)
global SystemParam
SystemParam = value;
end
