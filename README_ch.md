# TyTAN

TrustLite_v1:实现了基本的EA_MPU功能，但是没有考虑TrustLite中和exception engine相关的内容。

修改过的文件：
core_region.sv
zeroriscy_core.sv
zeroriscy_id_stage.sv

添加的新文件：
ea_mpu.sv
ea_mpu_ram.sv
data_ram_mux.sv(在ram_mux.sv的基础上修改的)
