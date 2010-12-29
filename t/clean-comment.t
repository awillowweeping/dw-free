# -*-perl-*-

use strict;
use Test::More;
plan tests => 10;

use lib "$ENV{LJHOME}/cgi-bin";
require 'ljlib.pl';
use LJ::CleanHTML;

my $orig_comment;
my $clean_comment;

my $clean = sub {
    my $opts = shift;

    LJ::CleanHTML::clean_comment(\$orig_comment, $opts);
};

# remove various positioning and display rules
$orig_comment = qq{<span style="display: none; display:none; display : none; display: inline">};
$clean_comment = qq{<span style="\\s*display: inline\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~ /^$clean_comment$/, "Removed display:none ($orig_comment)");

$orig_comment = qq{<span style="margin-top: 10px;">};
$clean_comment = qq{<span style="\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~ /^$clean_comment$/, "Removed margin ($orig_comment)");

$orig_comment = qq{<span style="height: 150px;">};
$clean_comment = qq{<span style="\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~ /^$clean_comment$/, "Removed height");

# handle unreasonably large padding values
$orig_comment = qq{<span style="padding-top: 9999999px; padding-left: 9999999px; padding-top: 9999999px; padding-bottom: 9999999px"></span>};
$clean_comment = qq{<span style="\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~/^$clean_comment$/, "All padding removed. (Multiple rules, all too large)");

$orig_comment = qq{<span style="padding: 999px 999px 999px 999px"></span>};
$clean_comment = qq{<span style="\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~/^$clean_comment$/, "All padding removed. (Combined into one rule, all too large)");

$orig_comment = qq{<span style="padding-left: 999px; padding-right: 200px;"></span>};
$clean_comment = qq{<span style="\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~/^$clean_comment$/, "All padding removed. (Multiple rules, mixed too large and small enough)");

$orig_comment = qq{<span style="padding: 999px 200px;"></span>};
$clean_comment = qq{<span style="\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~/^$clean_comment$/, "All padding removed. (One dimension in a combined rule, mixed too large and small enough)");

$orig_comment = qq{<span style="padding-top: 200px; padding-left: 200px; padding-right: 150px; padding-bottom: 150px;"></span>};
$clean_comment = qq{<span style="\\s*padding-top: 200px;\\s*padding-left: 200px;\\s*padding-right: 150px;\\s*padding-bottom: 150px;\\s*"><\\/span>};
$clean->({ remove_positioning => 1 });
ok($orig_comment =~ /^$clean_comment$/, "Padding not removed; of reasonable size.");


# remove background urls from logged out users
$orig_comment = qq{<span style="background: url('http://www.example.com/example.gif');"></span>};
$clean_comment = qq{<span style="\\s*background: url\\(&\\#39;http://www.example.com/example.gif&\\#39;\\);\\s*"><\\/span>};
$clean->();
ok($orig_comment =~ /^$clean_comment$/, "Background URL not cleaned: logged-in user");

$orig_comment = qq{<span style="background: url('http://www.example.com/example.gif');"></span>};
$clean_comment = qq{<span style="background:\\s*;\\s*"><\\/span>};
$clean->({ anon_comment => 1 });
ok($orig_comment =~ /^$clean_comment$/, "Background URL removed: anonymous comment");

1;