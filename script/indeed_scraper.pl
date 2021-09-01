use strict;
use WWW::Selenium;
use Web::Scraper;
use DBI;

#Database
my $driver = 'SQLite';
my $path_db = './database/indeed_scraper.sqlite';

my $dbh = DBI -> connect("DBI:$driver:dbname=$path_db","","",{ RaiseError => 1 }) or die $DBI::errstr;

my $table_create = qq( CREATE TABLE indeed_scraper ( 
    job_title TEXT,
    company TEXT,
    location TEXT,
    post_date TEXT,
    extract_date TEXT,
    summary TEXT,
    salary TEXT
    ) );

my $exec_create = $dbh -> do($table_create) or die $DBI::errstr;
#######

#Selenium

my $path_to_browser = "";

my $webdriver = WWW::Selenium -> new (
    host => "localhost",
    port => "8080",
    browser => $path_to_browser,
    browser_url => "http://www.google.com" 
);




$webdriver -> stop;
$dbh -> disconnect();
