#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Sys::Hostname;
use Cwd qw(abs_path);
use Data::Dumper;
use File::Basename qw(dirname);
use lib dirname (abs_path $0) . '/../library';
use Utils qw(make_dir checkFile read_config cmd_system trim);

my ($input_path, $output_path, $config, $sample); 

GetOptions (
    'input|i=s' => \$input_path,
    'output|o=s' => \$output_path,
    'config|c=s' => \$config,
    'sample|s=s' => \$sample,
);

my %info;
read_config ($config, \%info);

my $snpeff_input = "$input_path/$sample/$sample.snpeff.isoform.tsv";
my @snpeff_array = read_var($snpeff_input);

my $gene_input = $info{MGB_gene_list};
my @gene_array = read_var($gene_input);
my $gene_list = join '|', @gene_array;

my $rs_input = $info{MGB_rs_list};
my @rs_array = read_var($rs_input);
my $rs_list = join '|', @rs_array;
#my %rs_hash = map{$_ => 1} @rs_array;
#print Dumper (\%rs_hash);

my $clinvar_input = $info{MGB_clinvar_list};
my @clinvar_array = read_var($clinvar_input);
my $clinvar_list = join '|', @clinvar_array;


##1. grep snpeff from gene list
my @snpeff_vs_gene = grep (/$gene_list/, @snpeff_array);
my @snpeff_gene_vs_rs = grep (/$rs_list/, @snpeff_vs_gene);
my @snpeff_gene_rs_vs_clinvar = grep (/$clinvar_list/, @snpeff_gene_vs_rs);

##2. filter from KRGB, Clinvar, Cosmic
my $HG_out = "$output_path/HelloGene_$sample.txt";
my $GS_out = "$output_path/GeneStyle_$sample.txt";

open my $fh_HG, '>', $HG_out or die;
open my $fh_GS, '>', $GS_out or die;

foreach my $line (@snpeff_gene_rs_vs_clinvar){
    my @line_array = split /\t/, $line;
    my $chr = $line_array[0];
    my $rs_id = $line_array[2];
    my $ref = $line_array[3];
    my $alt = $line_array[4];
    my $COSMIC = $line_array[27];
    my $KRG_AF = $line_array[51];
#    print $chr."\n";
#    print $line."\n";
#    print $KRG_AF."\n";
#    print $COSMIC."\n";
    if ($KRG_AF eq "." && $COSMIC eq ".") {
    print $fh_HG "$rs_id,$alt\n";
    print $fh_GS "$rs_id,$alt\n";
    }
}
close $fh_HG;
close $fh_GS;
#foreach my $line (@snpeff_gene_vs_rs) {
#    my @line_array = split /\t/, $line;
#    my $rs_id = $line_array[2];
#    my $ref = $line_array[3];
#    my $alt = $line_array[4];
#    print $fh_HG "$rs_id,$alt\n";
#    print $fh_GS "$rs_id,$alt\n";
#}

#
#foreach (@snpeff_gene_vs_rs) {
#    print "$_\n";
#}

#my %rs_hash;
#while (my $row = <$fh_rs>){
#    chomp $row;
#    if ($row =~ /^#/) {next;}
#    if (length($row) == 0) {next;}
#    my ($rs, $risk, $non_risk) = split /\t/, $row;
#    $rs_hash{$rs}->{risk}=trim($risk);
#    $rs_hash{$rs}->{non_risk}=trim($non_risk);
#}

sub read_var {
    my $file =  shift;
    my @array;
    open my $fh, '<:encoding(UTF-8)', $file or die;
    while (my $row = <$fh>){
        chomp $row;
        if ($row =~ /^#/) {next;}
        $row = trim($row);
        push @array, $row;
    }
    close $fh;
    return @array;
}
