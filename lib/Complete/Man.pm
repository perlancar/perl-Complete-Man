package Complete::Man;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_manpage);

$SPEC{complete_manpage} = {
    v => 1.1,
    summary => 'Complete from list of available manpages',
    description => <<'_',

For each directory in `MANPATH` environment variable, search man section
directories and man files.

_
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        section => {
            summary => 'Only search from this section',
            schema  => 'str*',
        },
    },
    result_naked => 1,
};
sub complete_manpage {
    require Complete::Util;
    require Filename::Compressed;

    my %args = @_;

    my $sect = $args{section};
    if (defined $sect) {
        $sect = "man$sect" unless $sect =~ /\Aman/;
    }

    return [] unless $ENV{MANPATH};

    my @res;
    for my $dir (split /:/, $ENV{MANPATH}) {
        next unless -d $dir;
        opendir my($dh), $dir or next;
        for my $sectdir (readdir $dh) {
            next unless $sectdir =~ /\Aman/;
            next if $sect && $sect ne $sectdir;
            opendir my($dh), "$dir/$sectdir" or next;
            my @files = readdir($dh);
            for my $file (@files) {
                next if $file eq '.' || $file eq '..';
                my $chkres = Filename::Compressed::check_compressed_filename(
                    filename => $file,
                );
                my $name = $chkres ? $chkres->{uncompressed_filename} : $file;
                $name =~ s/\.\w+\z//; # strip section name
                push @res, $name;
            }
        }
    }
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => \@res,
    );
}

1;
#ABSTRACT:

=head1 SYNOPSIS

 use Complete::Man qw(complete_manpage);

 my $res = complete_manpage(word => 'gre');
 # -> ['grep', 'grep-changelog', 'greynetic', 'greytiff']

 # only from certain section
 $res = complete_manpage(word => 'gre', section => 1);
 # -> ['grep', 'grep-changelog', 'greytiff']
