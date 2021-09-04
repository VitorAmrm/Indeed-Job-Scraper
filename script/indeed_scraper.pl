use strict;
use Web::Scraper;
use WWW::Mechanize;
use HTML::TreeBuilder;
use DBI;
use Encode;
use URI;

#Database
my $driver = 'SQLite';
my $path_db = './database/indeed_scraper.sqlite';

my $dbh = DBI -> connect("DBI:$driver:dbname=$path_db","","",{ RaiseError => 1 }) or die $DBI::errstr;


my $table_create = qq( CREATE TABLE indeed_scraper ( 
    job_title TEXT,
    company TEXT,
    location TEXT,
    post_date TEXT,
    summary TEXT,
    salary TEXT
    ) );

my $exec_create = $dbh -> do($table_create) or die $DBI::errstr;
#######

#MECHANIZE
my $url = 'https://br.indeed.com/';
my $mech = WWW::Mechanize->new();
my $search = 'mechanize';

my $job = @ARGV[0] or die "Pass a Job";

$mech->get( $url );
$mech->form_number(1);
$mech->field('q',$job);
$mech->click();

#SCRAPER&TreeBuilder


my $start_list = scraper {
    process 'div[class="pagination"] ul li', "btns[]" => scraper {

      process "a", uri => '@href';
    
    };
};
 
my $res = $start_list->scrape( Encode::encode("utf8","$mech->{content}") );


my $save_db = scraper {

    process 'div[class="job_seen_beacon"]',"jobs[]" => scraper {

        process 'h2 span[title]', "job_title" => 'TEXT',
        process 'span[class="companyName"]',"company" => 'TEXT',
        process 'div[class="companyLocation"]', "location" => 'TEXT',
        process 'span[class="date"]',"post_date" => 'TEXT', 
        process 'div[class="job-snippet"]',"summary" => 'TEXT',
        process 'span[class="salary-snippet"]', "salary" => 'TEXT' 
    };
};

my @uris_to_go;
#retirar URI iguais
for my $author (@{$res->{btns}}) {
    push @uris_to_go, $author if !grep{"$_->{uri}" eq "$author->{uri}"}@uris_to_go;
}

my $cont = 0;

for my $uris (@uris_to_go){

    print $cont;
    $cont += 1;

    my $to_go = substr($url,0,-1)."$uris->{uri}"."\n";

    my $content = $save_db -> scrape(URI -> new($to_go));

    for my $jobs (@{$content->{jobs}}){

        my $insert = qq(
            INSERT INTO indeed_scraper ( job_title, company, location, post_date, summary, salary)
            VALUES("$jobs->{job_title}","$jobs->{company}","$jobs->{location}","$jobs->{post_date}","$jobs->{summary}", "$jobs->{salary}")
        );

        my $exec_insert = $dbh -> do ($insert)or die $DBI::errstr;
    };

}


$dbh -> disconnect();
