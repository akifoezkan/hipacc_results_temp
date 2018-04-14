<AutoPilot:project xmlns:AutoPilot="com.autoesl.autopilot.project" projectType="C/C++" name="hipacc_project" top="hipaccRun">
    <Simulation argv="">
        <SimFlow name="csim" setup="false" optimizeCompile="false" clean="true" ldflags="-lrt" mflags=""/>
    </Simulation>
    <files>
        <file name="../../main.cc" sc="0" tb="1" cflags=" -I../../../../include -std=c++0x "/>
        <file name="hipacc_run.cc" sc="0" tb="false" cflags="-std=c++0x -I../../include"/>
    </files>
    <solutions>
        <solution name="solution1" status=""/>
    </solutions>
</AutoPilot:project>

