#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use HTML::Entities;
use v5.10;

sub usage {
    say qq{Usage: $0 gittag path-to-bin path-to-gitrepo

This script assumes a bitcoind instance is running in regtest mode.
Example: ./_tools/rpcdoc.pl v0.11I ../bitcoin-xt-0.11.0-I/bin ../bitcoinxt > ./doc/rpc_xxx.html"
};
    exit 1;
};

my $TAG = shift or usage();
my $BIN_PATH = shift or usage();
my $SRC_ROOT_PATH = shift or usage();

my $BITCOIN_CLI_CMD = "$BIN_PATH/bitcoin-cli -regtest=1 -testnet=0";
my $GIT_CMD = "git -C $SRC_ROOT_PATH/qa/rpc-tests";
my $QA_URL = "https://github.com/bitcoinxt/bitcoinxt/tree/$TAG/qa/rpc-tests";

sub parse_help {
    my $helpstr = shift or die;

    my @categories;
    my %cmds;
    my $category = q{};

    for my $l (split "\n", $helpstr) {
        if ($l =~ /^==/) {
            # it's a category

            # remove '==' prefix/suffix
            ($category) = $l =~ /== (.*?) ==/;
            push @categories, $category;
            next;
        }
        # remove args, we just want the commands.
        ($l) = $l =~ /(^[a-z_]+)/;
        next unless $l and $l ne q{};
        push @{$cmds{$category}}, $l;
    }
    return \@categories, \%cmds;
}

# Call bitcoin-cli, return the results
sub run_cli {
    my @args = @_;
    die "args missing"
        unless scalar @args;

    my $cmd = "$BITCOIN_CLI_CMD " . join(q{ }, @args);
    my $res = `$cmd` or die "failed to run '$cmd'";
    return $res;
}

# Runs git grep on rpc-tests directory to look for uses of command.
sub find_examples_as_html {
    my $command = shift;
    my $cmd = "$GIT_CMD grep -n '\\.\Q$command\E\('";
    my $res = `$cmd`;
    return "" unless $res;

    my $s = qq{<div class="toc_container"><p class="toc_title">Examples from test suite</p><ul>};
    for my $l (split "\n", $res) {
        my $regex = qr{(.*?):([0-9]+):\s*(.*)};
        my ($file, $line, $code) = $l =~ $regex;
        my $url = "$QA_URL/$file#L$line";
        $s .= qq{<li class="rpcexample"><a href="$url">$file:$line</a>&nbsp;};
        $s .= encode_entities($code) . "</li>";
    }
    $s .= "</ul></div>";
    return $s;
}

# Fetch descriptions and examples for command
sub cmd_to_html {
    my $cmd = shift
        or die "command missing";

    my $s = qq{<section><div><h3 id="$cmd">$cmd</h3>};
    $s .= "<pre>" . encode_entities(run_cli("help", $cmd)) . "</pre>";
    $s .= find_examples_as_html($cmd);
    $s .= qq{</div></section>};
    return $s;
}

sub category_to_html {
    my ($cat, $cmds) = @_;
    my $s = qq{
    <section><div>
        <h2 id="$cat">$cat</h2>
    </div></section>};

    for my $c (@{$cmds}) {
        $s .= cmd_to_html($c);
    }
    return $s;
}

sub table_of_contents {
    my ($categories, $cmds) = @_;
    my $s = qq{<section><div class="toc_container"><p class="toc_title">Contents</p><ul id="toc_container">};
    for my $cat (@${categories}) {
        $s .= qq{<li style="margin: 0;"><a href="#$cat"><em>$cat</em></a>};

        $s .= qq{<ul>};
        for my $cmd (@{$cmds->{$cat}}) {
            $s .= qq{<li style="margin: 0;"><a href="#$cmd">$cmd</a></li>};
        }
        $s .= qq{</li></ul>};
    }
    $s .= "</ul></div></section>";
    return $s;
}

my ($categories, $cmds) = parse_help(run_cli("help"));

# remove v prefix
my ($version) = $TAG =~ /^v(.*)/;
# Add main section
my $doc = qq{
<div class="main" id="doc">
<section><div>
<h1>Bitcoin XT $version RPC Reference - Bitcoin Cash</h1><p>
This is a developer reference to the Bitcoin XT RPC interface.
The categories and methods are listed in the same order as when calling bitcoin-cli help.
Each method is linked to its use in the Bitcoin XT RPC test set to serve as real use examples.</p>
</div></section>};

$doc .= table_of_contents($categories, $cmds);
for my $c (@{$categories}) {
    $doc .= category_to_html($c, $cmds->{$c});
}

$doc .= "</div>"; # end main

# add our layout
$doc = qq{---
layout: "base"
title: "Bitcoin XT $version RPC Reference"
description: "Developer reference for Bitcoin XT RPC interface"
---
} . $doc;

say $doc;
