# acinclude.m4 for Xastir
#
# Copyright (C) 2000-2023 The Xastir Group
#

# test for devices.  Avoid the tests on Cygwin as they hang on some
# WinXP boxes.
#
AC_DEFUN([XASTIR_DETECT_DEVICES],
[
AC_MSG_CHECKING([for devices])
if test -d /proc/registry ; then
ac_tnc_port=/dev/ttyS0
ac_gps_port=/dev/ttyS1
elif test -c /dev/cuaa0 ; then
ac_tnc_port=/dev/cuaa0
ac_gps_port=/dev/cuaa1
elif test -c /dev/ttyS0 ; then
ac_tnc_port=/dev/ttyS0
ac_gps_port=/dev/ttyS1
elif test -c /dev/cua/a ; then
ac_tnc_port=/dev/cua/a
ac_gps_port=/dev/cua/b
else
ac_tnc_port=none
ac_gps_port=none
fi

AC_DEFINE_UNQUOTED([TNC_PORT], "$ac_tnc_port", [Default TNC port.])
AC_DEFINE_UNQUOTED([GPS_PORT], "$ac_gps_port", [Default GPS port.])
AC_MSG_RESULT(found $ac_tnc_port and $ac_gps_port)
])

# add search paths
AC_DEFUN([XASTIR_ADD_SEARCH_PATHS],
[
AC_MSG_CHECKING([for search paths])

test -d /usr/local/include && CPPFLAGS="-I/usr/local/include $CPPFLAGS"
test -d /usr/local/lib && LDFLAGS="-L/usr/local/lib $LDFLAGS"

for d in /sw /opt /opt/local /usr/dt/share /usr/sfw /opt/sfw; do
test -d $d/include && CPPFLAGS="$CPPFLAGS -I$d/include"
test -d $d/lib && LDFLAGS="$LDFLAGS -L$d/lib"
done

AC_MSG_RESULT([done])
])

# add compiler flags
AC_DEFUN([XASTIR_COMPILER_FLAGS],
[

# brutal!
# check for sed maybe?
if test "$ac_cv_prog_ac_ct_CC" = "gcc"; then
gcc --help | sed -e "/^[^ ]/d" -e "/^ [^ ]/d" -e "/^  [^-]/d" -e "s/  //" -e "s/ .*//" > gccflags

# I need a test for -Wno-return-type and -DFUNCPROTO=15
# before adding them

for f in -no-cpp-precomp -pipe; do
grep -- $f gccflags > /dev/null && CFLAGS="$CFLAGS $f"
done

# delete temporary file
rm -f gccflags

# add any other flags that aren't added earlier
# Can't add "-Wno-unused-parameter" as older compilers don't like
# it.  
#
for f in -W -Wall -Wpointer-arith -Wstrict-prototypes; do
echo $CFLAGS | grep -- $f > /dev/null || CFLAGS="$CFLAGS $f"
done

# Now check whether to use -Wno-unused-parameter (gcc 3) or -Wno-unused
AC_MSG_CHECKING([whether compiler accepts -Wno-unused-parameter])
save_CFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Wno-unused-parameter"
AC_COMPILE_IFELSE(
 [AC_LANG_PROGRAM([[]],
                  [[int i;]])],
 [AC_MSG_RESULT([yes])],
 [AC_MSG_RESULT([no, using -Wno-unused]); CFLAGS="$save_CFLAGS -Wno-unused"])

# end gcc-specific checks
fi

# add any pthread flags now
CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

AC_MSG_CHECKING([for compiler flags])
AC_MSG_RESULT(using $CFLAGS)
])

AC_DEFUN([XASTIR_DETECT_BINARIES],
[
BINPATH=$PATH

for d in / /usr /usr/local /usr/X11 /usr/X11R6 /usr/sfw /opt/sfw /opt/local /sw; do
test -d $d/bin && echo $BINPATH | grep -- $d/bin > /dev/null || BINPATH="$BINPATH:$d/bin"
done

# it would be much nicer to do this in a for loop

if test "$use_lsb" = "yes"; then
  AC_DEFINE_UNQUOTED(HAVE_CONVERT, 1, [Define if you have gm or convert]) 
  AC_DEFINE_UNQUOTED(CONVERT_PATH, "/opt/Xastir/bin/gm convert", [Path to gm or convert]) 
else
  AC_PATH_PROG(gm, [gm version], no, $BINPATH)
  AC_CHECK_FILE(/usr/bin/gm.exe, gm="/usr/bin/gm")
  if test "$gm" != "no"; then
    AC_DEFINE_UNQUOTED(HAVE_CONVERT, 1, [Define if you have gm or convert]) 
    AC_DEFINE_UNQUOTED(CONVERT_PATH, "${gm} convert", [Path to gm or convert])
  else 
    AC_PATH_PROG(convert, [convert --version], no, $BINPATH)
    AC_CHECK_FILE(/usr/bin/convert.exe, convert="/usr/bin/convert")
    if test "$convert" != "no"; then
      AC_DEFINE_UNQUOTED(HAVE_CONVERT, 1, [Define if you have convert]) 
      AC_DEFINE_UNQUOTED(CONVERT_PATH, "${convert}", [Path to convert]) 
    fi
  fi
fi
 
AC_PATH_PROG(lpr, [lpr /dev/null], no, $BINPATH)
if test "$lpr" != "no"; then
  AC_DEFINE_UNQUOTED(HAVE_LPR, 1, [Define if you have lpr]) 
  AC_DEFINE_UNQUOTED(LPR_PATH, "${lpr}", [Path to lpr]) 
fi

#Find gv executable
AC_PATH_PROG(gv, [gv], no, $BINPATH)

if test "$gv" != "no"; then
  # Test gv version
  AC_MSG_CHECKING([gv version])
  gv_new="no";
  gv_version=`gv --version`
  gv_test=`echo $gv_version | cut -d ' ' -f 1`
  if test "$gv_test" != "gv"; then
    gv_version=`gv -v`
  fi
  gv_test=`echo $gv_version | cut -d ' ' -f 1`
  if test "$gv_test" != "gv"; then
    # No gv found.  Put an AC_PATH_PROG here so the "then" clause has
    # something to do and so that we get proper output to the user.
    AC_MSG_RESULT([gv version test likely exited with error, this is what it said: $gv_version])
  else
    gv_short_version=`echo $gv_version | cut -d ' ' -f 2`
    gv_major=`echo $gv_short_version | cut -d '.' -f 1`
    gv_minor=`echo $gv_short_version | cut -d '.' -f 2`
    gv_tiny=`echo $gv_short_version | cut -d '.' -f 3`
    if test "$gv_major" -gt 3; then
      gv_new="yes";
    elif test "$gv_major" -ge 3 -a "$gv_minor" -gt 6; then
      gv_new="yes";
    elif test "$gv_major" -ge 3 -a "$gv_minor" -ge 6 -a "$gv_tiny" -ge 1; then
      gv_new="yes";
    fi
    if test "$gv_new" != "no"; then
      AC_MSG_RESULT([new, >= 3.6.1])
      AC_DEFINE_UNQUOTED(HAVE_GV, 1, [Define if you have gv])
      AC_DEFINE_UNQUOTED(HAVE_NEW_GV, 1, [Define if you have old gv])
      AC_DEFINE_UNQUOTED(GV_PATH, "${gv}", [Path to gv])
    else
      AC_MSG_RESULT([old, pre 3.6.1])
      AC_DEFINE_UNQUOTED(HAVE_GV, 1, [Define if you have gv])
      AC_DEFINE_UNQUOTED(HAVE_OLD_GV, 1, [Define if you have old gv])
      AC_DEFINE_UNQUOTED(GV_PATH, "${gv}", [Path to gv])
    fi
  fi
fi

if test "$use_festival" != "no"; then 
 AC_PATH_PROG(festival, [festival], no, $BINPATH)
 if test "$festival" != "no"; then
   AC_DEFINE_UNQUOTED(HAVE_FESTIVAL, 1, [Define if you have festival])
 fi
fi

if test "$use_gpsman" != "no"; then
 AC_PATH_PROG(gpsman, [gpsman haslib gpsmanshp], no, $BINPATH)
 if test "$gpsman" != "no"; then
   AC_DEFINE_UNQUOTED(HAVE_GPSMAN, 1, [Define if you have gpsman])
   AC_DEFINE_UNQUOTED(GPSMAN_PATH, "${gpsman}", [Path to gpsman])
 fi
fi

if test "$use_err_popups" != "no"; then
 AC_DEFINE_UNQUOTED(HAVE_ERROR_POPUPS, 1, [Define if you have error popups enabled])
fi

if test "$use_lsb" != "no"; then
 AC_DEFINE_UNQUOTED(__LSB__, 1, [Define if you're compiling for Linux Standard Base])
fi



])

AC_DEFUN([XASTIR_CHECK_POSTGIS],
[
BINPATH="${PATH}${EXTRA_BIN_PATH}"
# test for postgresql
if test "${with_postgis+set}" = set; then
  PG_CONFIG="pg_config"
  if test "$with_postgis" != "yes"; then 
    # get path if provided
    pg_path="$with_postgis"
    PG_CONFIG_PATH="${pg_path}/bin"
    BINPATH="${BINPATH}:${PG_CONFIG_PATH}"
    POSTGIS_LIB_DIR="-L${pg_path}/lib"
    AC_PATH_PROG(PG_CONFIG, [pg_config], no, $PG_CONFIG_PATH)
  else 
    AC_PATH_PROG(PG_CONFIG, [pg_config], no)
  fi
  if test "$PG_CONFIG" != "no"; then
    # Check for postgis spatial extensions.
    # Look for lwpostgis.sql script in default location.
    # If found, is likely a postgis installation.
    # Need more definitive test for postgis, as this may fail to detect postgres 
    # installations where this script was removed, and will incorrectly 
    # detect postgres without postgis where this script has been installed but not run.
    AC_PATH_PROG(LWPOSTGIS, [lwpostgis.sql], no, "${pg_path}/share")
    if test "LWPOSTGIS" != "no"; then 
       #postgres with postgis enabled
       use_postgis=yes
       use_spatial_db=yes
       save_cppflags="$CPPFLAGS" 
       save_cxxflags="$CXXFLAGS" 
       save_libs="$LIBS" 
       save_ldflags="$LDFLAGS" 
       CPPFLAGS="$CPPFLAGS -I`${PG_CONFIG} --includedir` `${PG_CONFIG} --cppflags`" 
       CXXFLAGS="$CXXFLAGS `${PG_CONFIG} --cflags`" 
       LDFLAGS="$LDFLAGS `${PG_CONFIG} --ldflags`" 
       LIBS="${POSTGIS_LIB_DIR} `${PG_CONFIG} --libs` -lpq $LIBS" 
       AC_DEFINE(HAVE_POSTGIS, 1, Postgresql with postgis is present. )
    else
       AC_MSG_WARN(*** Cannot find lwpostgis.sql:  Building w/o Postgresql/Postgis support. ***)
       AC_MSG_WARN(*** Postgresql was found, but does not appear to have Postgis added.     ***)
       AC_MSG_WARN(*** Install and enable postgis and leave the lwpostgis.sql script in     ***)
       AC_MSG_WARN(*** ${pg_path}/share                                                     ***)
    fi
  else
    use_postgis=no
    AC_MSG_WARN(*** Cannot find pg_config:  Building w/o Postgresql/Postgis support. ***)
    AC_MSG_WARN(*** Specify the path to the posgresql installation directory         ***)
    AC_MSG_WARN(*** For example: --with-postgis=/usr/local/pgsql                     ***)
  fi
fi

])

AC_DEFUN([XASTIR_CHECK_MYSQL],
[
BINPATH="${PATH}${EXTRA_BIN_PATH}"

# test for MySQL
if test "${with_mysql+set}" = set; then
  MYSQL_CONFIG="mysql_config"
  if test "$with_mysql" != "yes"; then 
    # get path to mysql_config if provided
    mysql_path="$with_mysql"
    BINPATH="${BINPATH}:${mysql_path}"
    AC_PATH_PROG(MYSQL_CONFIG, [mysql_config], no, $mysql_path)
  else 
    AC_PATH_PROG(MYSQL_CONFIG, [mysql_config], no)
  fi
  use_mysql_spatial=no
  use_mysql_any=no
  if test "$MYSQL_CONFIG" != "no"; then
  
    # check for mysql version with spatial support 
    # look for mysql 4.1.2 or greater for spatial support 
    # and standardized prepared statements
    # 4.1.0 and 4.1.1 have spatial support, but only early versions
    # of prepared statement functions that changed in 4.1.2
    AC_MSG_CHECKING([mysql version >= 4.1.2])
    mysqlversion=`$MYSQL_CONFIG --version`
    mysqlversionmajor=`echo ${mysqlversion} | cut -d '.' -f 1`
    mysqlversionminor=`echo ${mysqlversion} | cut -d '.' -f 2`
    mysqlversiontiny=`echo ${mysqlversion} | cut -d '.' -f 3`
    if test "$mysqlversionmajor" -gt 4 ; then
      mysql_has_spatial="yes"
    elif test "$mysqlversionmajor" -ge 4 -a "$mysqlversionminor" -gt 1 ; then
      mysql_has_spatial="yes"
    elif test "$mysqlversionmajor" -ge 4 -a "$mysqlversionminor" -ge 1 -a "$mysqlversiontiny" -ge 2 ; then
      mysql_has_spatial="yes"
    else
      mysql_has_spatial="no"
    fi
    AC_MSG_RESULT($mysql_has_spatial)
    # if mysql version < 4.1, mysql present but no spatial support 
    if test "$mysql_has_spatial" = "yes"; then
       # mysql with spatial support
       use_mysql_spatial=yes
       use_spatial_db=yes
       AC_DEFINE(HAVE_MYSQL_SPATIAL, 1, MySQL with spatial support is present.)
    else 
       AC_MSG_WARN(*** MySQL version $mysqlversion detected is < 4.1.2         ***)
       AC_MSG_WARN(*** Spatial support enabled only for MySQL 4.1.2 and higher ***)
       AC_MSG_WARN(*** MySQL support for Lat/Long fields is available but      ***)
       AC_MSG_WARN(*** not for Points Polygons or other spatial objects.       ***)
    fi
    save_cppflags="$CPPFLAGS" 
    save_cxxflags="$CXXFLAGS" 
    save_libs="$LIBS" 
    CPPFLAGS="$CPPFLAGS `${MYSQL_CONFIG} --cflags`" 
    CXXFLAGS="$CXXFLAGS `${MYSQL_CONFIG} --cflags`" 
    LIBS=" `${MYSQL_CONFIG} --libs` $LIBS" 
    use_mysql_any=yes
    AC_DEFINE(HAVE_MYSQL, 1, MySQL is present.)
  else
    AC_MSG_WARN(*** Cannot find mysql_config:  Building w/o MySQL support. ***)
    AC_MSG_WARN(*** Specify the path to mysql_config                       ***)
    AC_MSG_WARN(*** For example: --with-mysql=/var/lib/mysql               ***)
  fi

fi
#AC_MSG_RESULT($use_mysql_spatial)
])



AC_DEFUN([XASTIR_CHECK_IMAGEMAGICK],
[
BINPATH="${PATH}${EXTRA_BIN_PATH}"

# Check for ImageMagick 
# 
# First look for the needed Magick-config script, which tells us all
# of the build options we need.
#
# Important: DO NOT use "use_imagemagick" as the variable here,
# because AC_CHECK_PROG will do nothing if the variable is already set!
#
use_imagemagick=no
AC_PATH_PROG(MAGIC_BIN, [MagickCore-config], no, $BINPATH)
if test "$MAGIC_BIN" != "no"; then
  use_imagemagick=yes
else
  AC_PATH_PROG(MAGIC_BIN, [Magick-config], no, $BINPATH)
  if test "$MAGIC_BIN" != "no"; then
    use_imagemagick=yes
  fi
#  AC_MSG_WARN(*** Cannot find Magick-config:  Building w/o ImageMagick support. ***)
fi

if test "${use_imagemagick}" = "yes"; then
#  #
#  # Compute the ImageMagick revision number
#  #
#  magickversion=`${MAGIC_BIN} --version` 
#  magickmajor=`echo $magickversion | cut -d '.' -f 1` 
#  magickminor=`echo $magickversion | cut -d '.' -f 2` 
#  magicktiny=`echo $magickversion | cut -d '.' -f 3` 
#  if test "$magickmajor" -lt 5; then 
#    magickold="yes"; 
#  elif test "$magickmajor" -eq 5 -a "$magickminor" -lt 4; then 
#    magickold="yes"; 
#  elif test "$magickmajor" -eq 5 -a "$magickminor" -eq 4 -a "$magicktiny" -lt 9; then 
#    magickold="yes"; 
#  fi
  #
  save_cppflags="$CPPFLAGS" 
  save_cxxflags="$CXXFLAGS" 
  save_libs="$LIBS" 
  save_ldflags="$LDFLAGS" 
  #
  # Figure out the build options using the Magick-config script
  #
  CPPFLAGS="$CPPFLAGS `${MAGIC_BIN} --cppflags`" 
  CXXFLAGS="$CXXFLAGS `${MAGIC_BIN} --cflags`" 
  LDFLAGS="$LDFLAGS `${MAGIC_BIN} --ldflags`" 
  LIBS="${MAGIC_LIB_DIR} `${MAGIC_BIN} --libs` $LIBS" 
  #
  AC_CHECK_HEADERS([MagickCore/MagickCore.h],[use_imagemagick="yes"],
                   [AC_CHECK_HEADERS([magick/api.h],[use_imagemagick="yes"],
                                     [use_imagemagick="no"])])

  if test "${use_imagemagick}" = "no"
  then
    AC_MSG_WARN([*** Cannot find ImageMagick include files:  Building w/o ImageMagick support. ***])
  else
    AC_MSG_CHECKING([if your ImageMagick is old enough for us to use])
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([
    #ifdef HAVE_MAGICKCORE_MAGICKCORE_H
    #include <MagickCore/MagickCore.h>
    #else
    #include <magick/api.h>
    #endif
    #if (MagickLibVersion > 0x0700)
    #error Your Magick is way too new
    #endif
    ])],[AC_MSG_RESULT([yes])],
    [AC_MSG_RESULT([no])
     AC_MSG_WARN([***Your ImageMagick is too new and Xastir cannot use it***])
     use_imagemagick="no"
     ])
    if test "${use_imagemagick}" = "yes"
    then
      AC_SEARCH_LIBS([WriteImage],[Magick MagickCore], [AC_DEFINE(HAVE_IMAGEMAGICK, 1, [Imagemagick image library])], [use_imagemagick="no"])
      if test "${use_imagemagick}" = "no"
      then
        AC_MSG_WARN(*** Cannot find ImageMagick library files:  Building w/o ImageMagick support. ***)
      fi
    fi
  fi
  #
  if test "${use_imagemagick}" = "no"; then
    #
    # No ImageMagick found.  Restore variables.
    #
    CPPFLAGS=$save_cppflags 
    CXXFLAGS=$save_cxxflags 
    LIBS=$save_libs 
    LDFLAGS=$save_ldflags 
  fi 
fi
# End of ImageMagick checks 

])





AC_DEFUN([XASTIR_CHECK_GRAPHICSMAGICK],
[
BINPATH="${PATH}${EXTRA_BIN_PATH}"

# Check for GraphicsMagick 
# 
# First look for the needed GraphicsMagick-config script, which tells us all
# of the build options we need.
#
# Important: DO NOT use "use_graphicsmagick" as the variable here,
# because AC_CHECK_PROG will do nothing if the variable is already set!
#
use_graphicsmagick=no
AC_PATH_PROG(GMAGIC_BIN, [GraphicsMagick-config], no, $BINPATH)
if test "$GMAGIC_BIN" != "no"; then
  use_graphicsmagick=yes
#else
#  AC_MSG_WARN(*** Cannot find GraphicsMagick-config:  Building w/o GraphicsMagick support. ***)
fi
#
if test "${use_graphicsmagick}" = "yes"; then
  save_cppflags="$CPPFLAGS" 
  save_cxxflags="$CXXFLAGS" 
  save_cflags="$CFLAGS" 
  save_libs="$LIBS" 
  save_ldflags="$LDFLAGS" 
  #
  # Figure out the build options using the GraphicsMagick-config script
  #
  CPPFLAGS="`${GMAGIC_BIN} --cppflags` $CPPFLAGS" 
  CXXFLAGS="`${GMAGIC_BIN} --cflags` $CXXFLAGS" 
  CFLAGS="`${GMAGIC_BIN} --cflags` $CFLAGS" 
  LDFLAGS="`${GMAGIC_BIN} --ldflags` $LDFLAGS" 
  LIBS="${MAGIC_LIB_DIR} `${GMAGIC_BIN} --libs` $LIBS" 
  # 
  AC_CHECK_HEADERS([magick/api.h], [use_graphicsmagick="yes"],[use_graphicsmagick="no"])
  if test "${use_graphicsmagick}" = "no"; then
    AC_MSG_WARN(*** Cannot find GraphicsMagick include files: Building w/o GraphicsMagick support. ***)
  else
    AC_CHECK_LIB([GraphicsMagick], [WriteImage], AC_DEFINE(HAVE_GRAPHICSMAGICK, 1, [GraphicsMagick image library]), use_graphicsmagick="no")
    if test "${use_graphicsmagick}" = "no"; then
      AC_MSG_WARN(*** Cannot find GraphicsMagick library files: Building w/o GraphicsMagick support. ***)
    fi
  fi
  #
  if test "${use_graphicsmagick}" = "no"; then
    #
    # No GraphicsMagick found.  Restore variables.
    #
    CPPFLAGS=$save_cppflags 
    CXXFLAGS=$save_cxxflags 
    CFLAGS=$save_cflags 
    LIBS=$save_libs 
    LDFLAGS=$save_ldflags 
  fi
fi 
# 
# End of GraphicsMagick checks 

])





# things grabbed elsewhere

# this is from Squeak-3.2-4's acinclude.m4
AC_DEFUN([AC_CHECK_GMTOFF],
[AC_CACHE_CHECK([for gmtoff in struct tm], ac_cv_tm_gmtoff,
  [AC_COMPILE_IFELSE(
    [AC_LANG_PROGRAM(
       [
        #include <time.h>
       ],
       [struct tm tm; tm.tm_gmtoff;])],
  ac_cv_tm_gmtoff="yes",
  ac_cv_tm_gmtoff="no")])
test "$ac_cv_tm_gmtoff" != "no" && AC_DEFINE(HAVE_TM_GMTOFF,,X)])

dnl Available from the GNU Autoconf Macro Archive at:
dnl http://www.gnu.org/software/ac-archive/htmldoc/acx_pthread.html
dnl
AC_DEFUN([ACX_PTHREAD], [
AC_REQUIRE([AC_CANONICAL_HOST])
AC_LANG_PUSH([C])
acx_pthread_ok=no

# We used to check for pthread.h first, but this fails if pthread.h
# requires special compiler flags (e.g. on True64 or Sequent).
# It gets checked for in the link test anyway.

# First of all, check if the user has set any of the PTHREAD_LIBS,
# etcetera environment variables, and if threads linking works using
# them:
if test x"$PTHREAD_LIBS$PTHREAD_CFLAGS" != x; then
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
        save_LIBS="$LIBS"
        LIBS="$PTHREAD_LIBS $LIBS"
        AC_MSG_CHECKING([for pthread_join in LIBS=$PTHREAD_LIBS with CFLAGS=$PTHREAD_CFLAGS])
        AC_TRY_LINK_FUNC(pthread_join, acx_pthread_ok=yes)
        AC_MSG_RESULT($acx_pthread_ok)
        if test x"$acx_pthread_ok" = xno; then
                PTHREAD_LIBS=""
                PTHREAD_CFLAGS=""
        fi
        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"
fi

# We must check for the threads library under a number of different
# names; the ordering is very important because some systems
# (e.g. DEC) have both -lpthread and -lpthreads, where one of the
# libraries is broken (non-POSIX).

# Create a list of thread flags to try.  Items starting with a "-" are
# C compiler flags, and other items are library names, except for "none"
# which indicates that we try without any flags at all.

acx_pthread_flags="pthreads none -Kthread -kthread lthread -pthread -pthreads -mthreads pthread --thread-safe -mt"

# The ordering *is* (sometimes) important.  Some notes on the
# individual items follow:

# pthreads: AIX (must check this before -lpthread)
# none: in case threads are in libc; should be tried before -Kthread and
#       other compiler flags to prevent continual compiler warnings
# -Kthread: Sequent (threads in libc, but -Kthread needed for pthread.h)
# -kthread: FreeBSD kernel threads (preferred to -pthread since SMP-able)
# lthread: LinuxThreads port on FreeBSD (also preferred to -pthread)
# -pthread: Linux/gcc (kernel threads), BSD/gcc (userland threads)
# -pthreads: Solaris/gcc
# -mthreads: Mingw32/gcc, Lynx/gcc
# -mt: Sun Workshop C (may only link SunOS threads [-lthread], but it
#      doesn't hurt to check since this sometimes defines pthreads too;
#      also defines -D_REENTRANT)
# pthread: Linux, etcetera
# --thread-safe: KAI C++

case "${host_cpu}-${host_os}" in
        *solaris*)

        # On Solaris (at least, for some versions), libc contains stubbed
        # (non-functional) versions of the pthreads routines, so link-based
        # tests will erroneously succeed.  (We need to link with -pthread or
        # -lpthread.)  (The stubs are missing pthread_cleanup_push, or rather
        # a function called by this macro, so we could check for that, but
        # who knows whether they'll stub that too in a future libc.)  So,
        # we'll just look for -pthreads and -lpthread first:

        acx_pthread_flags="-pthread -pthreads pthread -mt $acx_pthread_flags"
        ;;
esac

if test x"$acx_pthread_ok" = xno; then
for flag in $acx_pthread_flags; do

        case $flag in
                none)
                AC_MSG_CHECKING([whether pthreads work without any flags])
                ;;

                -*)
                AC_MSG_CHECKING([whether pthreads work with $flag])
                PTHREAD_CFLAGS="$flag"
                ;;

                *)
                AC_MSG_CHECKING([for the pthreads library -l$flag])
                PTHREAD_LIBS="-l$flag"
                ;;
        esac

        save_LIBS="$LIBS"
        save_CFLAGS="$CFLAGS"
        LIBS="$PTHREAD_LIBS $LIBS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

        # Check for various functions.  We must include pthread.h,
        # since some functions may be macros.  (On the Sequent, we
        # need a special flag -Kthread to make this header compile.)
        # We check for pthread_join because it is in -lpthread on IRIX
        # while pthread_create is in libc.  We check for pthread_attr_init
        # due to DEC craziness with -lpthreads.  We check for
        # pthread_cleanup_push because it is one of the few pthread
        # functions on Solaris that doesn't have a non-functional libc stub.
        # We try pthread_create on general principles.
        AC_LINK_IFELSE(
          [AC_LANG_PROGRAM([[#include <pthread.h>]],
             [[pthread_t th; pthread_join(th, 0);
               pthread_attr_init(0); pthread_cleanup_push(0, 0);
               pthread_create(0,0,0,0); pthread_cleanup_pop(0);]])],
          [acx_pthread_ok=yes],
          [acx_pthread_ok=no])

        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"

        AC_MSG_RESULT($acx_pthread_ok)
        if test "x$acx_pthread_ok" = xyes; then
                break;
        fi

        PTHREAD_LIBS=""
        PTHREAD_CFLAGS=""
done
fi

# Various other checks:
if test "x$acx_pthread_ok" = xyes; then
        save_LIBS="$LIBS"
        LIBS="$PTHREAD_LIBS $LIBS"
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

        # Detect AIX lossage: threads are created detached by default
        # and the JOINABLE attribute has a nonstandard name (UNDETACHED).
        AC_MSG_CHECKING([for joinable pthread attribute])
        AC_LINK_IFELSE(
          [AC_LANG_PROGRAM([[#include <pthread.h>]],
             [[int attr=PTHREAD_CREATE_JOINABLE;]])],
          [ok=PTHREAD_CREATE_JOINABLE],
          [ok=unknown])
        if test x"$ok" = xunknown; then
                AC_LINK_IFELSE(
                  [AC_LANG_PROGRAM([[#include <pthread.h>]],
                     [[int attr=PTHREAD_CREATE_UNDETACHED;]])],
                  [ok=PTHREAD_CREATE_UNDETACHED],
                  [ok=unknown])
        fi
        if test x"$ok" != xPTHREAD_CREATE_JOINABLE; then
                AC_DEFINE(PTHREAD_CREATE_JOINABLE, $ok,
                          [Define to the necessary symbol if this constant
                           uses a non-standard name on your system.])
        fi
        AC_MSG_RESULT(${ok})
        if test x"$ok" = xunknown; then
                AC_MSG_WARN([we do not know how to create joinable pthreads])
        fi

        AC_MSG_CHECKING([if more special flags are required for pthreads])
        flag=no
        case "${host_cpu}-${host_os}" in
                *-aix* | *-freebsd*)     flag="-D_THREAD_SAFE";;
                *solaris* | *-osf* | *-hpux*) flag="-D_REENTRANT";;
        esac
        AC_MSG_RESULT(${flag})
        if test "x$flag" != xno; then
                PTHREAD_CFLAGS="$flag $PTHREAD_CFLAGS"
        fi

        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"

        # More AIX lossage: must compile with cc_r
        AC_CHECK_PROG(PTHREAD_CC, cc_r, cc_r, ${CC})
else
        PTHREAD_CC="$CC"
fi

AC_SUBST(PTHREAD_LIBS)
AC_SUBST(PTHREAD_CFLAGS)
AC_SUBST(PTHREAD_CC)

# Finally, execute ACTION-IF-FOUND/ACTION-IF-NOT-FOUND:
if test x"$acx_pthread_ok" = xyes; then
        ifelse([$1],,AC_DEFINE(HAVE_PTHREAD,1,[Define if you have POSIX threads libraries and header files.]),[$1])
        :
else
        acx_pthread_ok=no
        $2
fi
AC_LANG_POP([C])
])dnl ACX_PTHREAD


#
AC_DEFUN([XASTIR_PATH_MOTIF], [
# New stuff to check for Motif/Lesstif.  Shamelessly borrowed from
# the opendx project. Opendx in turn snarfed their test from AC_PATH_X.

# Allow "--with-motif-includes" and "--with-motif-libs" so user can 
# force a specific set of includes.
AC_ARG_WITH(motif-includes, [  --with-motif-includes     Set path for motif includes (default none)],[with_motif_includes=$withval], [with_motif_includes=])
if test "$with_motif_includes" != "yes" && test -z "$with_motif_includes"
then
        with_motif_includes=
fi

AC_ARG_WITH(motif-libs, [  --with-motif-libs         Set path for motif libraries (default none)],[with_motif_libs=$withval], [with_motif_libs=])
if test "$with_motif_libs" != "yes" && test -z "$with_motif_libs"
then
  with_motif_libs=
fi

  # Guess where to find include files, by looking for this one Xm .h file.
  test -z "$xm_direct_test_include" && xm_direct_test_include=Xm/Xm.h

  # First, try using that file with no special directory specified.
AC_MSG_CHECKING([for Motif headers])
AC_PREPROC_IFELSE(
 [AC_LANG_SOURCE([[#include <$xm_direct_test_include>]])],
 [
  # We can compile using X headers with no special include directory.
  xm_includes=
  AC_MSG_RESULT([in default path])
 ],[
# that test didn't work, we need to hunt a little
# Look for the header file in a standard set of common directories.
# Check X11 before X11Rn because it is often a symlink to the current release.
  for ac_dir in               \
    /usr/X11/include          \
    /usr/X11R6/include        \
    /usr/X11R5/include        \
    /usr/X11R4/include        \
                              \
    /usr/include/X11          \
    /usr/include/X11R6        \
    /usr/include/X11R5        \
    /usr/include/X11R4        \
                              \
    /usr/local/X11/include    \
    /usr/local/X11R6/include  \
    /usr/local/X11R5/include  \
    /usr/local/X11R4/include  \
                              \
    /usr/local/include/X11    \
    /usr/local/include/X11R6  \
    /usr/local/include/X11R5  \
    /usr/local/include/X11R4  \
                              \
    /usr/X386/include         \
    /usr/x386/include         \
    /usr/XFree86/include/X11  \
                              \
    /usr/include              \
    /usr/local/include        \
    /usr/unsupported/include  \
    /usr/athena/include       \
    /usr/local/x11r5/include  \
    /usr/lpp/Xamples/include  \
                              \
    /usr/openwin/include      \
    /usr/openwin/share/include \
    "$with_motif_includes"    \
    ; \
  do
    if test -r "$ac_dir/$xm_direct_test_include"; then
      xm_includes=$ac_dir
      AC_MSG_RESULT([in $xm_includes])
      break
    fi
  done
  if test "x$xm_includes" = "x"; then
    AC_MSG_ERROR([**** NO MOTIF HEADERS FOUND **** install Motif  development headers or use --with-motif-includes to specify location of Xm/Xm.h ])
  fi
])
  # Check for the libraries.

  AC_MSG_CHECKING([for Motif libraries])
  test -z "$xm_direct_test_library" && xm_direct_test_library=Xm
  test -z "$xm_direct_test_function" && xm_direct_test_function=XmGetDestination

  # See if we find them without any special options.
  # Don't add to $LIBS permanently.
  ac_save_LIBS="$LIBS"
  LIBS="-l$xm_direct_test_library $LIBS"
AC_LINK_IFELSE([AC_LANG_PROGRAM([
  [#include <$xm_direct_test_include>
   #include <X11/Xlib.h>
     ]],
  [[Display *foobar; ${xm_direct_test_function}(foobar)]])],
 [
  LIBS="$ac_save_LIBS"
  # We can link Motif programs with no special library path.
  xm_libraries=
  AC_MSG_RESULT([in default path])
 ],[
 LIBS="$ac_save_LIBS"
# First see if replacing the include by lib works.
# Check X11 before X11Rn because it is often a symlink to the current release.
for ac_dir in `echo "$xm_includes" | sed s/include/lib/` \
    /usr/X11/lib          \
    /usr/X11R6/lib        \
    /usr/X11R5/lib        \
    /usr/X11R4/lib        \
                          \
    /usr/lib/X11          \
    /usr/lib/X11R6        \
    /usr/lib/X11R5        \
    /usr/lib/X11R4        \
                          \
    /usr/local/X11/lib    \
    /usr/local/X11R6/lib  \
    /usr/local/X11R5/lib  \
    /usr/local/X11R4/lib  \
                          \
    /usr/local/lib/X11    \
    /usr/local/lib/X11R6  \
    /usr/local/lib/X11R5  \
    /usr/local/lib/X11R4  \
                          \
    /usr/X386/lib         \
    /usr/x386/lib         \
    /usr/XFree86/lib/X11  \
                          \
    /usr/lib              \
    /usr/local/lib        \
    /usr/unsupported/lib  \
    /usr/athena/lib       \
    /usr/local/x11r5/lib  \
    /usr/lpp/Xamples/lib  \
    /lib/usr/lib/X11	  \
                          \
    /usr/openwin/lib      \
    /usr/openwin/share/lib \
    "$with_motif_libs"     \
    ; \
do
dnl Don't even attempt the hair of trying to link an X program!
  for ac_extension in a so sl; do
    if test -r $ac_dir/lib${xm_direct_test_library}.$ac_extension; then
      xm_libraries=$ac_dir
      AC_MSG_RESULT([in $xm_libraries])
      break 2
    fi
  done
done
if test "x$xm_libraries" = "x"; then
 AC_MSG_ERROR([**** MOTIF LIBRARIES NOT FOUND **** Install Motif development headers/libraries or use --with-motif-libraries to specify path to libXm.a ])
fi
])
])

# Look for a library that contains the Berkeley DB function "db_create"
# and put it into LIBS if it's not already found by the current setting of
# LIBS
#
# If "--with-bdb-incdir" was specified, it will already have been added
# to CPPFLAGS by the caller
#
# If "--with-bdb-libdir" was specified, we tentatively add it to LDFLAGS
# here and add it to BDB_LIBADD.  Only if we actually find the library
# will this get added to LDFLAGS permanently
#
# if we find it, dblib will have "berkeley" in it, otherwise it will have
# "no"
#
# Note that this is not perfectly safe.  We only call this macro if we
# have found a usable "db.h" header in the default CPP search path or
# the path augmented by "--with-bdb-incdir", but we have no way of telling
# (without actually running a program that calls db_version) whether
# this header is actually for the most recent libdb installed on the
# system.  This can bite users who have multiple versions, but tell Xastir
# that they want to use the older header in some nonstandard directory.
#
# In that case, the ONLY solution for forcing use of the old library is to
# specify it in LIBS (e.g. "LIBS='-ldb-5.3'").
AC_DEFUN([XASTIR_BERKELEY_DB_CHK_LIB],
[

  BDB_SAVE_LDFLAGS=$LDFLAGS

	if test -d $with_bdb_lib; then
	    LDFLAGS="-L$with_bdb_lib $LDFLAGS"
	    BDB_LIBADD="-L$with_bdb_lib $BDB_LIBADD"
	else
	    BDB_LIBADD=""
	fi

  AC_SEARCH_LIBS([db_create],[db-18.1 db-18 db-5.3 db5.3 db53 db-5.2 db-5.2 db52 db-5.1 db5.1 db51 db-5.0 db5.0 db50],[dblib="berkeley"],[dblib="no"])

  LDFLAGS=$BDB_SAVE_LDFLAGS
])

AC_DEFUN([XASTIR_BERKELEY_DB_OPTS],
[
AC_ARG_WITH(bdb-libdir,
	[  --with-bdb-libdir=DIR     Berkeley DB lib files are in DIR],
	with_bdb_lib=$withval,
	[ test "${with_bdb_lib+set}" = set || with_bdb_lib=none])
AC_ARG_WITH(bdb-incdir,
	[  --with-bdb-incdir=DIR     Berkeley DB include files are in DIR],
	with_bdb_inc=$withval,
	[ test "${with_bdb_inc+set}" = set || with_bdb_inc=none ])
])

AC_DEFUN([XASTIR_BERKELEY_DB_CHK],
[
	AC_REQUIRE([XASTIR_BERKELEY_DB_OPTS])

	xastir_save_CPPFLAGS=$CPPFLAGS

	if test -d $with_bdb_inc; then
	    CPPFLAGS="$CPPFLAGS -I$with_bdb_inc"
	    BDB_INCADD="-I$with_bdb_inc"
	else
	    BDB_INCADD=""
	fi

# check to see if the db.h we find first in the search
# path will actually pass the test we do in map_cache.c.  Don't even bother
# looking for a library if not.
        AC_MSG_CHECKING([if db.h is exists and is usable])
        AC_COMPILE_IFELSE(
        [AC_LANG_PROGRAM(
            [
            #include <db.h>
            ],
            [
              #if (DB_VERSION_MAJOR < 4 )
                 #error DB_VERSION_MAJOR < 4
              #endif
            ])],
         [
           AC_MSG_RESULT([yes])
           XASTIR_BERKELEY_DB_CHK_LIB()
         ],
         [
           AC_MSG_RESULT([no]);
           dblib="no"
         ])
	CPPFLAGS=$xastir_save_CPPFLAGS

  use_map_cache="no"
  if test "${dblib}" = "berkeley"; then
    	CPPFLAGS="$CPPFLAGS $BDB_INCADD"
    	LDFLAGS="$BDB_LIBADD $LDFLAGS"
      AC_DEFINE(USE_MAP_CACHE, 1, [Berkeley DB Map Caching])
      use_map_cache="yes"
  fi

])


