#!/bin/sh
#
# Universal Installer
#
VERSION="1.12.001"

#
# Test for GNU Textutil POSIX 200112 bug
#
if [ "`(echo | head -1 | tail +1) 2>&1`" ]; then
  _POSIX2_VERSION=199209; export _POSIX2_VERSION
fi

#
# Automatically fix PATH
#
case `PATH=/bin:/usr/bin:$PATH; uname -s` in
AIX)
  PATH=/usr/bin:/usr/ucb:$PATH;;
HP-UX)
  PATH=/usr/bin:/usr/ccs/bin:/usr/contrib/bin/X11:$PATH;;
IRIX*)
  PATH=/usr/sbin:/usr/bsd:/sbin:/usr/bin:$PATH;;
Linux)
  PATH=/usr/bin:/bin:$PATH;;
OSF1)
  PATH=/bin:/usr/bin:$PATH;;
SunOS)
  PATH=/bin:/sbin:/usr/sbin:/usr/ucb:/usr/ccs/bin:/usr/openwin/bin:$PATH;;
*)
  PATH=/usr/bin:/bin:$PATH;;
esac; export PATH
MYUNAME=`id | sed -e 's/^[^(]*(\([^)]*\)).*$/\1/'`

#
# Session Terminal
#
case `uname` in
Linux)
  if [ "`grep \"Red Hat Enterprise Linux.*release [4-9]\" /etc/redhat-release 2> /dev/null`" ];then
    stty werase  2> /dev/null; stty werase "^?" 2> /dev/null # Workaround bug in RHEL 4.0 and later
  else
    stty erase "^?" 2> /dev/null; stty werase  2> /dev/null
  fi;;
OSF1)
  if [ "`stty -a 2> /dev/null | grep \"^erase = \^?\"`" ]; then
    stty erase "^?" 2> /dev/null; stty werase  2> /dev/null # OSF1 keyboard
  else
    stty erase  2> /dev/null; stty werase "^?" 2> /dev/null
  fi;;
*)
  stty erase  2> /dev/null;;
esac

#
# Trap and ignore SIGINT (CTRL+C by user) and SIGTERM signals
#
case `uname` in
OSF1) trap true 2; trap true 15;;
* )   trap true INT; trap true TERM;;
esac

#
# Test for bash echo bug
#
if [ "`echo \"\n\"`" = "\n" ]; then
  ECHO="echo -e"
else
  ECHO=echo
fi

#
# Defaults
#
PAPER=white
INK=black
CURSOR=red
BORDER=purple
FONT=7x14
OPTION="-cu -s -j -sb -sl 4096 -fn $FONT -fg $INK -bg $PAPER -cr $CURSOR -bd $BORDER -geometry 80x40 -T Setup -n Setup"
case `uname` in
HI-UX/MPP|HP-UX)
  XTERM="/usr/bin/X11/xterm";;
SunOS)
  XTERM="/usr/openwin/bin/xterm";;
UNIX_System_V)
  XTERM="/usr/X11R6/bin/xterm";;
*)
  XTERM="/usr/bin/X11/xterm";;
esac
umask 022

# === Functions Start ===

#
# Function to show welcome title banner
#
show_title_banner() {
  echo
  echo "SETUP $VERSION - Universal Installer"
  echo "===================================="
  echo
  echo "The following software is available for installation:"
  echo
  ls -1 */*/*.* 2> /dev/null | cut -f1 -d"/" | sort | uniq | sed -e "s/_/ /" -e "s/^/  *  /"
  echo
  cat README */README 2> /dev/null
}

#
# Check disk is full
#
check_disk() {
  if [ -d "$1" ]; then
    mkdir -p $1/.check_disk-$MYUNAME 2> /dev/null
    if [ -d $1/.check_disk-$MYUNAME ]; then
      rmdir $1/.check_disk-$MYUNAME 2> /dev/null
    else
      echo "Disk is full"
    fi
  fi
}

#
# which (avoid buggy csh which)
#
which() {
  if [ "$1" ]; then
    for DIR in `echo $PATH | sed -e "s/:/ /g"`; do
      if [ -x "$DIR/$1" -a ! -d "$DIR/$1" ]; then
        echo "$DIR/$1"; break
      fi
    done
  fi
}

#
# Function to read input line and trap stdin errors (ie CTRL+D)
#
read_line() {
  read READLINE
  if [ $? = 0 ]; then
    STDIN_ERRORS=0
  else
    STDIN_ERRORS=`expr $STDIN_ERRORS + 1`
    if [ $STDIN_ERRORS -ge 64 ]; then
      echo "***ERROR*** Too many errors encountered. Assuming input device problems."; exit 1
    fi
  fi
  eval $1="\"$READLINE\""
}

#
# Function to install "7z" archive files
#
install_7z() {
  case `uname` in
  AIX)
    UNPACKER=`ls -1t ../tools/AIX_Power/*/7za 2> /dev/null | head -1`;;
  HP-UX)
    case `uname -m` in
    ia64) UNPACKER=`ls -1t ../tools/HP-UX_Itanium/*/7za 2> /dev/null | head -1`;;
    *)    UNPACKER=`ls -1t ../tools/HP-UX_PA-Risc/*/7za 2> /dev/null | head -1`;;
    esac;;
  IRIX*)
    UNPACKER=`ls -1t ../tools/IRIX_MIPS/*/7za 2> /dev/null | head -1`;;
  Linux)
    case `uname -m` in
    ia64)   UNPACKER=`ls -1t ../tools/Linux_Itanium/*/7za 2> /dev/null | head -1`;;
    ppc*)   UNPACKER=`ls -1t ../tools/Linux_Power/*/7za 2> /dev/null | head -1`;;
    sparc*) UNPACKER=`ls -1t ../tools/Linux_UltraSPARC/*/7za 2> /dev/null | head -1`;;
    *)      UNPACKER=`ls -1t ../tools/Linux_x86/*/7za 2> /dev/null | head -1`;;
    esac;;
  OSF1)
    UNPACKER=`ls -1t ../tools/OSF1_Alpha/*/7za 2> /dev/null | head -1`;;
  SunOS)
    case `uname -m` in
    i86*) UNPACKER=`ls -1t ../tools/SunOS_x86/*/7za 2> /dev/null | head -1`;;
    *)    UNPACKER=`ls -1t ../tools/SunOS_UltraSPARC/*/7za 2> /dev/null | head -1`;;
    esac;;
  *NT*)
    UNPACKER=`ls -1t ../tools/Windows_x86/*/7za 2> /dev/null | head -1`;;
  esac
  if [ ! "$UNPACKER" ]; then
    UNPACKER=`which 7za`
    if [ ! "$UNPACKER" ]; then
      echo "\r***ERROR*** Cannot find the \"7za\" archiver tool for unpacking package."; return 1
    fi
  fi
  cp $UNPACKER /tmp/7za-$MYUNAME.$$ 2> /dev/null
  UNPACKER=/tmp/7za-$MYUNAME.$$
  if [ "`check_disk /tmp`" ]; then
    $ECHO "\r***ERROR*** Unable to cache \"7za\" executable. /tmp disk is full."; rm -f $UNPACKER; return 1
  fi
  unset LANG # Avoids locale problems
  OUTPUT=`$UNPACKER x -y $1 -o$2 $FILE 2>&1 | sed -e 's@\\\\@/@g'`
  if [ ! "`echo \"$OUTPUT\" | grep \"Everything is Ok\"`" ]; then
    echo "$OUTPUT"
  fi; rm -f $UNPACKER
}

#
# Function to install "tar.bz2" archive files
#
install_tar_bz2() {
  case `uname` in
  AIX)
    UNPACKER=`ls -1t ../tools/AIX_Power/*/bzip2 2> /dev/null | head -1`;;
  HP-UX)
    case `uname -m` in
    ia64) UNPACKER=`ls -1t ../tools/HP-UX_Itanium/*/bzip2 2> /dev/null | head -1`;;
    *)    UNPACKER=`ls -1t ../tools/HP-UX_PA-Risc/*/bzip2 2> /dev/null | head -1`;;
    esac;;
  IRIX*)
    UNPACKER=`ls -1t ../tools/IRIX_MIPS/*/bzip2 2> /dev/null | head -1`;;
  Linux)
    case `uname -m` in
    ia64)   UNPACKER=`ls -1t ../tools/Linux_Itanium/*/bzip2 2> /dev/null | head -1`;;
    ppc*)   UNPACKER=`ls -1t ../tools/Linux_Power/*/bzip2 2> /dev/null | head -1`;;
    sparc*) UNPACKER=`ls -1t ../tools/Linux_UltraSPARC/*/bzip2 2> /dev/null | head -1`;;
    *)      UNPACKER=`ls -1t ../tools/Linux_x86/*/bzip2 2> /dev/null | head -1`;;
    esac;;
  OSF1)
    UNPACKER=`ls -1t ../tools/OSF1_Alpha/*/bzip2 2> /dev/null | head -1`;;
  SunOS)
    case `uname -m` in
    i86*) UNPACKER=`ls -1t ../tools/SunOS_x86/*/bzip2 2> /dev/null | head -1`;;
    *)    UNPACKER=`ls -1t ../tools/SunOS_UltraSPARC/*/bzip2 2> /dev/null | head -1`;;
    esac;;
  *NT*)
    UNPACKER=`ls -1t ../tools/Windows_x86/*/bzip2 2> /dev/null | head -1`;;
  esac
  if [ ! "$UNPACKER" ]; then
    UNPACKER=`which bzip2`
    if [ ! "$UNPACKER" ]; then
      echo "\r***ERROR*** Cannot find the \"bzip2\" archiver tool for unpacking package."; return 1
    fi
  fi
  cp $UNPACKER /tmp/bzip2-$MYUNAME.$$ 2> /dev/null
  UNPACKER=/tmp/bzip2-$MYUNAME.$$
  if [ "`check_disk /tmp`" ]; then
    $ECHO "\r***ERROR*** Unable to cache \"bzip2\" executable. /tmp disk is full."; rm -f $UNPACKER; return 1
  fi
  case `uname` in
  Linux)
    ($UNPACKER -d < $1 | (cd $2; tar --no-same-owner -xf -)) 2>&1;;
  IRIX*|OSF1)
    ($UNPACKER -d < $1 | (cd $2; tar xof -)) 2>&1 | grep -v "blocksize =";;
  *)
    ($UNPACKER -d < $1 | (cd $2; tar xof -)) 2>&1;;
  esac; rm -f $UNPACKER
}

#
# Function to install "tar.gz" archive files
#
install_tar_gz() {
  case `uname` in
  AIX)
    UNPACKER=`ls -1t ../tools/AIX_Power/*/gzip 2> /dev/null | head -1`;;
  HP-UX)
    case `uname -m` in
    ia64) UNPACKER=`ls -1t ../tools/HP-UX_Itanium/*/gzip 2> /dev/null | head -1`;;
    *)    UNPACKER=`ls -1t ../tools/HP-UX_PA-Risc/*/gzip 2> /dev/null | head -1`;;
    esac;;
  IRIX*)
    UNPACKER=`ls -1t ../tools/IRIX_MIPS/*/gzip 2> /dev/null | head -1`;;
  Linux)
    case `uname -m` in
    ia64)   UNPACKER=`ls -1t ../tools/Linux_Itanium/*/gzip 2> /dev/null | head -1`;;
    ppc*)   UNPACKER=`ls -1t ../tools/Linux_Power/*/gzip 2> /dev/null | head -1`;;
    sparc*) UNPACKER=`ls -1t ../tools/Linux_UltraSPARC/*/gzip 2> /dev/null | head -1`;;
    *)      UNPACKER=`ls -1t ../tools/Linux_x86/*/gzip 2> /dev/null | head -1`;;
    esac;;
  OSF1)
    UNPACKER=`ls -1t ../tools/OSF1_Alpha/*/gzip 2> /dev/null | head -1`;;
  SunOS)
    case `uname -m` in
    i86*) UNPACKER=`ls -1t ../tools/SunOS_x86/*/gzip 2> /dev/null | head -1`;;
    *)    UNPACKER=`ls -1t ../tools/SunOS_UltraSPARC/*/gzip 2> /dev/null | head -1`;;
    esac;;
  *NT*)
    UNPACKER=`ls -1t ../tools/Windows_x86/*/gzip 2> /dev/null | head -1`;;
  esac
  if [ ! "$UNPACKER" ]; then
    UNPACKER=`which gzip`
    if [ ! "$UNPACKER" ]; then
      echo "\r***ERROR*** Cannot find the \"gzip\" archiver tool for unpacking package."; return 1
    fi
  fi
  cp $UNPACKER /tmp/gzip-$MYUNAME.$$ 2> /dev/null
  UNPACKER=/tmp/gzip-$MYUNAME.$$
  if [ "`check_disk /tmp`" ]; then
    $ECHO "\r***ERROR*** Unable to cache \"gzip\" executable. /tmp disk is full."; rm -f $UNPACKER; return 1
  fi
  case `uname` in
  Linux)
    ($UNPACKER -d < $1 | (cd $2; tar --no-same-owner -xf -)) 2>&1;;
  IRIX*|OSF1)
    ($UNPACKER -d < $1 | (cd $2; tar xof -)) 2>&1 | grep -v "blocksize =";;
  *)
    ($UNPACKER -d < $1 | (cd $2; tar xof -)) 2>&1;;
  esac; rm -f $UNPACKER
}

# 
# Function to install files by tar copying
#
install_tar_copy() {
  cd `dirname $1`
  case `uname` in
  Linux)
    if [ "`tar --help 2>&1 | grep \" --no-same-owner\"`" ]; then
      tar cf - `basename $1` | (cd $2; tar --no-same-owner -xf -)
    else
      tar cf - `basename $1` | (cd $2; tar -xf -)
    fi;;
  OSF1)
    tar cf - `basename $1` | (cd $2; tar -xf -) 2>&1 | grep -v "blocksize =";;
  *)
    tar cf - `basename $1` | (cd $2; tar xof -);;
  esac
}

#
# Function to allow group and others read/execute access
#
allow_go_access() {
  if [ -d "$1" ]; then
    chmod -R u+w $1 2> /dev/null
    chmod -R go=r $1 2> /dev/null
    for DIR in `du $1 2> /dev/null | awk '{print $2}'`; do
      (cd $DIR; chmod go=rx . `ls -l | grep "^-rwx" | awk '{print $NF}'`) 2> /dev/null
    done
  fi
}

#
# Function to install package
#
install_package() {
  case $1 in
  *.7z)
    install_7z $1 $2 2>&1;;
  *.tar.bz2)
    install_tar_bz2 $1 $2 2>&1 | grep -v ": time stamp";;
  *.tar.gz)
    install_tar_gz $1 $2 2>&1 | grep -v ": time stamp";;
  *)
    install_tar_copy $1 $2 2>&1 | grep -v ": time stamp";;
  esac
  allow_go_access $2
}

#
# Menu system
#
menu_system() {
  if [ "`echo \"$OPTIONS\" | grep \"^Other$\"`" ]; then # Put Other last
    OPTIONS="`echo \"$OPTIONS\" | grep -v '^Other$'`
`echo \"$OPTIONS\" | grep '^Other$'`"
  fi
  while [ 1 ]; do
    NUMBER=0; echo "$1"
    echo "The following options can be toggled on or off by entering their numbers."
    echo "A keyword can be used to toggle any option that contains the keyword."
    echo "You may enter more than one option on the same line separated by a space."
    echo "In order to continue to the next stage you must select at least one option:"
    echo
    for OPTION in $OPTIONS; do
      NUMBER=`expr $NUMBER + 1`
      case $OPTION in
      +*)
        echo $NUMBER | awk '{printf (" %2d. [X] ",$1)}'
        echo $OPTION | cut -c2- | sed -e "s/_/ /" -e "s/\/.*\// > /" -e "s/[.]tar[.][^.]*$//" -e "s/[.]7z$//" -e"s/[.][^.0-9]*$//";;
      *)
        echo $NUMBER | awk '{printf (" %2d. [ ] ",$1)}'
        echo $OPTION | sed -e "s/_/ /" -e "s/\/.*\// > /" -e "s/\// > /" -e "s/[.]tar[.][^.]*$//" -e "s/[.]7z$//" -e"s/[.][^.0-9]*$//";;
      esac
    done
    echo "  A.     Select all options"
    echo "  U.     Unselect all options"
    echo
    echo "Please enter your selection (X=Exit B=Back N=Next):"
    read_line SELECTIONS
    for SELECTION in `echo $SELECTIONS | sed "s/,/ /g"`; do
      case $SELECTION in
      [1-9]|[1-9][0-9]*)
        if [ "`echo "$OPTIONS" | tail +$SELECTION | head -1 | cut -c1`" = "+" ]; then
          OPTIONS=`echo "$OPTIONS" | sed -e "${SELECTION}s/^+//"`
        else
          OPTIONS=`echo "$OPTIONS" | sed -e "${SELECTION}s/^/+/"`
        fi;;
      a|A)
        OPTIONS=`echo "$OPTIONS" | sed -e "s/^/+/" -e "s/^++/+/"`;;
      u|U)
        OPTIONS=`echo "$OPTIONS" | sed -e "s/^+//"`;;
      x|X)
        echo "Installation aborted!"; STAGE=-1; break 2;;
      b|B)
        STAGE=`expr $STAGE - 1`; break 2;;
      n|N)
        if [ "`echo \"$OPTIONS\" | grep \"^+\"`" ]; then
          STAGE=`expr $STAGE + 1`; break 2
        else
          echo "***ERROR*** You MUST select at least one option."; break
        fi;;
      [A-Za-z]?*)
        for SELECTION in `echo "$OPTIONS" | grep -in "$SELECTION" | cut -f1 -d":"`; do
          if [ "`echo "$OPTIONS" | tail +$SELECTION | head -1 | cut -c1`" = "+" ]; then
            OPTIONS=`echo "$OPTIONS" | sed -e "${SELECTION}s/^+//"`
          else
            OPTIONS=`echo "$OPTIONS" | sed -e "${SELECTION}s/^/+/"`
          fi
        done;;
      esac
    done
  done
}

#
# Time in seconds (must pass reference time in seconds)
#
time_sec() {
  SEC=`date +'%H %M %S' | awk '{print $1*3600+($2*60)+$3}'`
  if [ $SEC -lt $1 ]; then
    expr $SEC + 86400 - $1
  else
    expr $SEC - $1
  fi
}

# === Functions End ===

if [ ! -f "$0" ]; then
  sh ./setup # Call self (avoids ". setup" problems)
elif [ "`PATH=/usr/bin/X11:$PATH; xwininfo -root 2> /dev/null | grep Depth:`" -a -x "$XTERM" -a ! "$NO_SETUP_GUI" ]; then
  NO_SETUP_GUI=1; export NO_SETUP_GUI; exec $XTERM $OPTION -e sh $0
else
  clear 2> /dev/null
  if [ ! -f setup -o ! -d Packages ]; then
    cd `dirname $0 2> /dev/null` 2> /dev/null
  fi
  if [ ! -f setup -o ! -d Packages ]; then
    echo "***ERROR*** The \"setup\" script MUST be run in its own directory"
    echo "Installation aborted!"
  elif [ ! "`ls -1 Packages/*/*/*.* 2> /dev/null`" ]; then
    echo "***ERROR*** No software packages found."
    echo "Installation aborted!"
#
# Show title banner (STAGE=0)
#
  else
    cd Packages
    NUMBER=0
    RESTORE_OPTIONS=
    if [ STAGE != 0 ]; then
      if [ -f setup.0 ]; then # Stage 0 plug-in
        . ./setup.0
      elif [ "`which more`" ]; then
        (show_title_banner) | more
      else
        show_title_banner
      fi
    fi
  fi
#
# Main loop
#
  while [ 1 ]; do
    STAGE=1; STDIN_ERRORS=0
    while [ $STAGE -gt 0 ]; do
      case $STAGE in
#
# Read installation directory (STAGE=1)
#
      1)
        echo "
**************************************
* INSTALLATION DIRECTORY (Stage 1/7) *
**************************************
"
        if [ -f setup.1 ]; then # Stage 1 plug-in
          . ./setup.1
        else
          echo "Please enter the full path of the top level installation directory (X=Exit):"
          read_line INSTALL_DIR
          case $INSTALL_DIR in
          x|X)
            echo "Installation aborted!"; STAGE=-1;;
          /*)
             mkdir -p $INSTALL_DIR 2> /dev/null
            if [ ! -d "$INSTALL_DIR" ]; then
              echo "***ERROR*** Unable to create installation directory. Please check permissions."
            elif [ ! -w "$INSTALL_DIR" ]; then
              echo "***ERROR*** Unable to write in installation directory. Please check permissions."
            else
              STAGE=2
            fi;;
          *)
            echo "***ERROR*** A valid full path begins with \"/\". Please try again.";;
          esac
        fi;;
#
# Software menu (STAGE=2)
#
      2)
        TITLE="
**************************************
* SOFTWARE SELECTION     (Stage 2/7) *
**************************************
"
        STAGE2_SKIP=
        if [ "$RESTORE_OPTIONS" ]; then
          OPTIONS="$RESTORE_OPTIONS"; RESTORE_OPTIONS=
        else
          OPTIONS=`ls -1 */*/*.* 2> /dev/null | cut -f1 -d"/" | sort | uniq`
        fi
        if [ -f setup.2 ]; then # Stage 2 plug-in
          echo "$TITLE"
          . ./setup.2
          if [ "$STAGE" != 2 ]; then
            continue
          fi
        fi
        if [ "`echo \"$OPTIONS\" | wc -l | awk '{print $1}'`" = 1 ]; then
          echo "$TITLE"
          echo "Automatically selecting the only software available."; SOFTWARES="+$OPTIONS"; STAGE=3; STAGE2_SKIP=1
        else
          menu_system "$TITLE"
          SOFTWARES="$OPTIONS"
        fi;;
#
# Platform menu (STAGE=3)
#
      3)
        TITLE="
**************************************
* PLATFORMS SELECTION    (Stage 3/7) *
**************************************
"
        STAGE3_SKIP=
        if [ "$RESTORE_OPTIONS" ]; then
          OPTIONS="$RESTORE_OPTIONS"; RESTORE_OPTIONS=
        else
          OPTIONS=`ls -1d \`echo "$SOFTWARES" | grep "^+" | cut -c2- | sed -e "s/$/\/*\/*.*/"\` 2> /dev/null | grep -v "/Shared/" | grep -v "/Common/" | cut -f2 -d"/" | sort | uniq`
        fi
        if [ -f setup.3 ]; then # Stage 3 plug-in
          echo "$TITLE"
          . ./setup.3
          if [ "$STAGE" != 3 ]; then
            continue
          fi
        fi
        if [ ! "$OPTIONS" ]; then
          echo "$TITLE"
          echo "Platform selection not required."; PLATFORMS=; STAGE=4
        elif [ "`echo \"$OPTIONS\" | wc -l | awk '{print $1}'`" = 1 ]; then
          echo "$TITLE"
          echo "Automatically selecting the only platform available."; PLATFORMS="+$OPTIONS"; STAGE=4; STAGE3_SKIP=1
        else
          menu_system "$TITLE"
          PLATFORMS="$OPTIONS"
          if [ "$STAGE" = 2 ]; then
            RESTORE_OPTIONS="$SOFTWARES"
            if [ "$STAGE2_SKIP" ]; then
              STAGE=1
            fi
          fi
        fi;;
#
# Package menu (STAGE=4)
#
      4)
        TITLE="
**************************************
* PACKAGES SELECTION     (Stage 4/7) *
**************************************
"
        STAGE4_SKIP=
        if [ "$RESTORE_OPTIONS" ]; then
          OPTIONS="$RESTORE_OPTIONS"; RESTORE_OPTIONS=
        else
          OPTIONS=
          for CODE in `echo "$SOFTWARES" | grep "^+" | cut -c2-`; do
            for ARCH in Common `echo "$PLATFORMS" | grep "^+" | cut -c2-`; do
              OPTIONS="$OPTIONS
`ls -1 $CODE/$ARCH/*.* 2> /dev/null | egrep -v \"[.]list\$|[.]manifest\$\"`" # Ignore files
            done
          done
          OPTIONS=`echo "$OPTIONS" | grep -v "^$"`
        fi
        if [ -f setup.4 ]; then # Stage 4 plug-in
          echo "$TITLE"
          . ./setup.4
          if [ "$STAGE" != 4 ]; then
            continue
          fi
        fi
        if [ "`echo \"$OPTIONS\" | wc -l | awk '{print $1}'`" = 1 ]; then
          echo "$TITLE"
          echo "Automatically selecting the only package available."; PACKAGES="+$OPTIONS"; STAGE=5; STAGE4_SKIP=1
        else
          menu_system "$TITLE"
          PACKAGES="$OPTIONS"
          if [ "$STAGE" = 3 ]; then
            RESTORE_OPTIONS="$PLATFORMS"
            if [ "$STAGE3_SKIP" -o ! "$PLATFORMS" ]; then
              STAGE=2; RESTORE_OPTIONS="$SOFTWARES"
              if [ "$STAGE2_SKIP" ]; then
                STAGE=1
              fi
            fi
          fi
        fi;;
#
# Installation confirmation (STAGE=5)
#
      5)
        echo "
**************************************
* PACKAGES CONFIRMATION  (Stage 5/7) *
**************************************
"
        echo "The software packages will be installed in the following sub-directories of the"
        echo "installation directory \"$INSTALL_DIR\":"
        echo
        SOURCES=`echo "$PACKAGES" | grep "^+" | cut -c2-`
# Shared start
        SHARED=`ls -1 Shared/* 2> /dev/null | egrep -v "[.]list$|[.]manifest$"` # Ignore files
        for SOFTWARE in `echo "$PACKAGES" | cut -c2- | cut -f1 -d"/" | sort | uniq`; do
  	SHARED="$SHARED
`ls -1 $SOFTWARE/Shared/* 2> /dev/null | egrep -v \"[.]list\$|[.]manifest\$\"`" # Ignore files
        done
        if [ "`echo \"$SHARED\" | grep -v \"^$\"`" ]; then
          SOURCES="`echo \"$SHARED\" | grep -v \"^$\"`
$SOURCES"
        fi
# Shared end
        SOURCES_OK=; TARGET_DIRS=; PACKAGES_EXIST=; PACKAGES_ERROR=
        for SOURCE in $SOURCES; do
          TARGET_DIR=`echo $SOURCE | sed -e "s@^Shared/@@" -e "s/\/.*\//\//" -e "s@-@/@" -e "s/[.][^.]*$//" -e "s/[.]tar$//" -e "s/[.]7z$//"`
          if [ -f setup.5 ]; then # Stage 5 plug-in
            . ./setup.5
          fi
          if [ "$TARGET_DIR" ]; then
            echo "$TARGET_DIR"
            TARGET_DIRS="$TARGET_DIRS$TARGET_DIR " # List of all target directories used
            if [ -d $INSTALL_DIR/$TARGET_DIR ]; then
              if [ ! -w "$INSTALL_DIR/$TARGET_DIR" ]; then
                PACKAGES_ERROR="$PACKAGES_ERROR
$TARGET_DIR"
              else
                case $TARGET_DIR in
                */*)
                  PACKAGES_EXIST="$PACKAGES_EXIST
$TARGET_DIR"
                  SOURCES_OK="$SOURCES_OK$SOURCE ";;
                *)
                  SOURCES_OK="$SOURCES_OK$SOURCE ";;
                esac
              fi
            else
              SOURCES_OK="$SOURCES_OK$SOURCE "
            fi
          fi
        done
        if [ "$PACKAGES_EXIST" ]; then
          echo "
***WARNING*** The following installation directories will be over-written.
              Please go back and unselect if the old installation is required.
$PACKAGES_EXIST"
        fi  
        if [ "$PACKAGES_ERROR" ]; then
          echo "
***ERROR*** The following installation directories cannot be over-written.
            Please check permissions if you want to install these packages.
$PACKAGES_ERROR"
        fi
        echo
        echo "The next stage will start the installation process: (X=Exit B=Back N=Next)"
        read_line SELECTION
        case $SELECTION in
        x|X)
          echo "Installation aborted!"; STAGE=-1;;
        b|B)
          STAGE=4; RESTORE_OPTIONS="$PACKAGES"
          if [ "$STAGE4_SKIP" ]; then
            STAGE=3; RESTORE_OPTIONS="$PLATFORMS"
            if [ "$STAGE3_SKIP" -o ! "$PLATFORMS" ]; then
              STAGE=2; RESTORE_OPTIONS="$SOFTWARES"
              if [ "$STAGE2_SKIP" ]; then
                STAGE=1
              fi
            fi
          fi;;
        n|N)
          STAGE=6;;
        esac;;
#
# Installation process (STAGE=6)
#
      6)
        echo "
**************************************
* INSTALLATION PROCESS   (Stage 6/7) *
**************************************
"
        echo "Please wait. The installation process can take a few minutes..."
        mkdir $INSTALL_DIR/etc 2> /dev/null
        echo "`date +'%Y-%m-%d-%H:%M:%S'`: Installation starting
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
        WORK_TOTAL=`expr \`echo \\\`ls -l $SOURCES_OK | awk '{print $5}'\\\` | sed -e "s/ / + /g"\``
        WORK_DONE=0; TIME_INIT=`time_sec 0`
        INSTALL_ERROR=
        for SOURCE in $SOURCES_OK; do
          TARGET_DIR=`echo $SOURCE | sed -e "s@^Shared/@@" -e "s/\/.*\//\//" -e "s@-@/@" -e "s/[.][^.]*$//" -e "s/[.]tar$//" -e "s/[.]7z$//"`
          if [ -f setup.6 ]; then # Stage 6 plug-in
            . ./setup.6
          fi
          $ECHO "\r$TARGET_DIR..."
          mkdir -p $INSTALL_DIR/$TARGET_DIR 2> /dev/null
          if [ "`check_disk $INSTALL_DIR/$TARGET_DIR`" ]; then
            $ECHO "\r***ERROR*** Unable to create directory. Installation disk is full."
            echo "Installation failed!"; STAGE=0; break 2
          fi
          TIME_USED=`time_sec $TIME_INIT`
          if [ $TIME_USED != 0 -a $WORK_DONE != 0 ]; then
            if [ $WORK_DONE -le 1048576 ]; then # Estimates are inaccurate for less than 1MB of packages installed
              echo $WORK_TOTAL $WORK_DONE $TIME_USED | awk '{printf ("( Elapsed Time:%3dmin,  Estimated Time Left:  ?min, %6.2f%% Completion )",$3/60+0.5,$2/$1*100)}'
            else
              echo $WORK_TOTAL $WORK_DONE $TIME_USED | awk '{printf ("( Elapsed Time:%3dmin,  Estimated Time Left:%3dmin, %6.2f%% Completion )",$3/60+0.5,($1-$2)/($2*60)*$3+1,$2/$1*100)}'
            fi
          else
            $ECHO "( Elapsed Time:  0min,  Estimated Time Left:  ?min,   0.00% Completion )\c"
          fi
          UNPACK_ERROR=`install_package $SOURCE $INSTALL_DIR/$TARGET_DIR 2>&1`
          WORK_DONE=`expr $WORK_DONE + \`ls -l $SOURCE | awk '{print $5}'\``
          $ECHO "\r                                                                          \r\c" # 2 chars more than printout
          if [ "$UNPACK_ERROR" ]; then
            echo "$UNPACK_ERROR"; echo "***ERROR*** Unable to unpack \"$SOURCE\" package."; break 2
          fi
          if [ "`check_disk $INSTALL_DIR/$TARGET_DIR`" ]; then
            $ECHO "\r***ERROR*** Package installation error. Installation disk is full."
            echo "Installation failed!"; STAGE=0; break 2
          fi
          LIST=`echo $SOURCE | sed -e "s/[.][^.]*$//" -e "s/[.]tar$//" -e "s/[.]7z$//"`.list
          if [ -f "$LIST" ]; then
            TIME=`date +'%Y-%m-%d-%H:%M:%S'`
            echo "$TIME: Unpack `pwd`/$SOURCE
`sed -e \"s@^@$TIME: $INSTALL_DIR/$TARGET_DIR/@\" $LIST`
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
          fi
        done
        TIME_USED=`time_sec $TIME_INIT`
        echo $TIME_USED | awk '{printf ("( Elapsed Time:%3dmin,  Estimated Time Left:  0min, 100.00%% Completion )\n",$1/60+0.5)}'
        echo "Installation completed!"
        export SOFTWARES PLATFORMS PACKAGES # For setup plugins to use
        echo "
**************************************
* POST INSTALLATION      (Stage 7/7) *
**************************************
"
        echo "Running post installation configuration..."
        for SOFTWARE in `echo "$SOFTWARES" | grep "^+" | cut -c2-`; do
          TARGET_DIRTOP=`echo $SOFTWARE | sed -e "s@-@/@"`
          if [ -d "$INSTALL_DIR/$TARGET_DIRTOP" ]; then
            if [ -f $SOFTWARE/README ]; then
              cp $SOFTWARE/README $INSTALL_DIR/$TARGET_DIRTOP/README 2> /dev/null
            fi
            if [ -f $SOFTWARE/setup ]; then
              echo "Running \"Packages/$SOFTWARE/setup\"..."
              /bin/sh $SOFTWARE/setup $INSTALL_DIR/$TARGET_DIRTOP
              echo "`date +'%Y-%m-%d-%H:%M:%S'`: Running `pwd`/Packages/$SOFTWARE/setup $INSTALL_DIR/$TARGET_DIRTOP
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
            fi
            if [ "$INSTALL_ERROR" ]; then
              $ECHO "\r***ERROR*** One or more of the selected packages failed to install."
              echo "`date +'%Y-%m-%d-%H:%M:%S'`: Installation package failure 
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
              echo "Installation failed!"; STAGE=0; break 2
            fi
            if [ "`check_disk $INSTALL_DIR/$TARGET_DIRTOP`" ]; then
              $ECHO "\r***ERROR*** README file write error. Installation disk is full."
              echo "`date +'%Y-%m-%d-%H:%M:%S'`: Installation disk full failure 
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
              echo "Installation failed!"; STAGE=0; break 2
            fi
          fi
        done
        if [ -f README ]; then
          cp README $INSTALL_DIR/README 2> /dev/null
          chmod u+w $INSTALL_DIR/README
        fi
        if [ -f setup ]; then
          echo "Running \"Packages/setup\"..."
          /bin/sh setup $INSTALL_DIR # Packages/setup
          echo "`date +'%Y-%m-%d-%H:%M:%S'`: Running `pwd`/Packages/setup $INSTALL_DIR
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
        fi
        echo "`date +'%Y-%m-%d-%H:%M:%S'`: Installation finished
" >> $INSTALL_DIR/etc/installer.log 2> /dev/null
        echo "DONE!"; STAGE=0;;
      esac
    done
    while [ 1 ]; do
      echo
      echo "Please enter your selection (R=Restart C=Close):"
      read_line SELECTION
      case $SELECTION in
      r|R)
        break;;
      c|C)
        break 2;;
      esac
    done
  done
fi
