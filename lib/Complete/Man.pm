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
our @EXPORT_OK = qw(complete_manpage complete_manpage_section);

sub _complete_manpage_or_section {
    require Complete::Util;

    my $which = shift;
    my %args = @_;

    if ($which eq 'section' && $ENV{MANSECT}) {
        return Complete::Util::complete_array_elem(
            word => $args{word},
            array => [split(/\s+/, $ENV{MANSECT})],
        );
    }

    my $sect = $args{section};
    if (defined $sect) {
        $sect = "man$sect" unless $sect =~ /\Aman/;
    }

    return [] unless $ENV{MANPATH};

    require Filename::Compressed;

    my @res;
    my %res;
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
                if ($which eq 'section') {
                    $name =~ /\.(\w+)\z/ and $res{$1}++; # extract section name
                } else {
                    $name =~ s/\.\w+\z//; # strip section name
                    push @res, $name;
                }
            }
        }
    }
    if ($which eq 'section') {
        Complete::Util::complete_hash_key(
            word => $args{word},
            hash => \%res,
        );
    } else {
        Complete::Util::complete_array_elem(
            word => $args{word},
            array => \@res,
        );
    }
}

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
    _complete_manpage_or_section('manpage', @_);
}

$SPEC{complete_manpage_section} = {
    v => 1.1,
    summary => 'Complete from list of available manpage sections',
    description => <<'_',

If `MANSECT` is defined, will use that.

Otherwise, will collect section names by going through each directory in
`MANPATH` environment variable, searching man section directories and man files.

_
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_manpage_section {
    _complete_manpage_or_section('section', @_);
}

1;
#ABSTRACT:

=head1 SYNOPSIS

 use Complete::Man qw(complete_manpage complete_manpage_section);

 my $res = complete_manpage(word => 'gre');
 # -> ['grep', 'grep-changelog', 'greynetic', 'greytiff']

 # only from certain section
 $res = complete_manpage(word => 'gre', section => 1);
 # -> ['grep', 'grep-changelog', 'greytiff']

 # complete section
 $res = complete_manpage_section(word => '3');
 # -> ['3', '3perl', '3pm', '3readline']
