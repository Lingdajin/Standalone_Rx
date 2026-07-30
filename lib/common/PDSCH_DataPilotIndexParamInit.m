function DataPilotIndexParam = PDSCH_DataPilotIndexParamInit(CFI,FFT_size,Nd,Nc_Index,CRS_port,DMRS_port,CSIRS_port,CRS_position,DMRS_position,CSIRS_position,CRS_COLUMN_INDEX,DMRS_COLUMN_INDEX,CSIRS_COLUMN_INDEX)

%% note
% When link adaption is available, the reserverd REs for DMRS is variable
        % determined by the instant layer number, and the resource
        % allocation for DMRS will be operated in link adaption process. 
% When link adaption is closed, the resource allocation for DMRS will be 
        % operated here. 
%%
global SystemParam
TM = SystemParam.TM;
FrameIndex = zeros(FFT_size,Nd);
FrameIndex(Nc_Index,CFI+1:end) = 1;
% TS 38.214 §5.1.6.2: DMRS符号中未被DMRS占用的RE可承载PDSCH数据
% 不再整列清零, 仅通过后续DMRS标记覆盖对应位置 (Data_Index = find(FrameIndex==1))
% CRS resource allocation labelling
for nta = 1:CRS_port
    CRS_COLUMN_INDEX_temp = CRS_COLUMN_INDEX(nta,~isnan(CRS_COLUMN_INDEX(nta,:))); 	% remove NaN, and squeeze position NaN occupied
    for index_column = 1:size(CRS_COLUMN_INDEX_temp,2)
        Row = squeeze(CRS_position(nta,:,index_column));
        Col = CRS_COLUMN_INDEX_temp(index_column);
        FrameIndex(Row,Col) = (nta-1)+2;
    end
end
% DMRS resource allocation labelling
if TM == 'NR'
    switch DMRS_port
        case 0
            % do nothing
        case {1}
            for column_index= 1:size(DMRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(DMRS_position(1,:,column_index));            % port 5 为单端口DMRS，port 7、8导频位置相同
                FrameIndex(Pilot_D1,DMRS_COLUMN_INDEX(1,column_index)) = 6;
            end
        case {2,3,4,5,6,7,8}
            for column_index= 1:size(DMRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(DMRS_position(1,:,column_index));            % port 7,8,11,13导频位置相同；port 9,10,12,14导频位置相同
                Pilot_D2 = squeeze(DMRS_position(2,:,column_index));
                FrameIndex(Pilot_D1,DMRS_COLUMN_INDEX(1,column_index)) = 6;
                FrameIndex(Pilot_D2,DMRS_COLUMN_INDEX(1,column_index)) = 7;
            end
        otherwise
            error('Wrong DMRS_port!')
    end
elseif TM == 8 || TM == 9
    switch DMRS_port
        case 0
            % do nothing
        case {1,2}
            for column_index= 1:size(DMRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(DMRS_position(1,:,column_index));            % port 5 为单端口DMRS，port 7、8导频位置相同
                FrameIndex(Pilot_D1,DMRS_COLUMN_INDEX(1,column_index)) = 6;
            end
        case {3,4,5,6,7,8}
            for column_index= 1:size(DMRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(DMRS_position(1,:,column_index));            % port 7,8,11,13导频位置相同；port 9,10,12,14导频位置相同
                Pilot_D2 = squeeze(DMRS_position(3,:,column_index));
                FrameIndex(Pilot_D1,DMRS_COLUMN_INDEX(1,column_index)) = 6;
                FrameIndex(Pilot_D2,DMRS_COLUMN_INDEX(1,column_index)) = 7;
            end
        otherwise
            error('Wrong DMRS_port!')
    end
end
% CSI-RS resource allocation labelling
if TM == 'NR'
    %TBD
elseif TM == 8 || TM == 9
    switch CSIRS_port
        case 0
            % do nothing
        case {1,2}
            for column_index = 1:size(CSIRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(CSIRS_position(1,:,column_index));           % port 15,16导频位置相同
                FrameIndex(Pilot_D1,CSIRS_COLUMN_INDEX(1,column_index)) = 8;
            end
        case 4
            for column_index = 1:size(CSIRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(CSIRS_position(1,:,column_index));           % port 15,16导频位置相同
                Pilot_D2 = squeeze(CSIRS_position(3,:,column_index));           % port 17,18导频位置相同
                FrameIndex(Pilot_D1,CSIRS_COLUMN_INDEX(1,column_index)) = 8;
                FrameIndex(Pilot_D2,CSIRS_COLUMN_INDEX(1,column_index)) = 9;
            end
        case 8
            for column_index = 1:size(CSIRS_COLUMN_INDEX,2)
                Pilot_D1 = squeeze(CSIRS_position(1,:,column_index));           % port 15,16导频位置相同
                Pilot_D2 = squeeze(CSIRS_position(3,:,column_index));           % port 17,18导频位置相同
                Pilot_D3 = squeeze(CSIRS_position(5,:,column_index));           % port 19,20导频位置相同
                Pilot_D4 = squeeze(CSIRS_position(7,:,column_index));           % port 21,22导频位置相同
                FrameIndex(Pilot_D1,CSIRS_COLUMN_INDEX(1,column_index)) = 8;
                FrameIndex(Pilot_D2,CSIRS_COLUMN_INDEX(1,column_index)) = 9;
                FrameIndex(Pilot_D3,CSIRS_COLUMN_INDEX(1,column_index)) = 10;
                FrameIndex(Pilot_D4,CSIRS_COLUMN_INDEX(1,column_index)) = 11;
            end
        otherwise
            error('Wrong CSIRS_port!')
    end
end

Data_Index = find(FrameIndex==1);
CRS_Index = find(FrameIndex==2|FrameIndex==3|FrameIndex==4|FrameIndex==5);
DMRS_Index = find(FrameIndex==6|FrameIndex==7);
CSIRS_Index = find(FrameIndex==8|FrameIndex==9|FrameIndex==10|FrameIndex==11);
FrameIndex_Data = FrameIndex(Nc_Index,CFI+1:end);
Data_Index_DataRegion = find(FrameIndex_Data==1);

DataPilotIndexParam  = struct(...
    'Data_Index',Data_Index,...
    'CRS_Index',CRS_Index,...
    'DMRS_Index',DMRS_Index,...
    'CSIRS_Index',CSIRS_Index,...
    'Data_Index_DataRegion',Data_Index_DataRegion);

% 保存数据索引Data_Index
%save("../mat/Data_Index_1DMRS.mat","Data_Index");


% 保存索引mat变量，用于数据预处理过程
%Data_Index = find(FrameIndex==1|FrameIndex==6|FrameIndex == 7);
%save("./data_index.mat","Data_Index");
%save("./data_symbol_index.mat","Data_Index_DataRegion");
%save("./FrameIndex_Data.mat","FrameIndex_Data");


end
