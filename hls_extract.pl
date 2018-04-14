# sudo apt-get install libxml-simple-perl
#apt-get install libfile-find-rule-perl
##!/usr/bin/perl
use strict;
use XML::Simple qw(:strict);
use Data::Dumper;
use Cwd;
use Cwd qw(realpath);
use File::Find::Rule;
use File::Basename;

# # Fast use guide for XML parser
# use XML::Simple qw(:strict);
# use Data::Dumper;
# my $file_impl ='lambda_169493_export.xml';
# my $data_impl = XMLin($file_impl, ForceArray => 1, KeyAttr => [  ], KeepRoot => 1);
# print Dumper($data_impl);
# print @{$data_impl->{profile}[0]->{TimingReport}}[0]->{AchievedClockPeriod}[0];
# print @{$data_impl->{profile}[0]->{AreaReport}[0]->{Resources}[0]->{LUT}}[0] . "\n";
# ##

# ## Fast use guide for File:Find
# my $cwd = getcwd();
# my @files = File::Find::Rule->file()
#                             ->name('*_export.xml')
#                             ->in($cwd."/../sandbox/");
# print Dumper(\@files);
# ##

# ## Fast use guide for fileparse
# my($filename, $basename, $suffix) = fileparse($path_impl, ".xml");
# print $basename . "\n";
# print $filename . "\n";
# print $suffix . "\n";
# ##

##------------------------------ global stuff --------------------------------
my $cwd = getcwd();

##---------------------------- parser functions ------------------------------
sub formatfloat {
    my ($word) = @_;
    sprintf( "%.2f", $word)
}

sub makeNewHash($) {
    my $hashRef = shift;
    my %oldHash = %$hashRef;
    my %newHash = ();
    while ( my ($key, $innerRef) = each %oldHash ) {
        $newHash{$key} = @$innerRef[0];
    }
    return \%newHash;
    # ## Fast use guide
    # my $a = makeNewHash($data_synt);
    # print @{$a->{profile}->{TimingReport}}[0]->{AchievedClockPeriod}[0] . "\n";
    # ##
}

sub pushImplResults {
    my ($list_ref) = @_;

    foreach my $result (@$list_ref) {
        my $file_impl = $result->{job}->{path_impl};
        my $file_synt = $result->{job}->{path_synt};

        if ( -e "$file_synt" ) {
            ## hls synthesis estimation results
            my $data_synt      = XMLin($file_synt, ForceArray => 1, KeyAttr => [  ], KeepRoot => 1);
            my $area_synt      = makeNewHash($data_synt->{profile}[0]->{AreaEstimates}[0]->{Resources}[0]);
            my $available_synt  = makeNewHash($data_synt->{profile}[0]->{AreaEstimates}[0]->{AvailableResources}[0]);
            #print Dumper($data_synt);

            $result->{synt}->{II} = $data_synt->{profile}[0]->{PerformanceEstimates}[0]->{SummaryOfLoopLatency}[0]->{Loop1}[0]->{PipelineII}[0];
            $result->{synt}->{WorstcaseLatency} = formatfloat($data_synt->{profile}[0]->{PerformanceEstimates}[0]->{SummaryOfOverallLatency}[0]->{'Worst-caseLatency'}[0]);
            $result->{synt}->{EstimatedClockPeriod} = formatfloat($data_synt->{profile}[0]->{PerformanceEstimates}[0]->{SummaryOfTimingAnalysis}[0]->{EstimatedClockPeriod}[0]);
            $result->{synt}->{BRAM } = $area_synt->{BRAM_18K};
            $result->{synt}->{LUT  } = $area_synt->{LUT };
            $result->{synt}->{FF   } = $area_synt->{FF  };
            $result->{synt}->{DSP  } = $area_synt->{DSP48E};
            # will be set from impl again (if exist)
            $result->{available}->{BRAM} = $available_synt->{BRAM_18K};
            $result->{available}->{LUT } = $available_synt->{LUT };
            $result->{available}->{FF  } = $available_synt->{FF  };
            $result->{available}->{DSP } = $available_synt->{DSP48E};
        }

        if ( -e "$file_impl" ) {
            my $data_impl      = XMLin($file_impl, ForceArray => 1, KeyAttr => [  ], KeepRoot => 1);
            my $area_impl      = makeNewHash($data_impl->{profile}[0]->{AreaReport}[0]->{Resources}[0]);
            my $available_impl = makeNewHash($data_impl->{profile}[0]->{AreaReport}[0]->{AvailableResources}[0]);
            #print Dumper($data_impl);

            $result->{impl}->{TargetClockPeriod}   = formatfloat($data_impl->{profile}[0]->{TimingReport}[0]->{TargetClockPeriod}[0]);
            $result->{impl}->{AchievedClockPeriod} = formatfloat($data_impl->{profile}[0]->{TimingReport}[0]->{AchievedClockPeriod}[0]);
            $result->{impl}->{SLICE} = $area_impl->{SLICE};
            $result->{impl}->{BRAM } = $area_impl->{BRAM};
            $result->{impl}->{LUT  } = $area_impl->{LUT };
            $result->{impl}->{FF   } = $area_impl->{FF  };
            $result->{impl}->{DSP  } = $area_impl->{DSP };
            $result->{impl}->{SRL  } = $area_impl->{SRL };
            $result->{available}->{SLICE} = $available_impl->{SLICE};
            $result->{available}->{BRAM} = $available_impl->{BRAM};
            $result->{available}->{LUT } = $available_impl->{LUT };
            $result->{available}->{FF  } = $available_impl->{FF  };
            $result->{available}->{DSP } = $available_impl->{DSP };
            $result->{available}->{SRL } = $available_impl->{SRL };
            #print Dumper($result);
        }
        #print Dumper($result);
    }
}

sub ParseHlsReports {
    my ($joblist) = @_;

    my @resultlist;
    foreach my $task (@$joblist) {
        my %result = (
            job => {
                name => "name",
                path_synt => "path_synt",
                path_impl => "path_synt",
            },
            synt   => {
                LUT    => "LUT",
                BRAM   => "BRAM",
                FF     => "FF",
                DSP    => "DSP",
                II => "PipelineII",
                WorstcaseLatency => "WorstcaseLatency",
                EstimatedClockPeriod => "EstimatedClockPeriod",
            },
            impl   => {
                SLICE  => "SLICE",
                LUT    => "LUT",
                BRAM   => "BRAM",
                FF     => "FF",
                DSP    => "DSP",
                SRL    => "SRL",
                TargetClockPeriod => "TargetClockPeriod",
                AchievedClockPeriod => "AchievedClockPeriod",
            },
            available => {
                LUT    => "LUT",
                BRAM   => "BRAM",
                FF     => "FF",
                DSP    => "DSP",
                SRL    => "SRL",
                TargetClockPeriod => "TargetClockPeriod",
                AchievedClockPeriod => "AchievedClockPeriod",
            },
        );
        $result{job} = $task;
        push @resultlist, \%result;
    }
    pushImplResults(\@resultlist);
    @resultlist
}


##------------------------ search path funtions ------------------------------
# scans the given path and returns a joblist
sub createJobs{
    my ($search_path) = @_;
    #my $search_path = realpath($cwd . "/../sandbox/");

    my @impl_files = sort (File::Find::Rule->file()->name('*_export.xml')->in($search_path));
    #print Dumper(\@impl_files);

    my @joblist;
    foreach my $path_impl (@impl_files) {
        my ($filename, $basename) = fileparse($path_impl, "_export.xml");
        my $path_synt = realpath("$basename/../../../syn/report/" . $filename . "_csynth.xml");
        my $app_name = fileparse(realpath($basename . "../../../../.."));
        my %job = (
            name      => $app_name,
            path_synt => $path_synt,
            path_impl => $path_impl,
        );
        #print Dumper(\%job);
        push @joblist, \%job;
    }
    @joblist
}

sub getResultsInDir {
    my ($search_path) = @_;
    my @joblist   = createJobs($search_path);
    my @results   = ParseHlsReports(\@joblist);
    @results;
}

##------------------------ printing functions ------------------------------
my %tags_impl = (
    # resources (also available)
    NAME   => "App.",
    SLICE  => "SLICE",
    LUT    => "LUT",
    BRAM   => "BRAM",
    FF     => "FF",
    DSP    => "DSP",
    SRL    => "SRL",
    TargetClockPeriod   => "Tclk", #(ns)
    AchievedClockPeriod => "Aclk", #(ns)
    WorstcaseLatency => "WorstcaseLatency",
);

sub formatResult {
    my (@line) = @_;
    my $return = sprintf("%-28s %6s %8s %5s %5s %4s %4s   %5s %12s\n", @line);
    #print $return;
    $return
}
sub formatStringforTexTable {
    my ($word) = @_;
    $word =~ s/_/ /g;
    $word
}
sub formatTexTableRow {
    my (@line) = @_;
    my $return = sprintf("%-28s & %6s & %8s & %5s & %5s & %4s & %4s  & %5s & %12s\\\\\n", @line);
    #print $return;
    formatStringforTexTable($return)
}

sub getResultsArray {
    my ($results) = @_;
    my @return;

    push @return, [$tags_impl{NAME},
                   $tags_impl{BRAM },
                   $tags_impl{SLICE},
                   $tags_impl{LUT  },
                   $tags_impl{FF   },
                   $tags_impl{DSP  },
                   $tags_impl{SRL  },
                  #$tags_impl{TargetClockPeriod  },
                   $tags_impl{AchievedClockPeriod},
                   $tags_impl{WorstcaseLatency},
                  ];

    foreach my $result (@$results) {
        my @a = ( $result->{job}->{name},
                  $result->{impl}->{BRAM },
                  $result->{impl}->{SLICE},
                  $result->{impl}->{LUT  },
                  $result->{impl}->{FF   },
                  $result->{impl}->{DSP  },
                  $result->{impl}->{SRL  },
                 #$result->{impl}->{TargetClockPeriod  },
                  $result->{impl}->{AchievedClockPeriod},
                  $result->{synt}->{WorstcaseLatency},
                );
        push @return, \@a;
    };
    @return;
}

sub listResults {
    my ($results) = @_;
    my @return;

    my @result_array = getResultsArray($results);
    foreach my $result (@result_array) {
        push @return, formatResult(@$result);
    };
    @return;
}
sub listTexTableRows {
    my ($tex_lines) = @_;
    my @return;

    my $numOfcols  = 7;
    my $print_tags  = $tex_lines->{print_tags};
    my $subtitle = $tex_lines->{subtitle};
    my @results  = @{$tex_lines->{results}};

    my @result_array = getResultsArray(\@results);

    #print
    if(not $subtitle eq "") {
        push @return, "& \\multicolumn{" . ($numOfcols - 1) . "}{c}{$subtitle}\\\\ ". "\n";
        push @return, "\\midrule" . "\n";
    }

    if ( $print_tags == 1 ) {
        push @return, formatTexTableRow(@{$result_array[0]});
        push @return, "\\midrule" . "\n";
    }

    for (my $i = 1; $i < $#result_array + 1; $i++) {
        push @return, formatTexTableRow(@{$result_array[$i]});
    }
    push @return, "\\midrule" . "\n";

    @return;
}


sub wrapTexTable {
    my ($tex_table) = @_;
    my @return;

    my $allignment = "lrrrrrrr";
    my $scale      = ".76";
    my $caption    = $tex_table->{caption};
    my $subtitle   = $tex_table->{subtitle};
    my $label      = $tex_table->{label};

    push @return, "\\begin{table}[t]                                                    ". "\n";
    push @return, "  \\centering                                                        ". "\n";
    push @return, "  \\caption{$caption}                                                ". "\n";
    push @return, "  \\vspace{1ex}                                                      ". "\n";
    push @return, "  \\scalebox{$scale}{                                                ". "\n";
    push @return, "     \\begin{tabular}{$allignment}                                   ". "\n";
    push @return, "         \\toprule                                                   ". "\n";

    push @return, @{$tex_table->{lines}};

    pop @return;
    push @return, "         \\bottomrule      " . "\n";
    push @return, "     \\end{tabular}      " . "\n";
    push @return, "  }                   " . "\n";
    push @return, "  \\label{$label}     " . "\n";
    push @return, "\\end{table}          " . "\n";

    @return;
}


##------------------------ example usages  ---------------------------------
# examples
sub getResultsExample {
    my @joblist;

    my %job = (
        name      => "01",
        path_synt => './lambda_185247_csynth.xml',
        path_impl => './lambda_185247_export.xml',
    );
    #print Dumper(\%job);

    push @joblist, \%job;
    push @joblist, \%job;
    ParseHlsReports(\@joblist)
}

# scans the given path and lists the implementation results
sub getImplistExample {
    my ($search_path) = @_;
    my @joblist   = createJobs($search_path);
    my @results   = ParseHlsReports(\@joblist);
    my @list_impl = listResults(\@results);
    @list_impl;
}

# Test Functions
#1.
    #my @results = getResultsExample();
    #print Dumper(@results);
    #print listResults(\@results);
#2.
    #print getImplistExample(realpath($cwd . "/../sandbox/hls_i32"));


##------------------------ PACT 2018  ---------------------------------

sub printImpResultsSeparately {
    my $path = $cwd . "/../sandbox/hls_i32";
    foreach my $keyword ("apps_naive", "coarsening", "border_handling", "max_throughput", "pipelining") {
        my @results = getResultsInDir("$path/$keyword");
        print listResults(\@results);
        print "\n";
    }
}

sub printTexTablesSeparately {
    my $path = $cwd . "/../sandbox/hls_i32";
    foreach my $keyword ("apps_naive", "coarsening", "border_handling", "max_throughput", "pipelining") {
        my @results = getResultsInDir("$path/$keyword");

        my %tex_lines = (
            subtitle => "",
            print_tags => 1,
            results => \@results,
        );
        my @lines = listTexTableRows(\%tex_lines);

        my %tex_table = (
            caption  => formatStringforTexTable($keyword),
            label    => "tab:results_hls_" . $keyword,
            lines       => \@lines,
        );
        print wrapTexTable(\%tex_table);
        print "\n\n"
    }
}

sub printResultsInOneTable {
    my $path = $cwd . "/../sandbox/hls_i32";
    my @lines;
    foreach my $keyword ("apps_naive", "coarsening", "border_handling", "max_throughput", "pipelining") {
        my @results = getResultsInDir("$path/$keyword");

        my %tex_lines = (
            subtitle => formatStringforTexTable($keyword),
            print_tags => 1,
            results => \@results,
        );
        push @lines, listTexTableRows(\%tex_lines);
    }
    my %tex_table = (
          caption  => "Implementation results for Vivado HLS",
          label    => "tab:results_hls",
          lines    => \@lines,
    );
    print wrapTexTable(\%tex_table);
}

sub printHipacc{
    my $path = $cwd;
    my @lines;
    foreach my $keyword ("vivado_gen") { #"halide-hls", 
        my @results = getResultsInDir("$path/$keyword");

        my %tex_lines = (
            subtitle => formatStringforTexTable($keyword),
            print_tags => 1,
            results => \@results,
        );
        push @lines, listTexTableRows(\%tex_lines);
    }
    my %tex_table = (
          caption  => "Implementation results for Vivado HLS",
          label    => "tab:results_hls",
          lines    => \@lines,
    );
    print wrapTexTable(\%tex_table);
}


#printImpResultsSeparately();
#printTexTablesSeparately(); 
#printResultsInOneTable();

printHipacc();


