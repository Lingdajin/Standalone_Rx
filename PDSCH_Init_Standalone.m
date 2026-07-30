% PDSCH_Init_Standalone.m  — 独立接收机全局初始化脚本
% 直接从调用方工作区读取配置变量, 设置所有 global 变量
% 需在运行 PDSCH_Receiver_Standalone_Config 之后调用

%% 全局变量声明 (需与 PDSCH_Init.m 一致)
global SystemParam ChannelParam PilotParam DataPilotIndexParam
global MatrixParam LDPCCodingRateMatchingParam HARQParam
global TurboCodingRateMatchingParam
global MCS_all TBS
global InterferenceParam
global N_Matraix SC_perM DMRS_perM
global path_power_exp_PDP path_delay_exp_PDP
global MatrixForCE
global DataStruct save_interval


%% 读取配置变量 (由调用脚本 load)
% 变量来自 PDSCH_Receiver_Standalone_Config.m

%% ===== 独立项目根目录 =====
root = fileparts(mfilename('fullpath'));

%% ====== SystemParam ======
Ns = 1;
SystemParam = struct();
SystemParam.TM        = TM;
SystemParam.Ns_max    = Ns_max;
SystemParam.Ns        = Ns;
SystemParam.Nt        = Nt;
SystemParam.Nr        = Nr;
SystemParam.CFI       = CFI;
SystemParam.CRS_port  = 0;       % NR下不用CRS
SystemParam.DMRS_port = DMRS_port;
SystemParam.CSIRS_port= 0;

% 调用 SystemParamInit 计算 FFT_size, Nd, CP, Nc_Index 等
Nc_RB = 12;
MaxNumOfRB_table = [25,11,nan,nan,nan,nan,nan; 52,24,11,nan,nan,nan,nan; ...
    79,38,18,nan,nan,nan,nan; 106,51,24,nan,nan,nan,nan; ...
    133,65,31,nan,nan,nan,nan; 160,78,38,nan,nan,nan,nan; ...
    216,106,51,nan,nan,nan,nan; 270,133,65,32,nan,nan,nan; ...
    nan,162,79,nan,nan,nan,nan; nan,189,93,nan,nan,nan,nan; ...
    nan,217,107,nan,nan,nan,nan; nan,245,121,nan,nan,nan,nan; ...
    nan,273,135,66,nan,nan,nan];
BW_list = [5e6,10e6,15e6,20e6,25e6,30e6,40e6,50e6,60e6,70e6,80e6,90e6,100e6];
bw_idx = find(BW_list == BW, 1);
if isempty(bw_idx), error('Unsupported BW: %d', BW); end
MaxNumOfRB = MaxNumOfRB_table(bw_idx, miu+1);
if isnan(MaxNumOfRB), error('BW+miu组合不支持'); end
if NumOfRB > MaxNumOfRB
    warning('NumOfRB=%d clamped to Max=%d', NumOfRB, MaxNumOfRB);
    NumOfRB = MaxNumOfRB;
end
FFT_size = 2^ceil(log2(MaxNumOfRB * Nc_RB));
Nc_used = NumOfRB * Nc_RB;
Nc = MaxNumOfRB * Nc_RB;

% CP 计算
if CPType == 1  % NCP
    cp_ref_short = 144; cp_ref_long = 160; Nd = 14;
    LengthOfGI_cp_short = FFT_size * cp_ref_short / 2048;
    LengthOfGI_cp_long  = FFT_size * cp_ref_long  / 2048;
else
    if miu ~= 2, error('ECP仅支持miu=2'); end
    cp_ref_ext = 512; Nd = 12;
    LengthOfGI_cp_short = FFT_size * cp_ref_ext / 2048;
    LengthOfGI_cp_long  = LengthOfGI_cp_short;
end
LengthOfGI = LengthOfGI_cp_short;
SampleFreq = FFT_size * 15e3 * 2^miu;
dt = 1 / SampleFreq;

% 可变CP向量
if strcmp(TM,'NR') && CPType == 1
    LengthOfGI_vec = LengthOfGI_cp_short * ones(1, Nd);
    LengthOfGI_vec(1) = LengthOfGI_cp_long;
    l_long = 7 * 2^miu;
    if l_long > 0 && l_long < Nd
        LengthOfGI_vec(l_long + 1) = LengthOfGI_cp_long;
    end
else
    LengthOfGI_vec = LengthOfGI_cp_short * ones(1, Nd);
end

% 时隙对齐
total_len_actual = FFT_size * Nd + sum(LengthOfGI_vec);
N_align = 15 * FFT_size - total_len_actual;
if N_align > 0
    LengthOfGI_vec(1) = LengthOfGI_vec(1) + N_align;
end

% 相位补偿
if ~exist('FreqOffset_Hz','var'), FreqOffset_Hz = 0; end
if FreqOffset_Hz ~= 0
    cum_before = [0, cumsum(FFT_size + LengthOfGI_vec(1:end-1))];
    useful_start = cum_before + LengthOfGI_vec;
    Fs = FFT_size * 15e3 * 2^miu;
    PhaseComp_vec = exp(1j * 2 * pi * FreqOffset_Hz * useful_start / Fs);
else
    PhaseComp_vec = ones(1, Nd);
end

% 与发射端 PDSCH_SystemParamInit 保持同一载波栅格原点。Nc 表示该带宽/
% SCS 下的完整载波栅格宽度，NumOfRB 只占用从栅格起点开始的 Nc_used 个RE。
Nc_Index = (1:Nc_used) + (FFT_size - Nc) / 2;
SamplesPerOFDM = FFT_size + LengthOfGI;

SystemParam.BW          = BW;
SystemParam.NumOfRB     = NumOfRB;
SystemParam.Nc_RB       = Nc_RB;
SystemParam.Nc          = Nc;
SystemParam.Nc_used     = Nc_used;
SystemParam.Nc_Index    = Nc_Index;
SystemParam.FFT_size    = FFT_size;
SystemParam.Nd          = Nd;
SystemParam.Nd_data     = Nd - CFI;
SystemParam.LengthOfGI  = LengthOfGI;
SystemParam.LengthOfGI_vec = LengthOfGI_vec;
SystemParam.PhaseComp_vec  = PhaseComp_vec;
SystemParam.SamplesPerOFDM = SamplesPerOFDM;
SystemParam.SampleFreq  = SampleFreq;
SystemParam.dt          = dt;
SystemParam.miu         = miu;
SystemParam.CPType      = CPType;
SystemParam.NumOfAddDMRS = NumOfAddDMRS;
SystemParam.DMRSLength   = DMRSLength;
SystemParam.DMRS_Type    = DMRS_Type;
SystemParam.DMRS_ScramblingID0 = DMRS_ScramblingID0;
SystemParam.DMRS_ScramblingID1 = DMRS_ScramblingID1;
SystemParam.DMRS_nSCID   = DMRS_nSCID;
SystemParam.dmrs_TypeA_Position = dmrs_TypeA_Position;
SystemParam.CE_Mode_CRS   = CE_Mode_CRS;
SystemParam.CE_Mode_DMRS  = CE_Mode_DMRS;
SystemParam.CE_Mode_CSIRS = CE_Mode_CSIRS;
SystemParam.CSIRS_flag    = 0;
SystemParam.CSIRS_port    = 0;
SystemParam.CRS_port      = 0;
SystemParam.Matrix_StaticBF_Mode = Matrix_StaticBF_Mode;
SystemParam.Ns_rank       = Ns_rank;
SystemParam.channel_code  = channel_code;
SystemParam.RetransmissionIsBind = RetransmissionIsBind;
SystemParam.NRB_forEBB    = NRB_forEBB;
SystemParam.SRS_periodic  = SRS_periodic;
SystemParam.RML_Flag      = 0;
SystemParam.TDD_Config    = TDD_Config;
SystemParam.MaxNumOfRB    = MaxNumOfRB;
SystemParam.CSIRS_periodicity = 20;
SystemParam.NL            = DMRS_port;
SystemParam.n_s_f         = 0;
SystemParam.Nc_used_CRS   = 2 * NumOfRB;
SystemParam.Nc_used_DMRS  = 6 * NumOfRB;  % DMRS_REperRB=6 for type1
SystemParam.Nc_used_CSIRS = 3 * NumOfRB;

% Fading_Weight占位 (Ideal CE用, 但独立接收机用实际CE)
ChannelParam.NumOfTaps = 1;
ChannelParam.Path_Delay = 0;
ChannelParam.pathPower = 1;   % MatrixForCE_Gen需要

%% ====== PilotParam ======
PilotParam = PDSCH_PilotParamInit(TM, CFI, ...
    SystemParam.Nc_used_CRS, SystemParam.Nc_used_DMRS, SystemParam.Nc_used_CSIRS, SystemParam.Nc_used, ...
    FFT_size, Nc, 0, CPType, NumOfAddDMRS, Nd, Nd-CFI, ...
    DMRS_port, DMRSLength, DMRS_Type, ...
    DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, ...
    dmrs_TypeA_Position, 0);  % n_s_f=0 initially
PilotParam.CSIRS_COLUMN_INDEX = [];
PilotParam.CSIRS_position = [];

%% ====== DataPilotIndexParam ======
DataPilotIndexParam = PDSCH_DataPilotIndexParamInit(...
    CFI, FFT_size, Nd, Nc_Index, ...
    0, DMRS_port, 0, ...
    PilotParam.CRS_position, PilotParam.DMRS_position, ...
    PilotParam.CSIRS_position, PilotParam.CRS_COLUMN_INDEX, ...
    PilotParam.DMRS_COLUMN_INDEX, PilotParam.CSIRS_COLUMN_INDEX);

%% ====== MatrixParam (NR下简化) ======
MatrixParam = struct();
MatrixParam.Matrix_StaticBF = eye(Nt);
MatrixParam.Matrix_W = eye(DMRS_port);

%% ====== MatrixForCE (初始化为空, 后面用 MatrixForCE_Gen) ======
% (信道估计模式4需要expPDP矩阵, 稍后调用MatrixForCE_Gen)

%% ====== LDPC 编码参数占位 ======
LDPCCodingRateMatchingParam = struct();
LDPCCodingRateMatchingParam.modulation_mode = 0;
LDPCCodingRateMatchingParam.src_len = 0;
LDPCCodingRateMatchingParam.G = 0;
LDPCCodingRateMatchingParam.Rc = 0;
LDPCCodingRateMatchingParam.NL = DMRS_port;
LDPCCodingRateMatchingParam.saved_bits_1 = [];
LDPCCodingRateMatchingParam.saved_bits_2 = [];
LDPCCodingRateMatchingParam.C_save = [];
LDPCCodingRateMatchingParam.F_save = [];
LDPCCodingRateMatchingParam.len_Er_save = [];
LDPCCodingRateMatchingParam.len_CB_save = [];
LDPCCodingRateMatchingParam.LLRbuffer_1 = [];
LDPCCodingRateMatchingParam.LLRbuffer_2 = [];
LDPCCodingRateMatchingParam.Data_for_code = [];  % 独立接收无原始比特
LDPCCodingRateMatchingParam.des_bits_all = [];
LDPCCodingRateMatchingParam.crc_len = 24;

TurboCodingRateMatchingParam = struct();

%% ====== HARQParam ======
HARQParam.TransIndex = 1;
HARQParam.ACK = 0;
HARQParam.MaxTranx = 1;
HARQParam.rv_idx_seq = 0;
HARQParam.ACK_adjust = 0;
HARQParam.Adjust_dB = 0;

%% ====== 其他全局变量 ======
InterferenceParam = struct();
N_Matraix = 1;
SC_perM = Nc_used;  % 全频带BF
DMRS_perM = Nc_used / 2;
% 指数衰减PDP (用于 LMMSE/expPDP 信道估计)
div_para = SampleFreq * 1e-6;        % 微秒换算因子
tmp = exp(-((1:LengthOfGI)-1) / div_para / alphaForPDPCE);
path_power_exp_PDP = tmp / sum(tmp);
path_delay_exp_PDP = 0 : LengthOfGI-1;
ChannelParam.NumOfTaps = LengthOfGI;  % 匹配 PDP 长度
ChannelParam.pathPower = path_power_exp_PDP;
ChannelParam.Path_Delay = path_delay_exp_PDP;
MCS_all = []; TBS = [];
MatrixForCE = struct();
CSIRS_perM = 0;
DataStruct = struct();
save_interval = 1;

fprintf('全局参数初始化完成.\n');
