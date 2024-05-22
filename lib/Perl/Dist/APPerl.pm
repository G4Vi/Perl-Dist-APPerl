package Perl::Dist::APPerl;
# Copyright (c) 2022 Gavin Hayes, see LICENSE in the root of the project
use version 0.77; our $VERSION = qv(v0.5.0);
use strict;
use warnings;
use JSON::PP 2.0104 qw(decode_json);
use File::Path 2.07 qw(make_path remove_tree);
use Cwd qw(abs_path getcwd);
use Data::Dumper qw(Dumper);
use File::Basename qw(basename dirname);
use File::Copy qw(copy move cp);
use FindBin qw();
use Fcntl qw(SEEK_SET);
use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure qw(gnu_getopt);

use constant {
    START_WD => getcwd(),
    PROJECT_FILE => 'apperl-project.json',
};
use constant {
    PROJECT_TMP_DIR => (START_WD.'/.apperl'),
};
use constant {
    # DEFDATAROOT is used if the XDG base directories cannot be found
    DEFDATAROOT => defined($ENV{HOME}) ? $ENV{HOME}
    : defined($ENV{APPDATA}) ? $ENV{APPDATA} .'/apperl'
    : PROJECT_TMP_DIR.'/site',
    PROJECT_TMP_CONFIG_FILE => (PROJECT_TMP_DIR.'/user-project.json'),
};
use constant {
    SITE_CONFIG_DIR  => ($ENV{XDG_CONFIG_HOME} // (DEFDATAROOT.'/.config')) . '/apperl',
    SITE_REPO_DIR => ($ENV{XDG_DATA_HOME} // (DEFDATAROOT.'/.local/share')).'/apperl',
};
use constant {
    SITE_CONFIG_FILE => (SITE_CONFIG_DIR."/site.json"),
};
use constant {
    SHARE_DIR => sub {
        my $thispath = abs_path(__FILE__);
        defined($thispath) or die(__FILE__.'issues?');
        my $sharedir = dirname($thispath)."/../../../share";
        if (! -d $sharedir) {
            $sharedir = '/zip/lib/perl5/auto/share/dist/Perl-Dist-APPerl';
        }
        if (! -d $sharedir) {
            eval "use File::ShareDir; 1" or die "Failed to load File::ShareDir";
            $sharedir = File::ShareDir::dist_dir('Perl-Dist-APPerl');
        }
        $sharedir = abs_path($sharedir) // die "Failed to load sharedir";
        return $sharedir;
    }->()
};

sub _load_apperl_configs {

# https://packages.debian.org/experimental/amd64/perl-base/filelist with tweaks
my @smallmanifest = (
    '__perllib__/AutoLoader.pm',
    '__perllib__/Carp.pm',
    '__perllib__/Carp/Heavy.pm',
    '__perlarchlib__/Config.pm',
    '__perlarchlib__/Config_git.pl',
    '__perlarchlib__/Config_heavy.pl',
    '__perlarchlib__/Cwd.pm',
    '__perlarchlib__/DynaLoader.pm',
    '__perlarchlib__/Errno.pm',
    '__perlarchlib__/ErrnoRuntime.pm',
    '__perllib__/Exporter.pm',
    '__perllib__/Exporter/Heavy.pm',
    '__perlarchlib__/Fcntl.pm',
    '__perllib__/File/Basename.pm',
    '__perlarchlib__/File/Glob.pm',
    '__perllib__/File/Path.pm',
    '__perlarchlib__/File/Spec.pm',
    '__perlarchlib__/File/Spec/Unix.pm',
    '__perllib__/File/Temp.pm',
    '__perllib__/FileHandle.pm',
    '__perllib__/Getopt/Long.pm',
    '__perlarchlib__/Hash/Util.pm',
    '__perlarchlib__/IO.pm',
    '__perlarchlib__/IO/File.pm',
    '__perlarchlib__/IO/Handle.pm',
    '__perlarchlib__/IO/Pipe.pm',
    '__perlarchlib__/IO/Seekable.pm',
    '__perlarchlib__/IO/Select.pm',
    '__perlarchlib__/IO/Socket.pm',
    '__perlarchlib__/IO/Socket/INET.pm',
    '__perllib__/IO/Socket/IP.pm',
    '__perlarchlib__/IO/Socket/UNIX.pm',
    '__perllib__/IPC/Open2.pm',
    '__perllib__/IPC/Open3.pm',
    '__perlarchlib__/List/Util.pm',
    '__perlarchlib__/POSIX.pm',
    '__perlarchlib__/Scalar/Util.pm',
    '__perllib__/SelectSaver.pm',
    '__perlarchlib__/Socket.pm',
    '__perllib__/Symbol.pm',
    '__perllib__/Text/ParseWords.pm',
    '__perllib__/Text/Tabs.pm',
    '__perllib__/Text/Wrap.pm',
    '__perllib__/Tie/Hash.pm',
    '__perllib__/XSLoader.pm',
    '__perlarchlib__/attributes.pm',
    '__perllib__/base.pm',
    '__perllib__/builtin.pm',
    '__perllib__/bytes.pm',
    '__perllib__/bytes_heavy.pl',
    '__perllib__/constant.pm',
    '__perllib__/feature.pm',
    '__perllib__/fields.pm',
    '__perllib__/integer.pm',
    '__perlarchlib__/lib.pm',
    '__perllib__/locale.pm',
    '__perllib__/overload.pm',
    '__perllib__/overloading.pm',
    '__perllib__/parent.pm',
    '__perlarchlib__/re.pm',
    '__perllib__/strict.pm',
    '__perllib__/unicore/To/Age.pl',
    '__perllib__/unicore/To/Bc.pl',
    '__perllib__/unicore/To/Bmg.pl',
    '__perllib__/unicore/To/Bpb.pl',
    '__perllib__/unicore/To/Bpt.pl',
    '__perllib__/unicore/To/Cf.pl',
    '__perllib__/unicore/To/Ea.pl',
    '__perllib__/unicore/To/EqUIdeo.pl',
    '__perllib__/unicore/To/GCB.pl',
    '__perllib__/unicore/To/Gc.pl',
    '__perllib__/unicore/To/Hst.pl',
    '__perllib__/unicore/To/Identif2.pl',
    '__perllib__/unicore/To/Identifi.pl',
    '__perllib__/unicore/To/InPC.pl',
    '__perllib__/unicore/To/InSC.pl',
    '__perllib__/unicore/To/Isc.pl',
    '__perllib__/unicore/To/Jg.pl',
    '__perllib__/unicore/To/Jt.pl',
    '__perllib__/unicore/To/Lb.pl',
    '__perllib__/unicore/To/Lc.pl',
    '__perllib__/unicore/To/NFCQC.pl',
    '__perllib__/unicore/To/NFDQC.pl',
    '__perllib__/unicore/To/NFKCCF.pl',
    '__perllib__/unicore/To/NFKCQC.pl',
    '__perllib__/unicore/To/NFKDQC.pl',
    '__perllib__/unicore/To/Na1.pl',
    '__perllib__/unicore/To/NameAlia.pl',
    '__perllib__/unicore/To/Nt.pl',
    '__perllib__/unicore/To/Nv.pl',
    '__perllib__/unicore/To/PerlDeci.pl',
    '__perllib__/unicore/To/SB.pl',
    '__perllib__/unicore/To/Sc.pl',
    '__perllib__/unicore/To/Scx.pl',
    '__perllib__/unicore/To/Tc.pl',
    '__perllib__/unicore/To/Uc.pl',
    '__perllib__/unicore/To/Vo.pl',
    '__perllib__/unicore/To/WB.pl',
    '__perllib__/unicore/To/_PerlLB.pl',
    '__perllib__/unicore/To/_PerlSCX.pl',
    '__perllib__/unicore/lib/Age/NA.pl',
    '__perllib__/unicore/lib/Age/V100.pl',
    '__perllib__/unicore/lib/Age/V11.pl',
    '__perllib__/unicore/lib/Age/V110.pl',
    '__perllib__/unicore/lib/Age/V120.pl',
    '__perllib__/unicore/lib/Age/V130.pl',
    '__perllib__/unicore/lib/Age/V140.pl',
    '__perllib__/unicore/lib/Age/V20.pl',
    '__perllib__/unicore/lib/Age/V30.pl',
    '__perllib__/unicore/lib/Age/V31.pl',
    '__perllib__/unicore/lib/Age/V32.pl',
    '__perllib__/unicore/lib/Age/V40.pl',
    '__perllib__/unicore/lib/Age/V41.pl',
    '__perllib__/unicore/lib/Age/V50.pl',
    '__perllib__/unicore/lib/Age/V51.pl',
    '__perllib__/unicore/lib/Age/V52.pl',
    '__perllib__/unicore/lib/Age/V60.pl',
    '__perllib__/unicore/lib/Age/V61.pl',
    '__perllib__/unicore/lib/Age/V70.pl',
    '__perllib__/unicore/lib/Age/V80.pl',
    '__perllib__/unicore/lib/Age/V90.pl',
    '__perllib__/unicore/lib/Alpha/Y.pl',
    '__perllib__/unicore/lib/Bc/AL.pl',
    '__perllib__/unicore/lib/Bc/AN.pl',
    '__perllib__/unicore/lib/Bc/B.pl',
    '__perllib__/unicore/lib/Bc/BN.pl',
    '__perllib__/unicore/lib/Bc/CS.pl',
    '__perllib__/unicore/lib/Bc/EN.pl',
    '__perllib__/unicore/lib/Bc/ES.pl',
    '__perllib__/unicore/lib/Bc/ET.pl',
    '__perllib__/unicore/lib/Bc/L.pl',
    '__perllib__/unicore/lib/Bc/NSM.pl',
    '__perllib__/unicore/lib/Bc/ON.pl',
    '__perllib__/unicore/lib/Bc/R.pl',
    '__perllib__/unicore/lib/Bc/WS.pl',
    '__perllib__/unicore/lib/BidiC/Y.pl',
    '__perllib__/unicore/lib/BidiM/Y.pl',
    '__perllib__/unicore/lib/Blk/NB.pl',
    '__perllib__/unicore/lib/Bpt/C.pl',
    '__perllib__/unicore/lib/Bpt/N.pl',
    '__perllib__/unicore/lib/Bpt/O.pl',
    '__perllib__/unicore/lib/CE/Y.pl',
    '__perllib__/unicore/lib/CI/Y.pl',
    '__perllib__/unicore/lib/CWCF/Y.pl',
    '__perllib__/unicore/lib/CWCM/Y.pl',
    '__perllib__/unicore/lib/CWKCF/Y.pl',
    '__perllib__/unicore/lib/CWL/Y.pl',
    '__perllib__/unicore/lib/CWT/Y.pl',
    '__perllib__/unicore/lib/CWU/Y.pl',
    '__perllib__/unicore/lib/Cased/Y.pl',
    '__perllib__/unicore/lib/Ccc/A.pl',
    '__perllib__/unicore/lib/Ccc/AL.pl',
    '__perllib__/unicore/lib/Ccc/AR.pl',
    '__perllib__/unicore/lib/Ccc/ATAR.pl',
    '__perllib__/unicore/lib/Ccc/B.pl',
    '__perllib__/unicore/lib/Ccc/BR.pl',
    '__perllib__/unicore/lib/Ccc/DB.pl',
    '__perllib__/unicore/lib/Ccc/NK.pl',
    '__perllib__/unicore/lib/Ccc/NR.pl',
    '__perllib__/unicore/lib/Ccc/OV.pl',
    '__perllib__/unicore/lib/Ccc/VR.pl',
    '__perllib__/unicore/lib/CompEx/Y.pl',
    '__perllib__/unicore/lib/DI/Y.pl',
    '__perllib__/unicore/lib/Dash/Y.pl',
    '__perllib__/unicore/lib/Dep/Y.pl',
    '__perllib__/unicore/lib/Dia/Y.pl',
    '__perllib__/unicore/lib/Dt/Com.pl',
    '__perllib__/unicore/lib/Dt/Enc.pl',
    '__perllib__/unicore/lib/Dt/Fin.pl',
    '__perllib__/unicore/lib/Dt/Font.pl',
    '__perllib__/unicore/lib/Dt/Init.pl',
    '__perllib__/unicore/lib/Dt/Iso.pl',
    '__perllib__/unicore/lib/Dt/Med.pl',
    '__perllib__/unicore/lib/Dt/Nar.pl',
    '__perllib__/unicore/lib/Dt/Nb.pl',
    '__perllib__/unicore/lib/Dt/NonCanon.pl',
    '__perllib__/unicore/lib/Dt/Sqr.pl',
    '__perllib__/unicore/lib/Dt/Sub.pl',
    '__perllib__/unicore/lib/Dt/Sup.pl',
    '__perllib__/unicore/lib/Dt/Vert.pl',
    '__perllib__/unicore/lib/EBase/Y.pl',
    '__perllib__/unicore/lib/EComp/Y.pl',
    '__perllib__/unicore/lib/EPres/Y.pl',
    '__perllib__/unicore/lib/Ea/A.pl',
    '__perllib__/unicore/lib/Ea/H.pl',
    '__perllib__/unicore/lib/Ea/N.pl',
    '__perllib__/unicore/lib/Ea/Na.pl',
    '__perllib__/unicore/lib/Ea/W.pl',
    '__perllib__/unicore/lib/Emoji/Y.pl',
    '__perllib__/unicore/lib/Ext/Y.pl',
    '__perllib__/unicore/lib/ExtPict/Y.pl',
    '__perllib__/unicore/lib/GCB/CN.pl',
    '__perllib__/unicore/lib/GCB/EX.pl',
    '__perllib__/unicore/lib/GCB/LV.pl',
    '__perllib__/unicore/lib/GCB/LVT.pl',
    '__perllib__/unicore/lib/GCB/PP.pl',
    '__perllib__/unicore/lib/GCB/SM.pl',
    '__perllib__/unicore/lib/GCB/XX.pl',
    '__perllib__/unicore/lib/Gc/C.pl',
    '__perllib__/unicore/lib/Gc/Cf.pl',
    '__perllib__/unicore/lib/Gc/Cn.pl',
    '__perllib__/unicore/lib/Gc/L.pl',
    '__perllib__/unicore/lib/Gc/LC.pl',
    '__perllib__/unicore/lib/Gc/Ll.pl',
    '__perllib__/unicore/lib/Gc/Lm.pl',
    '__perllib__/unicore/lib/Gc/Lo.pl',
    '__perllib__/unicore/lib/Gc/Lu.pl',
    '__perllib__/unicore/lib/Gc/M.pl',
    '__perllib__/unicore/lib/Gc/Mc.pl',
    '__perllib__/unicore/lib/Gc/Me.pl',
    '__perllib__/unicore/lib/Gc/Mn.pl',
    '__perllib__/unicore/lib/Gc/N.pl',
    '__perllib__/unicore/lib/Gc/Nd.pl',
    '__perllib__/unicore/lib/Gc/Nl.pl',
    '__perllib__/unicore/lib/Gc/No.pl',
    '__perllib__/unicore/lib/Gc/P.pl',
    '__perllib__/unicore/lib/Gc/Pc.pl',
    '__perllib__/unicore/lib/Gc/Pd.pl',
    '__perllib__/unicore/lib/Gc/Pe.pl',
    '__perllib__/unicore/lib/Gc/Pf.pl',
    '__perllib__/unicore/lib/Gc/Pi.pl',
    '__perllib__/unicore/lib/Gc/Po.pl',
    '__perllib__/unicore/lib/Gc/Ps.pl',
    '__perllib__/unicore/lib/Gc/S.pl',
    '__perllib__/unicore/lib/Gc/Sc.pl',
    '__perllib__/unicore/lib/Gc/Sk.pl',
    '__perllib__/unicore/lib/Gc/Sm.pl',
    '__perllib__/unicore/lib/Gc/So.pl',
    '__perllib__/unicore/lib/Gc/Z.pl',
    '__perllib__/unicore/lib/Gc/Zs.pl',
    '__perllib__/unicore/lib/GrBase/Y.pl',
    '__perllib__/unicore/lib/GrExt/Y.pl',
    '__perllib__/unicore/lib/Hex/Y.pl',
    '__perllib__/unicore/lib/Hst/NA.pl',
    '__perllib__/unicore/lib/Hyphen/T.pl',
    '__perllib__/unicore/lib/IDC/Y.pl',
    '__perllib__/unicore/lib/IDS/Y.pl',
    '__perllib__/unicore/lib/IdStatus/Allowed.pl',
    '__perllib__/unicore/lib/IdStatus/Restrict.pl',
    '__perllib__/unicore/lib/IdType/DefaultI.pl',
    '__perllib__/unicore/lib/IdType/Exclusio.pl',
    '__perllib__/unicore/lib/IdType/Inclusio.pl',
    '__perllib__/unicore/lib/IdType/LimitedU.pl',
    '__perllib__/unicore/lib/IdType/NotChara.pl',
    '__perllib__/unicore/lib/IdType/NotNFKC.pl',
    '__perllib__/unicore/lib/IdType/NotXID.pl',
    '__perllib__/unicore/lib/IdType/Obsolete.pl',
    '__perllib__/unicore/lib/IdType/Recommen.pl',
    '__perllib__/unicore/lib/IdType/Technica.pl',
    '__perllib__/unicore/lib/IdType/Uncommon.pl',
    '__perllib__/unicore/lib/Ideo/Y.pl',
    '__perllib__/unicore/lib/In/10_0.pl',
    '__perllib__/unicore/lib/In/11_0.pl',
    '__perllib__/unicore/lib/In/12_0.pl',
    '__perllib__/unicore/lib/In/12_1.pl',
    '__perllib__/unicore/lib/In/13_0.pl',
    '__perllib__/unicore/lib/In/14_0.pl',
    '__perllib__/unicore/lib/In/2_0.pl',
    '__perllib__/unicore/lib/In/2_1.pl',
    '__perllib__/unicore/lib/In/3_0.pl',
    '__perllib__/unicore/lib/In/3_1.pl',
    '__perllib__/unicore/lib/In/3_2.pl',
    '__perllib__/unicore/lib/In/4_0.pl',
    '__perllib__/unicore/lib/In/4_1.pl',
    '__perllib__/unicore/lib/In/5_0.pl',
    '__perllib__/unicore/lib/In/5_1.pl',
    '__perllib__/unicore/lib/In/5_2.pl',
    '__perllib__/unicore/lib/In/6_0.pl',
    '__perllib__/unicore/lib/In/6_1.pl',
    '__perllib__/unicore/lib/In/6_2.pl',
    '__perllib__/unicore/lib/In/6_3.pl',
    '__perllib__/unicore/lib/In/7_0.pl',
    '__perllib__/unicore/lib/In/8_0.pl',
    '__perllib__/unicore/lib/In/9_0.pl',
    '__perllib__/unicore/lib/InPC/Bottom.pl',
    '__perllib__/unicore/lib/InPC/BottomAn.pl',
    '__perllib__/unicore/lib/InPC/Left.pl',
    '__perllib__/unicore/lib/InPC/LeftAndR.pl',
    '__perllib__/unicore/lib/InPC/NA.pl',
    '__perllib__/unicore/lib/InPC/Overstru.pl',
    '__perllib__/unicore/lib/InPC/Right.pl',
    '__perllib__/unicore/lib/InPC/Top.pl',
    '__perllib__/unicore/lib/InPC/TopAndBo.pl',
    '__perllib__/unicore/lib/InPC/TopAndL2.pl',
    '__perllib__/unicore/lib/InPC/TopAndLe.pl',
    '__perllib__/unicore/lib/InPC/TopAndRi.pl',
    '__perllib__/unicore/lib/InPC/VisualOr.pl',
    '__perllib__/unicore/lib/InSC/Avagraha.pl',
    '__perllib__/unicore/lib/InSC/Bindu.pl',
    '__perllib__/unicore/lib/InSC/Cantilla.pl',
    '__perllib__/unicore/lib/InSC/Consona2.pl',
    '__perllib__/unicore/lib/InSC/Consona3.pl',
    '__perllib__/unicore/lib/InSC/Consona4.pl',
    '__perllib__/unicore/lib/InSC/Consona5.pl',
    '__perllib__/unicore/lib/InSC/Consona6.pl',
    '__perllib__/unicore/lib/InSC/Consona7.pl',
    '__perllib__/unicore/lib/InSC/Consona8.pl',
    '__perllib__/unicore/lib/InSC/Consonan.pl',
    '__perllib__/unicore/lib/InSC/Invisibl.pl',
    '__perllib__/unicore/lib/InSC/Nukta.pl',
    '__perllib__/unicore/lib/InSC/Number.pl',
    '__perllib__/unicore/lib/InSC/Other.pl',
    '__perllib__/unicore/lib/InSC/PureKill.pl',
    '__perllib__/unicore/lib/InSC/Syllable.pl',
    '__perllib__/unicore/lib/InSC/ToneMark.pl',
    '__perllib__/unicore/lib/InSC/Virama.pl',
    '__perllib__/unicore/lib/InSC/Visarga.pl',
    '__perllib__/unicore/lib/InSC/Vowel.pl',
    '__perllib__/unicore/lib/InSC/VowelDep.pl',
    '__perllib__/unicore/lib/InSC/VowelInd.pl',
    '__perllib__/unicore/lib/Jg/Ain.pl',
    '__perllib__/unicore/lib/Jg/Alef.pl',
    '__perllib__/unicore/lib/Jg/Beh.pl',
    '__perllib__/unicore/lib/Jg/Dal.pl',
    '__perllib__/unicore/lib/Jg/FarsiYeh.pl',
    '__perllib__/unicore/lib/Jg/Feh.pl',
    '__perllib__/unicore/lib/Jg/Gaf.pl',
    '__perllib__/unicore/lib/Jg/Hah.pl',
    '__perllib__/unicore/lib/Jg/HanifiRo.pl',
    '__perllib__/unicore/lib/Jg/Kaf.pl',
    '__perllib__/unicore/lib/Jg/Lam.pl',
    '__perllib__/unicore/lib/Jg/NoJoinin.pl',
    '__perllib__/unicore/lib/Jg/Noon.pl',
    '__perllib__/unicore/lib/Jg/Qaf.pl',
    '__perllib__/unicore/lib/Jg/Reh.pl',
    '__perllib__/unicore/lib/Jg/Sad.pl',
    '__perllib__/unicore/lib/Jg/Seen.pl',
    '__perllib__/unicore/lib/Jg/Tah.pl',
    '__perllib__/unicore/lib/Jg/Waw.pl',
    '__perllib__/unicore/lib/Jg/Yeh.pl',
    '__perllib__/unicore/lib/Jt/C.pl',
    '__perllib__/unicore/lib/Jt/D.pl',
    '__perllib__/unicore/lib/Jt/L.pl',
    '__perllib__/unicore/lib/Jt/R.pl',
    '__perllib__/unicore/lib/Jt/T.pl',
    '__perllib__/unicore/lib/Jt/U.pl',
    '__perllib__/unicore/lib/Lb/AI.pl',
    '__perllib__/unicore/lib/Lb/AL.pl',
    '__perllib__/unicore/lib/Lb/BA.pl',
    '__perllib__/unicore/lib/Lb/BB.pl',
    '__perllib__/unicore/lib/Lb/CJ.pl',
    '__perllib__/unicore/lib/Lb/CL.pl',
    '__perllib__/unicore/lib/Lb/CM.pl',
    '__perllib__/unicore/lib/Lb/EX.pl',
    '__perllib__/unicore/lib/Lb/GL.pl',
    '__perllib__/unicore/lib/Lb/ID.pl',
    '__perllib__/unicore/lib/Lb/IN.pl',
    '__perllib__/unicore/lib/Lb/IS.pl',
    '__perllib__/unicore/lib/Lb/NS.pl',
    '__perllib__/unicore/lib/Lb/NU.pl',
    '__perllib__/unicore/lib/Lb/OP.pl',
    '__perllib__/unicore/lib/Lb/PO.pl',
    '__perllib__/unicore/lib/Lb/PR.pl',
    '__perllib__/unicore/lib/Lb/QU.pl',
    '__perllib__/unicore/lib/Lb/SA.pl',
    '__perllib__/unicore/lib/Lb/XX.pl',
    '__perllib__/unicore/lib/Lower/Y.pl',
    '__perllib__/unicore/lib/Math/Y.pl',
    '__perllib__/unicore/lib/NFCQC/M.pl',
    '__perllib__/unicore/lib/NFCQC/Y.pl',
    '__perllib__/unicore/lib/NFDQC/N.pl',
    '__perllib__/unicore/lib/NFDQC/Y.pl',
    '__perllib__/unicore/lib/NFKCQC/N.pl',
    '__perllib__/unicore/lib/NFKCQC/Y.pl',
    '__perllib__/unicore/lib/NFKDQC/N.pl',
    '__perllib__/unicore/lib/NFKDQC/Y.pl',
    '__perllib__/unicore/lib/Nt/Di.pl',
    '__perllib__/unicore/lib/Nt/None.pl',
    '__perllib__/unicore/lib/Nt/Nu.pl',
    '__perllib__/unicore/lib/Nv/0.pl',
    '__perllib__/unicore/lib/Nv/1.pl',
    '__perllib__/unicore/lib/Nv/10.pl',
    '__perllib__/unicore/lib/Nv/100.pl',
    '__perllib__/unicore/lib/Nv/1000.pl',
    '__perllib__/unicore/lib/Nv/10000.pl',
    '__perllib__/unicore/lib/Nv/100000.pl',
    '__perllib__/unicore/lib/Nv/11.pl',
    '__perllib__/unicore/lib/Nv/12.pl',
    '__perllib__/unicore/lib/Nv/13.pl',
    '__perllib__/unicore/lib/Nv/14.pl',
    '__perllib__/unicore/lib/Nv/15.pl',
    '__perllib__/unicore/lib/Nv/16.pl',
    '__perllib__/unicore/lib/Nv/17.pl',
    '__perllib__/unicore/lib/Nv/18.pl',
    '__perllib__/unicore/lib/Nv/19.pl',
    '__perllib__/unicore/lib/Nv/1_16.pl',
    '__perllib__/unicore/lib/Nv/1_2.pl',
    '__perllib__/unicore/lib/Nv/1_3.pl',
    '__perllib__/unicore/lib/Nv/1_4.pl',
    '__perllib__/unicore/lib/Nv/1_6.pl',
    '__perllib__/unicore/lib/Nv/1_8.pl',
    '__perllib__/unicore/lib/Nv/2.pl',
    '__perllib__/unicore/lib/Nv/20.pl',
    '__perllib__/unicore/lib/Nv/200.pl',
    '__perllib__/unicore/lib/Nv/2000.pl',
    '__perllib__/unicore/lib/Nv/20000.pl',
    '__perllib__/unicore/lib/Nv/2_3.pl',
    '__perllib__/unicore/lib/Nv/3.pl',
    '__perllib__/unicore/lib/Nv/30.pl',
    '__perllib__/unicore/lib/Nv/300.pl',
    '__perllib__/unicore/lib/Nv/3000.pl',
    '__perllib__/unicore/lib/Nv/30000.pl',
    '__perllib__/unicore/lib/Nv/3_16.pl',
    '__perllib__/unicore/lib/Nv/3_4.pl',
    '__perllib__/unicore/lib/Nv/4.pl',
    '__perllib__/unicore/lib/Nv/40.pl',
    '__perllib__/unicore/lib/Nv/400.pl',
    '__perllib__/unicore/lib/Nv/4000.pl',
    '__perllib__/unicore/lib/Nv/40000.pl',
    '__perllib__/unicore/lib/Nv/5.pl',
    '__perllib__/unicore/lib/Nv/50.pl',
    '__perllib__/unicore/lib/Nv/500.pl',
    '__perllib__/unicore/lib/Nv/5000.pl',
    '__perllib__/unicore/lib/Nv/50000.pl',
    '__perllib__/unicore/lib/Nv/6.pl',
    '__perllib__/unicore/lib/Nv/60.pl',
    '__perllib__/unicore/lib/Nv/600.pl',
    '__perllib__/unicore/lib/Nv/6000.pl',
    '__perllib__/unicore/lib/Nv/60000.pl',
    '__perllib__/unicore/lib/Nv/7.pl',
    '__perllib__/unicore/lib/Nv/70.pl',
    '__perllib__/unicore/lib/Nv/700.pl',
    '__perllib__/unicore/lib/Nv/7000.pl',
    '__perllib__/unicore/lib/Nv/70000.pl',
    '__perllib__/unicore/lib/Nv/8.pl',
    '__perllib__/unicore/lib/Nv/80.pl',
    '__perllib__/unicore/lib/Nv/800.pl',
    '__perllib__/unicore/lib/Nv/8000.pl',
    '__perllib__/unicore/lib/Nv/80000.pl',
    '__perllib__/unicore/lib/Nv/9.pl',
    '__perllib__/unicore/lib/Nv/90.pl',
    '__perllib__/unicore/lib/Nv/900.pl',
    '__perllib__/unicore/lib/Nv/9000.pl',
    '__perllib__/unicore/lib/Nv/90000.pl',
    '__perllib__/unicore/lib/PCM/Y.pl',
    '__perllib__/unicore/lib/PatSyn/Y.pl',
    '__perllib__/unicore/lib/Perl/Alnum.pl',
    '__perllib__/unicore/lib/Perl/Assigned.pl',
    '__perllib__/unicore/lib/Perl/Blank.pl',
    '__perllib__/unicore/lib/Perl/Graph.pl',
    '__perllib__/unicore/lib/Perl/PerlWord.pl',
    '__perllib__/unicore/lib/Perl/PosixPun.pl',
    '__perllib__/unicore/lib/Perl/Print.pl',
    '__perllib__/unicore/lib/Perl/SpacePer.pl',
    '__perllib__/unicore/lib/Perl/Title.pl',
    '__perllib__/unicore/lib/Perl/Word.pl',
    '__perllib__/unicore/lib/Perl/XPosixPu.pl',
    '__perllib__/unicore/lib/Perl/_PerlAny.pl',
    '__perllib__/unicore/lib/Perl/_PerlCh2.pl',
    '__perllib__/unicore/lib/Perl/_PerlCha.pl',
    '__perllib__/unicore/lib/Perl/_PerlFol.pl',
    '__perllib__/unicore/lib/Perl/_PerlIDC.pl',
    '__perllib__/unicore/lib/Perl/_PerlIDS.pl',
    '__perllib__/unicore/lib/Perl/_PerlIsI.pl',
    '__perllib__/unicore/lib/Perl/_PerlNch.pl',
    '__perllib__/unicore/lib/Perl/_PerlPat.pl',
    '__perllib__/unicore/lib/Perl/_PerlPr2.pl',
    '__perllib__/unicore/lib/Perl/_PerlPro.pl',
    '__perllib__/unicore/lib/Perl/_PerlQuo.pl',
    '__perllib__/unicore/lib/QMark/Y.pl',
    '__perllib__/unicore/lib/SB/AT.pl',
    '__perllib__/unicore/lib/SB/CL.pl',
    '__perllib__/unicore/lib/SB/EX.pl',
    '__perllib__/unicore/lib/SB/FO.pl',
    '__perllib__/unicore/lib/SB/LE.pl',
    '__perllib__/unicore/lib/SB/LO.pl',
    '__perllib__/unicore/lib/SB/NU.pl',
    '__perllib__/unicore/lib/SB/SC.pl',
    '__perllib__/unicore/lib/SB/ST.pl',
    '__perllib__/unicore/lib/SB/Sp.pl',
    '__perllib__/unicore/lib/SB/UP.pl',
    '__perllib__/unicore/lib/SB/XX.pl',
    '__perllib__/unicore/lib/SD/Y.pl',
    '__perllib__/unicore/lib/STerm/Y.pl',
    '__perllib__/unicore/lib/Sc/Arab.pl',
    '__perllib__/unicore/lib/Sc/Beng.pl',
    '__perllib__/unicore/lib/Sc/Cprt.pl',
    '__perllib__/unicore/lib/Sc/Cyrl.pl',
    '__perllib__/unicore/lib/Sc/Deva.pl',
    '__perllib__/unicore/lib/Sc/Dupl.pl',
    '__perllib__/unicore/lib/Sc/Geor.pl',
    '__perllib__/unicore/lib/Sc/Glag.pl',
    '__perllib__/unicore/lib/Sc/Gong.pl',
    '__perllib__/unicore/lib/Sc/Gonm.pl',
    '__perllib__/unicore/lib/Sc/Gran.pl',
    '__perllib__/unicore/lib/Sc/Grek.pl',
    '__perllib__/unicore/lib/Sc/Gujr.pl',
    '__perllib__/unicore/lib/Sc/Guru.pl',
    '__perllib__/unicore/lib/Sc/Han.pl',
    '__perllib__/unicore/lib/Sc/Hang.pl',
    '__perllib__/unicore/lib/Sc/Hira.pl',
    '__perllib__/unicore/lib/Sc/Kana.pl',
    '__perllib__/unicore/lib/Sc/Knda.pl',
    '__perllib__/unicore/lib/Sc/Latn.pl',
    '__perllib__/unicore/lib/Sc/Limb.pl',
    '__perllib__/unicore/lib/Sc/Linb.pl',
    '__perllib__/unicore/lib/Sc/Mlym.pl',
    '__perllib__/unicore/lib/Sc/Mong.pl',
    '__perllib__/unicore/lib/Sc/Mult.pl',
    '__perllib__/unicore/lib/Sc/Orya.pl',
    '__perllib__/unicore/lib/Sc/Sinh.pl',
    '__perllib__/unicore/lib/Sc/Syrc.pl',
    '__perllib__/unicore/lib/Sc/Taml.pl',
    '__perllib__/unicore/lib/Sc/Telu.pl',
    '__perllib__/unicore/lib/Sc/Zinh.pl',
    '__perllib__/unicore/lib/Sc/Zyyy.pl',
    '__perllib__/unicore/lib/Scx/Adlm.pl',
    '__perllib__/unicore/lib/Scx/Arab.pl',
    '__perllib__/unicore/lib/Scx/Armn.pl',
    '__perllib__/unicore/lib/Scx/Beng.pl',
    '__perllib__/unicore/lib/Scx/Bhks.pl',
    '__perllib__/unicore/lib/Scx/Bopo.pl',
    '__perllib__/unicore/lib/Scx/Cakm.pl',
    '__perllib__/unicore/lib/Scx/Cham.pl',
    '__perllib__/unicore/lib/Scx/Copt.pl',
    '__perllib__/unicore/lib/Scx/Cprt.pl',
    '__perllib__/unicore/lib/Scx/Cyrl.pl',
    '__perllib__/unicore/lib/Scx/Deva.pl',
    '__perllib__/unicore/lib/Scx/Diak.pl',
    '__perllib__/unicore/lib/Scx/Dupl.pl',
    '__perllib__/unicore/lib/Scx/Ethi.pl',
    '__perllib__/unicore/lib/Scx/Geor.pl',
    '__perllib__/unicore/lib/Scx/Glag.pl',
    '__perllib__/unicore/lib/Scx/Gong.pl',
    '__perllib__/unicore/lib/Scx/Gonm.pl',
    '__perllib__/unicore/lib/Scx/Gran.pl',
    '__perllib__/unicore/lib/Scx/Grek.pl',
    '__perllib__/unicore/lib/Scx/Gujr.pl',
    '__perllib__/unicore/lib/Scx/Guru.pl',
    '__perllib__/unicore/lib/Scx/Han.pl',
    '__perllib__/unicore/lib/Scx/Hang.pl',
    '__perllib__/unicore/lib/Scx/Hebr.pl',
    '__perllib__/unicore/lib/Scx/Hira.pl',
    '__perllib__/unicore/lib/Scx/Hmng.pl',
    '__perllib__/unicore/lib/Scx/Hmnp.pl',
    '__perllib__/unicore/lib/Scx/Kana.pl',
    '__perllib__/unicore/lib/Scx/Khar.pl',
    '__perllib__/unicore/lib/Scx/Khmr.pl',
    '__perllib__/unicore/lib/Scx/Khoj.pl',
    '__perllib__/unicore/lib/Scx/Knda.pl',
    '__perllib__/unicore/lib/Scx/Kthi.pl',
    '__perllib__/unicore/lib/Scx/Lana.pl',
    '__perllib__/unicore/lib/Scx/Lao.pl',
    '__perllib__/unicore/lib/Scx/Latn.pl',
    '__perllib__/unicore/lib/Scx/Limb.pl',
    '__perllib__/unicore/lib/Scx/Lina.pl',
    '__perllib__/unicore/lib/Scx/Linb.pl',
    '__perllib__/unicore/lib/Scx/Mlym.pl',
    '__perllib__/unicore/lib/Scx/Mong.pl',
    '__perllib__/unicore/lib/Scx/Mult.pl',
    '__perllib__/unicore/lib/Scx/Mymr.pl',
    '__perllib__/unicore/lib/Scx/Nand.pl',
    '__perllib__/unicore/lib/Scx/Nko.pl',
    '__perllib__/unicore/lib/Scx/Orya.pl',
    '__perllib__/unicore/lib/Scx/Phlp.pl',
    '__perllib__/unicore/lib/Scx/Rohg.pl',
    '__perllib__/unicore/lib/Scx/Shrd.pl',
    '__perllib__/unicore/lib/Scx/Sind.pl',
    '__perllib__/unicore/lib/Scx/Sinh.pl',
    '__perllib__/unicore/lib/Scx/Syrc.pl',
    '__perllib__/unicore/lib/Scx/Tagb.pl',
    '__perllib__/unicore/lib/Scx/Takr.pl',
    '__perllib__/unicore/lib/Scx/Talu.pl',
    '__perllib__/unicore/lib/Scx/Taml.pl',
    '__perllib__/unicore/lib/Scx/Tang.pl',
    '__perllib__/unicore/lib/Scx/Telu.pl',
    '__perllib__/unicore/lib/Scx/Thaa.pl',
    '__perllib__/unicore/lib/Scx/Tibt.pl',
    '__perllib__/unicore/lib/Scx/Tirh.pl',
    '__perllib__/unicore/lib/Scx/Vith.pl',
    '__perllib__/unicore/lib/Scx/Xsux.pl',
    '__perllib__/unicore/lib/Scx/Yezi.pl',
    '__perllib__/unicore/lib/Scx/Yi.pl',
    '__perllib__/unicore/lib/Scx/Zinh.pl',
    '__perllib__/unicore/lib/Scx/Zyyy.pl',
    '__perllib__/unicore/lib/Scx/Zzzz.pl',
    '__perllib__/unicore/lib/Term/Y.pl',
    '__perllib__/unicore/lib/UIdeo/Y.pl',
    '__perllib__/unicore/lib/Upper/Y.pl',
    '__perllib__/unicore/lib/VS/Y.pl',
    '__perllib__/unicore/lib/Vo/R.pl',
    '__perllib__/unicore/lib/Vo/Tr.pl',
    '__perllib__/unicore/lib/Vo/Tu.pl',
    '__perllib__/unicore/lib/Vo/U.pl',
    '__perllib__/unicore/lib/WB/EX.pl',
    '__perllib__/unicore/lib/WB/Extend.pl',
    '__perllib__/unicore/lib/WB/FO.pl',
    '__perllib__/unicore/lib/WB/HL.pl',
    '__perllib__/unicore/lib/WB/KA.pl',
    '__perllib__/unicore/lib/WB/LE.pl',
    '__perllib__/unicore/lib/WB/MB.pl',
    '__perllib__/unicore/lib/WB/ML.pl',
    '__perllib__/unicore/lib/WB/MN.pl',
    '__perllib__/unicore/lib/WB/NU.pl',
    '__perllib__/unicore/lib/WB/WSegSpac.pl',
    '__perllib__/unicore/lib/WB/XX.pl',
    '__perllib__/unicore/lib/XIDC/Y.pl',
    '__perllib__/unicore/lib/XIDS/Y.pl',
    '__perllib__/utf8.pm',
    '__perllib__/vars.pm',
    '__perllib__/warnings.pm',
    '__perllib__/warnings/register.pm',
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
            desc => 'use nobuild as base instead of this',
            dest => 'perl-nobuild.com',
            MANIFEST => ['lib', 'bin'],
            zip_extra_files => {},
            nobuild_perl_bin => ['src/perl.com', $^X],
        },
        'v5.36.0-full-v0.1.0-vista' => {
            desc => 'Full perl v5.36.0, but with non-standard Cosmopolitan Libc that still supports vista',
            perl_id => 'b22da6b83c37604132694ead0bdcf61690f74a53',
            cosmo_id => '9c5a7795add7add5a214afce27d896084e0861c5',
            cosmo_mode => '',
            cosmo_ape_loader => 'ape-no-modify-self.o',
            dest => 'perl-vista.com',
            perl_flags => ['-Dprefix=/zip', '-Uversiononly', '-Dmyhostname=cosmo', '-Dmydomain=invalid'],
            perl_extra_flags => ['-Doptimize=-Os', '-de'],
            MANIFEST => ['lib', 'bin'],
            'include_Perl-Dist-APPerl' => 1,
            perl_repo_files => {},
            zip_extra_files => {},
        },
        'v5.36.0-small-v0.1.0-vista' => {
            desc => 'small perl v5.36.0, but with non-standard Cosmopolitan Libc that still supports vista',
            base => 'v5.36.0-full-v0.1.0-vista',
            perl_onlyextensions => [qw(Cwd Fcntl File/Glob Hash/Util IO List/Util POSIX Socket attributes re)],
            MANIFEST => \@smallmanifest,
            'include_Perl-Dist-APPerl' => 0,
            dest => 'perl-small-vista.com',
        },
        'full-vista' => { desc => 'moving target: full for vista', base => 'v5.36.0-full-v0.1.0-vista', perl_id => '239a05bbef291b8de3309c95852d41fc027cacab', cosmo_id => 'fea68b142e59b5861fe09375eb5bcb256b69b70e', '+perl_extra_flags' => ['-Dprivlib=/zip/lib/perl5', '-Darchlib=/zip/lib/perl5/x86_64-cosmo', '-Dsitelib=/zip/lib/perl5/site_perl', '-Dsitearch=/zip/lib/perl5/site_perl/x86_64-cosmo']},
        'small-vista' => { desc => 'moving target: small for vista', base => 'v5.36.0-small-v0.1.0-vista', perl_id => '239a05bbef291b8de3309c95852d41fc027cacab', cosmo_id => 'fea68b142e59b5861fe09375eb5bcb256b69b70e', '+perl_extra_flags' => ['-Dprivlib=/zip/lib/perl5', '-Darchlib=/zip/lib/perl5/x86_64-cosmo', '-Dsitelib=/zip/lib/perl5/site_perl', '-Dsitearch=/zip/lib/perl5/site_perl/x86_64-cosmo']},
        'full' => {
            desc => 'moving target: full',
            perl_flags => ['-Dprefix=/zip', '-Uversiononly', '-Dmyhostname=cosmo', '-Dmydomain=invalid'],
            perl_extra_flags => ['-Doptimize=-Os', '-de', '-Dprivlib=/zip/lib/perl5', '-Darchlib=/zip/lib/perl5/x86_64-cosmo', '-Dsitelib=/zip/lib/perl5/site_perl', '-Dsitearch=/zip/lib/perl5/site_perl/x86_64-cosmo'],
            MANIFEST => ['lib', 'bin'],
            'include_Perl-Dist-APPerl' => 1,
            perl_repo_files => {},
            zip_extra_files => {},
            cosmo3 => 1,
            dest => 'perl.com',
            perl_url => 'https://github.com/Perl/perl5/archive/refs/tags/v5.36.3.tar.gz',
            patches => ['__sharedir__/5.36-cosmo3.patch', '__sharedir__/5.36-cosmo-apperl.patch'],
            install_modules => [],
        },
        'small' => {
            desc => 'moving target: small',
            base => 'full',
            perl_onlyextensions => [qw(Cwd ErrnoRuntime Fcntl File/Glob Hash/Util IO List/Util POSIX Socket attributes re)],
            MANIFEST => \@smallmanifest,
            'include_Perl-Dist-APPerl' => 0,
            dest => 'perl-small.com',
            install_modules => [],
        },
        'nobuild' => {
            desc => 'base nobuild config',
            dest => 'perl-nobuild.com',
            MANIFEST => ['lib', 'bin'],
            zip_extra_files => {},
            nobuild_perl_bin => ['src/perl.com', $^X],
        },
        # development configs
        perl_cosmo_dev => {
            desc => "For developing cosmo platform perl without apperl additions",
            base => 'full',
            perl_id => 'v5.36.3',
            perl_url => undef,
            patches => ['__sharedir__/5.36-cosmo3.patch'],
        },
        perl_apperl_dev => {
            desc => "For developing apperl",
            base => 'perl_cosmo3_dev',
            '+patches' => ['__sharedir__/5.36-cosmo-apperl.patch'],
        }
    }
);
$defconfig{defaultconfig} = 'full';

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
    Checkout($jsondata{defaultconfig});
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

sub _install_cosmocc {
    my ($SiteConfig, $version) = @_;
    $version //= '3.3.6';
    my $cosmocc = SITE_REPO_DIR."/cosmocc";
    print "rm -rf $cosmocc\n";
    remove_tree($cosmocc);
    print "mkdir -p $cosmocc\n";
    make_path($cosmocc);
    print "cd $cosmocc\n";
    my $before = getcwd();
    chdir($cosmocc) or die "Failed to chdir $cosmocc";
    my $filename = "cosmocc-$version.zip";
    _command_or_die('wget', "https://cosmo.zip/pub/cosmocc/$filename");
    _command_or_die('unzip', $filename);
    chdir($before) or die "error resetting directory";
    $SiteConfig->{cosmocc} = $cosmocc;
    make_path(SITE_CONFIG_DIR);
    _write_json(SITE_CONFIG_FILE, $SiteConfig);
}

#sub _load_valid_site_config {
#    my ($is_cosmo3) = @_;
#    my $SiteConfig = _load_json(SITE_CONFIG_FILE);
#    $SiteConfig || defined($is_cosmo3) or die "Failed to load SiteConfig";
#    $SiteConfig //= {};
#    defined $is_cosmo3 or return $SiteConfig;
#    if ($is_cosmo3) {
#
#    }
#}

sub InstallBuildDeps {
    my ($perlrepo, $cosmorepo) = @_;
    my $SiteConfig = _load_json(SITE_CONFIG_FILE);
    $SiteConfig //= {};

    # if a repo is not set, set one up by default
    if(!exists $SiteConfig->{perl_repo} && !$perlrepo) {
        $perlrepo = SITE_REPO_DIR."/perl5";
        _setup_repo($perlrepo, _load_apperl_configs()->{perl_remotes});
        print "apperlm install-build-deps: setup perl repo\n";
    }
    if(!exists $SiteConfig->{cosmo_repo} && !$cosmorepo) {
        $cosmorepo = SITE_REPO_DIR."/cosmopolitan";
        _setup_repo( $cosmorepo, _load_apperl_configs()->{cosmo_remotes});
        print "apperlm install-build-deps: setup cosmo repo\n";
    }

    # (re)write site config
    $perlrepo //= $SiteConfig->{perl_repo};
    $cosmorepo //= $SiteConfig->{cosmo_repo};
    $SiteConfig->{perl_repo} = abs_path($perlrepo);
    $SiteConfig->{cosmo_repo} = abs_path($cosmorepo);
    make_path(SITE_CONFIG_DIR);
    _write_json(SITE_CONFIG_FILE, $SiteConfig);
    print "apperlm install-build-deps: wrote site config to ".SITE_CONFIG_FILE."\n";
}

sub _remove_arr_items_from_arr {
    my ($src, $toremove) = @_;
    my @remove = @{$toremove};
    foreach my $srcindex (reverse 0..$#{$src}) {
        for my $removeindex (reverse 0..$#remove) {
            if ($src->[$srcindex] eq $remove[$removeindex]) {
                splice(@$src, $srcindex, 1);
                return if (scalar(@remove) == 1);
                splice(@remove, $removeindex, 1);
                last;
            }
        }
    }
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

    my @projectitems;
    my $projectconfig = _load_json(PROJECT_FILE);
    if($projectconfig && exists $projectconfig->{apperl_configs}) {
        @projectitems = sort (keys %{$projectconfig->{apperl_configs}});
        _remove_arr_items_from_arr(\@configlist, \@projectitems);
    }
    my @rolling = grep(/^(full|small|nobuild)$/, @configlist);
    {
        my %preferences = ( full => 0, small => 1, nobuild => 2);
        @rolling = sort {$preferences{$a} <=> $preferences{$b}} @rolling;
    }
    _remove_arr_items_from_arr(\@configlist, \@rolling);
    my @deprecated = grep(/(\-vista|v0\.1\.0)$/, @configlist);
    _remove_arr_items_from_arr(\@configlist, \@deprecated);
    my @internal = grep(/^(dontuse_threads|perl_cosmo_dev|perl_apperl_dev|dbg)$/, @configlist);
    _remove_arr_items_from_arr(\@configlist, \@internal);
    my @stable = grep( /v\d+\.\d+\.\d+$/, @configlist);
    _remove_arr_items_from_arr(\@configlist, \@stable);
    my @categories = (
        ['PROJECT', \@projectitems],
        ['STABLE', \@stable],
        ['ROLLING', \@rolling],
        ['DEPRECATED', \@deprecated],
        ['UNSTABLE/INTERNAL', \@internal],
        ['UNKNOWN', \@configlist]
    );
    foreach my $cat (@categories) {
        foreach my $item (@{$cat->[1]}) {
            print (sprintf "%s %-30.30s | %-17.17s |%s\n", $CurAPPerlName && ($item eq $CurAPPerlName) ? '*' : ' ', $item, $cat->[0], ($Configs->{apperl_configs}{$item}{desc} // ''));
        }
    }
}

# unfortunately this needs to be called in several places to try to keep them in sync
# as perl's make trips up when trying to build an symlinked extension
sub _install_perl_src_files {
    my ($itemconfig, $perl_build_dir) = @_;
    foreach my $dest (keys %{$itemconfig->{perl_repo_files}}) {
        foreach my $file (@{$itemconfig->{perl_repo_files}{$dest}}) {
            _copy_recursive(START_WD."/$file", "$perl_build_dir/$dest");
        }
    }
}

sub Checkout {
    my ($cfgname) = @_;
    my $UserProjectConfig = _load_user_project_config();
    if($UserProjectConfig) {
        delete $UserProjectConfig->{nobuild_perl_bin};
    }
    else {
        $UserProjectConfig = {};
    }
    $UserProjectConfig->{apperl_output} //= PROJECT_TMP_DIR."/o";
    $UserProjectConfig->{current_apperl} = $cfgname;
    my $itemconfig = _load_apperl_config(_load_apperl_configs()->{apperl_configs}, $cfgname);
    print Dumper($itemconfig);
    if(! exists $itemconfig->{nobuild_perl_bin}) {
        my $SiteConfig = _load_json(SITE_CONFIG_FILE);
        if(! $itemconfig->{cosmo3}) {
            $SiteConfig or die "cannot set without build deps (run apperlm install-build-deps)";
            -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
            print "cd ".$SiteConfig->{cosmo_repo}."\n";
            chdir($SiteConfig->{cosmo_repo}) or die "Failed to enter cosmo repo";
            _command_or_die('git', 'checkout', $itemconfig->{cosmo_id});
        } else {
            $SiteConfig //= {};
            exists $SiteConfig->{cosmocc} or _install_cosmocc($SiteConfig);
            -d $SiteConfig->{cosmocc} or die $SiteConfig->{cosmocc} . ' is not a directory';
        }
        $UserProjectConfig->{configs}{$cfgname}{perl_build_dir} //= $SiteConfig->{perl_repo} if !$itemconfig->{perl_url};
        $UserProjectConfig->{configs}{$cfgname}{perl_build_dir} //= "$UserProjectConfig->{apperl_output}/$cfgname/tmp/perl5";
        my $perl_build_dir = $UserProjectConfig->{configs}{$cfgname}{perl_build_dir};
        if (! $itemconfig->{perl_url}) {
            -d $perl_build_dir or die $perl_build_dir .' is not directory';
            print "cd ".$perl_build_dir."\n";
            chdir($perl_build_dir) or die "Failed to enter perl repo";
            print "make veryclean\n";
            system("make", "veryclean");
            foreach my $todelete ('miniperl.com', 'perl.com', 'miniperl.elf', 'miniperl.com.dbg', 'perl.elf', 'perl.com.dbg') {
                print "rm $todelete\n";
                unlink($todelete) || $!{ENOENT} or die "failed to delete $todelete";
            }
            _command_or_die('git', 'checkout', '-f', $itemconfig->{perl_id});
            _command_or_die('git', 'clean', '-f', '-e.vscode', '-d');
            $itemconfig->{patches} //= [];
        } else {
            my $tarball_name = basename($itemconfig->{perl_url});
            my $download_dir = $UserProjectConfig->{apperl_output};
            print "mkdir -p $download_dir\n";
            make_path($download_dir);
            chdir($download_dir) or die "Failed to enter download dir";
            if (! -f $tarball_name) {
                _command_or_die('wget', $itemconfig->{perl_url});
            }
            _command_or_die('tar', '-xf', $tarball_name);
            print "rm -rf $perl_build_dir\n";
            remove_tree($perl_build_dir);
            my ($version) = $tarball_name =~ /^v(\d+\.\d+\.\d+)\.tar/;
            my $perl_build_dir_dir = dirname($perl_build_dir);
            print "mkdir -p $perl_build_dir_dir\n";
            make_path($perl_build_dir_dir);
            my $tomove = "perl5-$version";
            print "mv $tomove $perl_build_dir\n";
            move($tomove, $perl_build_dir) or die "Failed to move perl src";
            chdir($perl_build_dir) or die "Failed to enter perl build_dir";
        }
        foreach my $patch (@{$itemconfig->{patches}}) {
            my $realpatch = _fix_bases($patch, {__sharedir__ => SHARE_DIR});
            # can't `git apply` to ignored files within a git repository :(
            _cmdinputfile_or_die('patch', '-p1', $realpatch);
        }
        print "cd ".START_WD."\n";
        chdir(START_WD) or die "Failed to restore cwd";
        _install_perl_src_files($itemconfig, $perl_build_dir);
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
        print "Checkout UserProjectConfig to nobuild_perl-bin to $validperl\n";
    }
    _write_user_project_config($UserProjectConfig);
    print "$0: Successfully switched to $cfgname\n";
}

sub Configure {
    my $Configs = _load_apperl_configs();
    my ($UserProjectConfig, $CurAPPerlName) = _load_valid_user_project_config_with_default($Configs) or die "cannot Configure without valid UserProjectConfig";
    ! exists $UserProjectConfig->{nobuild_perl_bin} or die "nobuild perl cannot be configured";
    my $perl_build_dir = $UserProjectConfig->{configs}{$CurAPPerlName}{perl_build_dir};
    $perl_build_dir && -d $perl_build_dir or die "$perl_build_dir is not a directory";
    my $itemconfig = _load_apperl_config($Configs->{apperl_configs}, $CurAPPerlName);
    _install_perl_src_files($itemconfig, $perl_build_dir);
    my $SiteConfig = _load_json(SITE_CONFIG_FILE);
    if(! $itemconfig->{cosmo3}) {
        $SiteConfig or die "cannot Configure without build deps (run apperlm install-build-deps)";
        -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
        # build toolchain
        _command_or_die('make', '-C', $SiteConfig->{cosmo_repo}, '-j', 'toolchain', 'MODE=', 'ARCH=x86_64');
        # build cosmo
        print "$0: Building cosmo, COSMO_MODE=$itemconfig->{cosmo_mode} COSMO_APE_LOADER=$itemconfig->{cosmo_ape_loader}\n";
        _command_or_die('make', '-C', $SiteConfig->{cosmo_repo}, '-j4', "MODE=$itemconfig->{cosmo_mode}",
        "o/$itemconfig->{cosmo_mode}/cosmopolitan.a",
        "o/$itemconfig->{cosmo_mode}/libc/crt/crt.o",
        "o/$itemconfig->{cosmo_mode}/ape/public/ape.lds",
        "o/$itemconfig->{cosmo_mode}/ape/$itemconfig->{cosmo_ape_loader}",
        );
        $ENV{COSMO_MODE} = $itemconfig->{cosmo_mode};
        $ENV{COSMO_APE_LOADER} = $itemconfig->{cosmo_ape_loader};
        $ENV{COSMO_REPO} = $SiteConfig->{cosmo_repo};
    } else {
        $SiteConfig //= {};
        exists $SiteConfig->{cosmocc} or _install_cosmocc($SiteConfig);
        -d $SiteConfig->{cosmocc} or die $SiteConfig->{cosmocc} . ' is not a directory';
        $ENV{COSMOCC} = $SiteConfig->{cosmocc};
    }

    # Finally Configure perl
    print "cd $perl_build_dir\n";
    chdir($perl_build_dir) or die "Failed to enter perl repo";
    my @onlyextensions = ();
    push @onlyextensions, ("-Donlyextensions= ".join(' ', sort @{$itemconfig->{perl_onlyextensions}}).' ') if(exists $itemconfig->{perl_onlyextensions});
    _command_or_die('sh', 'Configure', @{$itemconfig->{perl_flags}}, @onlyextensions, @{$itemconfig->{perl_extra_flags}}, @_);
    print "$0: Configure successful, time for apperlm build\n";
}

sub _fix_bases {
    my ($in, $aliasmap) = @_;
    foreach my $key (keys %{$aliasmap}) {
        $in =~ s/^$key/$aliasmap->{$key}/;
    }
    return $in;
}

# system is pretty broken on APPerl when running on Windows
# let's search PATH ourselves ...
sub _find_zip {
    if(($^O ne 'cosmo') || (! -f '/C/Windows/System32/cmd.exe')) {
        return 'zip';
    }
    else {
        foreach my $dir (split(':', $ENV{PATH})) {
            my $zippath = "$dir/zip.exe";
            return $zippath if(-f $zippath);
        }
    }
    die("Failed to find zip.exe, did you download Info-Zip and add the folder containing zip.exe to \%PATH\%?");
}

sub Build {
    my ($zippath) = @_;
    my $Configs = _load_apperl_configs();
    my ($UserProjectConfig, $CurAPPerlName) = _load_valid_user_project_config_with_default($Configs) or die "cannot Build without valid UserProjectConfig";
    my $itemconfig = _load_apperl_config($Configs->{apperl_configs}, $CurAPPerlName);
    my $startdir = abs_path('./');

    my $PERL_APE;
    my @perl_config_cmd;
    # build cosmo perl if this isn't a nobuild config
    if(! exists $UserProjectConfig->{nobuild_perl_bin}){
        my $SiteConfig = _load_json(SITE_CONFIG_FILE) or die "cannot build without build deps (run apperlm install-build-deps)";
        if (! $itemconfig->{cosmo3}) {
            -d $SiteConfig->{cosmo_repo} or die $SiteConfig->{cosmo_repo} .' is not directory';
        } else {
            -d $SiteConfig->{cosmocc} or die $SiteConfig->{cosmocc} .' is not directory';
        }
        my $perl_build_dir = $UserProjectConfig->{configs}{$CurAPPerlName}{perl_build_dir};
        $perl_build_dir && -d $perl_build_dir or die "$perl_build_dir is not a directory";
        _install_perl_src_files($itemconfig, $perl_build_dir);
        print "cd $perl_build_dir\n";
        chdir($perl_build_dir) or die "Failed to enter perl repo";
        # build using cosmo's zlib to avoid name clashes or including two versions of zlib
        local $ENV{'BUILD_ZLIB'} = 'False' if $itemconfig->{cosmo3};
        local $ENV{'ZLIB_INCLUDE'} = $SiteConfig->{cosmocc} . '/include/third_party/zlib' if $itemconfig->{cosmo3};
        local $ENV{'ZLIB_LIB'} = '' if $itemconfig->{cosmo3};
        _command_or_die('make');
        $PERL_APE = "$perl_build_dir/perl.com";
        @perl_config_cmd = ('./perl', '-Ilib');
    }
    else {
        $PERL_APE = $UserProjectConfig->{nobuild_perl_bin};
        @perl_config_cmd = ($PERL_APE);
    }

    # prepare for install and pack
    -f $PERL_APE or die "apperlm build: perl ape not found";
    my $OUTPUTDIR = "$UserProjectConfig->{apperl_output}/$CurAPPerlName/o";
    if(-d $OUTPUTDIR) {
        print "rm -rf $OUTPUTDIR\n";
        remove_tree($OUTPUTDIR);
    }
    my $TEMPDIR = "$OUTPUTDIR/tmp";
    print "mkdir -p $TEMPDIR\n";
    make_path($TEMPDIR);
    my %proxyConfig;
    foreach my $item (qw(prefix version archname cc installprivlib installarchlib installsitelib installsitearch installprefixexp installbin installman1dir installman3dir)) {
        $proxyConfig{$item} = _cmdoutput_or_die(@perl_config_cmd, '-e', "use Config; print \$Config{$item}");
    }
    my %aliasmap = (
        '__perllib__' => $proxyConfig{installprivlib},
        '__perlarchlib__' => $proxyConfig{installarchlib},
        '__sitelib__' => $proxyConfig{installsitelib},
        '__sitearchlib__' => $proxyConfig{installsitearch}
    );
    foreach my $libdir (keys %aliasmap) {
        $aliasmap{$libdir} =~ s/$proxyConfig{installprefixexp}\///;
    }
    my @zipfiles = map { _fix_bases($_, \%aliasmap) } @{$itemconfig->{MANIFEST}};
    my $ZIP_ROOT = "$TEMPDIR$proxyConfig{installprefixexp}";

    # install cosmo perl if this isn't a nobuild config
    if(! exists $UserProjectConfig->{nobuild_perl_bin}){
        _command_or_die('make', "DESTDIR=$TEMPDIR", 'install');
        my @toremove = ("$TEMPDIR$proxyConfig{installbin}/perl", "$TEMPDIR$proxyConfig{installbin}/perl$proxyConfig{version}");
        print 'rm '.join(' ', @toremove)."\n";
        unlink(@toremove) == scalar(@toremove) or die "Failed to unlink some files";
        # HACK install Devel::PPort lib as this doesn't get done for some reason
        if (-f "$TEMPDIR$proxyConfig{installarchlib}/Devel/PPPort.pm") {
            _copy_recursive("lib/auto/Devel/PPPort", "$TEMPDIR$proxyConfig{installarchlib}/auto/Devel");
            unlink("$TEMPDIR$proxyConfig{installarchlib}/auto/Devel/PPPort/.exists");
        }
    }
    else {
        make_path($ZIP_ROOT);
    }

    # add zip_extra_files to the tree
    foreach my $destkey (keys %{$itemconfig->{zip_extra_files}}) {
        my $dest = "$ZIP_ROOT/"._fix_bases($destkey, \%aliasmap);
        foreach my $file (@{$itemconfig->{zip_extra_files}{$destkey}}) {
            _copy_recursive($file, $dest);
        }
    }

    # pack
    my $APPPATH = "$TEMPDIR/".basename($PERL_APE);
    my $packAPE = sub {
        my $copyexe = sub {
            my ($srcpath, $destpath) = @_;
            print "cp $srcpath $destpath\n";
            copy($srcpath, $destpath) or die "copy failed: $!";
            print "chmod 755 $destpath\n";
            chmod(0755, $destpath) or die $!;
        };
        $copyexe->($PERL_APE, $APPPATH);
        my $srcdbg = "$PERL_APE.dbg";
        for(1..2) {
            if(-f $srcdbg) {
                $copyexe->($srcdbg, "$APPPATH.dbg");
                last;
            }
            $srcdbg = $PERL_APE;
            $srcdbg =~ s/com$/elf/;
        }
        if((! exists $UserProjectConfig->{nobuild_perl_bin}) || scalar(keys %{$itemconfig->{zip_extra_files}})) {
            print "cd $ZIP_ROOT\n";
            chdir($ZIP_ROOT) or die "failed to enter ziproot";
            _command_or_die($zippath // _find_zip(), '-r', $APPPATH, @zipfiles);
        }
    };
    $packAPE->();

    # install modules
    if(exists $itemconfig->{install_modules}) {
        my $perlman1 = "$TEMPDIR$proxyConfig{installman1dir}";
        my $perlman3 = "$TEMPDIR$proxyConfig{installman3dir}";
        my $perlbin = "$TEMPDIR$proxyConfig{installbin}";
        my $perllib = "$TEMPDIR$proxyConfig{installprivlib}";
        my $perlarchlib = "$TEMPDIR$proxyConfig{installarchlib}";
        my $mmopt = sub {
            my @mmopt = ("PERL_LIB=$perllib", "PERL_ARCHLIB=$perlarchlib",
                #"MAP_TARGET=perl.com.dbg",
                "MAP_TARGET=perl.com",
                "INSTALLDIRS=perl",
                "INSTALLARCHLIB=$perlarchlib",
                "INSTALLPRIVLIB=$perllib",
                "INSTALLBIN=$perlbin",
                "INSTALLSCRIPT=$perlbin",
                "INSTALLMAN1DIR=$perlman1",
                "INSTALLMAN3DIR=$perlman3"
            );
            my $str;
            $str .= qq["$_" ] foreach @mmopt;
            chop $str;
            return $str;
        }->();
        my $mbopt = sub {
            my %mbinstall_path = (
                lib => $perllib,
                arch => $perlarchlib,
                script => $perlbin,
                bin => $perlbin,
                bindoc => $perlman1,
                libdoc => $perlman3
            );
            my $mbopt;
            foreach my $key (keys %mbinstall_path) {
                $mbopt .= qq[--install_path $key=$mbinstall_path{$key} ];
            };
            chop $mbopt;
            return $mbopt;
        }->();
        local $ENV{PERL_MB_OPT} = $mbopt;
        local $ENV{PERL_MM_OPT} = $mmopt;
        local $ENV{PERL5LIB} = $perllib;
        local $ENV{PERL_LOCAL_LIB_ROOT} = '';
        foreach my $module (@{$itemconfig->{install_modules}}) {
            my $modulepath = "$startdir/$module";
            if(-d $modulepath) {
                _copy_recursive($modulepath, $TEMPDIR);
                $modulepath = "$TEMPDIR/".basename($modulepath);
            }
            elsif( -f _) {
                _command_or_die('tar', 'xvf', $modulepath, '-C', $TEMPDIR);
                $modulepath = "$TEMPDIR/".basename($modulepath);
                $modulepath =~ s/\.tar.*$//;
            }
            else {
                die "Module must be a directory or tarball";
            }

            print "cd $modulepath\n";
            chdir($modulepath) or die "Failed to enter module dir";
            # Module::Build (including installing Module::Build)
            # Beware, Module::Build has no support for relinking the Perl binary like EU::MM - https://rt.cpan.org/Public/Bug/Display.html?id=47282
            if(-f 'Build.PL') {
                _command_or_die($APPPATH, 'Build.PL');
                _command_or_die($APPPATH, 'Build');
                _command_or_die($APPPATH, 'Build', 'install');
            }
            # ExtUtils::MakeMaker
            elsif( -f 'Makefile.PL') {
                # build
                _command_or_die($APPPATH, 'Makefile.PL');
                _command_or_die('make');
                # install into the src tree
                _command_or_die('make', 'install');
                # build a new perl binary, convert to APE, and repack zip
                #_command_or_die('make', 'perl.com.dbg');
                #_command_or_die(dirname($proxyConfig{cc})."/x86_64-linux-musl-objcopy", '-S', '-O', 'binary', 'perl.com.dbg', 'perl.com');
                _command_or_die('make', 'Makefile.aperl');
                # HACK, add in DynaLoader as it's missing
                open(my $makefile, '<', 'Makefile.aperl') or die "failed to open Makefile.aperl";
                my @newlines = map { $_ =~ s/writemain\((grep[^\)]+\))/writemain((DynaLoader, $1)/; $_} <$makefile>;
                close($makefile);
                open(my $newmakefile, '>', 'Makefile.aperl') or die "failed to open Makefile.aperl for writing";
                print $newmakefile $_ foreach @newlines;
                close($newmakefile);
                # finally rebuild perl
                _command_or_die('make', '-f', 'Makefile.aperl', 'perl.com');
                $PERL_APE = abs_path('./perl.com');
            }
            else {
                die "No Makefile.PL or Build.PL found, unable to install module";
            }
            $packAPE->();
        }
    }

    # patch default script
    if(exists $itemconfig->{default_script}) {
        length($itemconfig->{default_script}) <= 255 or die "default script path is too long";
        open(my $fh, '+<:raw', $APPPATH) or die "$!";
        my $fsize = (stat($fh))[7];
        my $bread = read($fh, my $outdata, $fsize);
        $bread && $bread == $fsize or die "failed to read full file $APPPATH";
        my $sentinel = "APPERL_DEFAULT_SCRIPT";
        my $sentinelpos = index($outdata, $sentinel);
        $sentinelpos != -1 or die "Failed to find APPERL_DEFAULT_SCRIPT, is this an old APPerl binary?";
        print "patching default script at " . ($sentinelpos+length($sentinel)+1) . "\n";
        seek($fh, $sentinelpos+length($sentinel)+1, SEEK_SET) or die "$!";
        print $fh $itemconfig->{default_script}."\0" or die "$!";
        close($fh);
    }

    foreach my $file ('perl.com', 'perl.com.dbg') {
        my $srcpath = "$TEMPDIR/$file";
        -e $srcpath or next;
        my $destpath = "$OUTPUTDIR/$file";
        print "mv $srcpath $destpath\n";
        move($srcpath, $destpath) or die "move failed: $!";
    }

    # copy to user specified location
    if(exists $itemconfig->{dest}) {
        print "cd ".START_WD."\n";
        chdir(START_WD) or die "Failed to restore cwd";
        foreach my $srcfile ('perl.com', 'perl.com.dbg') {
            my $destfile = $itemconfig->{dest};
            $destfile .= '.dbg' if ($srcfile =~ /dbg$/);
            my @args = ("$UserProjectConfig->{apperl_output}/$CurAPPerlName/o/$srcfile", $destfile);
            -e $args[0] or next;
            print 'cp '.join(' ', @args)."\n";
            cp(@args) or die "copy failed: $!";
        }
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
        my $usage = <<'END_USAGE';
apperlm list
List available APPerl configs; checks apperl-project.json and built-in
to Perl::Dist::APPerl configs. If a current config is set it is denoted
with a '*'.
END_USAGE
        die($usage) if(@_);
        Perl::Dist::APPerl::Status();
    }
    elsif($command eq 'build') {
        my $usage = <<'END_USAGE';
apperlm build [-z|--zippath <zip_binary_path>]
  -z|--zippath     Path to InfoZip zip executable
Build APPerl. If the current config is a from-scratch build, you must
run `apperlm configure` first.
END_USAGE
        my $zippath;
        my $help;
        GetOptionsFromArray(\@_, "zippath|z=s" => \$zippath,
                   "help|h" => \$help,
        ) or die($usage);
        if($help) {
            print $usage;
            exit 0;
        }
        Perl::Dist::APPerl::Build($zippath);
    }
    elsif($command eq 'configure') {
        Perl::Dist::APPerl::Configure(@_);
    }
    elsif($command =~ /^(\-)*(halp|help|h)$/i) {
        print $generic_usage;
    }
    elsif($command =~ /^(\-)*(version|v)$/i) {
        my $message = <<"END_USAGE";
apperlm $VERSION
Copyright (C) 2022 Gavin Arthur Hayes
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
END_USAGE
        print $message;
    }
    elsif($command eq 'checkout') {
        scalar(@_) == 1 or die('bad args');
        my $cfgname = $_[0];
        Perl::Dist::APPerl::Checkout($cfgname);
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
    elsif($command eq 'get-config-key') {
        scalar(@_) == 2 or die('bad args');
        my $itemconfig = _load_apperl_config(_load_apperl_configs()->{apperl_configs}, $_[0]);
        print $itemconfig->{$_[1]};
    }
    else {
        die($generic_usage);
    }
    1;
}

sub _command_or_die {
    print join(' ', @_), "\n";
    (system { $_[0] } @_) == 0 or die;
}

sub _cmdoutput_or_die {
    print join(' ', @_), "\n";
    my $kid = open(my $from_kid, '-|', @_) or die "can't fork $!";
    my $output = do { local $/; <$from_kid> };
    waitpid($kid, 0);
    (($? >> 8) == 0) or die("child failed");
    return $output;
}

sub _cmdinputfile_or_die {
    my $input_file = pop @_;
    print join(' ', @_), " < $input_file\n";
    my $kid = fork() // die "forking failed";
    if ($kid == 0) {
        open(STDIN, '<', $input_file) or die "Can't dup to STDIN";
        exec { $_[0] } @_;
        die "exec failed"
    }
    waitpid($kid, 0);
    (($? >> 8) == 0) or die("child failed");
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
    # keys that start with '+' are appended to the non-plus variant instead of replacing
    # keys that start with '-' are removed from the non-plus variant instead of replacing
    # Removing a key added the same stage or vice versa is undefined
    my %itemconfig;
    foreach my $config (@configlist) {
        foreach my $key (keys %$config) {
            if($key =~ /^(\+|\-)(.+)/) {
                my $append = $1 eq '+';
                my $realkey = $2;
                exists $itemconfig{$realkey} or die "cannot append without existing key: $realkey";
                my $rtype = ref($itemconfig{$realkey});
                $rtype or die("not ref");
                if($append) {
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
                    if($rtype eq 'ARRAY') {
                        _remove_arr_items_from_arr($itemconfig{$realkey}, $config->{$key});
                    }
                    else {
                        die($rtype);
                    }
                }
            }
            else {
                $itemconfig{$key} = $config->{$key};
            }
        }
    }

    # switch these from relative paths to abs paths
    foreach my $destdir (keys %{$itemconfig{zip_extra_files}}) {
        foreach my $path (@{$itemconfig{zip_extra_files}{$destdir}}) {
            $path = abs_path($path);
            $path or die "zip_extra_files: check that all files exist for destdir: $destdir";
            -e $path or die "zip_extra_files: missing file $path";
        }
    }

    # add in ourselves for bootstrapping, this even works when running internal Perl::Dist::APPerl from a bootstrapped build
    if(exists $itemconfig{'include_Perl-Dist-APPerl'} && $itemconfig{'include_Perl-Dist-APPerl'}) {
        my $thispath = abs_path(__FILE__);
        defined($thispath) or die(__FILE__.'issues?');
        push @{$itemconfig{zip_extra_files}{"__perllib__/Perl/Dist"}}, $thispath;
        my $apperlm = $0;
        if(basename($0) ne 'apperlm') {
            $apperlm = dirname($thispath)."/../../../script/apperlm";
        }
        $apperlm = abs_path($apperlm);
        defined($apperlm) or die "error getting path to apperlm";
        my @additionalfiles = ($apperlm);
        -e $_ or die("$_ $!") foreach @additionalfiles;
        push @{$itemconfig{zip_extra_files}{bin}}, @additionalfiles;
        opendir(my $dh, SHARE_DIR) or die "error opening patch dir";
        while(my $file = readdir $dh) {
            next if(($file eq '.') || ($file eq '..'));
            push @{$itemconfig{zip_extra_files}{"__perllib__/auto/share/dist/Perl-Dist-APPerl"}}, SHARE_DIR."/$file";
        }
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
            return ($UserProjectConfig, $CurAPPerlName);
        }
    }
    return ();
}

sub _load_valid_user_project_config_with_default {
    my ($Configs) = @_;
    my ($UserProjectConfig, $CurAPPerlName) = _load_valid_user_project_config($Configs);
    if($UserProjectConfig) {
        return ($UserProjectConfig, $CurAPPerlName);
    } elsif(!exists $Configs->{defaultconfig}) {
        return ();
    }
    Checkout($Configs->{defaultconfig});
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
several x86_64 operating systems via the same binary. It builds to a
single binary with perl modules packed inside of it.

Cross-platform, single binary, standalone Perl applications can be made
by building custom versions of APPerl, with and without compiling
Perl from scratch, so it can be used an alternative to L<PAR::Packer>.
APPerl could also easily be added to development SDKs,
carried on your USB drive, or just allow you to run the exact same perl
on all your PCs multiple computers.

This package documentation covers the apperlm tool for building APPerl,
APPerl usage, and how to create applications with APPerl. To handle the
chicken-and egg-situation of needing Perl to build APPerl, APPerl may
be bootstrapped from an existing build of APPerl. See README.md for
instructions.

Information on the creation of APPerl can be found in this blog post:
L<https://computoid.com/posts/Perl-is-Actually-Portable.html>.

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

To build small APPerl from scratch:

    apperlm install-build-deps
    apperlm checkout small
    apperlm configure
    apperlm build

To start an APPerl project from an existing APPerl and build it:

    mkdir src
    mv perl.com src/
    apperlm init --name your_config_name --base nobuild-v0.1.0
    apperlm build

To start an APPerl project and build from scratch:

    apperlm install-build-deps
    apperlm init --name your_config_name --base small
    apperlm configure
    apperlm build

=head1 apperlm

The C<apperlm> (APPerl Manager) script is a CLI interface to configuring
and building APPerl.

=head2 COMMAND REFERENCE

=over 4

=item *

C<apperlm install-build-deps> installs APPerl build dependencies,
currently, a fork of the perl5 source and the Cosmopolitan Libc. This
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
is set it is denoted with a C<*>. Project configs are
labeled PROJECT. The exact configuration of a STABLE config may change
from release to release of Perl::Dist::APPerl, but only non-breaking
changes should occur. ROLLING configurations are always the latest
STABLE configurations, but breaking changes may occur from release to
release of Perl::Dist::APPerl.

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
C<apperl-project.json> to customize output binary path and name. A
C<zip> binary is required to build, see README.md for details. The
C<zip> binary path may be explictly set by passing in
--zippath <zip_binary_path> .

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

=head2 EMBEDDED SCRIPTS

The APPerl binary is also a ZIP file. Paths starting with C</zip/>
refer to files compressed in the binary itself. At runtime the zip
filesystem is readonly, but additional modules and scripts can be added
just by adding them to the zip file. For example, perldoc and the other
standard scripts are shipped inside of C</zip/bin>

  ./perl.com /zip/bin/perldoc perlcosmo

For convenience, APPerl has some other ways of invoking embedded
scripts:

=over 4

=item *

C<APPERL_SCRIPTNAME> - When the environment variable C<APPERL_SCRIPTNAME>
is set, APPerl attempts to load the basename of C<APPERL_SCRIPTNAME>
without file extension from C</zip/bin> or opens the perl interpreter
like normal if it is C<perl>.

  APPERL_SCRIPTNAME=perldoc ./perl.com perlcosmo

=item *

C<argv[0]> - If C<APPERL_SCRIPTNAME> is not set, APPerl attempts to
load the basename of C<argv[0]> without file extension from C</zip/bin>
or opens the perl interpreter like normal if it is C<perl>. This
enables making single binary perl applications, with a symlink, move,
or copy!

  ln -s perl.com perldoc.com
  ./perldoc.com perlcosmo

=item *

C<APPERL_DEFAULT_SCRIPT> - If C<argv[0]> doesn't yield a valid target
either, if the C<APPERL_DEFAULT_SCRIPT> field inside of the binary
is set, APPerl will attempt to load that. This way is meant for APPerl
application authors to protect against accidental rename messing up
C<argv[0]> script execution. L</BUILDING AN APPLICATION FROM EXISTING APPERL>
shows how to set it with C<"default_script">, but you could also
set/change it, by searching for C<APPERL_DEFAULT_SCRIPT> in a hex
editor and modifying it.

=back

If a valid target is not found via the script execution methods, the
perl interpreter is invoked like normal.

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

=head2 BUILDING AN APPLICATION FROM EXISTING APPERL

The easiest way to build an APPerl application is to build it from
existing APPerl. If your application doesn't depend on non-standard
C or XS extensions, it can be built from one of the official APPerl
builds, skipping the need for building Perl from scratch.

Enter your projects directory, create it if it doesn't exists. Download
or copy in an existing version of APPerl you wish to build off of.
Official builds are available on the APPerl web page:
L<https://computoid.com/APPerl/>.
Create a new nobuild APPerl project and build it.

  cd projectdir
  mkdir src
  cp ./perl.com src/
  apperlm init --name my_nobuild_config
  apperlm build

Now you should have a newly built perl.com inside the current
directory. However, this isn't very exciting as it's identical to the
one you copied into src. Let's create a script.

  printf "%s\n" \
  '#!/usr/bin/perl' \
  'use strict; use warnings;' \
  'print "Hello, World!\n";' > src/hello

To add it open apperl-project.json and add the following to
my_nobuild_config:

  "zip_extra_files" : { "bin" : ["src/hello"] }

Rebuild and try loading the newly added script

   apperlm build
   ./perl.com /zip/bin/hello

You have embedded a script inside APPerl, however running it is a
little awkward. What if you could run it by the name of the script?
APPerl has argv[0] script execution, enabling the following:

  ln -s perl.com hello
  ./hello

Now, you may still wish for your application to be run, even if the
executable is renamed. Add C<default_script> to your config to set a
fallback script:

  "default_script" : "/zip/bin/hello"

Now, what about Perl modules? Perl modules can be packed in the same
way, but to ease setting the correct directory to packing them into,
the magic prefix __perllib__ can be used in the destination. Note, you
may have to add items to the MANIFEST key if the MANIFEST isn't set
permissively already.

  "zip_extra_files" : { "__perllib__/Your" : ["Module.pm"] }

=head2 BUILDING AN APPLICATION FROM SCRATCH

If your application requires non-standard C or XS extensions, or you
would like to install CPAN distributions through their standard
mechanisms (C<Makefile.PL> or C<Build.PL>), APPerl must be built from
scratch as it only supports static linking and installing distributions
may require adding in extensions. Note, this process can only be
completed on Linux as building the Cosmopolitan Libc from scratch is
only supported on Linux and APPerl uses the unix-like C<Configure> to
configure perl. This tutorial assumes you already have an APPerl
project, possibly from following the L</BUILDING AN APPLICATION FROM EXISTING APPERL>
tutorial.

First install the APPerl build dependencies and create a new config
based on the current full config, checkout, configure, and build.

  apperlm install-build-deps
  apperlm new-config --name my_src_build_config --base full
  apperlm checkout my_src_build_config
  apperlm configure
  apperlm build

If all goes well you should have compiled APPerl from source!

  ./perl.com -V
  stat perl.com

=head3 ADDING CPAN DISTRIBUTIONS

The recommended way of adding CPAN distributions or C or XS extensions
is via the C<"install_modules"> mechanism.

Currently, no CPAN client is used, so you must download or make
available or disk otherwise the needed distributions for C<apperlm>
to be able to build and install them into your APPerl. It supports
folder paths and paths to tarballs such as the one's directly
downloaded from CPAN.

For example to install B<Geo::Calc:XS>, download its tarball from CPAN
and add to to my_src_build_config in apperl-project.json:

  "install_modules" : ["Geo-Calc-XS-0.33.tar.gz"]

Then, build and test it:

  apperlm build
  ./perl.com -MGeo::Calc::XS -e 'print $Geo::Calc::XS::VERSION'

Distributions in C<"install_modules"> are installed in order, so
modules with dependencies just need them to be installed before in
order for them to be added.

=cut

=head3 ADDING VIA PERL BUILD

This method is B<NOT RECOMMENDED> as many modules/extensions cannot be
built this way, it only works for modules that can be built with
C<miniperl>, do not have dependencies, and requires reconfiguring Perl.
The method listed in L</ADDING CPAN DISTRIBUTIONS> supersedes this
method.

Now let's create a very basic C extension.

  mkdir MyCExtension
  printf "%s\n" \
  "package MyCExtension;" \
  "use strict; use warnings;" \
  "our \$VERSION = '0.0';" \
  "require XSLoader;" \
  'XSLoader::load("MyCExtension", $VERSION);' \
  "1;" > MyCExtension/MyCExtension.pm
  printf "%s\n" \
  '#define PERL_NO_GET_CONTEXT' \
  '#include "EXTERN.h"' \
  '#include "perl.h"' \
  '#include "XSUB.h"' \
  '#include <stdio.h>' \
  '' \
  'MODULE = MyCExtension    PACKAGE = MyCExtension' \
  '' \
  'void' \
  'helloworld()' \
  '    CODE:' \
  '        printf("Hello, World!\n");' > MyCExtension/MyCExtension.xs

Add it to my_src_build_config in apperl-project.json . Keys that begin
with '+' will be merged with the non-plus variant of the parent config.
Keys the begin with '-' will be removed from the non-minus variant of
the parent config.

  "perl_repo_files" : { "ext" : [
      "MyCExtension"
  ]},
  "+MANIFEST" : ["__perlarchlib__/MyCExtension.pm"],
  "+perl_onlyextensions" : ["MyCExtension"]

Build it and try it out. apperlm checkout is needed as Perl must be
rebuilt from scratch as the Configure flags changed and new files were
added to the perl5 repo.

  apperlm checkout my_src_build_config
  apperlm configure
  apperlm build
  ./perl-small.com -MMyCExtension -e 'MyCExtension::helloworld();'

Now for completeness sake, let's turn this custom build of APPerl into
an application that calls the extension function we just added. First
make the application main script.

  printf "%s\n" \
  '#!/usr/bin/perl' \
  'use strict; use warnings;' \
  'use MyCExtension;' \
  'MyCExtension::helloworld();' > helloext

Then, add it the project config and set the dest binary name to match
the script so that it will launch the script.

  "dest" : "helloext.com",
  "+MANIFEST" : ["__perlarchlib__/MyCExtension.pm", "bin/helloext"],
  "zip_extra_files" : { "bin" : ["helloext"] }

Build and test it.

  apperlm build
  ./helloext.com

=head1 DEBUGGING

APPerl binaries as with other Actually Portable Executables built with
the Cosmopolitan Libc have some nice debug features:

Syscall logging can be performed just by running with C<--strace> as
the first argument:

  ./perl.com --strace /zip/bin/perldoc perlcosmo

Function call logging can be performed if you have the accompanying
C<.com.dbg> file in the same directory as your APPerl binary:

  ./perl.com --ftrace /zip/bin/perldoc perlcosmo

In theory, it should be possible to use C<gdb> with APPerl binaries,
but the author has had great difficulty getting this to work. The
C<dbg> APPerl config is available to build Cosmopolitan with C<MODE=dbg>
and Perl with C<-Doptimize=-g3 -gdwarf-4>.

=head1 SUPPORT AND DOCUMENTATION

APPerl web page: L<https://computoid.com/APPerl/>

Support and bug reports can be found at the repository
L<https://github.com/G4Vi/Perl-Dist-APPerl>

=head1 ACKNOWLEDGEMENTS

The Cosmopolitan Libc (L<https://github.com/jart/cosmopolitan>)
contributors, especially Justine Tunney (L<https://justine.lol/>) and
Gautham Venkatasubramanian (L<https://ahgamut.github.io>). APPerl
wouldn't be possible without Actually Portable Executables and
polyfills of several Linux and POSIX APIs for other platforms.
Gautham's Python port
(L<https://ahgamut.github.io/2021/07/13/ape-python/>)
inspired this project.

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut