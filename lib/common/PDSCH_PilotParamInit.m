function PilotParam = PDSCH_PilotParamInit(TM,CFI,Nc_used_CRS,Nc_used_DMRS,Nc_used_CSIRS,Nc_used,FFT_size,Nc,CSIRS_position_config,CPType,NumOfAddDMRS,Nd,Nd_data,DMRS_port,DMRSLength,DMRS_Type,DMRS_ScramblingID0,DMRS_ScramblingID1,DMRS_nSCID,dmrs_TypeA_Position,n_s_f,varargin)
                               
%% CRS generation (port0~port3)
% CRS signal
Max_CRS_port = 4;   % max CRS port number
CRS_Signal = ((2*randi([0,1],[Max_CRS_port,Nc_used_CRS,4])-1)+1i*(2*randi([0,1],[Max_CRS_port,Nc_used_CRS,4])-1))./sqrt(2);
% CRS position
CRS_position = zeros(Max_CRS_port,Nc_used_CRS,4);
CRS_position(1,:,:) = [1:6:Nc_used;4:6:Nc_used;1:6:Nc_used;4:6:Nc_used].'+(FFT_size-Nc)/2;
CRS_position(2,:,:) = [4:6:Nc_used;1:6:Nc_used;4:6:Nc_used;1:6:Nc_used].'+(FFT_size-Nc)/2;
CRS_position(3,:,1:2) = [1:6:Nc_used;4:6:Nc_used].'+(FFT_size-Nc)/2;
CRS_position(4,:,1:2) = [4:6:Nc_used;1:6:Nc_used].'+(FFT_size-Nc)/2;
CRS_COLUMN_INDEX = [1 5 8 12;1 5 8 12;2 9 NaN NaN;2 9 NaN NaN];

%% DMRS (UE-Specific RS) generation (port5 for TM7, port7~port14 for other)
% DMRS signal
if TM == 7
    Max_DMRS_port = 1;
    DMRS_Signal = ((2*randi([0,1],[Max_DMRS_port,Nc_used_DMRS,4])-1)+1i*(2*randi([0,1],[Max_DMRS_port,Nc_used_DMRS,4])-1))./sqrt(2);
elseif TM == 'NR'
     Max_DMRS_port = 8;   % 3GPP DMRS type1 最高支持8端口(1000~1007)
     Npos = NumOfAddDMRS + 1;              % DMRS位置数 (front-loaded + additional)
     Nsym_DMRS = Npos * DMRSLength;        % DMRS总OFDM符号数
     % 校验: 8端口需要双符号DMRS (TD-OCC需要相邻双符号)
     if DMRS_port > 4 && DMRSLength ~= 2
         error('DMRS port>4 requires DMRSLength=2 (double-symbol DMRS for TD-OCC). DMRS_port=%d, DMRSLength=%d.', DMRS_port, DMRSLength);
     end
     
     % --- DMRS_COLUMN_INDEX (需在DMRS序列生成前确定, 供c_init计算符号索引l) ---
     % TS 38.211 Table 7.4.1.1.2-3: PDSCH mapping type A, single-symbol DMRS
     % l0: dmrs-TypeA-Position, 'pos2'→l0=2 (0-based), 'pos3'→l0=3 (0-based)
     % 以下数组均为 MATLAB 1-based 索引
     if strcmp(dmrs_TypeA_Position, 'pos2')
         if CPType == 1 % NCP, l0=2, ld=12
             switch NumOfAddDMRS
                 case 0,  basePos = [3];          % l0=2
                 case 1,  basePos = [3, 12];      % l0=2, l1=11
                 case 2,  basePos = [3, 8, 12];   % l0=2, l1=7, l2=11
                 case 3,  basePos = [3, 6, 9, 12];% l0=2, l1=5, l2=8, l3=11
                 otherwise, error('Wrong NumOfAddDMRS');
             end
         else % ECP, l0=2, ld=10
             switch NumOfAddDMRS
                 case 0,  basePos = [3];
                 case 1,  basePos = [3, 10];
                 case 2,  basePos = [3, 7, 10];
                 case 3,  basePos = [3, 6, 9, 12];
                 otherwise, error('Wrong NumOfAddDMRS');
             end
         end
     elseif strcmp(dmrs_TypeA_Position, 'pos3')
         if CPType == 1 % NCP, l0=3, ld=11
             switch NumOfAddDMRS
                 case 0,  basePos = [4];           % l0=3
                 case 1,  basePos = [4, 12];       % l0=3, l1=11
                 case 2,  basePos = [4, 8, 12];    % l0=3, l1=7, l2=11
                 case 3,  basePos = [4, 6, 9, 12]; % l0=3, l1=5, l2=8, l3=11
                 otherwise, error('Wrong NumOfAddDMRS');
             end
         else % ECP, l0=3, ld=9
             switch NumOfAddDMRS
                 case 0,  basePos = [4];
                 case 1,  basePos = [4, 10];
                 case 2,  basePos = [4, 7, 10];
                 case 3,  basePos = [4, 6, 9, 12];
                 otherwise, error('Wrong NumOfAddDMRS');
             end
         end
     else
         error('dmrs_TypeA_Position must be ''pos2'' or ''pos3''. Got: %s', dmrs_TypeA_Position);
     end
     if DMRSLength == 1
         DMRS_cols = basePos;
     else
         DMRS_cols = zeros(1, length(basePos)*2);
         for i = 1:length(basePos)
             DMRS_cols(2*i-1) = basePos(i);
             DMRS_cols(2*i)   = basePos(i) + 1;
         end
     end
     DMRS_COLUMN_INDEX = repmat(DMRS_cols, Max_DMRS_port, 1);
     
     % --- DMRS_position (供信道估计使用, 基于FFT绝对子载波索引) ---
     for loopcol = 1:Nsym_DMRS
         % CDM组0 (Δ=0, 奇数子载波): ports 1000(1), 1001(3), 1004(5), 1005(7)
         DMRS_position(1,:,loopcol) = [1:2:Nc_used].'+(FFT_size-Nc)/2;
         DMRS_position(3,:,loopcol) = DMRS_position(1,:,loopcol);
         DMRS_position(5,:,loopcol) = DMRS_position(1,:,loopcol);
         DMRS_position(7,:,loopcol) = DMRS_position(1,:,loopcol);
         % CDM组1 (Δ=1, 偶数子载波): ports 1002(2), 1003(4), 1006(6), 1007(8)
         DMRS_position(2,:,loopcol) = [2:2:Nc_used].'+(FFT_size-Nc)/2;
         DMRS_position(4,:,loopcol) = DMRS_position(2,:,loopcol);
         DMRS_position(6,:,loopcol) = DMRS_position(2,:,loopcol);
         DMRS_position(8,:,loopcol) = DMRS_position(2,:,loopcol);
     end
     
     % --- DMRS_Signal: 按TS 38.211 §7.4.1.1.1公式生成Gold序列 ---
     % OCC表 (TS 38.211 Table 7.4.1.1.2-1, type1)
     % Port索引: 1→1000, 2→1002, 3→1001, 4→1003, 5→1004, 6→1006, 7→1005, 8→1007
     wf_table = [ 1,  1;   % port 1000 (FD-OCC k'=0,1)
                  1,  1;   % port 1002
                  1, -1;   % port 1001
                  1, -1;   % port 1003
                  1,  1;   % port 1004
                  1,  1;   % port 1006
                  1, -1;   % port 1005
                  1, -1];  % port 1007
     wt_table = [ 1,  1;   % port 1000 (TD-OCC l'=0,1)
                  1,  1;   % port 1002
                  1,  1;   % port 1001
                  1,  1;   % port 1003
                  1, -1;   % port 1004
                  1, -1;   % port 1006
                  1, -1;   % port 1005
                  1, -1];  % port 1007
     
     % c_init 参数
     N_symb_slot = Nd;   % 每时隙OFDM符号数 (NCP=14, ECP=12)
     % n_s_f: 无线帧内时隙号, 范围 0~(10*2^miu-1), 每时隙自增, 帧结束归零 (TS 38.211 §7.4.1.1.1)
     if DMRS_nSCID == 0
         N_ID = DMRS_ScramblingID0;
     else
         N_ID = DMRS_ScramblingID1;
     end
     
     DMRS_Signal = zeros(Max_DMRS_port, Nc_used_DMRS, Nsym_DMRS);
     r_len = Nc_used_DMRS;  % r(n)序列长度 (= Nc_used/2 for type1)
     c_len = 2 * r_len;     % 每个r(n)需要2bits Gold序列
     
     for pos = 1:Npos
         for lprime = 0:(DMRSLength-1)
             sym = (pos-1)*DMRSLength + lprime + 1;   % MATLAB 1-based列索引
             
             % OFDM符号编号 l (0-based, within slot, TS 38.211)
             l_ofdm = DMRS_COLUMN_INDEX(1, sym) - 1;
             
             % c_init = (2^17*(N_symb^slot*n_s_f + l + 1)*(2*N_ID+1) + 2*N_ID + n_SCID) mod 2^31
             c_init = mod(2^17 * (N_symb_slot * n_s_f + l_ofdm + 1) * (2*N_ID + 1) + 2*N_ID + DMRS_nSCID, 2^31);
             
             % Gold序列 → r(n) = 1/√2*((1-2*c(2n)) + j*(1-2*c(2n+1)))
             c_seq = GoldSequenceNR(c_init, c_len);
             r_seq = (1/sqrt(2)) * ((1 - 2*c_seq(1:2:end)) + 1j*(1 - 2*c_seq(2:2:end)));
             
             % 映射到各端口: a = β * w_f(k') * w_t(l') * r(2n + k')
             for loop = 1:Max_DMRS_port
                 wt = wt_table(loop, lprime + 1);
                 wf0 = wf_table(loop, 1);
                 wf1 = wf_table(loop, 2);
                 % k'=0→r(2n), k'=1→r(2n+1), n=0,1,...
                 for n_idx = 0:(r_len/2 - 1)
                     sc0 = 2*n_idx + 1;   % MATLAB 1-based, k'=0位置
                     sc1 = 2*n_idx + 2;   % MATLAB 1-based, k'=1位置
                     DMRS_Signal(loop, sc0, sym) = wt * wf0 * r_seq(2*n_idx + 1);
                     DMRS_Signal(loop, sc1, sym) = wt * wf1 * r_seq(2*n_idx + 2);
                 end
             end
         end
     end
elseif TM == 8 || TM == 9
    Max_DMRS_port = 8;
    DMRS_Signal = zeros(Max_DMRS_port,Nc_used_DMRS,4);
    spread_code = ...
        [ 1  1  1  1;...
          1 -1  1 -1;...
          1  1  1  1;...
          1 -1  1 -1;...
          1  1 -1 -1;...
         -1 -1  1  1;...
          1 -1 -1  1;...
         -1  1  1 -1 ];
     squeence_DMRS = ((2*randi([0,1],[Nc_used_DMRS,1])-1)+1i*(2*randi([0,1],[Nc_used_DMRS,1])-1))./sqrt(2);
     for loop = 1:Max_DMRS_port
         DMRS_Signal(loop,:,:) = kron(spread_code(loop,:),squeence_DMRS);
     end
else
    DMRS_Signal = [];
end
% DMRS position
if TM == 7
    DMRS_position(1,:,:) = [1:4:Nc_used;3:4:Nc_used;1:4:Nc_used;3:4:Nc_used].'+(FFT_size-Nc)/2;
    DMRS_COLUMN_INDEX = [4 7 10 13];
elseif TM == 'NR'
    % DMRS_position / DMRS_COLUMN_INDEX already defined in signal generation section above
elseif TM == 8 || TM == 9
    DMRS_position_group1 = zeros(1,Nc_used_DMRS/3);     % Nc_used_DMRS/3 = NumOfRB
    count = 0;
    for loop = 1:Nc_used_DMRS/3 
        count = count+1;
        DMRS_position_group1(count) = (loop-1)*12+2;
        count = count+1;
        DMRS_position_group1(count) = (loop-1)*12+7;
        count = count+1;
        DMRS_position_group1(count) = (loop-1)*12+12;
    end
    DMRS_position_group2 = DMRS_position_group1-1;
    DMRS_position(1,:,:) = [DMRS_position_group1;DMRS_position_group1;DMRS_position_group1;DMRS_position_group1].'+(FFT_size-Nc)/2;
    DMRS_position(2,:,:) = DMRS_position(1,:,:);
    DMRS_position(5,:,:) = DMRS_position(1,:,:);
    DMRS_position(7,:,:) = DMRS_position(1,:,:);
    DMRS_position(3,:,:) = [DMRS_position_group2;DMRS_position_group2;DMRS_position_group2;DMRS_position_group2].'+(FFT_size-Nc)/2;
    DMRS_position(4,:,:) = DMRS_position(3,:,:);
    DMRS_position(6,:,:) = DMRS_position(3,:,:);
    DMRS_position(8,:,:) = DMRS_position(3,:,:);
    DMRS_COLUMN_INDEX = [6 7 13 14; 6 7 13 14; 6 7 13 14; 6 7 13 14; 6 7 13 14; 6 7 13 14; 6 7 13 14; 6 7 13 14];
else
    DMRS_position = [];
    DMRS_COLUMN_INDEX = [];
end

%% CSI-RS generation 
switch TM
    case {7,8,9}
        %(port15~port22)
        % CSI-RS signal
        Max_CSIRS_port = 8;
        CSIRS_Signal = zeros(Max_CSIRS_port,Nc_used_CSIRS,2);
        squeence_CSIRS = ((2*randi([0,1],[Nc_used_CSIRS,1])-1)+1i*(2*randi([0,1],[Nc_used_CSIRS,1])-1))./sqrt(2);
        for loop = 1:Max_CSIRS_port
            CSIRS_Signal(loop,:,:)=kron([1,(-1).^(loop-1)],squeence_CSIRS);
        end
        % CSI-RS position
        CSIRS_position_temp = zeros(Max_CSIRS_port,Nc_used_CSIRS,2);
        for loop = 1:2
            CSIRS_position_temp(1,:,loop) = [10:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(2,:,loop) = [10:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(3,:,loop) = [4:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(4,:,loop) = [4:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(5,:,loop) = [9:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(6,:,loop) = [9:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(7,:,loop) = [3:12:Nc_used]+(FFT_size-Nc)/2;
            CSIRS_position_temp(8,:,loop) = [3:12:Nc_used]+(FFT_size-Nc)/2;
        end
        switch CSIRS_position_config
            case {0,2,4,21}
                CSIRS_position = CSIRS_position_temp;
            case {6,23}
                CSIRS_position = CSIRS_position_temp+1;
            case {1,20}
                CSIRS_position = CSIRS_position_temp+2;
            case {5,7,9,24}
                CSIRS_position = CSIRS_position_temp-1;
            case {3,22}
                CSIRS_position = CSIRS_position_temp-2;
            case {8,25}
                CSIRS_position = CSIRS_position_temp-3;
            case {12,26}
                CSIRS_position = CSIRS_position_temp-4;
            case {13,27}
                CSIRS_position = CSIRS_position_temp-5;
            case {10,14,18,28}
                CSIRS_position = CSIRS_position_temp-6;
            case {11,15,19,29}
                CSIRS_position = CSIRS_position_temp-7;
            case {16,30}
                CSIRS_position = CSIRS_position_temp-8;
            case {17,31}
                CSIRS_position = CSIRS_position_temp-9;
            otherwise
                error('Wrong CSIRS_position_config!')
        end

        switch CSIRS_position_config
            case {0,5,10,11}
                CSIRS_COLUMN_INDEX = repmat([6 7],8,1);
            case {1,2,3,6,7,8,12,13,14,15,16,17}
                CSIRS_COLUMN_INDEX = repmat([10 11],8,1);
            case {4,9,18,19}
                CSIRS_COLUMN_INDEX = repmat([13 14],8,1);
            case {20:31}
                CSIRS_COLUMN_INDEX = repmat([9 11],8,1);
            otherwise
                error('Wrong CSIRS_position_config!')
        end
    case 'NR'
        Max_CSIRS_port = 1; %先写到2端口
        CSIRS_COLUMN_INDEX = [5 9]; % TRS_index = [4 8] 
        CSIRS_Signal = zeros(Max_CSIRS_port,Nc_used_CSIRS,2);
        squeence_CSIRS = ((2*randi([0,1],[Nc_used_CSIRS,2])-1)+1i*(2*randi([0,1],[Nc_used_CSIRS,2])-1))./sqrt(2);
        CSIRS_Signal(1,:,:) = squeence_CSIRS;
        CSIRS_position_temp = zeros(Max_CSIRS_port,Nc_used_CSIRS,2);
        for loop = 1:size(CSIRS_position_temp,3)
            CSIRS_position_temp(1,:,loop) = [1:4:Nc_used]+(FFT_size-Nc)/2;
        end
        CSIRS_position = CSIRS_position_temp;
    otherwise 
        CSIRS_COLUMN_INDEX = [];
        CSIRS_Signal = [];
        CSIRS_position = [];
end
%% structure "PilotParam" generation
if isempty(varargin)
    pdschNumSymbols = Nd - CFI;
else
    pdschNumSymbols = varargin{1};
end
DATA_COLUMN_INDEX = CFI + (1:pdschNumSymbols);
if isempty(DATA_COLUMN_INDEX) || DATA_COLUMN_INDEX(end) > Nd
    error('PDSCH_PilotParamInit:InvalidSymbolAllocation', ...
        'PDSCH symbol allocation exceeds the slot.');
end
if strcmp(TM, 'NR') && any(~ismember(DMRS_COLUMN_INDEX(1,:), DATA_COLUMN_INDEX))
    error('PDSCH_PilotParamInit:DmrsOutsidePdsch', ...
        'At least one DMRS symbol is outside the configured PDSCH allocation.');
end
PilotParam = struct(...
    'CRS_Signal',CRS_Signal,...
    'CRS_position',CRS_position,...
    'CRS_COLUMN_INDEX',CRS_COLUMN_INDEX,...
    'DMRS_Signal',DMRS_Signal,...
    'DMRS_position',DMRS_position,...
    'DMRS_COLUMN_INDEX',DMRS_COLUMN_INDEX,...
    'CSIRS_Signal',CSIRS_Signal,...
    'CSIRS_position',CSIRS_position,...
    'CSIRS_COLUMN_INDEX',CSIRS_COLUMN_INDEX,...
    'DATA_COLUMN_INDEX',DATA_COLUMN_INDEX);

end
