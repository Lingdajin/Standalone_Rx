# PDSCH Standalone Receiver

该目录是可直接迁移的独立 PDSCH 接收机项目。项目代码只从本目录及其 `lib` 子目录加载，不依赖原 `PDSCH_baseline` 的其他文件夹。

## 环境要求

- MATLAB R2024a（或兼容版本）
- Signal Processing Toolbox
- Communications Toolbox
- Windows x64（当前 LDPC 编解码器为 `.mexw64`）

## 使用

1. 将 VSA `.mat` 文件放入 `input`，文件至少包含 `Y` 和 `XDelta`，可选包含 `InputCenter`、`NumAntennas`。
2. 编辑 `PDSCH_Receiver_Standalone_Config.m`，使系统、DMRS、MCS 和时隙参数与发射端一致。
3. 运行 `PDSCH_Receiver_Standalone.m`。
4. 结果写入 `results/Rx_Standalone_Result.mat`。

也可通过环境变量 `PDSCH_VSA_FILE` 指定任意输入文件，无需修改配置：

```matlab
setenv('PDSCH_VSA_FILE', 'D:/captures/example.mat');
PDSCH_Receiver_Standalone
```

## 验证

```matlab
run_standalone_tests
```

该命令先恢复 MATLAB 默认路径，只加载本项目，再运行回归测试和依赖闭包检查。`input` 中的采集文件属于运行输入，不属于代码依赖，因此没有随项目复制。

## 目录

- `lib/common`: NR 导频、索引和信道估计矩阵辅助代码
- `lib/receiver`: OFDM 解调、信道估计、均衡、软解调和统计代码
- `lib/ldpc`: LDPC 参数、速率匹配、MEX 编解码器和基图
- `lib/transmitter`: 接收机重编码/EVM 所需的少量调制辅助代码
- `lib/main`: 保留的 RML 分支辅助代码
- `data/MatForLDPC`: LDPC 矩阵缓存
- `input`: VSA 输入文件目录
- `results`: 接收结果目录
