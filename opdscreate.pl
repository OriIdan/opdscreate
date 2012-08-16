#!/usr/bin/perl

sub CreateCatalog {
	my $dirname = shift;
	my $catalogname = shift;
	my $catalogid = shift;
	my $selflink = shift;
	my $rootlink = shift;
	my $catalogcreator = shift;
	my $acqprefix = shift;
	
	my %meta;
	my $txt;

	my($base, $d) = fileparse($dirname);
	open(FILE, ">$base.xml");
	print FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print FILE "<feed xmlns=\"http://www.w3.org/2005/Atom\" xmlns:dc=\"http://purl.org/dc/terms/\" xmlns:opds=\"http://opds-spec.org/2010/catalog\">\n";
	print FILE "<id>$catalogid</id>\n";
	print FILE "<link rel=\"self\" href=\"$selflink\" type=\"application/atom+xml;profile=opds-catalog;kind=acquisition\"/>\n";
	if($rootlink eq '') {
		$rootlink = $selflink;
	}
	print FILE "<link rel=\"root\" href=\"$rootlink\" type=\"application/atom+xml;profile=opds-catalog;kind=acquisition\"/>\n";
	print FILE "<title>$catalogname</title>\n";
	my $strtime = strftime('%Y-%m-%dT%H:%M:%SZ', localtime);
	print FILE "<updated>$strtime</updated>\n";
	print FILE "<author><name>$catalogcreator</name></author>\n";
	
	# Now the real part, go over each EPUB file in this directory and create an entry according to it's metadata
	require "$basedir/readmeta.pl";
	@files = <*.epub>;
	foreach (@files) {
		print "Reading metadata from file: $_\n";
		
		$epubname = $_;
		%meta = ReadMeta($_);
		print FILE "<entry>\n";
		$txt = $meta{"title"};
		print FILE "<title>$txt</title>\n";
		$txt = $meta{"identifier"};
		print FILE "<id>$txt</id>\n";
		$txt = $meta{"modified"};
		if($txt eq '') {
			$txt = $strtime;
		}
		print FILE "<updated>$txt</updated>\n";
		$txt = $meta{"creator"};
		print FILE "<author><name>$txt</name></author>\n";
		$txt = $meta{"language"};
		print FILE "<dc:language>$txt</dc:language>\n";
		$txt = $meta{"description"};
		print FILE "<summery>\n$txt\n</summery>\n";
		$txt = $meta{"coverimg"};
		print FILE "<link rel=\"http://opds-spec.org/image\" href=\"$txt\" type=\"image/jpeg\">\n";
		print FILE "<link rel=\"http://opds-spec.org/acquisition\" href=\"$acqprefix$epubname\" type=\"application/html\">\n";
		print FILE "</entry>\n";
	}
	print FILE "</feed>\n";
	close(FILE);
}

1;

