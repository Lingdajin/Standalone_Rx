function ideal_Mod = reencode_for_evm(des_bits, LDPCParam, SystemParam, HARQParam)
%% reencode_for_evm: 收端重编码解码比特→理想星座点 (EVM用)
%  输入:
%    des_bits  - 解码后的源比特 (无误码时=Data_for_code)
%    LDPCParam - LDPCCodingRateMatchingParam 全局结构体
%    SystemParam - 系统参数结构体
%  输出:
%    ideal_Mod - 重调制后的理想星座点 (维度同发端Data_Mod)

NL = SystemParam.NL;
Ns = SystemParam.Ns;
mod_mode = LDPCParam.modulation_mode;
src_len  = LDPCParam.src_len;
Rc       = LDPCParam.Rc;
C_save   = LDPCParam.C_save;
F_save   = LDPCParam.F_save;
len_CB_save = LDPCParam.len_CB_save;
len_Er_save = LDPCParam.len_Er_save;

rv_idx_seq = HARQParam.rv_idx_seq;

ideal_Mod = [];
ptr = 1;  % 指向des_bits当前码字的起始位置

for loop_Ns = 1:Ns
    % --- 1. 提取该码字的源比特 ---
    sLen = src_len(loop_Ns);
    src_bits = des_bits(ptr : ptr + sLen - 1);
    ptr = ptr + sLen;
    
    % --- 2. TB分割 (含CRC) ---
    [C, CBS, F, CBsets] = LDPC_TBseg(src_bits, sLen, Rc);
    
    % --- 3. 获取存储的编码参数 ---
    if loop_Ns == 1
        SimParam = LDPCParam.SimParam_1;
    else
        SimParam = LDPCParam.SimParam_2;
    end
    liftZ    = SimParam.liftZ;
    l_padding = SimParam.l_padding;
    BGtype   = SimParam.BGtype;
    Hd_base  = SimParam.Hd_base;
    [~, Hb, ~] = genHb(CBS, Rc);
    [mb, nb] = size(Hb);
    MH = mb * liftZ;
    NH = nb * liftZ;
    E = len_Er_save(1, 1:C);    % 每个CB的速率匹配输出长度
    
    % --- 4. 加载/生成 LU 分解矩阵 ---
    global MainFileAddress
    base_address = MainFileAddress.address;
    cache_dir = fullfile(base_address, 'data', 'MatForLDPC');
    if ~isfolder(cache_dir), mkdir(cache_dir); end
    name = fullfile(cache_dir, ['LU_mb', num2str(mb), '_nb', num2str(nb), ...
        '_Z', num2str(liftZ), '.mat']);
    if exist(name, 'file')
        load(name, 'press_L1', 'Length_L1', 'press_U1', 'Length_U1', 'press_H1', ...
                   'Length_H1', 'press_P', 'Length_P', 'max_L1', 'max_U1', 'max_H1');
    else
        [~, Hb_temp, ~] = genHb(CBS, Rc);
        [press_L1, Length_L1, press_U1, Length_U1, press_H1, Length_H1, press_P, Length_P, ...
        max_L1, max_U1, max_H1] = genLU(Hb_temp, liftZ);
    end
    
    % --- 5. LDPC编码 (逐CB) ---
    saved_bits = zeros(C, NH - 2*liftZ);
    for r = 1:C
        uncoded = [CBsets(r,:), zeros(1, l_padding)];
        encoded = encoder_jia(uncoded, press_L1, press_U1, press_P, press_H1, ...
                              MH, NH, Length_L1, Length_U1, Length_H1, ...
                              max_L1, max_U1, max_H1);
        saved_bits(r,:) = encoded(2*liftZ + 1 : end);  % 打孔
    end
    
    % --- 6. 速率匹配 + 交织 + CB连接 ---
    TB_rmbits = [];
    for r = 1:C
        Er = E(r);
        [CB_rmbits, ~] = LDPC_ratematch(CBS, saved_bits(r,:), BGtype, liftZ, ...
                                        1, Er, rv_idx_seq, l_padding);
        inter_bits = LDPC_interleaver(CB_rmbits, mod_mode(loop_Ns));
        TB_rmbits = [TB_rmbits, inter_bits];
    end
    
    % --- 7. 加扰 ---
    scramblingbits = scrambling(TB_rmbits);
    
    % --- 8. 调制 ---
    Data_Mod_temp = modulation36211(scramblingbits, 2^mod_mode(loop_Ns));
    
    % --- 9. 层映射 ---
    ideal_Mod = [ideal_Mod; reshape(Data_Mod_temp, NL(loop_Ns), [])];
end
end
