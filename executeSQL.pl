#!/usr/bin/perl
#
################################################################################
#
# executeSQL.pl
# - executes a given SQL statement specified by option s
# - statement can be in a file or entered on command line
# - any parsing or execution errors are trapped and reported via standard
#   ErrorExit routine
#
################################################################################
# Enhancements
#
# 20080213
# - added code to strip trailing semicolon, "quit" and "exit" statements from
#   SQL
#
# 20080930
# - changed options o,p,u to uppercase O,P,U to match t2t
################################################################################

### Make perl complain about sloppy code
use strict;

### Load the DBI, IO and other modules
use DBI;
use Getopt::Std;
use IO::Handle;

### Load CSICommon package
# need following if CSICommon package is not installed in Perl include path
use lib $ENV{UTIL};
use CSICommon;

### Define common script processing variables
my $delim = "\t";
my $err   = false;
my ( $i, $j, $k );
my (%OPT);

# fix problem with log outputting only on exit
autoflush STDOUT 1;

################################################################################
# Option validation
# - See ShowUsage subroutine for explanation of options
################################################################################
if ( getopts( "i:s:DO:P:U:?", \%OPT ) ) { ; }
else {
  $err = true;
  ShowUsage();
}

# option ? reserved for ShowUsage call
# option D reserved for DEBUG mode flag
#
if ( $OPT{"?"} ) {
  ShowUsage();
}

# check option D
if   ( $OPT{D} ) { $debug = true; }
else             { $debug = false; }

# chec for additional identifier option
if ( $OPT{i} ) {

  # reset ME adding identifier if specified
  $ME = "$ME-$OPT{i}";
}

if ( $OPT{s} ) { ; }
else {
  print "ERROR: arg s is required\n";
  $err = true;
}

# check for overriding database, userID, and password
$dbname = $OPT{O} if ( $OPT{O} );

$dbuser = $OPT{U} if ( $OPT{U} );

$dbpass = $OPT{P} if ( $OPT{P} );

# execute ShowUsage subroutine if there are any errors in option validation
ShowUsage() if ( $err == true );

################################################################################
# Mainline
################################################################################
EchoStep("Start of $ME");

# define script specific variables (group as appropriate)
my $subj = "";

# Define Oracle connection variables
my ( %db, $dbh, $sql, $sth );

### Connect to the database, assuming: $dbname, $dbuser, $dbpass
$dbh = DBI->connect(
  "dbi:Oracle:$dbname",
  $dbuser, $dbpass,
  {
    PrintError => 1,    ### Do report errors via warn(  )
    RaiseError => 0     ### Don't report errors via die(  )
  }
);

# The following line is required for strings to work as sql argument with placeholders
$dbh->{ora_ph_type} = 96;

if ( -f $OPT{s} ) {
  if ( open( IN, $OPT{s} ) ) {

    # undefine the end of record character to read in the whole file
    undef $/;
    $sql = <IN>;
    close(IN);

    # restore the end of record character
    $/ = "\n";
  }
}
else {
  $sql = $OPT{s};
}

print "before sub sql: $sql\n" if ($debug);

# remove any terminating semicolon, "quit" or "exit" statement from $sql
$sql =~ s/\nexit[\n]*$//gi;
$sql =~ s/\nquit[\n]*$//gi;
$sql =~ s/;$//g;

print "after sub sql: $sql\n" if ($debug);

if ( $sth = $dbh->prepare($sql) ) {
  if ( $sth->execute() ) { ; }
  else {
    $err  = 2;
    $subj = "$ME - error during execute of SQL";
  }
}
else {
  $err  = 1;
  $subj = "$ME - error during prepare of SQL";
}

# if $err (non-zero value) execute ErrorExit otherwise exit with zero
if ($err) {
  print "error = $DBI::errstr\n" if ($debug);

  # set $MESSAGE used in ErrorExit routine to add to email body
  $MESSAGE = $DBI::errstr;
  ErrorExit($subj);
}
else {
  EchoStep("End of $ME");
  exit(0);
}

################################################################################
# Subfunctions
################################################################################
sub ShowUsage() {
  print qq{
Usage:
  $ME -s _ [-i _] [-O _] [-P _] [-U _] [-D]

  Option               Description
  -------------------  ---------------------------------------------------------
  -i identifier        string to identify this call for error reporting
  -s sql_or_file       sql query or file containing sql query
  -O                   override Oracle database name [$dbname]
  -P                   override password [$dbpass]
  -U                   override user name [$dbuser]
  -D                   turn debug mode on
  \n};
  exit($err);
}
