function [ Data_after_Equ,SNR_after_Equ ] = PDSCH_Equalizer(TM,H_Equalization,FFT_Out_User,CRS_port,Nt,Nr,Data_Index,SNR_line,sigma,MH_AMC,InterferencePower)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description:
% (1) PDSCH_Equalizer accomplishes equalization.
% (2) Two different Signal Detectors are used:
% TM2: SFBC (or Alamuti coding) dedicated detector.
% TM3/4/7/8/: MMSE detector.
%% Input Parameters:
% TM: transmission mode, support TM2/3/4/7/8
% H_Equalization: channel frequency response for equalization
% FFT_Out_User: received CRS_port,Nt,Nr,Data_Index,SNR_line,sigma
%% Output Parameters:
% H_AMC: channel frequency response for AMC
% H_Equalization: channel frequency response for equalization
% FFT_Out_User: reveived user data
% CRS_port: CRS port number
% Nt: transmission antenna number
% Nr: receiving antenna number
% Data_Index: data position index
% SNR_line: linear SNR
% sigma: noise strandard deviation
%% Modification records:
% (1) Add annotations in 2012.11.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SystemParam TurboCodingRateMatchingParam LDPCCodingRateMatchingParam
global MatrixParam

switch TM
    case 2
        H_temp = (H_Equalization(:,1:2:end)+H_Equalization(:,2:2:end))./2;%两时间间隔分组平均值；
        if CRS_port == 2
            H = H_temp;
        elseif Nr == 2 && CRS_port == 4
            [a,b,c] = size(H_temp);
            H = zeros(Nr*CRS_port/2,b*c*CRS_port/4);
            H([1 2],1:2:end) = H_temp([1 2],1:2:end);
            H([3 4],1:2:end) = H_temp([5 6],1:2:end);
            H([1 2],2:2:end) = H_temp([3 4],2:2:end);
            H([3 4],2:2:end) = H_temp([7 8],2:2:end);
        elseif Nr == 4 && CRS_port == 4
            [a,b,c] = size(H_temp);
            H = zeros(Nr*CRS_port/2,b*c*CRS_port/4);
            H([1 2],1:2:end) = H_temp([1 2],1:2:end);
            H([3 4],1:2:end) = H_temp([3 4],1:2:end);
            H([1 2],2:2:end) = H_temp([5 6],2:2:end);
            H([3 4],2:2:end) = H_temp([7 8],2:2:end);
            H([5 6],1:2:end) = H_temp([9 10],1:2:end);
            H([7 8],1:2:end) = H_temp([11 12],1:2:end);
            H([5 6],2:2:end) = H_temp([13 14],2:2:end);
            H([7 8],2:2:end) = H_temp([15 16],2:2:end);
        end
        data = reshape(FFT_Out_User,Nr*2,[]);
        Data_after_Equ = zeros(1,length(Data_Index));
        SNR_after_Equ = zeros(1,length(Data_Index));
        for index = 1:length(Data_Index)/2
            H_tmp = H(:,index);
            H_current = reshape(H_tmp,Nr,2+mod(Nt,2))*[1/sqrt(2),0;0,1/sqrt(2)];
            data_tmp = data(:,index);
            Data_current = reshape(data_tmp,Nr,2+mod(Nt,2));
            Data_after_Equ(:,[2*index-1,2*index]) = reshape(STBCDecoder(Data_current,H_current).',1,[]);
            SNR_after_Equ(:,[2*index-1,2*index]) = SNR_line*(abs(H_current(1,1)).^2+abs(H_current(1,2)).^2+abs(H_current(2,1)).^2+abs(H_current(2,2)).^2);
        end
    case {3,4}
        Matrix_W = MatrixParam.Matrix_W;
        if TM == 3
            Ns = SystemParam.Ns;
            FFT_size = SystemParam.FFT_size;
            Nc = SystemParam.Nc;
            Matrix_D = MatrixParam.Matrix_D;
            Matrix_U = MatrixParam.Matrix_U;
        end
        data_len = size(H_Equalization,2);
        for loop = 1:data_len
            % Temp variable for the detection at the nth subcarrier
            H_tmp_0 = H_Equalization(:,loop);
            H_current = reshape(H_tmp_0,Nr,[]);
            %H_tmp_1 = MH_AMC(:,loop);
            %H_current1 = reshape(H_tmp_1,Nr,[]);
            if TM == 3
                re_index=mod(Data_Index(loop),FFT_size);
                D_Index = re_index-(FFT_size-Nc)/2;
                if CRS_port == 4
                    p_index=mod(floor(D_Index/Ns),4)+1;
                    Matrix_W_temp = Matrix_W(:,:,p_index);
                else
                    Matrix_W_temp = Matrix_W;
                end
                H_eq = H_current * Matrix_W_temp * diag(Matrix_D(:,D_Index)) * Matrix_U;
            else
                H_eq = H_current * Matrix_W;           % 等效矩阵
               % H_eq1 = H_current1 * Matrix_W;           % 等效矩阵
            end
            Data_current = reshape(FFT_Out_User(:,loop),Nr,[]);
            % BLAST-MMSE
             [Data_MMSE SNR_sub] = rx_vblast_mmse_vB(H_eq,Data_current,sigma^2);
          %  [Data_MMSE SNR_sub] = rx_vblast_mmse_IRC_vB(H_eq,H_eq1,Data_current ,sigma^2,InterferencePower);
            Data_after_Equ (:,loop) = Data_MMSE.';
            SNR_after_Equ (:,loop) = SNR_sub.';
        end
    case {7,8,9,'NR'}
        data_len = size(H_Equalization,2);
        if SystemParam.RML_Flag == 1
            if SystemParam.channel_code == 1
                modulation_mode = TurboCodingRateMatchingParam.modulation_mode;
            else
                modulation_mode = LDPCCodingRateMatchingParam.modulation_mode;
            end
            for loop = 1:data_len
                % Temp variable for the detection at the nth subcarrier
                H_tmp_0 = H_Equalization(:,loop);
                H_current = reshape(H_tmp_0,Nr,[]);
                H_eq = H_current;           % 等效矩阵
                Data_current = reshape(FFT_Out_User(:,loop),Nr,[]);
                nt = size(H_eq,2);
                % R-ML
%                 [Data_after_Equ((loop-1)*modulation_mode*nt+1:loop*modulation_mode*nt)]=PDSCH_QRMMLD(H_eq,Data_current,sigma^2);
                [Data_after_Equ((loop-1)*modulation_mode*nt+1:loop*modulation_mode*nt)]=PDSCH_QRMMLD(H_eq,Data_current,sigma^2);
            end
            SNR_after_Equ =[];
        else
            for loop = 1:data_len
                % Temp variable for the detection at the nth subcarrier
                H_tmp_0 = H_Equalization(:,loop);
                H_current = reshape(H_tmp_0,Nr,[]);
                H_eq = H_current;           % 等效矩阵
                Data_current = reshape(FFT_Out_User(:,loop),Nr,[]);
                % BLAST-MMSE
                [Data_MMSE, SNR_sub] = rx_vblast_mmse_vB(H_eq,Data_current,sigma^2);
                Data_after_Equ (:,loop) = Data_MMSE.';
                SNR_after_Equ (:,loop) = SNR_sub.';
            end
        end
    otherwise
        error('Wrong TM!')
end
end