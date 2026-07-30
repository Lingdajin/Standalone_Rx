%% ================================================================
%%  独立接收机配置文件 (PDSCH_Receiver_Standalone 调用)
%%  修改以下参数以匹配待解调VSA文件
%% ================================================================

%% ---------- 输入文件 ----------
% VSA采集的.mat文件路径 (由 savevsarecording 生成)
config_dir = fileparts(mfilename('fullpath'));
VSA_File = getenv('PDSCH_VSA_FILE');
if isempty(VSA_File)
    VSA_File = fullfile(config_dir, 'input', ...
        'PDSCH_TX_BW100M_SCS30kHz_SNR25_10ms_ANT8_padded_3frame.mat');
end

%% ---------- 系统参数 (需与发射端一致) ----------
TM      = 'NR';          % 传输模式: 'NR'
BW      = 100e6;         % 带宽 (Hz)
NumOfRB = 10;           % 使用的RB数
miu     = 1;             % SCS: 0=15k,1=30k,2=60k,3=120k,4=240k,5=480k,6=960k
CPType  = 1;             % 1=NCP, 2=ECP
Nt      = 8;             % 发射天线数
Nr      = 8;             % 接收天线数

%% ---------- DMRS配置 (需与发射端一致) ----------
DMRS_port           = 8;      % DMRS端口数 (1~8)
NumOfAddDMRS        = 1;      % 附加DMRS位置 {0,1,2,3}
DMRSLength          = 2;      % 1=单符号, 2=双符号
DMRS_Type           = 1;      % 1=Type1(comb-2)
DMRS_ScramblingID0  = 0;      % N_ID^0
DMRS_ScramblingID1  = 1;      % N_ID^1
DMRS_nSCID          = 0;      % n_SCID {0,1}
dmrs_TypeA_Position = 'pos2'; % 'pos2' or 'pos3'

%% ---------- 信道估计模式 ----------
CE_Mode_DMRS  = 5;    % <1>:ideal <2>:LMMSE <3>:expPDP <4>:expPDP+idealPDP <5>:LS (1、4在独立接收机中不可用)
CE_Mode_CRS   = 0;    % (NR不用)
CE_Mode_CSIRS = 0;    % (NR不用)

%% ---------- MCS / 传输块配置 (需与发射端一致) ----------
MCS_TABLE_PDSCH = 1;   % 1=Table1(64QAM), 2=Table2(256QAM), 3=Table3(64QAM-lowSE)
MCS             = 13;   % MCS索引 (对应调制阶数和码率)
% 以下由TBS_calculation_f30自动计算:
% src_len, modulation_mode, Rc

%% ---------- 帧/时隙结构 ----------
NumFrames        = 1;       % 文件包含的无线帧数 (手动配置)
% TDD pattern: 标记帧内每个时隙是否为PDSCH(DL)时隙
% miu=0: 10时隙/帧, miu=1: 20时隙/帧, miu=2: 40时隙/帧
% 例: miu=1,20时隙, pattern [3:18]=1 表示时隙3~18为PDSCH
N_slots_frame = 10 * 2^miu;
DL_Slot_Mask = ones(1, N_slots_frame);  % 1=PDSCH(DL), 0=UL/GP

%% ---------- 其他 ----------
SNR_dB_est   = 25;   % 估计SNR (dB), 用于LMMSE信道估计; 未知时设为合理值
alphaForPDPCE = 1;   % expPDP衰减因子 (郊区0.1~0.5, 城区1~2)
FreqOffset_Hz = 0;    % 自动从VSA文件读取, 此处为后备默认值
CFI          = 0;     % 控制信道符号数(NR下=0)
Ns_max       = 1;     % 最大流数
Ns_rank      = 1;     % 流数rank
Matrix_StaticBF_Mode = 2;  % 静态BF模式
channel_code = 2;     % 2=LDPC
RetransmissionIsBind = 1;  % 重传绑定
TDD_Config    = 1;         % TDD配置 (仅统计用)
SRS_periodic  = 10;        % SRS周期 (NR不用)
NRB_forEBB    = NumOfRB;   % 波束赋形RB组大小

%% ---------- 输出路径 ----------
ResultSaveFile = fullfile(config_dir, 'results', 'Rx_Standalone_Result.mat');
