# Perl-Dist-APPerl
[Actually Portable Perl](https://computoid.com/APPerl/)

## DESCRIPTION

Actually Portable Perl (APPerl) is a distribution of Perl the runs on
several x86_64 operating systems via the same binary. It builds to a
single binary with perl modules packed inside of it.

Cross-platform, single binary, standalone Perl applications can be made
by building custom versions of APPerl, with and without compiling
Perl from scratch, so it can be used an alternative to **PAR::Packer**.
APPerl could also easily be added to development SDKs,
carried on your USB drive, or just allow you to run the exact same perl
on all your PCs multiple computers.

Information on the creation of APPerl can be found in this
[blogpost](https://computoid.com/posts/Perl-is-Actually-Portable.html).

## NON-PERL DEPENDENCIES

A `zip` binary ([Info-ZIP](https://infozip.sourceforge.net/)) is
required to build. Your distro likely has it in its package
repository. For Windows, the official download is available via FTP
<ftp://ftp.info-zip.org/pub/infozip/>.

### Windows x64 Info-ZIP download and install instructions
- Get an FTP client if needed: [WinSCP](https://winscp.net/eng/index.php)
- Connect to the [InfoZip FTP server](ftp://ftp.info-zip.org/pub/infozip/) with anonymous login.
- Enter the `win32` folder and download `zip300xn-x64.zip`.
- Extract the zip file and its inner zip file.
- Add the folder containing `zip.exe` to `%PATH%`: [step-by-step](https://www.computerhope.com/issues/ch000549.htm)

The last step isn't strictly necessary, the absolute path to a zip binary may be passed in to `apperlm build` with the `--zippath` arg.

## TRADITIONAL INSTALLATION

To install this module, run the following commands:
```
perl Makefile.PL
make
make test
make install
```

## BOOTSTRAPPING

To handle the chicken-and egg-situation of needing Perl to build
APPerl, APPerl may be bootstrapped from an existing build of APPerl.
See [releases](https://github.com/G4Vi/Perl-Dist-APPerl/releases) and
pick a "full" build. From inside a copy of this repo, you can run
`apperlm` as follows: `./perl.com -Ilib script/apperlm`

`apperlm` is actually included in a full build of APPerl too.
```
ln -s perl.com apperlm
./apperlm
```

## SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

`perldoc Perl::Dist::APPerl`

More information may be available at the [APPerl webpage](https://computoid.com/APPerl/)

Support and bug reports can be found at the repository <https://github.com/G4Vi/Perl-Dist-APPerl>

## LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself. See LICENSE.
