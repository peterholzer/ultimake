#!/usr/bin/perl

# usage: find . -iname "*.hpp" -o -name "*.h" -o -iname "*.cpp" -o -iname "*.c"  | xargs ./src2dot.pl | dot -Tpng -o f.png

# use strict;
use warnings;

use File::Basename;

use Getopt::Long;
Getopt::Long::Configure ("bundling");
# use Data::Dumper;   # for '--verbose' debugging output

# my $usage = "Usage: $0 [OPTION...] FILE... [ -o FILE ]\n\n";
my $usage = "Usage: find . -iname '*.hpp' -o -name '*.h' -o -iname '*.cpp' -o -iname '*.c'  | xargs $0 | dot -Tpng -o OUTPUT_FILE\n\n";

my %options = ();
GetOptions(\%options,
           # 'prefix=s',
           'output|o=s',
           'system-headers|s',
           'help|h|?',
           'verbose|v')
or die("Error in command line arguments\n");

foreach my $opt (sort keys %options)
{
    print STDERR "$opt is $options{$opt}.\n";
}

if($options{'help'})
{
    print STDERR "$usage";
    exit(1);
}

# if($options{'system-headers'})
# {
# }

if($options{'output'})
{
    open(STDOUT, "> $options{'output'}");
}


print "digraph g\n{\n";

@extension_list = qw(.c .cpp .h .hpp);

foreach (@ARGV)
{
    my $target = $_;

    print  "    // File: '$target'\n" if $options{'verbose'};

    # TODO: check if file or folder and recursively open any folders for easier usage

    open my $fd, $target or die "Could not open $target: $!";

    print_folder_subgraph($target);
    my ($target_file, $target_dir, $target_ext) = fileparse($target, @extension_list);

    while (<$fd>)
    {
        if( $_ =~ /^\s*#include\s*\"(.*)\"/ )
        # if( $_ =~ /^\s*#include\s*\"(.*)\"/ or
            # $_ =~ /^\s*#include\s*<(.*)>/ )
        {
            my ($prereq_file, $prereq_dir, $prereq_ext) = fileparse($1, @extension_list);

            if ($options{'verbose'})
            {
                print  "    // fileparse('$target') = ('$target_file', '$target_dir')\n";
                print  "    // fileparse('$1') = ('$prereq_file', '$prereq_dir')\n";
            }
            if ($target_ext eq ".h"
             or $target_ext eq ".hpp" )
            {
                print "    \"$target_file\" -> \"$prereq_file\"[penwidth = 2,color=\"#808080\"]\n";
            }
            elsif (($target_ext eq ".c" or $target_ext eq ".cpp") and ($prereq_file ne $target_file))
            {
                print "    \"$target_file\" -> \"$prereq_file\"[penwidth = 1,color=\"#C0C0C0\"]\n";
            }
            else
            {
                # print "    \"$target_file\" -> \"$prereq_file\"[penwidth = 5,color=\"#FF0000\"]\n";
            }

        }
        # include dependencies on system headers
        elsif ( $options{'system-headers'} && $_ =~ /^\s*#include\s*<(.*)>/ )
        {
            print_folder_subgraph2("/usr/include/.../" . $1);
            my ($prereq_file, $prereq_dir) = fileparse($1);
            print "    \"$target_file\" -> \"$prereq_file\"[penwidth = 1,color=\"#C0C0C0\"]\n";
        }

    }
    close $fd;
    print "\n";
}

print "}\n";

exit(0);




sub mangle
{
    my ($name) = @_;
    $name =~ s#/#_#g;
    $name =~ s#-#_#g;
    $name =~ s#\.#_#g;
    return $name;
}

sub print_folder_subgraph
{
    my ($path) = @_;
    my ($file, $dir, $ext) = fileparse($path, @extension_list);
    return if $dir eq "./";
    {

        my $subgraph_name = mangle($dir);
        print(
"    subgraph cluster_$subgraph_name
    {
        label = \"$dir\";
        penwidth = 0;
        style=\"filled\";
        \"$file\"[style=\"filled\",fillcolor=\"#FFFFFF\"];
        fillcolor=\"#F0E0C0\"
    }\n");
    }
}


sub print_folder_subgraph2
{
    my ($path) = @_;
    my ($file, $dir, $ext) = fileparse($path, @extension_list);
    return if $dir eq "./";
    {

        my $subgraph_name = mangle($dir);
        print(
"    subgraph cluster_$subgraph_name
    {
        label = \"$dir\";
        penwidth = 0;
        style=\"filled\";
        \"$file\"[style=\"filled\",fillcolor=\"#FFFFFF\"];
        fillcolor=\"#E0E0F0\"
    }\n");
    }
}


