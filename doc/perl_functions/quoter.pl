#!/usr/bin/perl -w
use Gaim;

$tab = "&nbsp;" x 4;
$nl = "<br>";
$seconds = 30;
$max = 1020;
$command = "fortune -sn " . $max;

%PLUGIN_INFO = (
	perl_api_version => 2,
	name             => "quoter away",
	version          => "1.0",
	summary          => "",
	description      => "random fortune every 30 seconds",
	author           => "Matt Cowell",
	url              => "",
	load             => "plugin_load"
);

sub plugin_init {
    return %PLUGIN_INFO;
}

sub plugin_load {
	$plugin = shift;
	Gaim::timeout_add($plugin, $seconds, \&update_away, "initial");
}

sub update_away {
	do {
		$fortune = `$command`;
		$fortune =~ s/\n/$nl/g;
		$fortune =~ s/\t/$tab/g;
	} until (length($fortune) < $max);

	foreach $id (Gaim::accounts()) {Gaim::Account::set_user_info($id, $fortune);} 
	Gaim::timeout_add($plugin, $seconds, \&update_away, "repeat");
}
