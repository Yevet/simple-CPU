# MIPS SoC Design and Performance Optimization

1. The simple five-level pipelined CPU implemented in Experiment 4 of "Principle of Composition" was expanded from 10 instructions to 57 instructions, and the exception handling module was implemented. 

   Including all non-floating-point MIPS I instructions (except LWL, LWR, SWL, SWR) and ERET instructions in MIPS 32, there are 14 arithmetic operation instructions, 8 logic operation instructions, 6 shift instructions, 12 branch instructions, 4 data movement instructions, 2 trap instructions, 8 access instructions, 3 privileged instructions, There are 57 instructions in total.

2. Add Cache to speed up CPU memory access. The basic requirement is 4KB, block size is 1word, and the processing method is to write direct, direct mapping i-cache and d-cache.

3. Processor performance optimization. Contains the following:

   - Optimization of pipeline cut-off problem. Pipeline interruptions focus on branch instructions and access delay. When some instructions are related to the pipeline, data cannot be pushed forward to meet the needs, resulting in the pipeline suspension and flow interruptions. Analyze the path diagram, optimize the data forward path, reduce the probability of pipeline pause, and achieve the role of performance optimization.
   - Balancing the combined logic delay of each stage. Combinational logic parts to complete in different stages of the functional complexity is different, the decoding, the execution phase of combinational logic to complete the required time delay is significantly higher than other phases, time needed for the optimization of a single cycle, as far as possible make the function of complex phase to realize the combination of logic have reduced latency, optimization of single cycle execution time.
   - Critical path optimization. Because the CPU's internal composition logic is directly connected to IO, IO access becomes a critical path. Optimizing IO delay can effectively reduce the total time of critical path and achieve clock frequency optimization. At the same time, the influence on IPC should be considered to achieve the effect of equilibrium optimization.

   

   Extension:

   Improve the Cache. On top of the base Cache, the write back Cache is implemented, which supports larger block size, and the mapping mode is changed to two way group concatenation. The code is connected to the SRAM module and the AXI module respectively for testing.
   
### 说明

本发布包用于整理硬综需要用到的所有资料，防止有资料漏发的情况。持续更新。

### 目录说明

- 硬综要求：包含硬综任务书、评分标准和报告模板。
- doc：用于存放硬综涉及到的参考文档和每次讲解用到的PPT。
- ref_code：用于存放一些发给同学们参考的代码。
- test：包含功能测试和性能测试的目录。

### 更新记录

- 2020/12/23
  1. 删除原本的soc_sram_func_n4ddr.tar(有错误)。添加完整移植的功能测试和性能测试(test/n4ddr/*)。
  2. 添加score.xls文件
- 2020/12/28
  1. 添加2020硬综讲解ppt
  2. 添加体系结构cache实验指导书，*doc/其它/Cache实验指导书.pdf*
  3. 添加*ref_code/axi_interface_lv.zip*
- 2020/12/30
  1. 添加lab4工程
  
  
