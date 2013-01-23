#!/usr/bin/perl
# A perl script to read EPUB file metadata
# This script can be used as a module call subroutine ReadMeta with filename as parameter

$progdir = $0;
if($progdir =~ /readmeta.pl/) {
	$standalone = 1;
}

if($standalone == 1) {
	use utf8;   # Needed for Hebrew
	use Encode;
	use POSIX qw/strftime/;
	use File::Spec::Functions qw(rel2abs);
	use File::Basename;
	use File::Copy;
	use Cwd;
	
	$filename = $ARGV[0];
	if($filename eq '') {
		print "usage: readmeta.pl <epub file>\n";
		exit;
	}	
}

sub ReadMeta {
	my $fname = shift;
	my $state = 0;
	my %meta;

	use File::Temp qw(tempdir);

	$tempdir = tempdir(CLEANUP => 1);
	print "Tempoarary directory: $tempdir\n";
	system("unzip -d $tempdir \"$fname\"");
	# We now have all EPUB files in $tempdir
	# open container.xml to find out OPF file name
	open(HANDLE, "$tempdir/META-INF/container.xml");
	while(<HANDLE>) {
		if(/full-path=(.*?) .*>/) {
			print "OPF name: $1\n";
			$opfname = $1;
			last;
		}
	}
	close(HANDLE);
	if($opfname eq '') {
		print "Error finding OPF file\n";
		exit;
	}
	$opfname =~ s/\"//g;
	# Now the real thing, open OPF file and read metadata from it
	open(HANDLE, "$tempdir/$opfname");
	while(<HANDLE>) {
		if(/<dc:(.*)>(.*)<\/dc:.*>/) {
			$meta{$1} = $2;
			print "meta $1 = $2\n";
		}
		if(/<dc:identifier.*>(.*)<\/dc:.*>/) {
			$meta{"identifier"} = $1;
			print "meta identifier = $1\n";
		}
		if(/<meta property="dcterms:modified">(.*)<\/meta>/) {
			$meta{"modified"} = $1;
			print "meta modified = $1\n";
		}
		if(/<dc:description>(.*)/) {
			if($meta{"description"} eq '') {	# We already have description
				my $description = $1;
				$state = 1;
			}
		}
		if(/id="cover.*href=(.*?) .*media-type="image\/jpeg"/) {
			$coverimg = $1;
			$coverimg =~ s/"//g;
			print "Spliting $fname\n";
			($base, $dirname, $ext) = fileparse($fname, qr/\.[^.]*/);
			copy("$tempdir/OEPBS/$coverimg", "$base.jpg");
			print "Cover image: $base.jpg\n";
			$meta{"coverimg"} = "$base.jpg";
		}
		
		if($state == 1) {	# We are inside description tag
			if(/(.*)<dc:description>/) {
				$description .= $_;
				$state = 0;
			}
			else {
				$description .= $_;
			}
		}		
	}
	close(HANDLE);
	return %meta;
}

if($standalone) {
	my %meta = ReadMeta($filename);
	print %meta;
}

1;

