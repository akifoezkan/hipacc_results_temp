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
    sprintf( "%.3f", $word)
}

sub getWord{
    my ($line, $idx) = @_;

    chomp($line);
    my @words = split(" ", $line);
    my $value = $words[$idx];
    $value =~ s/,//;

    formatfloat($value)
}

sub ParseTimingReports {
    my ($joblist) = @_;
  
    my @resultlist;
    foreach my $job (@$joblist) {
        my $path = $job->{path};

        if ( -e "$path" ) {
            my %keywords = (
                kernel_timing => "Timing",
                host_timing   => "End-to-End",
                device_timing => "Total timing",
            );
            my %lines = (
                kernel_timing => "",
                host_timing   => "",
                device_timing => "",
            );
            my %report = (
                job => $job,
                kernel_timing => { median => "", minimum => "", maximum => ""},
                host_timing   => { median => "", minimum => "", maximum => ""},
                device_timing => { cpu    => "", gpu     => "", fpga    => ""},
            );

            open my $file, '<', $path or return;
            while(<$file>) {
                $lines{kernel_timing} = $_ if /\b$keywords{kernel_timing}\b/;
                $lines{host_timing  } = $_ if /\b$keywords{host_timing  }\b/;
                $lines{device_timing} = $_ if /\b$keywords{device_timing}\b/;
            }
            close $file;

            $report{kernel_timing}{median } = getWord($lines{kernel_timing}, 1); 
            $report{kernel_timing}{minimum} = getWord($lines{kernel_timing}, 3);
            $report{kernel_timing}{maximum} = getWord($lines{kernel_timing}, 5);

            $report{host_timing}{median } = getWord($lines{host_timing}, 3); 
            $report{host_timing}{minimum} = getWord($lines{host_timing}, 5);
            $report{host_timing}{maximum} = getWord($lines{host_timing}, 7);

            $report{device_timing}{cpu } = getWord($lines{device_timing}, 8); 
            $report{device_timing}{gpu } = getWord($lines{device_timing}, 10);
            $report{device_timing}{fpga} = getWord($lines{device_timing}, 12);
            
            push @resultlist, \%report;
        }
    }
    @resultlist
}


##------------------------ search path funtions ------------------------------
# scans the given path and returns a joblist
sub createJobs{
    my ($search_path) = @_;
    #my $search_path = realpath($cwd . "/../sandbox/");

    my @impl_files = sort (File::Find::Rule->file()->name('run_app.log')->in($search_path));
    #print Dumper(\@impl_files);

    my @joblist;
    foreach my $path (@impl_files) {
        my ($filename, $basename) = fileparse($path);
        my $app_name = fileparse(realpath($basename));
        my %job = (
            name => "$app_name",
            path => $path,
        );
        #print Dumper(\%job);
        push @joblist, \%job;
    }
    @joblist
}

sub getResultsInDir {
    my ($search_path) = @_;
    my @joblist = createJobs(realpath($search_path));
    my @results = ParseTimingReports(\@joblist);
    @results;
}

##------------------------ printing functions ------------------------------
my %tags_timing = (
    # resources (also available)
    name  => "App.",
    kernel_median  => "median",
    kernel_minimum => "minimum",
    kernel_maximum => "maximum",
    host_median    => "h. med",
    host_minimum   => "h. min",
    host_maximum   => "h. max",
    cpu   => "cpu",
    gpu   => "gpu",
    fpga  => "fpg",
);

sub formatResult {
    my (@line) = @_;
    my $return = sprintf("%-18s   %8s   %8s   %8s     %8s   %8s   %8s \n", @line);
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
    my $return = sprintf("%-18s & %8s & %8s & %8s  &  %8s & %8s & %8s \\\\\n", @line);
    #print $return;
    formatStringforTexTable($return)
}

sub getResultsArray {
    my ($results) = @_;
    my @return;
    push @return, [ $tags_timing{name},
                    $tags_timing{kernel_median },
                    $tags_timing{kernel_minimum},
                    $tags_timing{kernel_maximum},
                    $tags_timing{host_median   },
                    $tags_timing{host_minimum  },
                    $tags_timing{host_maximum  },
                  ];

    foreach my $result (@$results) {
        my @a = ( $result->{job }->{name},
                  $result->{kernel_timing}->{median },
                  $result->{kernel_timing}->{minimum},
                  $result->{kernel_timing}->{maximum},
                  $result->{host_timing}->{median },
                  $result->{host_timing}->{minimum},
                  $result->{host_timing}->{maximum},
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

    my $allignment = "lrrrrrr";
    my $scale      = ".65";
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
        name => 'example',
        path => './run_app.log',
    );
    #print Dumper(\%job);

    #push @joblist, \%job;
    push @joblist, \%job;
    ParseTimingReports(\@joblist)
}

# scans the given path and lists the implementation results
sub getImplistExample {
    my ($search_path) = @_;
    my @joblist   = createJobs($search_path);
    my @results   = ParseTimingReports(\@joblist);
    #print Dumper(@results);
    my @list_impl = listResults(\@results);
    @list_impl;
}

# Test Functions
#1.
    #my @results = getResultsExample();
    #print Dumper(@results);
    #print listResults(\@results);
#2.
    #print getImplistExample(realpath($cwd . "/../sandbox/aocl_i32/"));


##------------------------ PACT 2018  ---------------------------------

sub printImpResultsSeparately {
    my $path = $cwd . "/../sandbox/aocl_i32";
    foreach my $keyword ("apps_naive", "coarsening", "border_handling", "max_throughput", "pipelining") {
        my @results = getResultsInDir("$path/$keyword");
        print listResults(\@results);
        print "\n";
    }
}

sub printTexTablesSeparately {
    my $path = $cwd . "/../sandbox/aocl_i32";
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
            label    => "tab:results_aoc_" . $keyword,
            lines       => \@lines,
        );
        print wrapTexTable(\%tex_table);
        print "\n\n"
    }
}

sub printResultsInOneTable {
    my $path = $cwd . "/../sandbox/aocl_i32";
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
          caption  => "Timing results for Altera OpenCL",
          label    => "tab:results_aoc",
          lines    => \@lines,
    );
    print wrapTexTable(\%tex_table);
}


#printImpResultsSeparately();
#printTexTablesSeparately();
printResultsInOneTable();
