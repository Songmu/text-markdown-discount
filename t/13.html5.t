use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use Text::Markdown::Discount;

my $html = '<article>abc</article>';
{
    my $md = Text::Markdown::Discount->new;
    is trim($md->markdown($html)), '<p><article>abc</article></p>';
}

{
    my $md = Text::Markdown::Discount->new(html5 => 1);
    is trim($md->markdown($html)), '<article>abc</article>';
}

sub trim {
    my $text = shift;
    $text =~ s/\A\s+//ms;
    $text =~ s/\s+$//ms;
    $text;
}
