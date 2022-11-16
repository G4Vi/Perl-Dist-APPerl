#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Pod::LinkCheck::Lite;

Test::Pod::LinkCheck::Lite->new->all_pod_files_ok('.');
done_testing();
