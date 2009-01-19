use strict;
use Test::More tests => 21;

use lib "./";
use Bootloader::Library;
use Bootloader::Tools;

use Cwd;

$ENV{PERL_BOOTLOADER_TESTSUITE_PATH} = getcwd()."/fake_root1/";

my $lib_ref = Bootloader::Library->new();

ok($lib_ref->SetLoaderType("ppc","iseries"));
$lib_ref->InitializeBootloader(); #this is expected fail, because it check real hardware
my %mount_points = ( '/' => '/dev/sda2' );
ok($lib_ref->DefineMountPoints(\%mount_points));
ok($lib_ref->ReadSettings());


#test globals
my $globals = $lib_ref->GetGlobalSettings();
ok($globals);
is($globals->{'default'},'Linux');
is($globals->{"timeout"},"80");
is($globals->{"activate"},"true");
is($globals->{"boot_iseries_custom"},"/dev/sda2");

#test sections
my @sections = @{$lib_ref->GetSections()};
ok(@sections);
foreach my $section (@sections) {
  if ( $section->{'original_name'} eq "linux" ){
    is( $section->{'type'}, 'image' );
    is( $section->{'image'}, '/boot/vmlinux-2.6.25.4-10-default' );
    is( $section->{'initrd'}, '/boot/initrd-2.6.25.4-10-default' );
    is( $section->{'name'}, 'Linux' );
    ok( not defined $section->{'vgamode'} );
    is( $section->{'append'}, ' quiet sysrq=1' );
    ok( not exists $section->{'console'} );
    ok( $section->{'optional'});
    $section->{'__modified'} = 1;
  } 
}



ok($lib_ref->SetSections(\@sections));
ok($lib_ref->WriteSettings());
ok($lib_ref->UpdateBootloader(1));

my $res = qx:grep -c "optional" ./fake_root1/etc/lilo.conf:;
chomp($res);
is( $res, 1); #test correct created xen append

Bootloader::Tools::DumpLog( $lib_ref );
