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
sub getWord{
    my ($line, $idx) = @_;

    chomp($line);
    my @words = split(" ", $line);
    my $value = $words[$idx];
    $value =~ s/,//;

    $value
}

sub formatfloat {
    my ($word) = @_;
    sprintf( "%.2f", $word)
}

sub ParseAocReports {
    my ($joblist) = @_;
  
    my @resultlist;
    foreach my $job (@$joblist) {
        my $path_impl = $job->{path_impl};

        if ( -e "$path_impl" ) {
            open my $file, '<', $path_impl or return; #return "Cannot open $path_impl !\n";
            my @lines = <$file>;
            close $file;
            
            my %result = (
                job => $job,  
                impl   => {
                    LOGIC  => "LOGIC",
                    ALUT   => "LUT",
                    FF     => "FF",
                    DSP    => "DSP",
                    RAM    => "RAM",
                    FMAX   => "fMax",
                },
                available => {
                    LOGIC  => "LOGIC",
                    #ALUT   => "ALUT",
                    #FF     => "FF",
                    DSP    => "DSP",
                    RAM    => "RAM",
                },
            );
            $result{impl}{ALUT} = getWord($lines[0], 1);
            $result{impl}{FF}   = getWord($lines[1], 1);
            $result{impl}{LOGIC}= getWord($lines[2], 2);
            $result{impl}{DSP}  = getWord($lines[4], 2);
            $result{impl}{RAM}  = getWord($lines[6], 2);
            $result{impl}{FMAX} = formatfloat(getWord($lines[8], 2));

            $result{available}{LOGIC}= getWord($lines[2], 4);
            $result{available}{DSP}  = getWord($lines[4], 4);
            $result{available}{RAM}  = getWord($lines[6], 4);
            #print Dumper(\%result);
            
            push @resultlist, \%result;
        }
    }
    @resultlist
}


##------------------------ search path funtions ------------------------------
# scans the given path and returns a joblist
sub createJobs{
    my ($search_path) = @_;
    #my $search_path = realpath($cwd . "/../sandbox/");

    my @impl_files = sort (File::Find::Rule->file()->name('acl_quartus_report.txt')->in($search_path));
    #print Dumper(\@impl_files);

    my @joblist;
    foreach my $path_impl (@impl_files) {
        my ($filename, $basename) = fileparse($path_impl);
        #my $app_name = fileparse(realpath($basename . ".."));
        my $app_name = fileparse(realpath($basename . "../.."));
        my %job = (
            name      => "$app_name",
            path_impl => $path_impl,
        );
        #print Dumper(\%job);
        push @joblist, \%job;
    }
    @joblist
}

sub getResultsInDir {
    my ($search_path) = @_;
    my @joblist = createJobs(realpath($search_path));
    my @results = ParseAocReports(\@joblist);
    @results;
}

##------------------------ printing functions ------------------------------
my %tags_impl = (
    # resources (also available)
    name  => "App.",
    LOGIC => "ALM",
    RAM   => "M10K",
    ALUT  => "ALUT",
    FF    => "FF",
    DSP   => "DSP",
    FMAX  => "fMax", #(Hz)
);

sub formatResult {
    my (@line) = @_;
    my $return = sprintf("%-18s %6s %8s   %8s %7s %4s    %6s\n", @line);
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
    my $return = sprintf("%-18s & %6s & %8s  &  %8s & %7s & %4s  &  %6s \\\\\n", @line);
    #print $return;
    formatStringforTexTable($return)
}

sub getResultsArray {
    my ($results) = @_;
    my @return;
    push @return, [$tags_impl{name },
                   $tags_impl{RAM  },
                   $tags_impl{LOGIC},
                   $tags_impl{ALUT },
                   $tags_impl{FF   },
                   $tags_impl{DSP  },
                   $tags_impl{FMAX },
                  ];

    foreach my $result (@$results) {
        my @a = ( $result->{job}->{name},
                  $result->{impl}->{RAM  },
                  $result->{impl}->{LOGIC},
                  $result->{impl}->{ALUT },
                  $result->{impl}->{FF   },
                  $result->{impl}->{DSP  },
                  $result->{impl}->{FMAX },
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
        name      => 'example',
        path_impl => './acl_quartus_report.txt',
    );
    #print Dumper(\%job);

    push @joblist, \%job;
    push @joblist, \%job;
    ParseAocReports(\@joblist)
}

# scans the given path and lists the implementation results
sub getImplistExample {
    my ($search_path) = @_;
    my @joblist   = createJobs($search_path);
    my @results   = ParseAocReports(\@joblist);
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
          caption  => "Implementation results for Altera OpenCL",
          label    => "tab:results_aoc",
          lines    => \@lines,
    );
    print wrapTexTable(\%tex_table);
}
sub printHipacc {
    my $path = $cwd . "/altera_gen";
    my @lines;
    foreach my $keyword ("hipacc_altera") {
        my @results = getResultsInDir("$path/$keyword");

        my %tex_lines = (
            subtitle => formatStringforTexTable($keyword),
            print_tags => 1,
            results => \@results,
        );
        push @lines, listTexTableRows(\%tex_lines);
    }
    my %tex_table = (
          caption  => "Implementation results for Altera OpenCL",
          label    => "tab:results_aoc",
          lines    => \@lines,
    );
    print wrapTexTable(\%tex_table);
}


#printImpResultsSeparately();
#printTexTablesSeparately();
#printResultsInOneTable();

printHipacc();
