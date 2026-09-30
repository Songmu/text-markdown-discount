package builder::MyBuilder;
use strict;
use warnings;

use base "Module::Build";
use Cwd qw(getcwd);
use File::Path qw(mkpath rmtree);
use File::Spec;

my $DISCOUNT_VERSION = "3.0.2.0";
my $DISCOUNT_SOURCE_DIR = "discount-$DISCOUNT_VERSION";
my $DISCOUNT_BUILD_DIR = File::Spec->catdir("_build", "discount-$DISCOUNT_VERSION");
my $DISCOUNT_PATCH = File::Spec->catfile(
    "patches",
    "discount-$DISCOUNT_VERSION-alt-as-title.patch",
);

sub new {
    my ($class, %argv) = @_;

    $class->SUPER::new(
        %argv,
        needs_compiler => 1,
        include_dirs => [$DISCOUNT_BUILD_DIR],
    );
}

sub _prepare_discount {
    my $self = shift;

    rmtree($DISCOUNT_BUILD_DIR) if -e $DISCOUNT_BUILD_DIR;
    mkpath(File::Spec->catdir("_build"));

    $self->do_system("cp", "-R", $DISCOUNT_SOURCE_DIR, $DISCOUNT_BUILD_DIR)
        or return;
    $self->do_system(
        "patch",
        "-d", $DISCOUNT_BUILD_DIR,
        "-p1",
        "-i", File::Spec->rel2abs($DISCOUNT_PATCH),
    );
}

sub _build_discount {
    my $self = shift;

    $self->_prepare_discount or return;

    my $cwd = getcwd();
    chdir $DISCOUNT_BUILD_DIR or die "chdir $DISCOUNT_BUILD_DIR: $!";
    my $ok = do {
        local $ENV{CC} = $self->config("cc") . " -fPIC";
        $self->do_system("sh", "configure.sh");
    };
    $ok &&= $self->do_system($self->config("make"), "clean");
    $ok &&= $self->do_system($self->config("make"), "libmarkdown");
    chdir $cwd or die "chdir $cwd: $!";
    $ok;
}

sub ACTION_code {
    my ($self, @argv) = @_;

    my $spec = $self->_infer_xs_spec(File::Spec->catfile("lib", "Text", "Markdown", "Discount.xs"));
    my $archive = File::Spec->catfile($DISCOUNT_BUILD_DIR, "libmarkdown.a");
    my @sources = (
        __FILE__,
        $DISCOUNT_PATCH,
        grep { -f } glob(File::Spec->catfile($DISCOUNT_SOURCE_DIR, "*")),
    );
    if (!$self->up_to_date(\@sources, $archive)) {
        $self->_build_discount or die;
    }
    push @{$self->{properties}{objects}}, $archive;
    $self->SUPER::ACTION_code(@argv);
}

1;
