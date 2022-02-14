`ifdef RTL
    `timescale 1ns/1ps
    `include "CDC.v"
    `define CYCLE_TIME_clk1 14.1
    `define CYCLE_TIME_clk2 2.5
    `define CYCLE_TIME_clk3 2.7
`endif
`ifdef GATE
    `timescale 1ns/1ps
    `include "CDC_SYN.v"
    `define CYCLE_TIME_clk1 14.1
    `define CYCLE_TIME_clk2 2.5
    `define CYCLE_TIME_clk3 2.7
`endif

module PATTERN(
    // Output signals
    clk_1,
    clk_2,
    clk_3,
    rst_n,
    in_valid,
    mode,
    CRC,
    message,

    // Input signals
    out_valid,
    out
    
);
//======================================
//          I/O PORTS
//======================================
output reg        clk_1;
output reg        clk_2;
output reg        clk_3;
output reg        rst_n;
output reg        in_valid;
output reg        mode;
output reg [59:0] message;
output reg        CRC;

input             out_valid;
input [59:0]      out;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter CYCLE1       = `CYCLE_TIME_clk1;
parameter CYCLE2       = `CYCLE_TIME_clk2;
parameter CYCLE3       = `CYCLE_TIME_clk3;
parameter PATNUM       = 500;
parameter DELAY        = 400;
parameter INPUT_DELAY  = 12.05;
integer   SEED         = 1024;//1208;//1024;

//======================================
//      WIRE & REGISTER
//======================================
integer            i;
integer            j;
integer            m;
integer            n;
integer          pat;
integer      exe_lat;
integer      out_lat;
integer      tot_lat;

reg [59:0]      data;
reg [59:0] send_data;
reg [59:0]      gold;
integer        moder;
integer         crcr;

// Calculate CRC
reg     check_flag;
integer   err_flag;
reg     shift_flag;
// CRC = 0
reg [8:0]    crc_8 = 100110001;
reg [7:0]    rem_8;
reg [7:0]    rem_check_8;
// CRC = 1
reg [5:0]    crc_5 = 101011;
reg [4:0]    rem_5;
reg [4:0]    rem_check_5;

//======================================
//              Clock
//======================================
initial clk_1 = 0;
always #(CYCLE1/2.0) clk_1 = ~clk_1;

initial clk_2 = 0;
always #(CYCLE2/2.0) clk_2 = ~clk_2;

initial clk_3 = 0;
always #(CYCLE3/2.0) clk_3 = ~clk_3;

//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              TASKS
//======================================
task exe_task; begin

    reset_task;
    for (pat=0; pat<PATNUM; pat=pat+1) begin
        input_task;
        wait_task;
        check_task;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
        tot_lat = tot_lat + exe_lat;
    end
    pass_task;
    $finish;

end endtask

task reset_task; begin

    tot_lat = 0;

    force clk_1 = 0;
    force clk_2 = 0;
    force clk_3 = 0;
    rst_n       = 1;
    in_valid    = 0;
    mode        = 'dx;
    message     = 'dx;
    CRC         = 'dx;

    #(CYCLE1/2.0) rst_n = 0;
    #(CYCLE1/2.0) rst_n = 1;
    if ( out_valid !== 0 || out !== 0 ) begin       
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE1);
        $finish;
    end

    #(CYCLE1/2.0)
    release clk_1;
    release clk_2;
    release clk_3;

end endtask

task input_task; begin
    repeat($urandom_range(1,3)) @(negedge clk_1);

    // Generate mode, CRC, message
    data_task;

    #(INPUT_DELAY-(CYCLE1/2.0));

    in_valid = 1;
    CRC      = crcr;
    mode     = moder;
    message  = send_data;
    #(CYCLE1);

    in_valid = 0;
    CRC      = 'dx;
    mode     = 'dx;
    message  = 'dx;

end endtask

task data_task; begin

    //===========================
    // Generate initialized data
    //===========================

    // Random generate mode & CRC
    moder = {$random(SEED)}%2;
    crcr  = {$random(SEED)}%2;

    // Generate original message
    if(pat<20) begin
        data = {$random(SEED)}%16;
    end
    else begin
        if(crcr==0) begin
            for (i=0 ; i<60 ; i=i+1) begin
                if(i>51) data[i] = 0;
                else     data[i] = {$random(SEED)}%2;
            end
        end
        else begin
            for (i=0 ; i<60 ; i=i+1) begin
                if(i>54) data[i] = 0;
                else     data[i] = {$random(SEED)}%2;
            end
        end
    end

    calculate_task;

    //==============================================
    // Base on different operation to modify data
    //==============================================
    check_flag = {$random(SEED)}%2;

    // check_flag = 1 & mode = 1
    // I will generate the wrong message
    if(moder == 1) begin
        if(crcr==0) send_data = {data[51:0], rem_8};
        else        send_data = {data[54:0], rem_5};
        if(check_flag == 1) begin
            err_flag = {$random(SEED)}%60;
            send_data[err_flag] = ~send_data[err_flag];
        end
        gold = {60{check_flag}};
    end
    else begin
        if(crcr==0) gold = {data[51:0], rem_8};
        else        gold = {data[54:0], rem_5};
        send_data = data;
    end

    //==============================================
    // Keep original message in "data"
    // Send modified message in "send_data"
    //==============================================
    calculate_check_task;
end endtask

//###########################################################
task calculate_task; begin
    // Initial remainder
    rem_5 = 0;
    rem_8 = 0;

    // CRC-8
    if( crcr==0 ) begin
        for(i=51 ; i>=0 ; i=i-1) begin
            shift_flag = data[i] ^ rem_8[7];
            rem_8[7] = rem_8[6];
            rem_8[6] = rem_8[5];
            rem_8[5] = rem_8[4] ^ shift_flag;
            rem_8[4] = rem_8[3] ^ shift_flag;
            rem_8[3] = rem_8[2];
            rem_8[2] = rem_8[1];
            rem_8[1] = rem_8[0];
            rem_8[0] = shift_flag;
        end
    end
    // CRC-5
    else begin
        for(i=54 ; i>=0 ; i=i-1) begin
            shift_flag = data[i] ^ rem_5[4];
            rem_5[4]   = rem_5[3];
            rem_5[3]   = rem_5[2] ^ shift_flag;
            rem_5[2]   = rem_5[1];
            rem_5[1]   = rem_5[0] ^ shift_flag;
            rem_5[0]   = shift_flag;
        end
    end
end endtask

//###########################################################
// ONLY FOR mode=1 to generate the remainder of the check
//###########################################################
task calculate_check_task; begin
    // Initial remainder
    rem_check_5 = 0;
    rem_check_8 = 0;

    // CRC-8
    if( crcr==0 ) begin
        for(i=59 ; i>=8 ; i=i-1) begin
            shift_flag = send_data[i] ^ rem_check_8[7];
            rem_check_8[7] = rem_check_8[6];
            rem_check_8[6] = rem_check_8[5];
            rem_check_8[5] = rem_check_8[4] ^ shift_flag;
            rem_check_8[4] = rem_check_8[3] ^ shift_flag;
            rem_check_8[3] = rem_check_8[2];
            rem_check_8[2] = rem_check_8[1];
            rem_check_8[1] = rem_check_8[0];
            rem_check_8[0] = shift_flag;
        end
        rem_check_8 = rem_check_8 ^ send_data[7:0];
    end
    // CRC-5
    else begin
        for(i=59 ; i>=5 ; i=i-1) begin
            shift_flag = send_data[i] ^ rem_check_5[4];
            rem_check_5[4]   = rem_check_5[3];
            rem_check_5[3]   = rem_check_5[2] ^ shift_flag;
            rem_check_5[2]   = rem_check_5[1];
            rem_check_5[1]   = rem_check_5[0] ^ shift_flag;
            rem_check_5[0]   = shift_flag;
        end
        rem_check_5 = rem_check_5 ^ send_data[4:0];
    end
end endtask

task wait_task; begin
    exe_lat = -1;
    while ( out_valid!==1 ) begin
        if ( out !== 0 ) begin
            $display("                                           `:::::`                                                       ");
            $display("                                          .+-----++                                                      ");
            $display("                .--.`                    o:------/o                                                      ");
            $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
            $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
            $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
            $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
            $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
            $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
            $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
            $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
            $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
            $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
            $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
            $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
            $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
            $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
            $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
            $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
            $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
            $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
            $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
            $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
            $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
            $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
            $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
            $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
            $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
            $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
            $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
            $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
            $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
            $display("                       `s--------------------------::::::::-----:o                                       ");
            $display("                       +:----------------------------------------y`                                      ");
            repeat(5) @(negedge clk_1);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             "); 
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over 400  cycles       `:::--:/++:----------::/:.                ");
            $display("                            -+:--:++////-------------::/-               ");
            $display("                            .+---------------------------:/--::::::.`   ");
            $display("                          `.+-----------------------------:o/------::.  ");
            $display("                       .-::-----------------------------:--:o:-------:  ");
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");
            $display("              `:oosh/--------++-----------------:--:------/.            ");
            $display("              +ssssyy--------:y:---------------------------/            ");
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");
            $display("           -osssssssssssssso/---------------------------:/.             ");
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");
            $display("       `/o+----------------------------------------------:o---+`        ");
            $display("         `+-----------------------------------------------o::+.         ");
            $display("          +-----------------------------------------------/o/`          ");
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk_1);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk_3);
    end
end endtask

task check_task; begin
    out_lat = 0;
    while ( out_valid === 1 ) begin
        if(out_lat == 1) begin
            $display("                                                                                ");   
            $display("                                                   ./+oo+/.                     ");   
            $display("    Out cycles is more than 1 cycle               /s:-----+s`     at %-12d ps   ", $time*1000);   
            $display("                                                  y/-------:y                   ");   
            $display("                                             `.-:/od+/------y`                  ");   
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");   
            $display("                              -m+:::::::---------------------::o+.              ");   
            $display("                             `hod-------------------------------:o+             ");   
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");   
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");   
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");   
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");   
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");   
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");   
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");   
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");   
            $display("                 s:----------------/s+///------------------------------o`       ");   
            $display("           ``..../s------------------::--------------------------------o        ");   
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");   
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");   
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");   
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");   
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");   
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");   
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");   
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");   
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");   
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");   
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");   
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");   
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");   
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");   
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");   
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");   
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");   
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");   
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");   
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");   
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");   
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");   
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
            repeat(5) @(negedge clk_1);
            $finish;
        end
        else begin
            if(out !== gold) begin
                $display("                                                                                ");   
                $display("                                                   ./+oo+/.                     ");   
                $display("    Your output is not correct!!!                 /s:-----+s`     at %-12d ps   ", $time*1000);   
                $display("                                                  y/-------:y                   ");   
                $display("                                             `.-:/od+/------y`                  ");   
                $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");   
                $display("                              -m+:::::::---------------------::o+.              ");   
                $display("                             `hod-------------------------------:o+             ");   
                $display("                       ./++/:s/-o/--------------------------------/s///::.      ");   
                $display("                      /s::-://--:--------------------------------:oo/::::o+     ");   
                $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");   
                $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");   
                $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");   
                $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");   
                $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");   
                $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");   
                $display("                 s:----------------/s+///------------------------------o`       ");   
                $display("           ``..../s------------------::--------------------------------o        ");   
                $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");   
                $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");   
                $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");   
                $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");   
                $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");   
                $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");   
                $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");   
                $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");   
                $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");   
                $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");   
                $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");   
                $display("  `s+--------------------------------------:syssssssssssssssyo                  ");   
                $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");   
                $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");   
                $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");   
                $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");   
                $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");   
                $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");   
                $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");   
                $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");   
                $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");   
                $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");   
                $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
                $display("================================================================================");
                if(moder== 0) $display("Mode (Generate)       : %-1d", moder);
                else          $display("Mode (Check)          : %-1d", moder);
                if(crcr == 0) $display("CRC                   : %-1d (100110001)", crcr);
                else          $display("CRC                   : %-1d (101011)   ", crcr);
                $display("================================================================================");
                if(moder == 0) $display("Original message(hex) : %-15h", send_data);
                else           $display("Received data   (hex) : %-15h", send_data);
                $display("Gold pattern    (hex) : %-15h", gold);
                $display("Your output     (hex) : %-15h", out);
                $display("================================================================================");
                // Mode 0
                if(moder == 0 && crcr == 0) $display("For mode 0 the remainder(hex)  : %-2h", rem_8);
                if(moder == 0 && crcr == 1) $display("For mode 0 the remainder(hex)  : %-2h", rem_5);
                // Mode 1
                if(moder == 1)              $display("For mode 1 the message   (hex) : %-15h", data);
                if(moder == 1 && crcr == 0) $display("For mode 1 the remainder (hex) : %-2h", rem_8);
                if(moder == 1 && crcr == 1) $display("For mode 1 the remainder (hex) : %-2h", rem_5);
                if(moder == 1 && crcr == 0) $display("For mode 1 the Pass check(hex) : %-2h", rem_check_8);
                if(moder == 1 && crcr == 1) $display("For mode 1 the Pass check(hex) : %-2h", rem_check_5);
                $display("================================================================================");
                repeat(5) @(negedge clk_1);
                $finish;
            end
        end
        out_lat = out_lat + 1;
        @(negedge clk_3);
    end
end endtask

task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Total Cycles : %-d \033[1;0m                                  ", tot_lat);
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o                                                                                      ");
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk_1);
    $finish;
end endtask
endmodule
