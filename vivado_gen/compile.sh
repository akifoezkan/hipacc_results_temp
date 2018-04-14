source ~/init_vivado.sh
list="$(find * -name "*hipacc_run.cc")"
while read -r app; do
    base_name="$(echo ${app} | cut -d"/" -f1)"
    test -f "hipacc_project/solution1/impl/report/verilog/hipaccRun_export.rpt" && echo "${base_name} is skipped"
    test -f "hipacc_project/solution1/impl/report/verilog/hipaccRun_export.rpt" && continue
    cd ${base_name}
    make 
    cd -
done <<< "$list"
