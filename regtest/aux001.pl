#!/usr/bin/perl -w

use Getopt::Long;

sub require_file {die ("MY ERROR\n" );}

sub parse_opts
{
  my %param;

  eval
  {
    local $SIG{ __WARN__ } = sub { die $_[0] };

    print STDERR ("Failed!\n") unless
      GetOptions( 'require=s', \&require_file );
  };

  die $@ if $@;

}

@ARGV = qw(--require xx);

eval {
    parse_opts();
};
die ("Fail ", __FILE__, "\n") unless $@ =~ /^MY ERROR/;

__END__
From: Diab Jerius <dj@head-cfa.harvard.edu>
To: jvromans@squirrel.nl
Subject: Getopt::Long and localization of $@ during callbacks
Date: Wed, 24 Apr 2002 12:41:31 -0400 (EDT)

Hi,

I often wrap calls to GetOpt::Long with code like this:

=============

  eval
  {
    local $SIG{ __WARN__ } = sub { die $_[0] };

    GetOptions( ... );

  };

  die $@ if $@;

=============

I do this because GetOptions uses warn() to print out error messages
and I need to present those to the user in a manner other than having
things written directly to STDERR.

This has worked well, until I came up with code like this:

=============

sub require_file {die ("MY ERROR\n" );}

sub parse_opts
{
  my %param;

  eval
  {
    local $SIG{ __WARN__ } = sub { die $_[0] };

    GetOptions( 'require=s', \&require_file );
  };

  die $@ if $@;

}

=============

This unfortunately does not work, because GetOptions localizes
$@ before invoking the callback, causing the $@ generated by the die
in the signal handler to be reset before escaping out of my eval.

=============
  local ($@);
    eval {
        &{$linkage{$opt}}($opt, $arg);
    };
    print STDERR ("=> die($@)\n") if $debug && $@ ne '';
    if ( $@ =~ /^!/ ) {
        if ( $@ =~ /^!FINISH\b/ ) {
            $goon = 0;
        }
    }
    elsif ( $@ ne '' ) {
        warn ($@);
        $error++;
    }
=============

I believe the following changes will make the warn behavior consistent
and will preserve your intent to protect the global $@:

=============
  my $_eval_error;
  {
  local ($@);
    eval {
        &{$linkage{$opt}}($opt, $arg);
    };
    $_eval_error = $@;
  }
    print STDERR ("=> die($_eval_error)\n") if $debug && $_eval_error ne '';
    if ( $_eval_error =~ /^!/ ) {
        if ( $_eval_error =~ /^!FINISH\b/ ) {
            $goon = 0;
        }
    }
    elsif ( $_eval_error ne '' ) {
        warn ($_eval_error);
        $error++;
    }
=============

Would you consider making this change? There are two places in the code
which would require alteration: the above CODE linkage and the
non-options call-back.

Thanks,
Diab

P.S. Here's a fairly short snippet illustrating what's going on.
Commenting out the local $@ line causes the error propagation to work.

=============

eval {
  local $SIG{ __WARN__ } = sub { die $_[0]; };

  local $@;
  eval { die ("My Error") };
  warn $@ if $@ ne '';
};

die $@ if $@;

---
Diab Jerius                       Harvard-Smithsonian Center for Astrophysics
                                  60 Garden St, MS 70, Cambridge MA 02138 USA
djerius@cfa.harvard.edu           vox: 617 496 7575         fax: 617 495 7356
