source ~/init_opencl.sh
list="$(find * -name "hipacc_run.cl")"
while read -r app; do
    kernel_name="$(echo ${app} | cut -d"." -f1)"
    test -f "${kernel_name}_fpga/acl_quartus_report.txt" && echo "${kernel_name} is skipped"
    test -f "${kernel_name}_fpga/acl_quartus_report.txt" && continue
    #echo "aoc --report ${app} -I./include -o ${kernel_name}_fpga.aocx 2>&1 | tee ${kernel_name}.log"
    aoc --report "${app}" -I"../include" -o "${kernel_name}_fpga.aocx" 2>&1 | tee "${kernel_name}.log"
    mv "${kernel_name}_fpga.aocx" "${kernel_name}.aocx"
done <<< "$list"
