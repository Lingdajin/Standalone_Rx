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
        'PDSCH_TX_BW100M_SCS30kHz_SNR25_10ms_padded_3frame.mat');
end

%% ---------- 系统参数 (需与发射端一致) ----------
TM      = 'NR';          % 传输模式: 'NR'
BW      = 100e6;         % 带宽 (Hz)
NumOfRB = 273;           % 使用的RB数
miu     = 1;             % SCS: 0=15k,1=30k,2=60k,3=120k,4=240k,5=480k,6=960k
CPType  = 1;             % 1=NCP, 2=ECP
Nt      = 1;             % 发射天线数
Nr      = 1;             % 接收天线数

%% ---------- 信道估计模式 ----------
CE_Mode_DMRS  = 5;    % <1>:ideal <2>:LMMSE <3>:expPDP <4>:expPDP+idealPDP <5>:LS (1、4在独立接收机中不可用)
CE_Mode_CRS   = 0;    % (NR不用)
CE_Mode_CSIRS = 0;    % (NR不用)

%% ---------- LDPC译码范围 ----------
% 0=译码全部CB; 正整数N=仅译码每个TB最前面的N个CB
% 当N小于TB的总CB数时，BER/BLER/EVM不可用，未译码的输出比特保存为-1。
C_cut = 0;

%% ---------- 单帧多PDSCH profile配置 ----------
% SlotIndices使用NR的0-based时隙号；例如12:19对应帧内slot 12~19。
% 定义PDSCH_Profiles后，接收机由各profile的SlotIndices自动生成DL_Slot_Mask。
PDSCH_Profiles = struct([]);
PDSCH_Profiles(1).Name = 'pdsch0';
PDSCH_Profiles(1).SlotIndices = 0:19;
PDSCH_Profiles(1).RBStart = 0;              % BWP/载波栅格内0-based起始RB
PDSCH_Profiles(1).NumOfRB = NumOfRB;
PDSCH_Profiles(1).MCS_TABLE_PDSCH = 1;
PDSCH_Profiles(1).MCS = 13;
PDSCH_Profiles(1).PDSCH_StartSymbol = 1;    % 1-based
PDSCH_Profiles(1).PDSCH_NumSymbols = 14;    % 连续PDSCH OFDM符号数(一般为14-PDSCH_StartSymbol+1)
%% ---------- DMRS配置 (需与发射端一致) ----------
PDSCH_Profiles(1).DMRS_port = 1;            % DMRS端口数 (1~8)
PDSCH_Profiles(1).NumOfAddDMRS = 1;         % 附加DMRS位置 {0,1,2,3}
PDSCH_Profiles(1).DMRSLength = 1;           % 1=单符号, 2=双符号
PDSCH_Profiles(1).DMRS_Type = 1;            % 1=Type1(comb-2)
PDSCH_Profiles(1).DMRS_ScramblingID0 = 0;   % N_ID^0
PDSCH_Profiles(1).DMRS_ScramblingID1 = 1;   % N_ID^1
PDSCH_Profiles(1).DMRS_nSCID = 0;           % n_SCID {0,1}
PDSCH_Profiles(1).dmrs_TypeA_Position = 'pos2'; % 'pos2' or 'pos3'
%% ---------- LDPC解码配置 (需与发射端一致) ----------
PDSCH_Profiles(1).RNTI = 1;                 % PDSCH数据扰码RNTI
PDSCH_Profiles(1).nID = 10;                  % dataScramblingIdentityPDSCH
PDSCH_Profiles(1).q = 0;                    % codeword index
PDSCH_Profiles(1).RV = 0;                   % redundancy version {0,1,2,3}
PDSCH_Profiles(1).MaxLDPCIterations = 50;
PDSCH_Profiles(1).UseCppLDPCDecoder = true;

% 新增格式时复制一个profile并修改其参数，SlotIndices不能与其他profile重叠：
% PDSCH_Profiles(2).Name = 'pdsch2';
% PDSCH_Profiles(2).SlotIndices = 12:19;
% PDSCH_Profiles(2).RBStart = 0;              % BWP/载波栅格内0-based起始RB
% PDSCH_Profiles(2).NumOfRB = NumOfRB;
% PDSCH_Profiles(2).MCS_TABLE_PDSCH = 2;
% PDSCH_Profiles(2).MCS = 20;
% PDSCH_Profiles(2).PDSCH_StartSymbol = 1;    % 1-based
% PDSCH_Profiles(2).PDSCH_NumSymbols = 14;    % 连续PDSCH OFDM符号数(一般为14-PDSCH_StartSymbol+1)
% %% ---------- DMRS配置 (需与发射端一致) ----------
% PDSCH_Profiles(2).DMRS_port = 1;            % DMRS端口数 (1~8)
% PDSCH_Profiles(2).NumOfAddDMRS = 0;         % 附加DMRS位置 {0,1,2,3}
% PDSCH_Profiles(2).DMRSLength = 1;           % 1=单符号, 2=双符号
% PDSCH_Profiles(2).DMRS_Type = 1;            % 1=Type1(comb-2)
% PDSCH_Profiles(2).DMRS_ScramblingID0 = 0;   % N_ID^0
% PDSCH_Profiles(2).DMRS_ScramblingID1 = 1;   % N_ID^1
% PDSCH_Profiles(2).DMRS_nSCID = 0;           % n_SCID {0,1}
% PDSCH_Profiles(2).dmrs_TypeA_Position = 'pos2'; % 'pos2' or 'pos3'
% %% ---------- LDPC解码配置 (需与发射端一致) ----------
% PDSCH_Profiles(2).RNTI = 1;                 % PDSCH数据扰码RNTI
% PDSCH_Profiles(2).nID = 0;                  % dataScramblingIdentityPDSCH
% PDSCH_Profiles(2).q = 0;                    % codeword index
% PDSCH_Profiles(2).RV = 0;                   % redundancy version {0,1,2,3}
% PDSCH_Profiles(2).MaxLDPCIterations = 50;
% PDSCH_Profiles(2).UseCppLDPCDecoder = true;


%% --------以下为默认配置参数，用来兜底----------------
%% ---------- DMRS配置 (需与发射端一致) ----------
DMRS_port           = 1;      % DMRS端口数 (1~8)
NumOfAddDMRS        = 0;      % 附加DMRS位置 {0,1,2,3}
DMRSLength          = 1;      % 1=单符号, 2=双符号
DMRS_Type           = 1;      % 1=Type1(comb-2)
DMRS_ScramblingID0  = 0;      % N_ID^0
DMRS_ScramblingID1  = 1;      % N_ID^1
DMRS_nSCID          = 0;      % n_SCID {0,1}
dmrs_TypeA_Position = 'pos2'; % 'pos2' or 'pos3'

%% ---------- MCS / 传输块配置 (需与发射端一致) ----------
MCS_TABLE_PDSCH = 2;   % 1=Table1(64QAM), 2=Table2(256QAM), 3=Table3(64QAM-lowSE)
MCS             = 20;   % MCS索引 (对应调制阶数和码率)
% 以下由TBS_calculation_f30自动计算:
% src_len, modulation_mode, Rc

%% ---------以下为公共配置参数-----------
%% ---------- 帧/时隙结构 ----------
NumFrames        = 0;       % 无线帧数: 0=自动检测VSA中所有完整帧; >0=最多处理N帧
% TDD pattern: 标记帧内每个时隙是否为PDSCH(DL)时隙
% miu=0: 10时隙/帧, miu=1: 20时隙/帧, miu=2: 40时隙/帧
% 例: miu=1,20时隙, pattern [3:18]=1 表示时隙3~18为PDSCH
N_slots_frame = 10 * 2^miu;
% 自动从所有PDSCH_Profiles的SlotIndices生成DL_Slot_Mask (0-based -> +1)
DL_Slot_Mask = zeros(1, N_slots_frame);  % 1=PDSCH(DL), 0=UL/GP
for p = 1:length(PDSCH_Profiles)
    if ~isempty(PDSCH_Profiles(p).SlotIndices)
        DL_Slot_Mask(PDSCH_Profiles(p).SlotIndices + 1) = 1;
    end
end

%% ---------- PDSCH OFDM符号配置 ----------
% PDSCH_StartSymbol: PDSCH在每时隙内的起始OFDM符号位置 (1-based)
%   = 1 : 所有 OFDM 符号均为 PDSCH (无 PDCCH, 默认)
%   = 2 : 第1个OFDM符号为PDCCH, 第2~Nd为PDSCH (典型场景)
%   = 3 : 第1~2个OFDM符号为PDCCH, 第3~Nd为PDSCH
%   注意: 需确保DMRS符号位置落在 PDSCH 符号范围内
PDSCH_StartSymbol = 1;    % PDSCH起始OFDM符号位置 (1-based)
CFI = PDSCH_StartSymbol - 1;  % 由PDSCH_StartSymbol自动计算: 控制区域占用的OFDM符号数

%% ---------- 其他 ----------
SNR_dB_est   = 40;   % 估计SNR (dB), 用于LMMSE信道估计; 未知时设为合理值
alphaForPDPCE = 1;   % expPDP衰减因子 (郊区0.1~0.5, 城区1~2)
FreqOffset_Hz = 0;    % 自动从VSA文件读取, 此处为后备默认值
Ns_max       = 1;     % 最大流数
Ns_rank      = 1;     % 流数rank
Matrix_StaticBF_Mode = 2;  % 静态BF模式
channel_code = 2;     % 2=LDPC
RetransmissionIsBind = 1;  % 重传绑定
TDD_Config    = 1;         % TDD配置 (仅统计用)
SRS_periodic  = 10;        % SRS周期 (NR不用)
NRB_forEBB    = NumOfRB;   % 波束赋形RB组大小

%% ---------- 可视化 ----------
PlotConstellation = true;   % true=绘制均衡后数据星座图; false=不绘制

%% ---------- 输出路径 ----------
ResultSaveFile = fullfile(config_dir, 'results', 'Rx_Standalone_Result.mat');
