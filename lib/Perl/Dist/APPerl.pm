package Perl::Dist::APPerl;
# Copyright (c) 2022 Gavin Hayes, see LICENSE in the root of the project
use version; our $VERSION = version->declare("v0.0.1");
use strict;
use warnings;
use JSON::PP qw(decode_json);
use File::Path qw(make_path);
use Cwd qw(abs_path getcwd);
use Data::Dumper qw(Dumper);
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use FindBin qw();
use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure qw(gnu_getopt);

use constant {
    SITE_CONFIG_DIR  => (($ENV{XDG_CONFIG_HOME} // ($ENV{HOME}.'/.config')).'/apperl'),
    PROJECT_FILE => 'apperl-project.json',
    START_WD => getcwd(),
    PROJECT_TMP_DIR => abs_path('.apperl')
};
use constant {
    SITE_CONFIG_FILE => (SITE_CONFIG_DIR."/site.json"),
    PROJECT_TMP_CONFIG_FILE => (PROJECT_TMP_DIR.'/user-project.json')
};

sub _load_apperl_configs {

# https://packages.debian.org/experimental/amd64/perl-base/filelist with tweaks
my @smallmanifest = (
    'lib/perl5/5.36.0/AutoLoader.pm',
    'lib/perl5/5.36.0/Carp.pm',
    'lib/perl5/5.36.0/Carp/Heavy.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Config.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Config_git.pl',
    'lib/perl5/5.36.0/x86_64-cosmo/Config_heavy.pl',
    'lib/perl5/5.36.0/x86_64-cosmo/Cwd.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/DynaLoader.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Errno.pm',
    'lib/perl5/5.36.0/Exporter.pm',
    'lib/perl5/5.36.0/Exporter/Heavy.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Fcntl.pm',
    'lib/perl5/5.36.0/File/Basename.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/File/Glob.pm',
    'lib/perl5/5.36.0/File/Path.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/File/Spec.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/File/Spec/Unix.pm',
    'lib/perl5/5.36.0/File/Temp.pm',
    'lib/perl5/5.36.0/FileHandle.pm',
    'lib/perl5/5.36.0/Getopt/Long.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Hash/Util.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/File.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Handle.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Pipe.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Seekable.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Select.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Socket.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Socket/INET.pm',
    'lib/perl5/5.36.0/IO/Socket/IP.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/IO/Socket/UNIX.pm',
    'lib/perl5/5.36.0/IPC/Open2.pm',
    'lib/perl5/5.36.0/IPC/Open3.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/List/Util.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/POSIX.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Scalar/Util.pm',
    'lib/perl5/5.36.0/SelectSaver.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/Socket.pm',
    'lib/perl5/5.36.0/Symbol.pm',
    'lib/perl5/5.36.0/Text/ParseWords.pm',
    'lib/perl5/5.36.0/Text/Tabs.pm',
    'lib/perl5/5.36.0/Text/Wrap.pm',
    'lib/perl5/5.36.0/Tie/Hash.pm',
    'lib/perl5/5.36.0/XSLoader.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/attributes.pm',
    'lib/perl5/5.36.0/base.pm',
    'lib/perl5/5.36.0/builtin.pm',
    'lib/perl5/5.36.0/bytes.pm',
    'lib/perl5/5.36.0/bytes_heavy.pl',
    'lib/perl5/5.36.0/constant.pm',
    'lib/perl5/5.36.0/feature.pm',
    'lib/perl5/5.36.0/fields.pm',
    'lib/perl5/5.36.0/integer.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/lib.pm',
    'lib/perl5/5.36.0/locale.pm',
    'lib/perl5/5.36.0/overload.pm',
    'lib/perl5/5.36.0/overloading.pm',
    'lib/perl5/5.36.0/parent.pm',
    'lib/perl5/5.36.0/x86_64-cosmo/re.pm',
    'lib/perl5/5.36.0/strict.pm',
    'lib/perl5/5.36.0/unicore/To/Age.pl',
    'lib/perl5/5.36.0/unicore/To/Bc.pl',
    'lib/perl5/5.36.0/unicore/To/Bmg.pl',
    'lib/perl5/5.36.0/unicore/To/Bpb.pl',
    'lib/perl5/5.36.0/unicore/To/Bpt.pl',
    'lib/perl5/5.36.0/unicore/To/Cf.pl',
    'lib/perl5/5.36.0/unicore/To/Ea.pl',
    'lib/perl5/5.36.0/unicore/To/EqUIdeo.pl',
    'lib/perl5/5.36.0/unicore/To/GCB.pl',
    'lib/perl5/5.36.0/unicore/To/Gc.pl',
    'lib/perl5/5.36.0/unicore/To/Hst.pl',
    'lib/perl5/5.36.0/unicore/To/Identif2.pl',
    'lib/perl5/5.36.0/unicore/To/Identifi.pl',
    'lib/perl5/5.36.0/unicore/To/InPC.pl',
    'lib/perl5/5.36.0/unicore/To/InSC.pl',
    'lib/perl5/5.36.0/unicore/To/Isc.pl',
    'lib/perl5/5.36.0/unicore/To/Jg.pl',
    'lib/perl5/5.36.0/unicore/To/Jt.pl',
    'lib/perl5/5.36.0/unicore/To/Lb.pl',
    'lib/perl5/5.36.0/unicore/To/Lc.pl',
    'lib/perl5/5.36.0/unicore/To/NFCQC.pl',
    'lib/perl5/5.36.0/unicore/To/NFDQC.pl',
    'lib/perl5/5.36.0/unicore/To/NFKCCF.pl',
    'lib/perl5/5.36.0/unicore/To/NFKCQC.pl',
    'lib/perl5/5.36.0/unicore/To/NFKDQC.pl',
    'lib/perl5/5.36.0/unicore/To/Na1.pl',
    'lib/perl5/5.36.0/unicore/To/NameAlia.pl',
    'lib/perl5/5.36.0/unicore/To/Nt.pl',
    'lib/perl5/5.36.0/unicore/To/Nv.pl',
    'lib/perl5/5.36.0/unicore/To/PerlDeci.pl',
    'lib/perl5/5.36.0/unicore/To/SB.pl',
    'lib/perl5/5.36.0/unicore/To/Sc.pl',
    'lib/perl5/5.36.0/unicore/To/Scx.pl',
    'lib/perl5/5.36.0/unicore/To/Tc.pl',
    'lib/perl5/5.36.0/unicore/To/Uc.pl',
    'lib/perl5/5.36.0/unicore/To/Vo.pl',
    'lib/perl5/5.36.0/unicore/To/WB.pl',
    'lib/perl5/5.36.0/unicore/To/_PerlLB.pl',
    'lib/perl5/5.36.0/unicore/To/_PerlSCX.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/NA.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V100.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V11.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V110.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V120.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V130.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V140.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V20.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V30.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V31.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V32.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V40.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V41.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V50.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V51.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V52.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V60.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V61.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V70.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V80.pl',
    'lib/perl5/5.36.0/unicore/lib/Age/V90.pl',
    'lib/perl5/5.36.0/unicore/lib/Alpha/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/AL.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/AN.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/B.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/BN.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/CS.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/EN.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/ES.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/ET.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/L.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/NSM.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/ON.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/R.pl',
    'lib/perl5/5.36.0/unicore/lib/Bc/WS.pl',
    'lib/perl5/5.36.0/unicore/lib/BidiC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/BidiM/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Blk/NB.pl',
    'lib/perl5/5.36.0/unicore/lib/Bpt/C.pl',
    'lib/perl5/5.36.0/unicore/lib/Bpt/N.pl',
    'lib/perl5/5.36.0/unicore/lib/Bpt/O.pl',
    'lib/perl5/5.36.0/unicore/lib/CE/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CI/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CWCF/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CWCM/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CWKCF/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CWL/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CWT/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/CWU/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Cased/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/A.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/AL.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/AR.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/ATAR.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/B.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/BR.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/DB.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/NK.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/NR.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/OV.pl',
    'lib/perl5/5.36.0/unicore/lib/Ccc/VR.pl',
    'lib/perl5/5.36.0/unicore/lib/CompEx/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/DI/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Dash/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Dep/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Dia/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Com.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Enc.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Fin.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Font.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Init.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Iso.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Med.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Nar.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Nb.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/NonCanon.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Sqr.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Sub.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Sup.pl',
    'lib/perl5/5.36.0/unicore/lib/Dt/Vert.pl',
    'lib/perl5/5.36.0/unicore/lib/EBase/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/EComp/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/EPres/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Ea/A.pl',
    'lib/perl5/5.36.0/unicore/lib/Ea/H.pl',
    'lib/perl5/5.36.0/unicore/lib/Ea/N.pl',
    'lib/perl5/5.36.0/unicore/lib/Ea/Na.pl',
    'lib/perl5/5.36.0/unicore/lib/Ea/W.pl',
    'lib/perl5/5.36.0/unicore/lib/Emoji/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Ext/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/ExtPict/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/CN.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/EX.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/LV.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/LVT.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/PP.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/SM.pl',
    'lib/perl5/5.36.0/unicore/lib/GCB/XX.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/C.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Cf.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Cn.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/L.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/LC.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Ll.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Lm.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Lo.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Lu.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/M.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Mc.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Me.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Mn.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/N.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Nd.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Nl.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/No.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/P.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Pc.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Pd.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Pe.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Pf.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Pi.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Po.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Ps.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/S.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Sc.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Sk.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Sm.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/So.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Z.pl',
    'lib/perl5/5.36.0/unicore/lib/Gc/Zs.pl',
    'lib/perl5/5.36.0/unicore/lib/GrBase/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/GrExt/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Hex/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Hst/NA.pl',
    'lib/perl5/5.36.0/unicore/lib/Hyphen/T.pl',
    'lib/perl5/5.36.0/unicore/lib/IDC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/IDS/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/IdStatus/Allowed.pl',
    'lib/perl5/5.36.0/unicore/lib/IdStatus/Restrict.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/DefaultI.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/Exclusio.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/Inclusio.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/LimitedU.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/NotChara.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/NotNFKC.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/NotXID.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/Obsolete.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/Recommen.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/Technica.pl',
    'lib/perl5/5.36.0/unicore/lib/IdType/Uncommon.pl',
    'lib/perl5/5.36.0/unicore/lib/Ideo/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/In/10_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/11_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/12_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/12_1.pl',
    'lib/perl5/5.36.0/unicore/lib/In/13_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/14_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/2_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/2_1.pl',
    'lib/perl5/5.36.0/unicore/lib/In/3_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/3_1.pl',
    'lib/perl5/5.36.0/unicore/lib/In/3_2.pl',
    'lib/perl5/5.36.0/unicore/lib/In/4_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/4_1.pl',
    'lib/perl5/5.36.0/unicore/lib/In/5_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/5_1.pl',
    'lib/perl5/5.36.0/unicore/lib/In/5_2.pl',
    'lib/perl5/5.36.0/unicore/lib/In/6_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/6_1.pl',
    'lib/perl5/5.36.0/unicore/lib/In/6_2.pl',
    'lib/perl5/5.36.0/unicore/lib/In/6_3.pl',
    'lib/perl5/5.36.0/unicore/lib/In/7_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/8_0.pl',
    'lib/perl5/5.36.0/unicore/lib/In/9_0.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/Bottom.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/BottomAn.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/Left.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/LeftAndR.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/NA.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/Overstru.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/Right.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/Top.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/TopAndBo.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/TopAndL2.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/TopAndLe.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/TopAndRi.pl',
    'lib/perl5/5.36.0/unicore/lib/InPC/VisualOr.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Avagraha.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Bindu.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Cantilla.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona2.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona3.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona4.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona5.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona6.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona7.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consona8.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Consonan.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Invisibl.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Nukta.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Number.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Other.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/PureKill.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Syllable.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/ToneMark.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Virama.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Visarga.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/Vowel.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/VowelDep.pl',
    'lib/perl5/5.36.0/unicore/lib/InSC/VowelInd.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Ain.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Alef.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Beh.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Dal.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/FarsiYeh.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Feh.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Gaf.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Hah.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/HanifiRo.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Kaf.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Lam.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/NoJoinin.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Noon.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Qaf.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Reh.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Sad.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Seen.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Tah.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Waw.pl',
    'lib/perl5/5.36.0/unicore/lib/Jg/Yeh.pl',
    'lib/perl5/5.36.0/unicore/lib/Jt/C.pl',
    'lib/perl5/5.36.0/unicore/lib/Jt/D.pl',
    'lib/perl5/5.36.0/unicore/lib/Jt/L.pl',
    'lib/perl5/5.36.0/unicore/lib/Jt/R.pl',
    'lib/perl5/5.36.0/unicore/lib/Jt/T.pl',
    'lib/perl5/5.36.0/unicore/lib/Jt/U.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/AI.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/AL.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/BA.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/BB.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/CJ.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/CL.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/CM.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/EX.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/GL.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/ID.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/IN.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/IS.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/NS.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/NU.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/OP.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/PO.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/PR.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/QU.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/SA.pl',
    'lib/perl5/5.36.0/unicore/lib/Lb/XX.pl',
    'lib/perl5/5.36.0/unicore/lib/Lower/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Math/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/NFCQC/M.pl',
    'lib/perl5/5.36.0/unicore/lib/NFCQC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/NFDQC/N.pl',
    'lib/perl5/5.36.0/unicore/lib/NFDQC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/NFKCQC/N.pl',
    'lib/perl5/5.36.0/unicore/lib/NFKCQC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/NFKDQC/N.pl',
    'lib/perl5/5.36.0/unicore/lib/NFKDQC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Nt/Di.pl',
    'lib/perl5/5.36.0/unicore/lib/Nt/None.pl',
    'lib/perl5/5.36.0/unicore/lib/Nt/Nu.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/0.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/10.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/100.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/10000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/100000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/11.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/12.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/13.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/14.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/15.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/16.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/17.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/18.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/19.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1_16.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1_2.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1_3.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1_4.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1_6.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/1_8.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/2.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/20.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/200.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/2000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/20000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/2_3.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/3.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/30.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/300.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/3000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/30000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/3_16.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/3_4.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/4.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/40.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/400.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/4000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/40000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/5.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/50.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/500.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/5000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/50000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/6.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/60.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/600.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/6000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/60000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/7.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/70.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/700.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/7000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/70000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/8.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/80.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/800.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/8000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/80000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/9.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/90.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/900.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/9000.pl',
    'lib/perl5/5.36.0/unicore/lib/Nv/90000.pl',
    'lib/perl5/5.36.0/unicore/lib/PCM/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/PatSyn/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Alnum.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Assigned.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Blank.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Graph.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/PerlWord.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/PosixPun.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Print.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/SpacePer.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Title.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/Word.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/XPosixPu.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlAny.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlCh2.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlCha.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlFol.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlIDC.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlIDS.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlIsI.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlNch.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlPat.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlPr2.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlPro.pl',
    'lib/perl5/5.36.0/unicore/lib/Perl/_PerlQuo.pl',
    'lib/perl5/5.36.0/unicore/lib/QMark/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/AT.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/CL.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/EX.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/FO.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/LE.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/LO.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/NU.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/SC.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/ST.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/Sp.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/UP.pl',
    'lib/perl5/5.36.0/unicore/lib/SB/XX.pl',
    'lib/perl5/5.36.0/unicore/lib/SD/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/STerm/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Arab.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Beng.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Cprt.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Cyrl.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Deva.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Dupl.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Geor.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Glag.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Gong.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Gonm.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Gran.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Grek.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Gujr.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Guru.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Han.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Hang.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Hira.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Kana.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Knda.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Latn.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Limb.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Linb.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Mlym.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Mong.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Mult.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Orya.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Sinh.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Syrc.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Taml.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Telu.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Zinh.pl',
    'lib/perl5/5.36.0/unicore/lib/Sc/Zyyy.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Adlm.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Arab.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Armn.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Beng.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Bhks.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Bopo.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Cakm.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Cham.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Copt.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Cprt.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Cyrl.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Deva.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Diak.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Dupl.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Ethi.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Geor.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Glag.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Gong.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Gonm.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Gran.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Grek.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Gujr.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Guru.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Han.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Hang.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Hebr.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Hira.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Hmng.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Hmnp.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Kana.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Khar.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Khmr.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Khoj.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Knda.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Kthi.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Lana.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Lao.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Latn.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Limb.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Lina.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Linb.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Mlym.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Mong.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Mult.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Mymr.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Nand.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Nko.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Orya.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Phlp.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Rohg.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Shrd.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Sind.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Sinh.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Syrc.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Tagb.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Takr.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Talu.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Taml.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Tang.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Telu.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Thaa.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Tibt.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Tirh.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Vith.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Xsux.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Yezi.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Yi.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Zinh.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Zyyy.pl',
    'lib/perl5/5.36.0/unicore/lib/Scx/Zzzz.pl',
    'lib/perl5/5.36.0/unicore/lib/Term/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/UIdeo/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Upper/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/VS/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/Vo/R.pl',
    'lib/perl5/5.36.0/unicore/lib/Vo/Tr.pl',
    'lib/perl5/5.36.0/unicore/lib/Vo/Tu.pl',
    'lib/perl5/5.36.0/unicore/lib/Vo/U.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/EX.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/Extend.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/FO.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/HL.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/KA.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/LE.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/MB.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/ML.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/MN.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/NU.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/WSegSpac.pl',
    'lib/perl5/5.36.0/unicore/lib/WB/XX.pl',
    'lib/perl5/5.36.0/unicore/lib/XIDC/Y.pl',
    'lib/perl5/5.36.0/unicore/lib/XIDS/Y.pl',
    'lib/perl5/5.36.0/utf8.pm',
    'lib/perl5/5.36.0/vars.pm',
    'lib/perl5/5.36.0/warnings.pm',
    'lib/perl5/5.36.0/warnings/register.pm',
);

my %defconfig = (
    cosmo_remotes => {
        origin => 'https://github.com/G4Vi/cosmopolitan',
        upstream => 'https://github.com/jart/cosmopolitan',
    },
    perl_remotes => {
        origin => 'https://github.com/G4Vi/perl5',
    },
    apperl_configs => {
        'nobuild-v0.1.0' => {
            desc => 'base nobuild config',
            dest => 'perl-nobuild.com',
            MANIFEST => ['lib', 'bin'],
            post_make_install_files => {},
            nobuild_perl_bin => ['src/perl.com', $^X],
        },
        'v5.36.0-full-v0.1.0' => {
            desc => 'Full perl v5.36.0',
            perl_id => 'cosmo-apperl',
            cosmo_id => 'af24c19db395b8edd3f8aab194675eadad173cca',
            cosmo_mode => '',
            cosmo_ape_loader => 'ape-no-modify-self.o',
            perl_flags => ['-Dprefix=/zip', '-Uversiononly', '-Dmyhostname=cosmo', '-Dmydomain=invalid'],
            perl_extra_flags => ['-Doptimize=-Os', '-de'],
            dest => 'perl.com',
            MANIFEST => ['lib', 'bin'],
            'include_Perl-Dist-APPerl' => 1,
            perl_repo_files => {},
            post_make_install_files => {},
        },
        'v5.36.0-full-v0.1.0-vista' => {
            desc => 'Full perl v5.36.0, but with non-standard cosmopolitan libc that still supports vista',
            base => 'v5.36.0-full-v0.1.0',
            perl_id => 'cosmo-apperl-vista',
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
        'v5.36.0-small-v0.1.0' => {
            desc => 'small perl v5.36.0',
            base => 'v5.36.0-full-v0.1.0',
            perl_extra_flags => ['-Doptimize=-Os', "-Donlyextensions= Cwd Fcntl File/Glob Hash/Util IO List/Util POSIX Socket attributes re ", '-de'],
            MANIFEST => \@smallmanifest,
            'include_Perl-Dist-APPerl' => 0
        },
        'v5.36.0-small-v0.1.0-vista' => {
            desc => 'small perl v5.36.0, but with non-standard cosmopolitan libc that still supports vista',
            base => 'v5.36.0-small-v0.1.0',
            perl_id => 'cosmo-apperl-vista',
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
        'full' => { desc => 'moving target: full', base => 'v5.36.0-full-v0.1.0' },
        'full-vista' => { desc => 'moving target: full for vista', base => 'v5.36.0-full-v0.1.0-vista' },
        'small' => { desc => 'moving target: small', base => 'v5.36.0-small-v0.1.0' },
        'small-vista' => { desc => 'moving target: small for vista', base => 'v5.36.0-small-v0.1.0-vista' },
        # development configs
        dontuse_threads => {
            desc => "not recommended, threaded build is buggy",
            base => 'v5.36.0-full-v0.1.0',
            perl_extra_flags => ['-Doptimize=-Os', '-Dusethreads', '-de'],
            perl_id => 'cosmo'
        },
        perl_cosmo_dev => {
            desc => "For developing cosmo platform perl without apperl additions",
            base => 'v5.36.0-full-v0.1.0',
            perl_id => 'cosmo'
        },
        perl_cosmo_dev_on_vista => {
            desc => "For developing cosmo platform perl without apperl additions on vista",
            base => "perl_cosmo_dev",
            cosmo_id => '4381b3d9254d6001f4bead71b458a377e854fbc5',
        },
    }
);
$defconfig{defaultconfig} = $defconfig{apperl_configs}{full}{base};

    my $projectconfig = _load_json(PROJECT_FILE);
    if($projectconfig) {
        foreach my $projkey (keys %$projectconfig) {
            if($projkey ne 'apperl_configs') {
                $defconfig{$projkey} = $projectconfig->{$projkey};
            }
            else {
                $defconfig{$projkey} = {%{$defconfig{$projkey}}, %{$projectconfig->{$projkey}}};
            }
        }
    }
    return \%defconfig;
}

sub _build_def_config {
    return {
        base => ($_[0] // 'nobuild-v0.1.0'),
        desc => 'description of this config',
        dest => 'perl.com'
    };
}

sub Init {
    my ($defaultconfig, $base) = @_;
    # validate
    die "Cannot create project config, it already exists ".PROJECT_FILE if(-e PROJECT_FILE);
    my $Configs = _load_apperl_configs();
    if(defined $base) {
        $defaultconfig or die "Cannot set base without name for new config";
        if(exists $Configs->{apperl_configs}{$defaultconfig}) {
            die "Cannot set base for $defaultconfig, $defaultconfig already exists ";
        }
        exists $Configs->{apperl_configs}{$base} or die "base config $base does not exist";
    }

    # create project config
    my %jsondata = ( 'defaultconfig' =>  ($defaultconfig // 'nobuild-v0.1.0'));
    if($defaultconfig && ! exists $Configs->{apperl_configs}{$defaultconfig}) {
        $jsondata{apperl_configs} = {
            $defaultconfig => _build_def_config($base),
        };
    }
    print "writing new project\n";
    _write_json(PROJECT_FILE, \%jsondata);

    # checkout default config
    Set($jsondata{defaultconfig});
}

sub NewConfig {
    my ($name, $base) = @_;
    $name or die "Name required to add new config";
    my $Configs = _load_apperl_configs();
    ! exists $Configs->{apperl_configs}{$name} or die "Cannot create already existing config";
    if(defined $base) {
        exists $Configs->{apperl_configs}{$base} or die "base config $base does not exist";
    }
    my $projectconfig = _load_json(PROJECT_FILE) or die "project file must already exist";
    $projectconfig->{apperl_configs}{$name} = _build_def_config($base);
    print "rewriting project\n";
    _write_json(PROJECT_FILE, $projectconfig);
}

sub InstallBuildDeps {
    my ($perlrepo, $cosmorepo) = @_;
    my $SiteConfig = _load_json(SITE_CONFIG_FILE);
    # if a repo is not set, set one up by default
    if((!$SiteConfig || !exists $SiteConfig->{perl_repo}) && (!$perlrepo)) {
        $perlrepo = SITE_CONFIG_DIR."/perl5";
        _setup_repo($perlrepo, _load_apperl_configs()->{perl_remotes});
        print "apperlm install-build-deps: setup perl repo\n";
    }
    if((!$SiteConfig || !exists $SiteConfig->{cosmo_repo}) && (!$cosmorepo)) {
        $cosmorepo = SITE_CONFIG_DIR."/cosmopolitan";
        _setup_repo( $cosmorepo, _load_apperl_configs()->{cosmo_remotes});
        print "apperlm install-build-deps: setup cosmo repo\n";
    }

    # (re)write site config
    $perlrepo //= $SiteConfig->{perl_repo};
    $cosmorepo //= $SiteConfig->{cosmo_repo};
    my %siteconfig = (
        perl_repo => abs_path($perlrepo),
        cosmo_repo => abs_path($cosmorepo)
    );
    $SiteConfig = \%siteconfig;
    make_path(SITE_CONFIG_DIR);
    _write_json(SITE_CONFIG_FILE, \%siteconfig);
    print "apperlm install-build-deps: wrote site config to ".SITE_CONFIG_FILE."\n";
}

sub Status {
    my $Configs = _load_apperl_configs();
    my @configlist = sort(keys %{$Configs->{apperl_configs}});
    my $UserProjectConfig = _load_user_project_config();
    my $CurAPPerlName;
    if($UserProjectConfig) {
        if(exists $UserProjectConfig->{current_apperl}) {
            $CurAPPerlName = $UserProjectConfig->{current_apperl};
            exists $Configs->{apperl_configs}{$CurAPPerlName} or die("non-existent apperl config $CurAPPerlName in user project config");
        }
    }
    if(!defined $CurAPPerlName && exists $Configs->{'defaultconfig'}) {
        $CurAPPerlName = $Configs->{'defaultconfig'};
        exists $Configs->{apperl_configs}{$CurAPPerlName} or die("non-existent default apperl config $CurAPPerlName");
    }
    foreach my $item (@configlist) {
        print (sprintf "%s %-30.30s | %s\n", $CurAPPerlName && ($item eq $CurAPPerlName) ? '*' : ' ', $item, ($Configs->{apperl_configs}{$item}{desc} // ''));
    }
}

sub Set {
    my ($cfgname) = @_;
    my $UserProjectConfig = _load_user_project_config();
    if($UserProjectConfig) {
        delete $UserProjectConfig->{nobuild_perl_bin};
    }
    else {
        $UserProjectConfig = {};
    }
    my $itemconfig = _load_apperl_config(_load_apperl_configs()->{apperl_configs}, $cfgname);
    print Dumper($itemconfig);
    if(! exists $itemconfig->{nobuild_perl_bin}) {
        my $SiteConfig = _load_json(SITE_CONFIG_FILE) or die "cannot set without build deps (run apperlm install-build-deps)";
        -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
        -d $SiteConfig->{perl_repo} or die $SiteConfig->{perl_repo} .' is not directory';
        print "cd ".$SiteConfig->{cosmo_repo}."\n";
        chdir($SiteConfig->{cosmo_repo}) or die "Failed to enter cosmo repo";
        _command_or_die('git', 'checkout', $itemconfig->{cosmo_id});

        print "cd ".$SiteConfig->{perl_repo}."\n";
        chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
        print "make veryclean\n";
        system("make", "veryclean");
        _command_or_die('rm', '-f', 'miniperl.com', 'miniperl.elf', 'perl.com', 'perl.elf');
        _command_or_die('git', 'checkout', $itemconfig->{perl_id});

        print "cd ".START_WD."\n";
        chdir(START_WD) or die "Failed to restore cwd";
        foreach my $dest (keys %{$itemconfig->{perl_repo_files}}) {
            _command_or_die('cp', '-r', $_, "$SiteConfig->{perl_repo}/$dest/") foreach @{$itemconfig->{perl_repo_files}{$dest}};
        }
    }
    else {
        my $validperl;
        foreach my $perlbin (@{$itemconfig->{nobuild_perl_bin}}) {
            print "perlbin $perlbin\n";
            if(-f $perlbin) {
                if(( $perlbin eq $^X) && (! -d '/zip')) {
                    print "skipping $perlbin, it appears to not be APPerl\n";
                    next;
                }
                $validperl = $perlbin;
                last;
            }
        }
        $validperl or die "no valid perl found to use for nobuild config";
        $validperl = abs_path($validperl);
        $validperl or die "no valid perl found to use for nobuild config";
        $UserProjectConfig->{nobuild_perl_bin} = $validperl;
        print "Set UserProjectConfig to nobuild_perl-bin to $validperl\n";
    }
    $UserProjectConfig->{apperl_output} //= PROJECT_TMP_DIR."/o";
    $UserProjectConfig->{current_apperl} = $cfgname;
    _write_user_project_config($UserProjectConfig);
    print "$0: Successfully switched to $cfgname\n";
}

sub Configure {
    my $Configs = _load_apperl_configs();
    my $UserProjectConfig = _load_valid_user_project_config_with_default($Configs) or die "cannot Configure without valid UserProjectConfig";
    my $CurAPPerlName = $UserProjectConfig->{current_apperl};
    ! exists $UserProjectConfig->{nobuild_perl_bin} or die "nobuild perl cannot be configured";
    my $SiteConfig = _load_json(SITE_CONFIG_FILE) or die "cannot Configure without build deps (run apperlm install-build-deps)";
    -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
    -d $SiteConfig->{perl_repo} or die $SiteConfig->{perl_repo} .' is not directory';
    my $itemconfig = _load_apperl_config($Configs->{apperl_configs}, $CurAPPerlName);
    # build cosmo
    print "$0: Building cosmo, COSMO_MODE=$itemconfig->{cosmo_mode} COSMO_APE_LOADER=$itemconfig->{cosmo_ape_loader}\n";
    _command_or_die('make', '-C', $SiteConfig->{cosmo_repo}, '-j4', "MODE=$itemconfig->{cosmo_mode}",
    "o/$itemconfig->{cosmo_mode}/cosmopolitan.a",
    "o/$itemconfig->{cosmo_mode}/libc/crt/crt.o",
    "o/$itemconfig->{cosmo_mode}/ape/public/ape.lds",
    "o/$itemconfig->{cosmo_mode}/ape/$itemconfig->{cosmo_ape_loader}",
    );

    # Finally Configure perl
    print "cd ".$SiteConfig->{perl_repo}."\n";
    chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
    $ENV{COSMO_REPO} = $SiteConfig->{cosmo_repo};
    $ENV{COSMO_MODE} = $itemconfig->{cosmo_mode};
    $ENV{COSMO_APE_LOADER} = $itemconfig->{cosmo_ape_loader};
    _command_or_die('sh', 'Configure', @{$itemconfig->{perl_flags}}, @{$itemconfig->{perl_extra_flags}}, @_);
    print "$0: Configure successful, time for apperlm build\n";
}

sub Build {
    my $Configs = _load_apperl_configs();
    my $UserProjectConfig = _load_valid_user_project_config_with_default($Configs) or die "cannot Build without valid UserProjectConfig";
    my $CurAPPerlName = $UserProjectConfig->{current_apperl};
    my $itemconfig = _load_apperl_config($Configs->{apperl_configs}, $CurAPPerlName);

    my $PERL_APE;
    my @perl_config_cmd;
    # build cosmo perl if this isn't a nobuild config
    if(! exists $UserProjectConfig->{nobuild_perl_bin}){
        my $SiteConfig = _load_json(SITE_CONFIG_FILE) or die "cannot build without build deps (run apperlm install-build-deps)";
        -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
        -d $SiteConfig->{perl_repo} or die $SiteConfig->{perl_repo} .' is not directory';
        print "cd ".$SiteConfig->{perl_repo}."\n";
        chdir($SiteConfig->{perl_repo}) or die "Failed to enter perl repo";
        _command_or_die('make');
        $PERL_APE = "$SiteConfig->{perl_repo}/perl.com";
        @perl_config_cmd = ('./perl', '-Ilib');
    }
    else {
        $PERL_APE = $UserProjectConfig->{nobuild_perl_bin};
        @perl_config_cmd = ($PERL_APE);
    }

    # prepare for install and pack
    -f $PERL_APE or die "apperlm build: perl ape not found";
    my $OUTPUTDIR = "$UserProjectConfig->{apperl_output}/$CurAPPerlName";
    if(-d $OUTPUTDIR) {
        _command_or_die('rm', '-rf', $OUTPUTDIR);
    }
    my $TEMPDIR = "$OUTPUTDIR/tmp";
    _command_or_die('mkdir', '-p', $TEMPDIR);
    my $PERL_PREFIX = _cmdoutput_or_die(@perl_config_cmd, '-e', 'use Config; print $Config{prefix}');
    my $PREFIX_NOZIP = $PERL_PREFIX;
    $PREFIX_NOZIP =~ s/^\/zip\/*//;
    my @zipfiles = map { "$PREFIX_NOZIP$_" } @{$itemconfig->{MANIFEST}};
    my $PERL_VERSION = _cmdoutput_or_die(@perl_config_cmd, '-e', 'use Config; print $Config{version}');
    my $ZIP_ROOT = "$TEMPDIR/zip";

    # install cosmo perl if this isn't a nobuild config
    if(! exists $UserProjectConfig->{nobuild_perl_bin}){
        _command_or_die('make', "DESTDIR=$TEMPDIR", 'install');
        _command_or_die('rm', "$TEMPDIR$PERL_PREFIX/bin/perl", "$TEMPDIR$PERL_PREFIX/bin/perl$PERL_VERSION");
    }
    else {
        make_path($ZIP_ROOT);
    }

    # pack
    my $APPNAME = basename($PERL_APE);
    my $APPPATH = "$TEMPDIR/$APPNAME";
    _command_or_die('cp', $PERL_APE, $APPPATH);
    _command_or_die('chmod', 'u+w', $APPPATH);
    if((! exists $UserProjectConfig->{nobuild_perl_bin}) || scalar(keys %{$itemconfig->{post_make_install_files}})) {
        print "cd $ZIP_ROOT\n";
        chdir($ZIP_ROOT) or die "failed to enter ziproot";
        foreach my $destkey (keys %{$itemconfig->{post_make_install_files}}) {
            my $dest = $destkey;
            $dest =~ s/^__perllib__/lib\/perl5\/$PERL_VERSION/;
            foreach my $file (@{$itemconfig->{post_make_install_files}{$destkey}}) {
                _copy_recursive($file, $dest);
            }
        }
        _command_or_die('zip', '-r', $APPPATH, @zipfiles);
    }
    _command_or_die('mv', $APPPATH, "$OUTPUTDIR/perl.com");

    # copy to user specified location
    if(exists $itemconfig->{dest}) {
        print "cd ".START_WD."\n";
        chdir(START_WD) or die "Failed to restore cwd";
        _command_or_die('cp', "$UserProjectConfig->{apperl_output}/$CurAPPerlName/perl.com", $itemconfig->{dest});
    }
}

sub apperlm {
    my $generic_usage = <<'END_USAGE';
apperlm <command> [...]
List of commands, try apperlm <command> --help for info about a command
  list               | List available APPerl configurations
  init               | Create an APPerl project in the current dir
  new-config         | Add a new APPerl configuration to the project
  checkout           | Switch to another APPerl configurations
  install-build-deps | Install build dependencies for APPerl
  configure          | `Configure` Perl (only valid with build config)
  build              | Build APPerl
  help               | Prints this message

Actually Portable Perl Manager (apperlm) handles configuring and
building Actually Portable Perl (APPerl). See
`perldoc Perl::Dist::APPerl` for more info.
END_USAGE
    my $command = shift(@_) if(@_);
    $command or die($generic_usage);
    if($command eq 'list') {
        Perl::Dist::APPerl::Status();
    }
    elsif($command eq 'build') {
        Perl::Dist::APPerl::Build();
    }
    elsif($command eq 'configure') {
        Perl::Dist::APPerl::Configure(@_);
    }
    elsif($command =~ /^(\-)*(halp|help|h)$/i) {
        print $generic_usage;
    }
    elsif($command eq 'checkout') {
        scalar(@_) == 1 or die('bad args');
        my $cfgname = $_[0];
        Perl::Dist::APPerl::Set($cfgname);
    }
    elsif($command eq 'init') {
        my $usage = <<'END_USAGE';
apperlm init [-h|--help] [-n|--name <name>] [-b|--base <base>]
  -n|--name     name of the default config
  -b|--base     base class of the config
  -h|--help     Show this message
Create an APPerl project, create a config if -n specified and it
doesn't already exist, checkout the config.
END_USAGE
        my $name;
        my $base;
        my $help;
        GetOptionsFromArray(\@_, "name|n=s" => \$name,
                   "base|b=s" => \$base,
                   "help|h" => \$help,
        ) or die($usage);
        if($help) {
            print $usage;
            exit 0;
        }
        Perl::Dist::APPerl::Init($name, $base);
    }
    elsif($command eq 'install-build-deps') {
        my $usage = <<'END_USAGE';
apperlm install-build-deps [-h|--help] [-c|--cosmo <path>] [-p|--perl <path>]
  -c|--cosmo <path> set path to cosmopolitan repo (skips git initialization)
  -p|--perl  <path> set path to perl repo (skips git initialization)
  -h|--help     Show this message
Install build dependencies for APPerl, use -c or -p to skip initializing
those repos by providing a path to it.
END_USAGE
        my $cosmo;
        my $perl;
        my $help;
        GetOptionsFromArray(\@_, "cosmo|c=s" => \$cosmo,
                   "perl|p=s" => \$perl,
                   "help|h" => \$help,
        ) or die($usage);
        if($help) {
            print $usage;
            exit 0;
        }
        Perl::Dist::APPerl::InstallBuildDeps($perl, $cosmo);
    }
    elsif($command eq 'new-config') {
        my $usage = <<'END_USAGE';
apperlm new-config [-h|--help] [-n|--name <name>] [-b|--base <base>]
  -n|--name     name of the default config
  -b|--base     base class of the config
  -h|--help     Show this message
Create a new APPerl config and add it to the project
END_USAGE
        my $name;
        my $base;
        my $help;
        GetOptionsFromArray(\@_, "name|n=s" => \$name,
                   "base|b=s" => \$base,
                   "help|h" => \$help,
        ) or die($usage);
        if($help) {
            print $usage;
            exit 0;
        }
        Perl::Dist::APPerl::NewConfig($name, $base);
    }
    else {
        die($generic_usage);
    }
}

sub _command_or_die {
    print join(' ', @_), "\n";
    system(@_) == 0 or die;
}

sub _cmdoutput_or_die {
    print join(' ', @_), "\n";
    my $kid = open(my $from_kid, '-|', @_) or die "can't fork $!";
    my $output = do { local $/; <$from_kid> };
    waitpid($kid, 0);
    (($? >> 8) == 0) or die("child failed");
    return $output;
}

sub _setup_repo {
    my ($repopath, $remotes) = @_;
    print "mkdir -p $repopath\n";
    make_path($repopath);
    print "cd $repopath\n";
    chdir($repopath) or die "Failed to chdir $repopath";
    _command_or_die('git', 'init');
    _command_or_die('git', 'checkout', '-b', 'placeholder_dont_use');
    foreach my $remote (keys %{$remotes}) {
        _command_or_die('git', 'remote', 'add', $remote, $remotes->{$remote});
        _command_or_die('git', 'fetch', $remote);
    }
}

sub _write_json {
    my ($destpath, $obj) = @_;
    open(my $fh, '>', $destpath) or die("Failed to open $destpath for writing");
    print $fh JSON::PP->new->pretty->encode($obj);
    close($fh);
}

sub _load_json {
    my ($jsonpath) = @_;
    open(my $fh, '<', $jsonpath) or return undef;
    my $file_content = do { local $/; <$fh> };
    close($fh);
    return decode_json($file_content);
}

sub _load_apperl_config {
    my ($apperlconfigs, $cfgname) = @_;
    exists $apperlconfigs->{$cfgname} or die "Unknown config: $cfgname";

    # find the base classes
    my $item = $apperlconfigs->{$cfgname};
    my @configlist = ($item);
    while(exists $item->{base}) {
        $item = $apperlconfigs->{$item->{base}};
        push @configlist, $item;
    }
    @configlist = reverse @configlist;

    # build the config from oldest to newest
    # keys that start with '+' are actually appended to the non-plus variant instead of replacing
    my %itemconfig;
    foreach my $config (@configlist) {
        foreach my $key (keys %$config) {
            if($key =~ /^\+(.+)/) {
                my $realkey = $1;
                exists $itemconfig{$realkey} or die("cannot append without existing key");
                my $rtype = ref($itemconfig{$realkey});
                $rtype or die("not ref");
                if($rtype eq 'ARRAY') {
                    $itemconfig{$realkey} = [@{$itemconfig{$realkey}}, @{$config->{$key}}];
                }
                elsif($rtype eq 'HASH') {
                    foreach my $dest (keys %{$config->{$key}}) {
                        push @{$itemconfig{$realkey}{$dest}}, @{$config->{$key}{$dest}};
                    }
                }
                else {
                    die($rtype);
                }
            }
            else {
                $itemconfig{$key} = $config->{$key};
            }
        }
    }

    # switch these from relative paths to abs paths
    foreach my $destdir (keys %{$itemconfig{post_make_install_files}}) {
        foreach my $path (@{$itemconfig{post_make_install_files}{$destdir}}) {
            $path = abs_path($path);
            $path or die;
            -e $path or die;
        }
    }

    # add in ourselves for bootstrapping, this even works when running internal Perl::Dist::APPerl from a bootstrapped build
    if(exists $itemconfig{'include_Perl-Dist-APPerl'} && $itemconfig{'include_Perl-Dist-APPerl'}) {
        my $thispath = abs_path(__FILE__);
        defined($thispath) or die(__FILE__.'issues?');
        push @{$itemconfig{post_make_install_files}{"__perllib__/Perl/Dist"}}, $thispath;
        my @additionalfiles = map { "$FindBin::Bin/$_" } ('apperlm');
        -e $_ or die($!) foreach @additionalfiles;
        push @{$itemconfig{post_make_install_files}{bin}}, @additionalfiles;
    }

    # verify apperl config sanity
    if(! exists $itemconfig{nobuild_perl_bin}) {
        $itemconfig{cosmo_ape_loader} //= 'ape-no-modify-self.o';
        ($itemconfig{cosmo_ape_loader} eq 'ape-no-modify-self.o') || ($itemconfig{cosmo_ape_loader} eq 'ape.o') or die "Unknown ape loader: " . $itemconfig{cosmo_ape_loader};
    }

    return \%itemconfig;
}

sub _load_user_project_config {
    return _load_json(PROJECT_TMP_CONFIG_FILE);
}

sub _load_valid_user_project_config {
    my ($Configs) = @_;
    my $UserProjectConfig = _load_user_project_config();
    if($UserProjectConfig) {
        if(exists $UserProjectConfig->{current_apperl}) {
            my $CurAPPerlName = $UserProjectConfig->{current_apperl};
            exists $Configs->{apperl_configs}{$CurAPPerlName} or die("non-existent apperl config $CurAPPerlName in user project config");
            return $UserProjectConfig;
        }
    }
    return undef;
}

sub _load_valid_user_project_config_with_default {
    my ($Configs) = @_;
    my $UserProjectConfig = _load_valid_user_project_config($Configs);
    return $UserProjectConfig if($UserProjectConfig || !exists $Configs->{defaultconfig});
    Set($Configs->{defaultconfig});
    return _load_valid_user_project_config($Configs);
}

sub _write_user_project_config {
    my ($config) = @_;
    if(! -d PROJECT_TMP_DIR) {
        make_path(PROJECT_TMP_DIR);
    };
    _write_json(PROJECT_TMP_CONFIG_FILE, $config);
}

sub _copy_recursive {
    my ($src, $dest) = @_;
    if(! -d $dest) {
        make_path($dest);
    }
    goto &_copy_recursive_inner;
}

sub _copy_recursive_inner {
    my ($src, $dest) = @_;
    print "_copy_recursive $src $dest\n";
    if(-f $src) {
        copy($src, $dest) or die("Failed to copy $!");
    }
    elsif(-d $src) {
        my $dest = "$dest/".basename($src);
        if(! -d $dest) {
            mkdir($dest) or die("Failed to mkdir $!");
        }
        opendir(my $dh, $src) or die("Failed to opendir");
        while(my $file = readdir($dh)) {
            next if(($file eq '.') || ($file eq '..'));
            _copy_recursive("$src/$file", $dest);
        }
        closedir($dh);
    }
    else {
        die "Unhandled file type for $src";
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Dist::APPerl - Actually Portable Perl

=head1 DESCRIPTION

Actually Portable Perl (APPerl) is a distribution of Perl the runs on
several x86_64 operating systems via the same binary. For portability,
it builds to a single binary with perl modules packed inside of it.

Cross-platform, single binary, standalone Perl applications can be made
by building custom versions of APPerl, with and without compiling
Perl from scratch, so it can be used an alternative to L<PAR::Packer>.
APPerl could also easily be added to development SDKs,
carried on your USB drive, or just allow you to run the exact same perl
on all your PCs multiple computers.

This package documentation covers the apperlm tool for building APPerl,
APPerl usage, and how to create applications with APPerl.

=head1 SYNOPSIS

    apperlm install-build-deps
    apperlm-list
    apperlm configure
    apperlm build
    ./perl.com /zip/bin/perldoc Perl::Dist::APPerl
    cp perl.com perl
    ./perl --assimilate
    ln -s perl perldoc
    ./perldoc perlcosmo

To build small APPerl from scratch
    apperlm install-build-deps
    apperlm checkout small
    apperlm configure
    apperlm build

To start an APPerl project from an existing APPerl and build it
    mkdir src
    mv perl.com src/
    apperlm init --name your_config_name --base nobuild-v0.1.0
    apperlm build

To start an APPerl project and build from scratch
    apperlm install-build-deps
    apperlm init --name your_config_name --base v5.36.0-small-v0.1.0
    apperlm configure
    apperlm build

=head1 apperlm

The C<apperlm> (APPerl manager) script is a CLI interface to configuring
and building APPerl.

=head2 COMMAND REFERENCE

=over 4

=item *

C<apperlm install-build-deps> installs APPerl build dependencies,
currently, a fork of the perl5 source and the cosmopolitan libc. This
is only necessary if you are building APPerl from scratch (not using a
nobuild configuration). Initialization of the repos can be skipped by
passing the path to them locally. The cosmopolitan repo
initialization can be skipped with -c <path_to_repo> . The perl5 repo
initialization can be skipped with -p <path_to_repo>. This install is
done user specific, installs to $XDG_CONFIG_HOME/apperl .

=item *

C<apperlm init> creates an APPerl project, C<apperl-project.json>. The
project default configuration may to specified with -n <name>. If the
configuration does not exist, a new configuration will be created, and
then the base of the configuration may be specified with
-b <base_config_name>. The default configuration is then checked out.

=item *

C<apperlm list> lists the available APPerl configs. If a current config
is set it is denoted with a C<*>.

=item *

C<apperlm checkout> sets the current APPerl config, this includes a
C<make veryclean> in the Perl repo and C<git checkout> in both Perl and
cosmo repos. The current config name is written to
C<.apperl/user-project.json> .

=item *

C<apperlm new-config> creates a new config and adds to to the project
config. -n specifies the name of the new config and must be provided.
-b specifies the base of the new config.

=item *

C<apperlm configure> builds cosmopolitan for the current APPerl config
and runs Perl's C<Configure>

=item *

C<apperlm build> C<make>s perl and builds apperl. The output binary by
default is copied to C<perl.com> in the current directory, set dest in
C<apperl-project.json> to customize output binary path and name.

=back

=head1 USAGE

APPerl doesn't need to be installed, the output C<perl.com> binary can
be copied between computers and ran without installation. However, in
certain cases such as magic (modifying $0, etc.) The binary must be
assimilated for it to work properly. Note, you likely want to copy
before this operation as it modifies the binary in-place to be bound to
the current environment.
  cp perl.com perl
  ./perl --assimilate

For the most part, APPerl works like normal perl, however it has a
couple additional features.

=over 4

=item *

C</zip/> filesystem - The APPerl binary is also a ZIP file. Paths
starting with C</zip/> refer to files compressed in the binary itself.
At runtime the zip filesystem is readonly, but additional modules and
scripts can be added just by adding them to the zip file. For example,
perldoc and the other standard scripts are shipped inside of /zip/bin

  ./perl.com /zip/bin/perldoc perlcosmo

=item *

C<argv[0]> script execution - this allows making single binary perl
applications! APPerl built with the APPerl additions
(found in cosmo-apperl branches) attempts to load the argv[0] basename
without extension from /zip/bin

  ln -s perl.com perldoc.com
  ./perldoc.com perlcosmo

=back

=head1 CREATING APPLICATIONS WITH APPERL

=head2 RATONALE

APPerl wasn't developed to be the 'hack of the day', but provide real
world utility by easing using Perl in user environments.

Unfortunately, scripting languages are often a second class citizen on
user environments due to them not being installed by default or only
broken/old/incomplete versions installed, and sometimes not being the
easiest to install. Providing native perl binaries with solutions like
L<PAR::Packer> is possible, but that requires juggling binaries for
every desired target and packing.

The idea of APPerl applications is that you can handcraft the desired
Perl environment with your application and then ship it as one portable
binary for all targets.

Building an APPerl application does nothing to ofuscate or hide your
source code, it is a feature that APPerl binaries are also zip files,
allowing for easy retrieval of Perl scripts and modules.

=head2 TUTORIAL

Enter your projects directory, create it if it doesn't exists. Download
or copy in an existing version of APPerl you wish to build off of.
Create a new nobuild APPerl project and build it.

  cd projectdir
  mkdir src
  cp ./perl.com src/
  apperlm init --name my_first_project_config
  apperlm build

Now you should have a newly built perl.com inside the current
directory. However, this isn't very exciting as it's identical to the
one you copied into source. Let's create a script.

  printf "%s\n%s\n%s\n" '#!/usr/bin/perl' 'use strict; use warnings;' \
  'print "Hello, World!\n";' > src/hello

To add it open apperl-project.json and add the following to
my_first_project_config:

  "post_make_install_files" : { "bin" : ["src/hello"] }

Rebuild and try loading the script you added

   apperlm build
   ./perl.com /zip/bin/hello

You have embedded a script inside APPerl, however running it is a
little awkward. What if you could run it by the name of the script?

  ln -s perl.com hello
  ./hello

More details on the argv[0] script execution is in USAGE above. Now,
what about Perl modules? Perl modules can be packed in the same way,
but to ease setting the correct directory to packing them into, the
magic prefix __perllib__ can be used in the destination. Note, you may
have to add items to the MANIFEST key if the MANIFEST isn't set
permissively.

  "post_make_install_files" : { "__perllib__/Your" : ["Module.pm"] }

TODO, write tutorial from building from scatch


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Perl::Dist::APPerl

L<APPerl webpage|https://computoid.com/APPerl/>

Support, and bug reports can be found at the repository
L<https://github.com/G4Vi/APPerl>

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut