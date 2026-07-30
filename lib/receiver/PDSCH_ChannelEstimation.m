function [ H_AMC,H_Equalization,H_BF,H_DMRS_Equ ] = PDSCH_ChannelEstimation( CE_Mode_CRS,CE_Mode_DMRS,CE_Mode_CSIRS,MatrixForCE,Fading_Weight,FFT_Out_CRS,FFT_Out_DMRS,FFT_Out_CSIRS,BF_Matrix )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description:
% (1) PDSCH_ChannelEstimation accomplishes channel estimation for PDSCH.
% (2) Three types of channel frequency response will be get for specificed purposes.
%% Input Parameters:
% CE_Mode_CRS: channel estimation mode based on CRS, 1 for ideal CE, 2 for LMMSE CE, 3 for expPDP CE
% CE_Mode_DMRS: channel estimation mode based on DMRS, 1 for ideal CE, 2 for LMMSE CE, 3 for expPDP CE

% MatrixForCE: structure variable,inculding components:
% M_LMMSE_odd_CRS and M_LMMSE_even_CRS: matrixes for LMMSE CE based on CRS.
% M_expPDP_CRS: matrix for expPDP CE based on CRS.
% M_LMMSE_odd_DMRS and M_LMMSE_even_DMRS: matrixes for LMMSE CE based on DMRS.
% M_expPDP_DMRS: matrix for expPDP CE based on DMRS.

% Fading_Weight: [Nr*Nt*NumOfTaps]*Nd, channel impulse response in time domain
% FFT_Out_CRS: Nr*Nt*Nc_used_CRS*ColumnNumberOfCRS, received CRS
% FFT_Out_DMRS: Nr*Nt*Nc_used_DMRS*ColumnNumberOfDMRS, received DMRS
% BF_Matrix: beamforming matrixes
%% Output Parameters:
% H_AMC: channel frequency response for AMC
% H_Equalization: channel frequency response for equalization
% H_BF: channel frequency response for beamforming
%% Modification records:
% (1) Add annotations in 2012.11.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SystemParam
global ChannelParam
global PilotParam
global MatrixParam
global DataPilotIndexParam
global N_Matraix
global SC_perM
global DMRS_perM
global PMI_index_final
global PMI_matrix

TM                    = SystemParam.TM;
Ns                    = SystemParam.Ns;
CRS_port              = SystemParam.CRS_port;
CSIRS_port            = SystemParam.CSIRS_port;
Nt                    = SystemParam.Nt;
Nr                    = SystemParam.Nr;
Nd                    = SystemParam.Nd;
Nc                    = SystemParam.Nc;
Nc_used               = SystemParam.Nc_used;
Nc_Index              = SystemParam.Nc_Index;
FFT_size              = SystemParam.FFT_size;
Path_Delay            = ChannelParam.Path_Delay;
NumOfTaps             = ChannelParam.NumOfTaps;
CRS_position          = PilotParam.CRS_position;
CRS_Signal            = PilotParam.CRS_Signal;
CRS_COLUMN_INDEX      = PilotParam.CRS_COLUMN_INDEX;
DATA_COLUMN_INDEX     = PilotParam.DATA_COLUMN_INDEX;
Data_Index_DataRegion = DataPilotIndexParam.Data_Index_DataRegion;
CSIRS_port = 0;
H_DMRS_Equ = [];
H_temp = [];
if CSIRS_port == 0
    %% *************** CRS-based Channel Estimation ***************
    switch CE_Mode_CRS
        case 1
            H_temp = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
            % 'H * Matrix_StaticBF' to get equivalent H corresponding to port, and Matrix_StaticBF denotes mapping matrix from port to physical antenna
            if Nt ~= CRS_port
                Matrix_StaticBF = MatrixParam.Matrix_StaticBF;
                NumOfSymbol = size(H_temp,3);                 % NumOfsymbol为OFDM符号个数
                for nSym = 1:NumOfSymbol
                    for num_sub = 1:Nc_used
                        H_pre_temp = H_temp(:,num_sub,nSym);
                        H_pre = reshape(H_pre_temp,Nr,Nt);
                        H_mid(:,num_sub,nSym) = reshape(H_pre * Matrix_StaticBF,[],1);
                    end
                end
                H_temp = H_mid;
            end
        case 2
            H_temp = LMMSE_CE(CRS_port,Nr,Nd,Nc_used,FFT_size,Nc,CRS_COLUMN_INDEX,DATA_COLUMN_INDEX,CRS_position,CRS_Signal,FFT_Out_CRS,MatrixForCE.M_LMMSE_CRS);
        case 3
            H_temp = expPDP_CE(CRS_port,Nr,Nd,Nc_used,CRS_COLUMN_INDEX,DATA_COLUMN_INDEX,FFT_Out_CRS,MatrixForCE.M_expPDP_CRS);
    end
    %% ************** CSI-RS-based Channel Estimation *************
elseif CSIRS_port ~= 0
    switch CE_Mode_CSIRS
        case 1
            H_temp = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
            % 'H * Matrix_StaticBF' to get equivalent H corresponding to port, and Matrix_StaticBF denotes mapping matrix from port to physical antenna
            if Nt ~= CSIRS_port
                Matrix_StaticBF = MatrixParam.Matrix_StaticBF;
                NumOfSymbol = size(H_temp,3);                 % NumOfsymbol为OFDM符号个数
                for nSym = 1:NumOfSymbol
                    for num_sub = 1:Nc_used
                        H_pre_temp = H_temp(:,num_sub,nSym);
                        H_pre = reshape(H_pre_temp,Nr,Nt);
                        H_mid(:,num_sub,nSym) = reshape(H_pre * Matrix_StaticBF,[],1);
                    end
                end
                H_temp = H_mid;
            end
            H_temp = H_temp(:,1:SystemParam.Nc_RB:end,:);
        case 2
            CSIRS_port = SystemParam.CSIRS_port;
            Nc_used_CSIRS = SystemParam.Nc_used_CSIRS;
            CSIRS_COLUMN_INDEX = PilotParam.CSIRS_COLUMN_INDEX;
            CSIRS_Signal = PilotParam.CSIRS_Signal;
            CSIRS_position = PilotParam.CSIRS_position;
            M_LMMSE_CSIRS = MatrixForCE.M_LMMSE_CSIRS;
            
            FFT_Out_CSIRS_temp = zeros(Nr,CSIRS_port,Nc_used_CSIRS,size(CSIRS_COLUMN_INDEX,2)/2);     
            for loop_layer = 1:CSIRS_port
                FFT_Out_CSIRS_temp(:,loop_layer,:,:) = (FFT_Out_CSIRS(:,loop_layer,:,1) + (-1)^(loop_layer-1)*FFT_Out_CSIRS(:,loop_layer,:,2))/2;
            end
            CSIRS_COLUMN_INDEX_temp = CSIRS_COLUMN_INDEX(1:CSIRS_port,1);
            CSIRS_Signal_temp = CSIRS_Signal(1:CSIRS_port,:,1);
            CSIRS_position_temp = CSIRS_position(1:CSIRS_port,:,1);
            H_temp = LMMSE_CE(CSIRS_port,Nr,Nd,Nc_used,FFT_size,Nc,CSIRS_COLUMN_INDEX_temp,DATA_COLUMN_INDEX,CSIRS_position_temp,CSIRS_Signal_temp,FFT_Out_CSIRS_temp,M_LMMSE_CSIRS);
            H_temp = H_temp(:,1:SystemParam.Nc_RB:end,:);
        case 3
            CSIRS_port = SystemParam.CSIRS_port;
            Nc_used_CSIRS = SystemParam.Nc_used_CSIRS;
            CSIRS_COLUMN_INDEX = PilotParam.CSIRS_COLUMN_INDEX;
            
            FFT_Out_CSIRS_temp = zeros(Nr,CSIRS_port,Nc_used_CSIRS,size(CSIRS_COLUMN_INDEX,2)/2);     
            for loop_layer = 1:CSIRS_port
                FFT_Out_CSIRS_temp(:,loop_layer,:,:) = (FFT_Out_CSIRS(:,loop_layer,:,1) + (-1)^(loop_layer-1)*FFT_Out_CSIRS(:,loop_layer,:,2))/2;
            end
            CSIRS_COLUMN_INDEX_temp = CSIRS_COLUMN_INDEX(:,1);
            M_expPDP_CSIRS_temp = MatrixForCE.M_expPDP_CSIRS(:,:,1,:,:);
%             H_temp = expPDP_CE(CSIRS_port,Nr,Nd,Nc_used,CSIRS_COLUMN_INDEX,DATA_COLUMN_INDEX,FFT_Out_CSIRS,M_expPDP_CSIRS);
            H_temp = expPDP_CE(CSIRS_port,Nr,Nd,SystemParam.Nc_used_CSIRS,CSIRS_COLUMN_INDEX_temp,DATA_COLUMN_INDEX,FFT_Out_CSIRS_temp,M_expPDP_CSIRS_temp);
        otherwise
            error('Wrong CE_Mode_CSIRS!')
    end
end
%% ************************* H_AMC *******************************
H_AMC_temp = H_temp(:,:,end);%为何取end？

switch TM
    case 2
        H_AMC_mid = (H_AMC_temp(:,1:2:end)+H_AMC_temp(:,2:2:end))./2;  % 认为相邻信道的信道相应一致
        if CRS_port == 2
            H_AMC = H_AMC_mid;
        elseif Nr == 2 && CRS_port == 4
            H_AMC = zeros(Nr*CRS_port/2,Nc_used/2);
            H_AMC([1 2],1:2:end) = H_AMC_mid([1 2],1:2:end);
            H_AMC([3 4],1:2:end) = H_AMC_mid([5 6],1:2:end);
            H_AMC([1 2],2:2:end) = H_AMC_mid([3 4],2:2:end);
            H_AMC([3 4],2:2:end) = H_AMC_mid([7 8],2:2:end);
        elseif Nr == 4 && CRS_port == 4
            H_AMC = zeros(Nr*CRS_port/2,Nc_used/2);
            H_AMC([1 2],1:2:end) = H_AMC_mid([1 2],1:2:end);
            H_AMC([3 4],1:2:end) = H_AMC_mid([3 4],1:2:end);
            H_AMC([1 2],2:2:end) = H_AMC_mid([5 6],2:2:end);
            H_AMC([3 4],2:2:end) = H_AMC_mid([7 8],2:2:end);
            H_AMC([5 6],1:2:end) = H_AMC_mid([9 10],1:2:end);
            H_AMC([7 8],1:2:end) = H_AMC_mid([11 12],1:2:end);
            H_AMC([5 6],2:2:end) = H_AMC_mid([13 14],2:2:end);
            H_AMC([7 8],2:2:end) = H_AMC_mid([15 16],2:2:end);
        end
    case 3
        Matrix_U = MatrixParam.Matrix_U;
        Matrix_D = MatrixParam.Matrix_D;
        Matrix_W = MatrixParam.Matrix_W;
        Ns = SystemParam.Ns;
        if CRS_port == 2
            for num_sub = 1:Nc_used
                H_AMC_mid = reshape(H_AMC_temp(:,num_sub),Nr,[]) * Matrix_W * diag(Matrix_D(:,num_sub)) * Matrix_U;
                H_AMC(:,num_sub) = reshape(H_AMC_mid,[],1);
            end
        else
            for num_sub = 1:Nc_used
                p_index = mod(floor(num_sub/Ns),4)+1;
                Matrix_W_temp = Matrix_W(:,:,p_index);
                H_AMC_mid = reshape(H_AMC_temp(:,num_sub),Nr,[]) * Matrix_W_temp * diag(Matrix_D(:,num_sub)) * Matrix_U;
                H_AMC(:,num_sub) = reshape(H_AMC_mid,[],1);
            end
        end
    case { 4,7,8,9 }
        H_AMC = H_AMC_temp;
    case 'NR'
        H_AMC = H_AMC_temp;   
    otherwise
        error('Wrong TM!')
end
%% ********************** H_Equalization *************************
switch TM
    case {2,3,4}
        for nH = 1:CRS_port*Nr
            H_Equalization_temp = squeeze(H_temp(nH,:,:));
            H_Equalization(nH,:,:) = H_Equalization_temp(Data_Index_DataRegion);
        end
    case {7,8}
        DMRS_port = Ns;
        switch CE_Mode_DMRS
            case 1
                H_Equalization_mid = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
                NumOfSymbol = size(H_temp,3);
                for nSym = 1:NumOfSymbol
                    for num_sub = 1:Nc_used
                        H_pre_temp =  H_Equalization_mid(:,num_sub,nSym);
                        H_pre = reshape(H_pre_temp,Nr,Nt);
                        H_Equalization_temp(:,num_sub,nSym) = reshape(H_pre * BF_Matrix(:,:,ceil(num_sub/SC_perM))./sqrt(Ns),[],1);
                    end
                end
            case 2
                % not avaliable
            case 3
                if TM == 7
                    DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
                    M_expPDP_DMRS = MatrixForCE.M_expPDP_DMRS;
                elseif TM == 8
                    for nra = 1:Nr
                        if Ns == 1
                            for ss = 1:2 %% for two symbols
                                FFT_Out_DMRS_temp(nra,1,:,ss) = (FFT_Out_DMRS(nra,1,:,(ss-1)*2+1)+FFT_Out_DMRS(nra,1,:,(ss-1)*2+2))/2;
                            end
                        elseif Ns == 2
                            for ss = 1:2 %% for two symbols
                                FFT_Out_DMRS_temp(nra,1,:,ss) = (FFT_Out_DMRS(nra,1,:,(ss-1)*2+1)+FFT_Out_DMRS(nra,1,:,(ss-1)*2+2))/2;
                                FFT_Out_DMRS_temp(nra,2,:,ss) = (FFT_Out_DMRS(nra,2,:,(ss-1)*2+1)-FFT_Out_DMRS(nra,2,:,(ss-1)*2+2))/2;
                            end
                        end
                    end
                    FFT_Out_DMRS = FFT_Out_DMRS_temp;
                    DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX(:,[1,3]);
                    M_expPDP_DMRS = MatrixForCE.M_expPDP_DMRS(:,:,:,[1,3],:,:);
                end
                
                for nrb = 1:N_Matraix
                    stp = (nrb-1)*SC_perM+1;
                    edp = nrb * SC_perM;
                    stp1 = (nrb-1)*DMRS_perM+1;
                    edp1 = nrb * DMRS_perM;
                    FFT_Out_DMRS_RB = FFT_Out_DMRS(:,:,stp1:edp1,:);
                    
                    [ a, b c d e f ] = size(M_expPDP_DMRS);
                    M_expPDP_DMRS_temp = zeros(b,c,d,e,f);
                    M_expPDP_DMRS_temp(:,:,:,:,:) = M_expPDP_DMRS(nrb,:,:,:,:,:);
                    H_temp = expPDP_CE(DMRS_port,Nr,Nd,SC_perM,DMRS_COLUMN_INDEX,DATA_COLUMN_INDEX,FFT_Out_DMRS_RB,M_expPDP_DMRS_temp);
                    
                    H_Equalization_temp(:,stp:edp,:)= H_temp;
                end
        end
        %% Extract H at DMRS positions for DMRS equalization
        DMRS_position_ce = PilotParam.DMRS_position;
        DMRS_COLUMN_INDEX_ce = PilotParam.DMRS_COLUMN_INDEX;
        N_dmrs_sc = size(DMRS_position_ce, 2);
        N_dmrs_sym = size(DMRS_COLUMN_INDEX_ce, 2);
        H_DMRS_Equ = zeros(Nr, DMRS_port, N_dmrs_sc, N_dmrs_sym);
        for nta = 1:DMRS_port
            for np = 1:N_dmrs_sym
                sym_idx = DMRS_COLUMN_INDEX_ce(nta, np);
                if isnan(sym_idx), continue; end
                sc_indices_fft = DMRS_position_ce(nta, :, np);
                valid_mask = ~isnan(sc_indices_fft);
                % Map FFT subcarrier indices to Nc_used relative indices
                sc_fft_valid = sc_indices_fft(valid_mask);
                [~, sc_nc] = ismember(sc_fft_valid, Nc_Index);
                keep_mask = sc_nc > 0;
                sc_nc = sc_nc(keep_mask);
                valid_idx = find(valid_mask);
                valid_mask(valid_idx(~keep_mask)) = false;
                for nra = 1:Nr
                    row_idx = (nta-1)*Nr + nra;
                    H_flat = squeeze(H_Equalization_temp(row_idx, :, sym_idx));
                    H_DMRS_Equ(nra, nta, valid_mask, np) = H_flat(sc_nc);
                end
            end
        end
        for nH = 1:DMRS_port*Nr
            H_Equalization_temp2 = squeeze(H_Equalization_temp(nH,:,:));
            H_Equalization(nH,:,:) = H_Equalization_temp2(Data_Index_DataRegion);
        end
    case 9
        DMRS_port = SystemParam.DMRS_port;
        switch CE_Mode_DMRS
            case 1
                H_Equalization_mid = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
                NumOfSymbol = size(H_temp,3);
                for nSym = 1:NumOfSymbol
                    for num_sub = 1:Nc_used
                        H_pre_temp =  H_Equalization_mid(:,num_sub,nSym);
                        H_pre = reshape(H_pre_temp,Nr,Nt);
                        H_Equalization_temp(:,num_sub,nSym) = reshape(H_pre * MatrixParam.Matrix_StaticBF*MatrixParam.Matrix_W,[],1);
                    end
                end
            case 2
                M_LMMSE_DMRS = MatrixForCE.M_LMMSE_DMRS;
                DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
                Nc_used_DMRS = SystemParam.Nc_used_DMRS;
                
                spread_code = ...
                    [ 1  1  1  1;...
                    1 -1  1 -1;...
                    1  1  1  1;...
                    1 -1  1 -1;...
                    1  1 -1 -1;...
                    -1 -1  1  1;...
                    1 -1 -1  1;...
                    -1  1  1 -1 ];
                for nra = 1:Nr
                    for loop_layer = 1:DMRS_port
                        FFT_Out_DMRS_temp(nra,loop_layer,:,:) = squeeze(FFT_Out_DMRS(nra,loop_layer,:,:)).*repmat(spread_code(loop_layer,:),Nc_used_DMRS,1);
                    end
                end
                if  DMRS_port <= 4
                    FFT_Out_DMRS_final = zeros(Nr,DMRS_port,Nc_used_DMRS,size(DMRS_COLUMN_INDEX,2)/2);
                    FFT_Out_DMRS_final(:,:,:,1) = (FFT_Out_DMRS_temp(:,:,:,1) + FFT_Out_DMRS_temp(:,:,:,2))/2;
                    FFT_Out_DMRS_final(:,:,:,2) = (FFT_Out_DMRS_temp(:,:,:,3) + FFT_Out_DMRS_temp(:,:,:,4))/2;
                    DMRS_COLUMN_INDEX_final = PilotParam.DMRS_COLUMN_INDEX(1:DMRS_port,[1 3]);
                    DMRS_position_final = PilotParam.DMRS_position(1:DMRS_port,:,[1,3]);
                    DMRS_Signal_final = PilotParam.DMRS_Signal(1:DMRS_port,:,[1,3]);
                else
                    FFT_Out_DMRS_final = zeros(Nr,DMRS_port,Nc_used_DMRS,size(DMRS_COLUMN_INDEX,2)/4);
                    FFT_Out_DMRS_final(:,:,:,1) = (FFT_Out_DMRS_temp(:,:,:,1) + FFT_Out_DMRS_temp(:,:,:,2) + FFT_Out_DMRS_temp(:,:,:,3) + FFT_Out_DMRS_temp(:,:,:,4))/4;
                    DMRS_COLUMN_INDEX_final([1:5,7],:) = PilotParam.DMRS_COLUMN_INDEX([1:5,7],1);
                    DMRS_COLUMN_INDEX_final([6,8],:) = PilotParam.DMRS_COLUMN_INDEX([6,8],3);
                    DMRS_position_final([1:5,7],:,:) = PilotParam.DMRS_position([1:5,7],:,1);
                    DMRS_position_final([6,8],:,:) = PilotParam.DMRS_position([6,8],:,3);
                    DMRS_Signal_final([1:5,7],:,:) = PilotParam.DMRS_Signal([1:5,7],:,1);
                    DMRS_Signal_final([6,8],:,:) = PilotParam.DMRS_Signal([6,8],:,3);
                end
                H_Equalization_temp = LMMSE_CE(DMRS_port,Nr,Nd,Nc_used,FFT_size,Nc,DMRS_COLUMN_INDEX_final,DATA_COLUMN_INDEX,DMRS_position_final,DMRS_Signal_final,FFT_Out_DMRS_final,M_LMMSE_DMRS);
            case 3
                DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
                Nc_used_DMRS = SystemParam.Nc_used_DMRS;
                spread_code = ...
                    [ 1  1  1  1;...
                    1 -1  1 -1;...
                    1  1  1  1;...
                    1 -1  1 -1;...
                    1  1 -1 -1;...
                    -1 -1  1  1;...
                    1 -1 -1  1;...
                    -1  1  1 -1 ];
                for nra = 1:Nr
                    for loop_layer = 1:DMRS_port
                        FFT_Out_DMRS_temp(nra,loop_layer,:,:) = squeeze(FFT_Out_DMRS(nra,loop_layer,:,:)).*repmat(spread_code(loop_layer,:),Nc_used_DMRS,1);
                    end
                end
                
                if  DMRS_port <= 4
                    FFT_Out_DMRS_final = zeros(Nr,DMRS_port,Nc_used_DMRS,size(DMRS_COLUMN_INDEX,2)/2);
                    FFT_Out_DMRS_final(:,:,:,1) = (FFT_Out_DMRS_temp(:,:,:,1) + FFT_Out_DMRS_temp(:,:,:,2))/2;
                    FFT_Out_DMRS_final(:,:,:,2) = (FFT_Out_DMRS_temp(:,:,:,3) + FFT_Out_DMRS_temp(:,:,:,4))/2;
                    DMRS_COLUMN_INDEX_final = PilotParam.DMRS_COLUMN_INDEX(:,[1 3]);
                    M_expPDP_DMRS_final = MatrixForCE.M_expPDP_DMRS(:,:,[1 3],:,:);
                else
                    FFT_Out_DMRS_final = zeros(Nr,DMRS_port,Nc_used_DMRS,size(DMRS_COLUMN_INDEX,2)/4);
                    FFT_Out_DMRS_final(:,:,:,1) = (FFT_Out_DMRS_temp(:,:,:,1) + FFT_Out_DMRS_temp(:,:,:,2) + FFT_Out_DMRS_temp(:,:,:,3) + FFT_Out_DMRS_temp(:,:,:,4))/4;
                    DMRS_COLUMN_INDEX_final([1:5,7],:) = PilotParam.DMRS_COLUMN_INDEX([1:5,7],1);
                    M_expPDP_DMRS_final(:,[1:5,7],:,:,:) = MatrixForCE.M_expPDP_DMRS(:,[1:5,7],1,:,:);
                    DMRS_COLUMN_INDEX_final([6,8],:) = PilotParam.DMRS_COLUMN_INDEX([6,8],3);
                    M_expPDP_DMRS_final(:,[6,8],:,:,:) = MatrixForCE.M_expPDP_DMRS(:,[6,8],3,:,:);
                end          
                H_Equalization_temp = expPDP_CE(DMRS_port,Nr,Nd,Nc_used,DMRS_COLUMN_INDEX_final,DATA_COLUMN_INDEX,FFT_Out_DMRS_final,M_expPDP_DMRS_final);
        end
        %% Extract H at DMRS positions for DMRS equalization
        DMRS_position_ce = PilotParam.DMRS_position;
        DMRS_COLUMN_INDEX_ce = PilotParam.DMRS_COLUMN_INDEX;
        N_dmrs_sc = size(DMRS_position_ce, 2);
        N_dmrs_sym = size(DMRS_COLUMN_INDEX_ce, 2);
        H_DMRS_Equ = zeros(Nr, DMRS_port, N_dmrs_sc, N_dmrs_sym);
        for nta = 1:DMRS_port
            for np = 1:N_dmrs_sym
                sym_idx = DMRS_COLUMN_INDEX_ce(nta, np);
                if isnan(sym_idx), continue; end
                sc_indices_fft = DMRS_position_ce(nta, :, np);
                valid_mask = ~isnan(sc_indices_fft);
                % Map FFT subcarrier indices to Nc_used relative indices
                sc_fft_valid = sc_indices_fft(valid_mask);
                [~, sc_nc] = ismember(sc_fft_valid, Nc_Index);
                keep_mask = sc_nc > 0;
                sc_nc = sc_nc(keep_mask);
                valid_idx = find(valid_mask);
                valid_mask(valid_idx(~keep_mask)) = false;
                for nra = 1:Nr
                    row_idx = (nta-1)*Nr + nra;
                    H_flat = squeeze(H_Equalization_temp(row_idx, :, sym_idx));
                    H_DMRS_Equ(nra, nta, valid_mask, np) = H_flat(sc_nc);
                end
            end
        end
        for nH = 1:DMRS_port*Nr
            H_Equalization_temp2 = squeeze(H_Equalization_temp(nH,:,:));
            H_Equalization(nH,:,:) = H_Equalization_temp2(Data_Index_DataRegion);
        end
    case 'NR'
        DMRS_port = SystemParam.DMRS_port;
        switch CE_Mode_DMRS
            case 1
                H_Equalization_mid = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
                NumOfSymbol = size(H_Equalization_mid,3);
                
                for nSym = 1:NumOfSymbol
                    for num_sub = 1:Nc_used
                        H_pre_temp =  H_Equalization_mid(:,num_sub,nSym);
                        H_pre = reshape(H_pre_temp,Nr,Nt);
                        H_Equalization_temp(:,num_sub,nSym) = reshape(H_pre *  MatrixParam.Matrix_StaticBF * BF_Matrix(:,:,ceil(num_sub/SC_perM)),[],1);
                    end
                    
                    
%                     H_Equalization_temp(:,num_sub,nSym) = reshape(H_pre *  MatrixParam.Matrix_StaticBF * BF_Matrix(:,:,ceil(num_sub/SC_perM)),[],1);
                    
%                     for num_sub = 6:SC_perM:Nc_used
%                         H_pre_temp1 =  H_Equalization_mid(:,num_sub,nSym);
%                         H_pre1 = reshape(H_pre_temp1,Nr,Nt);
%                         H_Equalization_temp1(:,ceil(num_sub/SC_perM),nSym) = reshape(H_pre1 *  MatrixParam.Matrix_StaticBF * BF_Matrix(:,:,ceil(num_sub/SC_perM)),[],1);
%                     end
                end
            case 2
                DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
                M_LMMSE_DMRS = MatrixForCE.M_LMMSE_DMRS;
                DMRS_position_final = PilotParam.DMRS_position;
                DMRS_Signal_final = PilotParam.DMRS_Signal;
                H_Equalization_temp = LMMSE_CE(DMRS_port,Nr,Nd,Nc_used,FFT_size,Nc,DMRS_COLUMN_INDEX,DATA_COLUMN_INDEX,DMRS_position_final,DMRS_Signal_final,FFT_Out_DMRS,M_LMMSE_DMRS);
                
            case 3
%%%%%%%%%%%%%%%%precoding bundle tm9
                DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
%                 M_expPDP_DMRS = MatrixForCE.M_expPDP_DMRS;
                M_expPDP_DMRS = MatrixForCE.M_expPDP_DMRS(:,:,1:DMRS_port,:,:,:);
                for nrb = 1:N_Matraix
                    stp = (nrb-1)*SC_perM+1;
                    edp = nrb * SC_perM;
                    stp1 = (nrb-1)*DMRS_perM+1;
                    edp1 = nrb * DMRS_perM;
                    FFT_Out_DMRS_RB = FFT_Out_DMRS(:,:,stp1:edp1,:);
                    
                    [ a, b c d e f ] = size(M_expPDP_DMRS);
                    M_expPDP_DMRS_temp = zeros(b,c,d,e,f);
                    M_expPDP_DMRS_temp(:,:,:,:,:) = M_expPDP_DMRS(nrb,:,:,:,:,:);
                    H_temp = expPDP_CE(DMRS_port,Nr,Nd,SC_perM,DMRS_COLUMN_INDEX,DATA_COLUMN_INDEX,FFT_Out_DMRS_RB,M_expPDP_DMRS_temp);
                    
                    H_Equalization_temp(:,stp:edp,:)= H_temp;
                end
%%%%%%%%%%%%%%%%%%无precoding bundle NR
%                 DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
%                 Nc_used_DMRS = SystemParam.Nc_used_DMRS;
%                 FFT_Out_DMRS_final = FFT_Out_DMRS;
%                 DMRS_COLUMN_INDEX_final = PilotParam.DMRS_COLUMN_INDEX;
%                 M_expPDP_DMRS_final = MatrixForCE.M_expPDP_DMRS;     
%                 H_Equalization_temp = expPDP_CE(DMRS_port,Nr,Nd,Nc_used,DMRS_COLUMN_INDEX_final,DATA_COLUMN_INDEX,FFT_Out_DMRS_final,M_expPDP_DMRS_final);
            case 4
                %%%%%%%%%%%%%%%%precoding bundle NR with ideal channel PDP
%                 H_Equalization_mid = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
%                 NumOfSymbol = size(H_Equalization_mid,3);
%                 H_pre = zeros(Nt,Nt);
%                 for nSym = 7
%                     for num_sub = 1:3:Nc_used
%                         H_pre_temp = reshape(H_Equalization_mid(:,num_sub,nSym),Nr,Nt);%Nr*Nt
%                         H_pre = H_pre + H_pre_temp'*H_pre_temp;%(Nr*Nt)'*(Nr*Nt)=Nt*Nt
%                     end
%                     PMI_decide1 = (PMI_matrix(:,:,1))'*H_pre*PMI_matrix(:,:,1);
%                     PMI_index_final = 1;
%                     for PMI_index = 2:32
%                         PMI_decide2 = (PMI_matrix(:,:,PMI_index))'*H_pre*PMI_matrix(:,:,PMI_index);
%                         if PMI_decide2 > PMI_decide1
%                             PMI_decide1 = PMI_decide2;
%                             PMI_index_final = PMI_index;
%                         end
%                     end
%                 end
                DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
                M_expPDP_DMRS = MatrixForCE.M_expPDP_DMRS(:,:,1:DMRS_port,:,:,:);
                for nrb = 1:N_Matraix
                    stp = (nrb-1)*SC_perM+1;
                    edp = nrb * SC_perM;
                    stp1 = (nrb-1)*DMRS_perM+1;
                    edp1 = nrb * DMRS_perM;
                    FFT_Out_DMRS_RB = FFT_Out_DMRS(:,:,stp1:edp1,:);
                    
                    [ a, b c d e f ] = size(M_expPDP_DMRS);
                    M_expPDP_DMRS_temp = zeros(b,c,d,e,f);
                    M_expPDP_DMRS_temp(:,:,:,:,:) = M_expPDP_DMRS(nrb,:,:,:,:,:);
                    H_temp = expPDP_CE(DMRS_port,Nr,Nd,SC_perM,DMRS_COLUMN_INDEX,DATA_COLUMN_INDEX,FFT_Out_DMRS_RB,M_expPDP_DMRS_temp);
                    
                    H_Equalization_temp(:,stp:edp,:)= H_temp;
                end
            case 5 
                DMRS_Subcarrier = size(PilotParam.DMRS_Signal,2); % DMRS 占用的子载波数 (Nc_used_DMRS)
                DMRS_OFDMs = size(PilotParam.DMRS_COLUMN_INDEX,2); % DMRS 所占 OFDM 符号数
                Total_OFDMs = size(PilotParam.DATA_COLUMN_INDEX,2); % 总 OFDM 符号数
    
                H_Equalization_temp = zeros(Nr*DMRS_port, Nc_used, Total_OFDMs);  
                DMRS_OFDM_indices = PilotParam.DMRS_COLUMN_INDEX(1,:);
                
                for nra = 1:Nr
                    for nta = 1:DMRS_port
                        H_est = zeros(Nc_used, DMRS_OFDMs);  % MIMO中每个信道下的导频符号估计值
                        for ofdm_idx = 1:DMRS_OFDMs
                            Y_current = squeeze(FFT_Out_DMRS(nra, nta, :, ofdm_idx)).';
                            X_current = squeeze(PilotParam.DMRS_Signal(nta, :, ofdm_idx));
        
                            % LS信道估计公式
                            H_ls = Y_current ./ X_current;   % 维度为 DMRS_Subcarrier (= Nc_used_DMRS)
                  
                            % DMRS_position 中存储的是 FFT 绝对子载波索引
                            % 必须使用 Nc_Index (同样是 FFT 绝对索引) 作为插值目标
                            sub_idx = PilotParam.DMRS_position(nta, :, ofdm_idx);
                            H_ls_interp = interp1(sub_idx, H_ls, Nc_Index, 'linear', 'extrap').';
                            H_est(:, ofdm_idx) = H_ls_interp;
                        end
                        % 时域OFDM符号插值: DMRS符号 → 全部OFDM符号
                        if DMRS_OFDMs == 1
                            % 仅一个DMRS符号, 跳过插值, 直接复制到所有符号
                            H_est_all_ofdm = repmat(H_est, 1, Total_OFDMs);
                        else
                            H_est_all_ofdm = interp1(DMRS_OFDM_indices, H_est.', 1:Total_OFDMs, 'linear', 'extrap').';
                        end
                        H_Equalization_temp((nta-1)*Nr+nra, :, :) = H_est_all_ofdm(:, 1:Total_OFDMs);
                    end
                end

        end
        %% Extract H at DMRS positions for DMRS equalization
        DMRS_position_ce = PilotParam.DMRS_position;
        DMRS_COLUMN_INDEX_ce = PilotParam.DMRS_COLUMN_INDEX;
        N_dmrs_sc = size(DMRS_position_ce, 2);
        N_dmrs_sym = size(DMRS_COLUMN_INDEX_ce, 2);
        H_DMRS_Equ = zeros(Nr, DMRS_port, N_dmrs_sc, N_dmrs_sym);
        for nta = 1:DMRS_port
            for np = 1:N_dmrs_sym
                sym_idx = DMRS_COLUMN_INDEX_ce(nta, np);
                if isnan(sym_idx), continue; end
                sc_indices_fft = DMRS_position_ce(nta, :, np);
                valid_mask = ~isnan(sc_indices_fft);
                % Map FFT subcarrier indices to Nc_used relative indices
                sc_fft_valid = sc_indices_fft(valid_mask);
                [~, sc_nc] = ismember(sc_fft_valid, Nc_Index);
                keep_mask = sc_nc > 0;
                sc_nc = sc_nc(keep_mask);
                valid_idx = find(valid_mask);
                valid_mask(valid_idx(~keep_mask)) = false;
                for nra = 1:Nr
                    row_idx = (nta-1)*Nr + nra;
                    H_flat = squeeze(H_Equalization_temp(row_idx, :, sym_idx));
                    H_DMRS_Equ(nra, nta, valid_mask, np) = H_flat(sc_nc);
                end
            end
        end
        for nH = 1:DMRS_port*Nr
            H_Equalization_temp2 = squeeze(H_Equalization_temp(nH,:,:));
            H_Equalization(nH,:,:) = H_Equalization_temp2(Data_Index_DataRegion);
        end
%         %理想信道估计
%         H_Equalization_mid = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
%         NumOfSymbol = size(H_Equalization_mid,3);
% 
%         for nSym = 1:NumOfSymbol
%             for num_sub = 1:Nc_used
%                 H_pre_temp =  H_Equalization_mid(:,num_sub,nSym);
%                 H_pre = reshape(H_pre_temp,Nr,Nt);
%                 H_Equalization_temp(:,num_sub,nSym) = reshape(H_pre *  MatrixParam.Matrix_StaticBF * BF_Matrix(:,:,ceil(num_sub/SC_perM)),[],1);
%             end
%         end
%         for nH = 1:DMRS_port*Nr
%             H_Equalization_temp2_ideal = squeeze(H_Equalization_temp(nH,:,:));
%             H_Equalization_ideal(nH,:,:) = H_Equalization_temp2_ideal(Data_Index_DataRegion);
%         end
%         mse = mean(abs(H_Equalization - H_Equalization_ideal).^2);
    otherwise
        error('Wrong TM!')
end
%% ************************* H_BF ********************************
switch TM
    case {2,3,4,9}
        H_BF = 1;
    case 'NR'
        H_BF = 1;
    case {7,8}
        H_BF_temp = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX);
        H_BF = H_BF_temp(:,:,end);
    otherwise
        error('Wrong TM!')
end

end
