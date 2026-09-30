package builder::MyBuilder;
use strict;
use warnings;

use base "Module::Build";
use Cwd qw(getcwd);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
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

sub _copy_tree {
    my ($source, $destination) = @_;

    my $source_abs = File::Spec->rel2abs($source);
    my $destination_abs = File::Spec->rel2abs($destination);
    mkpath($destination_abs);

    find(
        {
            no_chdir => 1,
            wanted => sub {
                my $path = $File::Find::name;
                return if $path eq $source_abs;

                my $relative = File::Spec->abs2rel($path, $source_abs);
                my $target = File::Spec->catfile($destination_abs, $relative);

                if (-l $path) {
                    my $link = readlink($path);
                    symlink($link, $target)
                        or die "symlink $target: $!";
                }
                elsif (-d _) {
                    mkpath($target);
                }
                elsif (-f _) {
                    mkpath(dirname($target));
                    copy($path, $target)
                        or die "copy $path to $target: $!";
                    chmod((stat($path))[2] & 07777, $target)
                        or die "chmod $target: $!";
                }
            },
        },
        $source_abs,
    );
}

sub _replace_once {
    my ($content, $old, $new, $description) = @_;

    my $offset = index($$content, $old);
    die "cannot apply $description: expected source was not found\n"
        if $offset < 0;
    die "cannot apply $description: expected source is not unique\n"
        if index($$content, $old, $offset + length($old)) >= 0;

    substr($$content, $offset, length($old), $new);
}

sub _apply_discount_patch {
    my $path = File::Spec->catfile($DISCOUNT_BUILD_DIR, "generate.c");

    open my $input, "<", $path or die "open $path: $!";
    local $/;
    my $content = <$input>;
    close $input or die "close $path: $!";

    _replace_once(
        \$content,
        "[MKD_TAGTEXT] = 1,\n"
            . "\t\t\t\t\t\t\t[MKD_ALT_AS_TITLE] = 1",
        "[MKD_TAGTEXT] = 1",
        "MKD_ALT_AS_TITLE image flag fix",
    );
    _replace_once(
        \$content,
        "if ( S(ref->title) || (is_flag_set(&f->flags, MKD_ALT_AS_TITLE) && "
            . "is_flag_set(&tag->flags, MKD_ALT_AS_TITLE)) ) {",
        "if ( S(ref->title) || (image && "
            . "is_flag_set(&f->flags, MKD_ALT_AS_TITLE)) ) {",
        "MKD_ALT_AS_TITLE rendering fix",
    );

    open my $output, ">", $path or die "open $path: $!";
    print {$output} $content or die "write $path: $!";
    close $output or die "close $path: $!";
}

sub _prepare_discount {
    my $self = shift;

    rmtree($DISCOUNT_BUILD_DIR) if -e $DISCOUNT_BUILD_DIR;
    mkpath(File::Spec->catdir("_build"));

    _copy_tree($DISCOUNT_SOURCE_DIR, $DISCOUNT_BUILD_DIR);
    _apply_discount_patch();
    return 1;
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
