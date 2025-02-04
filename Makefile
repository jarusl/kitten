VERSION = 1
PATCHLEVEL = 3
SUBLEVEL = 0
EXTRAVERSION = Kitten
NAME=Kitten


# *DOCUMENTATION*
# To see a list of typical targets execute "make help"
# More info can be located in ./README
# Comments in this file are targeted only to the developer, do not
# expect to learn how to build the kernel reading this file.

# Do not print "Entering directory ..."
MAKEFLAGS += --no-print-directory

# We are using a recursive build, so we need to do a little thinking
# to get the ordering right.
#
# Most importantly: sub-Makefiles should only ever modify files in
# their own directory. If in some directory we have a dependency on
# a file in another dir (which doesn't happen often, but it's often
# unavoidable when linking the built-in.o targets which finally
# turn into vmlwk), we will call a sub make in that other dir, and
# after that we are sure that everything which is in that other dir
# is now up to date.
#
# The only cases where we need to modify files which have global
# effects are thus separated out and done before the recursive
# descending is started. They are now explicitly listed as the
# prepare rule.

# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands

ifdef V
  ifeq ("$(origin V)", "command line")
    KBUILD_VERBOSE = $(V)
  endif
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

# Call sparse as part of compilation of C files
# Use 'make C=1' to enable sparse checking

ifdef C
  ifeq ("$(origin C)", "command line")
    KBUILD_CHECKSRC = $(C)
  endif
endif
ifndef KBUILD_CHECKSRC
  KBUILD_CHECKSRC = 0
endif

# Use make M=dir to specify directory of external module to build
# Old syntax make ... SUBDIRS=$PWD is still supported
# Setting the environment variable KBUILD_EXTMOD take precedence
ifdef SUBDIRS
  KBUILD_EXTMOD ?= $(SUBDIRS)
endif
ifdef M
  ifeq ("$(origin M)", "command line")
    KBUILD_EXTMOD := $(M)
  endif
endif


# kbuild supports saving output files in a separate directory.
# To locate output files in a separate directory two syntaxes are supported.
# In both cases the working directory must be the root of the kernel src.
# 1) O=
# Use "make O=dir/to/store/output/files/"
# 
# 2) Set KBUILD_OUTPUT
# Set the environment variable KBUILD_OUTPUT to point to the directory
# where the output files shall be placed.
# export KBUILD_OUTPUT=dir/to/store/output/files/
# make
#
# The O= assignment takes precedence over the KBUILD_OUTPUT environment
# variable.


# KBUILD_SRC is set on invocation of make in OBJ directory
# KBUILD_SRC is not intended to be used by the regular user (for now)
ifeq ($(KBUILD_SRC),)

# OK, Make called in directory where kernel src resides
# Do we want to locate output files in a separate directory?
ifdef O
  ifeq ("$(origin O)", "command line")
    KBUILD_OUTPUT := $(O)
  endif
endif

# That's our default target when none is given on the command line
PHONY := _all
_all:

ifneq ($(KBUILD_OUTPUT),)
# Invoke a second make in the output directory, passing relevant variables
# check that the output directory actually exists
saved-output := $(KBUILD_OUTPUT)
KBUILD_OUTPUT := $(shell cd $(KBUILD_OUTPUT) && /bin/pwd)
$(if $(KBUILD_OUTPUT),, \
     $(error output directory "$(saved-output)" does not exist))

PHONY += $(MAKECMDGOALS)

$(filter-out _all,$(MAKECMDGOALS)) _all:
	$(if $(KBUILD_VERBOSE:1=),@)$(MAKE) -C $(KBUILD_OUTPUT) \
	KBUILD_SRC=$(CURDIR) \
	KBUILD_EXTMOD="$(KBUILD_EXTMOD)" -f $(CURDIR)/Makefile $@

# Leave processing to above invocation of make
skip-makefile := 1
endif # ifneq ($(KBUILD_OUTPUT),)
endif # ifeq ($(KBUILD_SRC),)

# We process the rest of the Makefile if this is the final invocation of make
ifeq ($(skip-makefile),)

# If building an external module we do not care about the all: rule
# but instead _all depend on modules
PHONY += all
ifeq ($(KBUILD_EXTMOD),)
_all: all
else
_all: modules
endif

srctree		:= $(if $(KBUILD_SRC),$(KBUILD_SRC),$(CURDIR))
TOPDIR		:= $(srctree)
# FIXME - TOPDIR is obsolete, use srctree/objtree
objtree		:= $(CURDIR)
src		:= $(srctree)
obj		:= $(objtree)

VPATH		:= $(srctree)$(if $(KBUILD_EXTMOD),:$(KBUILD_EXTMOD))

export srctree objtree VPATH TOPDIR


# SUBARCH tells the usermode build what the underlying arch is.  That is set
# first, and if a usermode build is happening, the "ARCH=um" on the command
# line overrides the setting of ARCH below.  If a native build is happening,
# then ARCH is assigned, getting whatever value it gets normally, and 
# SUBARCH is subsequently ignored.

SUBARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ \
				  -e s/arm.*/arm/ -e s/sa110/arm/ \
				  -e s/s390x/s390/ -e s/parisc64/parisc/ \
				  -e s/ppc.*/powerpc/ -e s/mips.*/mips/ )

# Cross compiling and selecting different set of gcc/bin-utils
# ---------------------------------------------------------------------------
#
# When performing cross compilation for other architectures ARCH shall be set
# to the target architecture. (See arch/* for the possibilities).
# ARCH can be set during invocation of make:
# make ARCH=ia64
# Another way is to have ARCH set in the environment.
# The default ARCH is the host where make is executed.

# CROSS_COMPILE specify the prefix used for all executables used
# during compilation. Only gcc and related bin-utils executables
# are prefixed with $(CROSS_COMPILE).
# CROSS_COMPILE can be set on the command line
# make CROSS_COMPILE=ia64-linux-
# Alternatively CROSS_COMPILE can be set in the environment.
# Default value for CROSS_COMPILE is not to prefix executables
# Note: Some architectures assign CROSS_COMPILE in their arch/*/Makefile

ARCH		?= $(SUBARCH)
CROSS_COMPILE	?=

# Architecture as present in compile.h
UTS_MACHINE	:= $(ARCH)
SRCARCH		:= $(ARCH)

# Additional ARCH settings for x86
ifeq ($(ARCH),k1om)
        SRCARCH := x86_64
endif

# SHELL used by kbuild
CONFIG_SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	  else if [ -x /bin/bash ]; then echo /bin/bash; \
	  else echo sh; fi ; fi)

HOSTCC  	= gcc
HOSTCXX  	= g++
HOSTCFLAGS	= -Wall -Wstrict-prototypes -O2 -fomit-frame-pointer \
			-Wno-unused -Wno-format-security -U_FORTIFY_SOURCE
HOSTCXXFLAGS	= -O2

# 	Decide whether to build built-in, modular, or both.
#	Normally, just do built-in.

KBUILD_MODULES :=
KBUILD_BUILTIN := 1

#	If we have only "make modules", don't compile built-in objects.
#	When we're building modules with modversions, we need to consider
#	the built-in objects during the descend as well, in order to
#	make sure the checksums are uptodate before we record them.

ifeq ($(MAKECMDGOALS),modules)
  KBUILD_BUILTIN := $(if $(CONFIG_MODVERSIONS),1)
endif

#	If we have "make <whatever> modules", compile modules
#	in addition to whatever we do anyway.
#	Just "make" or "make all" shall build modules as well

ifneq ($(filter all _all modules,$(MAKECMDGOALS)),)
  KBUILD_MODULES := 1
endif

ifeq ($(MAKECMDGOALS),)
  KBUILD_MODULES := 1
endif

export KBUILD_MODULES KBUILD_BUILTIN
export KBUILD_CHECKSRC KBUILD_SRC KBUILD_EXTMOD

# Beautify output
# ---------------------------------------------------------------------------
#
# Normally, we echo the whole command before executing it. By making
# that echo $($(quiet)$(cmd)), we now have the possibility to set
# $(quiet) to choose other forms of output instead, e.g.
#
#         quiet_cmd_cc_o_c = Compiling $(RELDIR)/$@
#         cmd_cc_o_c       = $(CC) $(c_flags) -c -o $@ $<
#
# If $(quiet) is empty, the whole command will be printed.
# If it is set to "quiet_", only the short version will be printed. 
# If it is set to "silent_", nothing wil be printed at all, since
# the variable $(silent_cmd_cc_o_c) doesn't exist.
#
# A simple variant is to prefix commands with $(Q) - that's useful
# for commands that shall be hidden in non-verbose mode.
#
#	$(Q)ln $@ :<
#
# If KBUILD_VERBOSE equals 0 then the above command will be hidden.
# If KBUILD_VERBOSE equals 1 then the above command is displayed.

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

# If the user is running make -s (silent mode), suppress echoing of
# commands

ifneq ($(findstring s,$(MAKEFLAGS)),)
  quiet=silent_
endif

export quiet Q KBUILD_VERBOSE


# Look for make include files relative to root of kernel src
MAKEFLAGS += --include-dir=$(srctree)

# We need some generic definitions
include  $(srctree)/scripts/Kbuild.include

# For maximum performance (+ possibly random breakage, uncomment
# the following)

#MAKEFLAGS += -rR

# Make variables (CC, etc...)

AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)ld
CC		= $(CROSS_COMPILE)gcc
CPP		= $(CC) -E
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
STRIP		= $(CROSS_COMPILE)strip
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump
AWK		= awk
GENKSYMS	= scripts/genksyms/genksyms
DEPMOD		= /sbin/depmod
KALLSYMS	= scripts/kallsyms
PERL		= perl
CHECK		= sparse

CHECKFLAGS     := -D__lwk__ -Dlwk -D__STDC__ -Dunix -D__unix__ -Wbitwise $(CF)
MODFLAGS	= -DMODULE
CFLAGS_MODULE   = $(MODFLAGS)
AFLAGS_MODULE   = $(MODFLAGS)
LDFLAGS_MODULE  = -r
CFLAGS_KERNEL	=
AFLAGS_KERNEL	=
LINUX_INCLUDE   = -Iofed/include


# Use LWKINCLUDE when you must reference the include/ directory.
# Needed to be compatible with the O= option
LWKINCLUDE      := -Iinclude \
			$(LINUX_INCLUDE) \
		   $(if $(KBUILD_SRC),-Iinclude2 -I$(srctree)/include) \
		   -include include/lwk/autoconf.h

CPPFLAGS        := -D__KERNEL__ $(LWKINCLUDE) -D__LWK__

CFLAGS 		:= -std=gnu99 \
		   -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs \
		   -fno-strict-aliasing -fno-strict-overflow -fno-common -fno-pie -ffreestanding

ifeq ($(call cc-option-yn, -fstack-protector),y)
CFLAGS		+= -fno-stack-protector
endif

ifeq ($(call cc-option-yn, -fgnu89-inline),y)
CFLAGS		+= -fgnu89-inline
endif

AFLAGS		:= -D__ASSEMBLY__

# Read KERNELRELEASE from .kernelrelease (if it exists)
KERNELRELEASE = $(shell cat .kernelrelease 2> /dev/null)
KERNELVERSION = $(VERSION).$(PATCHLEVEL).$(SUBLEVEL)$(EXTRAVERSION)

export	VERSION PATCHLEVEL SUBLEVEL KERNELRELEASE KERNELVERSION \
	ARCH SRCARCH CONFIG_SHELL HOSTCC HOSTCFLAGS CROSS_COMPILE AS LD CC \
	CPP AR NM STRIP OBJCOPY OBJDUMP MAKE AWK GENKSYMS PERL UTS_MACHINE \
	HOSTCXX HOSTCXXFLAGS LDFLAGS_MODULE CHECK CHECKFLAGS

export CPPFLAGS NOSTDINC_FLAGS LWKINCLUDE OBJCOPYFLAGS LDFLAGS
export CFLAGS CFLAGS_KERNEL CFLAGS_MODULE 
export AFLAGS AFLAGS_KERNEL AFLAGS_MODULE

# When compiling out-of-tree modules, put MODVERDIR in the module
# tree rather than in the kernel tree. The kernel tree might
# even be read-only.
export MODVERDIR := $(if $(KBUILD_EXTMOD),$(firstword $(KBUILD_EXTMOD))/).tmp_versions

# Files to ignore in find ... statements

RCS_FIND_IGNORE := \( -name SCCS -o -name BitKeeper -o -name .svn -o -name CVS -o -name .pc -o -name .hg -o -name .git \) -prune -o
export RCS_TAR_IGNORE := --exclude SCCS --exclude BitKeeper --exclude .svn --exclude CVS --exclude .pc --exclude .hg --exclude .git

# ===========================================================================
# Rules shared between *config targets and build targets

# Basic helpers built in scripts/
PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic

# To avoid any implicit rule to kick in, define an empty command.
scripts/basic/%: scripts_basic ;

PHONY += outputmakefile
# outputmakefile generates a Makefile in the output directory, if using a
# separate output directory. This allows convenient use of make in the
# output directory.
outputmakefile:
ifneq ($(KBUILD_SRC),)
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile \
	    $(srctree) $(objtree) $(VERSION) $(PATCHLEVEL)
endif

# To make sure we do not include .config for any of the *config targets
# catch them early, and hand them over to scripts/kconfig/Makefile
# It is allowed to specify more targets when calling make, including
# mixing *config targets and build targets.
# For example 'make oldconfig all'. 
# Detect when mixed targets is specified, and make a second invocation
# of make so .config is not included in this case either (for *config).

no-dot-config-targets := clean mrproper distclean \
			 cscope TAGS tags help %docs check%

config-targets := 0
mixed-targets  := 0
dot-config     := 1

ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		dot-config := 0
	endif
endif

ifeq ($(KBUILD_EXTMOD),)
        ifneq ($(filter config %config,$(MAKECMDGOALS)),)
                config-targets := 1
                ifneq ($(filter-out config %config,$(MAKECMDGOALS)),)
                        mixed-targets := 1
                endif
        endif
endif

ifeq ($(mixed-targets),1)
# ===========================================================================
# We're called with mixed targets (*config and build targets).
# Handle them one by one.

%:: FORCE
	$(Q)$(MAKE) -C $(srctree) KBUILD_SRC= $@

else
ifeq ($(config-targets),1)
# ===========================================================================
# *config targets only - make sure prerequisites are updated, and descend
# in scripts/kconfig to make the *config target

# Read arch specific Makefile to set KBUILD_DEFCONFIG as needed.
# KBUILD_DEFCONFIG may point out an alternative default configuration
# used for 'make defconfig'
include $(srctree)/arch/$(SRCARCH)/Makefile
export KBUILD_DEFCONFIG

config: scripts_basic outputmakefile FORCE
	$(Q)mkdir -p include/lwk
	$(Q)$(MAKE) $(build)=scripts/kconfig $@
	$(Q)$(MAKE) -C $(srctree) KBUILD_SRC= .kernelrelease

%config: scripts_basic outputmakefile FORCE
	$(Q)mkdir -p include/lwk
	$(Q)$(MAKE) $(build)=scripts/kconfig $@
	$(Q)$(MAKE) -C $(srctree) KBUILD_SRC= .kernelrelease

else
# ===========================================================================
# Build targets only - this includes vmlwk, arch specific targets, clean
# targets and others. In general all targets except *config targets.

ifeq ($(KBUILD_EXTMOD),)
# Additional helpers built in scripts/
# Carefully list dependencies so we do not try to build scripts twice
# in parrallel
PHONY += scripts
scripts: scripts_basic include/config/MARKER
	$(Q)$(MAKE) $(build)=$(@)

scripts_basic: include/lwk/autoconf.h

# Objects we will link into vmlwk / subdirs we need to visit
drivers-y	:= drivers/
net-y		:= net/
block-y         := block/
libs-y		:= lib/
#linux-y		:= linux/
ofed-y          := ofed/
#core-y		:= usr/
endif # KBUILD_EXTMOD

ifeq ($(dot-config),1)
# In this section, we need .config

# Read in dependencies to all Kconfig* files, make sure to run
# oldconfig if changes are detected.
-include .kconfig.d

include .config

# If .config needs to be updated, it will be done via the dependency
# that autoconf has on .config.
# To avoid any implicit rule to kick in, define an empty command
.config .kconfig.d: ;

# If .config is newer than include/lwk/autoconf.h, someone tinkered
# with it and forgot to run make oldconfig.
# If kconfig.d is missing then we are probarly in a cleaned tree so
# we execute the config step to be sure to catch updated Kconfig files
include/lwk/autoconf.h: .kconfig.d .config
	$(Q)mkdir -p include/lwk
	$(Q)$(MAKE) -f $(srctree)/Makefile silentoldconfig
else
# Dummy target needed, because used as prerequisite
include/lwk/autoconf.h: ;
endif

DEFAULT_EXTRA_TARGETS=vmlwk.bin vmlwk.asm init_task

# The all: target is the default when no target is given on the
# command line.
# This allow a user to issue only 'make' to build a kernel including modules
# Defaults vmlwk but it is usually overriden in the arch makefile
all: vmlwk $(DEFAULT_EXTRA_TARGETS)

ifdef CONFIG_CC_OPTIMIZE_FOR_SIZE
CFLAGS		+= -Os
else
CFLAGS		+= -O2
endif

ifdef CONFIG_FRAME_POINTER
CFLAGS		+= -fno-omit-frame-pointer $(call cc-option,-fno-optimize-sibling-calls,)
else
CFLAGS		+= -fomit-frame-pointer
endif

ifdef CONFIG_UNWIND_INFO
CFLAGS		+= -fasynchronous-unwind-tables
endif

ifdef CONFIG_DEBUG_INFO
CFLAGS		+= -g
endif


include $(srctree)/arch/$(SRCARCH)/Makefile

# arch Makefile may override CC so keep this after arch Makefile is included
NOSTDINC_FLAGS += -nostdinc -isystem $(shell $(CC) -print-file-name=include)
CHECKFLAGS     += $(NOSTDINC_FLAGS)

# disable pointer signedness warnings in gcc 4.0
CFLAGS += $(call cc-option,-Wno-pointer-sign,)

# Default kernel image to build when no specific target is given.
# KBUILD_IMAGE may be overruled on the commandline or
# set in the environment
# Also any assignments in arch/$(SRCARCH)/Makefile take precedence over
# this default value
export KBUILD_IMAGE ?= vmlwk

#
# INSTALL_PATH specifies where to place the updated kernel and system map
# images. Default is /boot, but you can set it to other values
export	INSTALL_PATH ?= /boot

#
# INSTALL_MOD_PATH specifies a prefix to MODLIB for module directory
# relocations required by build roots.  This is not defined in the
# makefile but the arguement can be passed to make if needed.
#

MODLIB	= $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)
export MODLIB


ifeq ($(KBUILD_EXTMOD),)
#core-y		+= kernel/ fs/ ipc/ security/ crypto/ block/
core-y		+= kernel/ modules/

vmlwk-dirs	:= $(patsubst %/,%,$(filter %/, $(init-y) $(init-m) \
		     $(core-y) $(core-m) $(drivers-y) $(drivers-m) \
		     $(ofed-y) $(ofed-m)\
		     $(net-y) $(net-m) $(block-y) $(block-m) $(libs-y) $(libs-m)))

vmlwk-alldirs	:= $(sort $(vmlwk-dirs) $(patsubst %/,%,$(filter %/, \
		     $(init-n) $(init-) \
		     $(core-n) $(core-) $(drivers-n) $(drivers-) \
		     $(ofed-n) $(ofed-) \
		     $(net-n)  $(net-) $(block-n) $(block-)  $(libs-n)    $(libs-))))

init-y		:= $(patsubst %/, %/built-in.o, $(init-y))
core-y		:= $(patsubst %/, %/built-in.o, $(core-y))
drivers-y	:= $(patsubst %/, %/built-in.o, $(drivers-y))
net-y		:= $(patsubst %/, %/built-in.o, $(net-y))
block-y         := $(patsubst %/, %/built-in.o, $(block-y))
libs-y1		:= $(patsubst %/, %/lib.a, $(libs-y))
libs-y2		:= $(patsubst %/, %/built-in.o, $(libs-y))
libs-y		:= $(libs-y1) $(libs-y2)
#linux-y		:= $(patsubst %/, %/built-in.o, $(linux-y))
ofed-y          := $(patsubst %/, %/built-in.o, $(ofed-y))

# Link the LWK with the Palacios virtual machine monitor
#libs-$(CONFIG_PALACIOS) += $(shell echo $(CONFIG_PALACIOS_PATH)/libv3vee.a)

# Build vmlwk
# ---------------------------------------------------------------------------
# vmlwk is build from the objects selected by $(vmlwk-init) and
# $(vmlwk-main). Most are built-in.o files from top-level directories
# in the kernel tree, others are specified in arch/$(SRCARCH)Makefile.
# Ordering when linking is important, and $(vmlwk-init) must be first.
#
# vmlwk
#   ^
#   |
#   +-< $(vmlwk-init)
#   |   +--< kernel/version.o + more
#   |
#   +--< $(vmlwk-main)
#   |    +--< driver/built-in.o + more
#   |
#   +-< kallsyms.o (see description in CONFIG_KALLSYMS section)
#
# vmlwk version (uname -v) cannot be updated during normal
# descending-into-subdirs phase since we do not yet know if we need to
# update vmlwk.
# Therefore this step is delayed until just before final link of vmlwk -
# except in the kallsyms case where it is done just before adding the
# symbols to the kernel.
#
# System.map is generated to document addresses of all kernel symbols


v3vee-objs :=

ifdef CONFIG_PALACIOS
v3vee-objs += $(CONFIG_PALACIOS_PATH)/libv3vee.a
endif

v3vee: FORCE
ifdef CONFIG_PALACIOS
	make -C $(CONFIG_PALACIOS_PATH)
endif

vmlwk-init := $(head-y) $(init-y)
vmlwk-main := $(core-y) $(libs-y) $(drivers-y) $(net-y) $(block-y) $(ofed-y)
vmlwk-all  := $(vmlwk-init) $(vmlwk-main)
vmlwk-lds  := arch/$(SRCARCH)/kernel/vmlwk.lds

# Rule to link vmlwk - also used during CONFIG_KALLSYMS
# May be overridden by arch/$(SRCARCH)/Makefile
quiet_cmd_vmlwk__ ?= LD      $@
      cmd_vmlwk__ ?= $(LD) $(LDFLAGS) $(LDFLAGS_vmlwk) -o $@   \
      -T $(vmlwk-lds) $(vmlwk-init)                            \
      --start-group $(vmlwk-main) $(v3vee-objs) --end-group                  \
      $(filter-out $(vmlwk-lds) $(vmlwk-init) $(vmlwk-main) v3vee FORCE ,$^)

# Generate new vmlwk version
quiet_cmd_vmlwk_version = GEN     .version
      cmd_vmlwk_version = set -e;                       \
	if [ ! -r .version ]; then			\
	  rm -f .version;				\
	  echo 1 >.version;				\
	else						\
	  mv .version .old_version;			\
	  expr 0$$(cat .old_version) + 1 >.version;	\
	fi;						\
	$(MAKE) $(build)=kernel

# Generate System.map
quiet_cmd_sysmap = SYSMAP 
      cmd_sysmap = $(CONFIG_SHELL) $(srctree)/scripts/mksysmap

# Link of vmlwk
# If CONFIG_KALLSYMS is set .version is already updated
# Generate System.map and verify that the content is consistent
# Use + in front of the vmlwk_version rule to silent warning with make -j2
# First command is ':' to allow us to use + in front of the rule
define rule_vmlwk__
	:
	$(if $(CONFIG_KALLSYMS),,+$(call cmd,vmlwk_version))

	$(call cmd,vmlwk__)
	$(Q)echo 'cmd_$@ := $(cmd_vmlwk__)' > $(@D)/.$(@F).cmd

	$(Q)$(if $($(quiet)cmd_sysmap),                 \
	  echo '  $($(quiet)cmd_sysmap) System.map' &&) \
	$(cmd_sysmap) $@ System.map;                    \
	if [ $$? -ne 0 ]; then                          \
		rm -f $@;                               \
		/bin/false;                             \
	fi;
	$(verify_kallsyms)
endef


ifdef CONFIG_KALLSYMS
# Generate section listing all symbols and add it into vmlwk $(kallsyms.o)
# It's a three stage process:
# o .tmp_vmlwk1 has all symbols and sections, but __kallsyms is
#   empty
#   Running kallsyms on that gives us .tmp_kallsyms1.o with
#   the right size - vmlwk version (uname -v) is updated during this step
# o .tmp_vmlwk2 now has a __kallsyms section of the right size,
#   but due to the added section, some addresses have shifted.
#   From here, we generate a correct .tmp_kallsyms2.o
# o The correct .tmp_kallsyms2.o is linked into the final vmlwk.
# o Verify that the System.map from vmlwk matches the map from
#   .tmp_vmlwk2, just in case we did not generate kallsyms correctly.
# o If CONFIG_KALLSYMS_EXTRA_PASS is set, do an extra pass using
#   .tmp_vmlwk3 and .tmp_kallsyms3.o.  This is only meant as a
#   temporary bypass to allow the kernel to be built while the
#   maintainers work out what went wrong with kallsyms.

ifdef CONFIG_KALLSYMS_EXTRA_PASS
last_kallsyms := 3
else
last_kallsyms := 2
endif

kallsyms.o := .tmp_kallsyms$(last_kallsyms).o

define verify_kallsyms
	$(Q)$(if $($(quiet)cmd_sysmap),                       \
	  echo '  $($(quiet)cmd_sysmap) .tmp_System.map' &&)  \
	  $(cmd_sysmap) .tmp_vmlwk$(last_kallsyms) .tmp_System.map
	$(Q)cmp -s System.map .tmp_System.map ||              \
		(echo Inconsistent kallsyms data;             \
		 echo Try setting CONFIG_KALLSYMS_EXTRA_PASS; \
		 rm .tmp_kallsyms* ; /bin/false )
endef

# Update vmlwk version before link
# Use + in front of this rule to silent warning about make -j1
# First command is ':' to allow us to use + in front of this rule
cmd_ksym_ld = $(cmd_vmlwk__)
define rule_ksym_ld
	: 
	+$(call cmd,vmlwk_version)
	$(call cmd,vmlwk__)
	$(Q)echo 'cmd_$@ := $(cmd_vmlwk__)' > $(@D)/.$(@F).cmd
endef

# Generate .S file with all kernel symbols
quiet_cmd_kallsyms = KSYM    $@
      cmd_kallsyms = $(NM) -n $< | $(KALLSYMS) \
                     $(if $(CONFIG_KALLSYMS_ALL),--all-symbols) > $@

.tmp_kallsyms1.o .tmp_kallsyms2.o .tmp_kallsyms3.o: %.o: %.S scripts FORCE
	$(call if_changed_dep,as_o_S)

.tmp_kallsyms%.S: .tmp_vmlwk% $(KALLSYMS)
	$(call cmd,kallsyms)

# .tmp_vmlwk1 must be complete except kallsyms, so update vmlwk version
.tmp_vmlwk1: $(vmlwk-lds) $(vmlwk-all) FORCE
	$(call if_changed_rule,ksym_ld)

.tmp_vmlwk2: $(vmlwk-lds) $(vmlwk-all) .tmp_kallsyms1.o FORCE
	$(call if_changed,vmlwk__)

.tmp_vmlwk3: $(vmlwk-lds) $(vmlwk-all) .tmp_kallsyms2.o FORCE
	$(call if_changed,vmlwk__)

# Needs to visit scripts/ before $(KALLSYMS) can be used.
$(KALLSYMS): scripts ;

# Generate some data for debugging strange kallsyms problems
debug_kallsyms: .tmp_map$(last_kallsyms)

.tmp_map%: .tmp_vmlwk% FORCE
	($(OBJDUMP) -h $< | $(AWK) '/^ +[0-9]/{print $$4 " 0 " $$2}'; $(NM) $<) | sort > $@

.tmp_map3: .tmp_map2

.tmp_map2: .tmp_map1

endif # ifdef CONFIG_KALLSYMS


# vmlwk image - including updated kernel symbols
vmlwk: $(vmlwk-lds) $(vmlwk-init) $(vmlwk-main) v3vee $(kallsyms.o) FORCE
	$(call if_changed_rule,vmlwk__)
	$(Q)rm -f .old_version

ifeq ($(CONFIG_CRAY_GEMINI),y)
# Generate the necessary padding to push the executable image
# to the start address since the Cray bootloader always loads
# at 0x10000.
vmlwk.bin: vmlwk
	$(OBJCOPY) -O binary $< $@.tmp
	( perl -e 'print chr(0x90) x (1<<20)' ; cat $@.tmp ) > $@
	$(RM) $@.tmp
else
vmlwk.bin: vmlwk
	$(OBJCOPY) -O binary $< $@
endif

vmlwk.asm: vmlwk
	$(OBJDUMP) --disassemble $< > $@

# The actual objects are generated when descending, 
# make sure no implicit rule kicks in
$(sort $(vmlwk-init) $(vmlwk-main)) $(vmlwk-lds): $(vmlwk-dirs) ;

# Handle descending into subdirectories listed in $(vmlwk-dirs)
# Preset locale variables to speed up the build process. Limit locale
# tweaks to this spot to avoid wrong language settings when running
# make menuconfig etc.
# Error messages still appears in the original language

PHONY += $(vmlwk-dirs)
$(vmlwk-dirs): prepare scripts
	$(Q)$(MAKE) $(build)=$@

# Build the kernel release string
# The KERNELRELEASE is stored in a file named .kernelrelease
# to be used when executing for example make install or make modules_install
#
# Take the contents of any files called localversion* and the config
# variable CONFIG_LOCALVERSION and append them to KERNELRELEASE.
# LOCALVERSION from the command line override all of this

nullstring :=
space      := $(nullstring) # end of line

___localver = $(objtree)/localversion* $(srctree)/localversion*
__localver  = $(sort $(wildcard $(___localver)))
# skip backup files (containing '~')
_localver = $(foreach f, $(__localver), $(if $(findstring ~, $(f)),,$(f)))

localver = $(subst $(space),, \
	   $(shell cat /dev/null $(_localver)) \
	   $(patsubst "%",%,$(CONFIG_LOCALVERSION)))
	       
# If CONFIG_LOCALVERSION_AUTO is set scripts/setlocalversion is called
# and if the SCM is know a tag from the SCM is appended.
# The appended tag is determinded by the SCM used.
#
# Currently, only git, mercurial and svn are supported.
# Other SCMs can edit scripts/setlocalversion and add the appropriate
# checks as needed.
ifdef CONFIG_LOCALVERSION_AUTO
	_localver-auto = $(shell $(CONFIG_SHELL) \
	                  $(srctree)/scripts/setlocalversion $(srctree))
	localver-auto  = $(LOCALVERSION)$(_localver-auto)
endif

localver-full = $(localver)$(localver-auto)

# Store (new) KERNELRELASE string in .kernelrelease
kernelrelease = $(KERNELVERSION)$(localver-full)
.kernelrelease: FORCE
	$(Q)rm -f $@
	$(Q)echo $(kernelrelease) > $@


# Things we need to do before we recursively start building the kernel
# or the modules are listed in "prepare".
# A multi level approach is used. prepareN is processed before prepareN-1.
# archprepare is used in arch Makefiles and when processed arch symlink,
# version.h and scripts_basic is processed / created.

# Listed in dependency order
PHONY += prepare archprepare prepare0 prepare1 prepare2 prepare3

# prepare-all is deprecated, use prepare as valid replacement
PHONY += prepare-all

# prepare3 is used to check if we are building in a separate output directory,
# and if so do:
# 1) Check that make has not been executed in the kernel src $(srctree)
# 2) Create the include2 directory, used for the second arch symlink
prepare3: .kernelrelease
ifneq ($(KBUILD_SRC),)
	@echo '  Using $(srctree) as source for kernel'
	$(Q)if [ -f $(srctree)/.config ]; then \
		echo "  $(srctree) is not clean, please run 'make mrproper'";\
		echo "  in the '$(srctree)' directory.";\
		/bin/false; \
	fi;
	$(Q)if [ ! -d include2 ]; then mkdir -p include2; fi;
	$(Q)ln -fsn $(srctree)/include/arch-$(SRCARCH) include2/arch
	$(Q)if [ ! -d linux/include2 ]; then mkdir -p linux/include2; fi;
	$(Q)ln -fsn $(srctree)/linux/include/asm-$(SRCARCH) linux/include2/asm
endif

# prepare2 creates a makefile if using a separate output directory
prepare2: prepare3 outputmakefile

prepare1: prepare2 include/lwk/version.h include/arch linux/include/asm \
                   include/config/MARKER
ifneq ($(KBUILD_MODULES),)
	$(Q)mkdir -p $(MODVERDIR)
	$(Q)rm -f $(MODVERDIR)/*
endif

archprepare: prepare1 scripts_basic

prepare0: archprepare FORCE
	$(Q)$(MAKE) $(build)=.

# All the preparing..
prepare prepare-all: prepare0

#	Leave this as default for preprocessing vmlwk.lds.S, which is now
#	done in arch/$(SRCARCH)/kernel/Makefile

export CPPFLAGS_vmlwk.lds += -P -C -U$(SRCARCH)


# The asm symlink changes when $(SRCARCH) changes.
# Detect this and ask user to run make mrproper

include/arch: FORCE
	$(Q)set -e; asmlink=`readlink include/arch | cut -d '-' -f 2`;   \
	if [ -L include/arch ]; then                                     \
		if [ "$$asmlink" != "$(SRCARCH)" ]; then                \
			echo "ERROR: the symlink $@ points to arch-$$asmlink but arch-$(SRCARCH) was expected"; \
			echo "       set ARCH or save .config and run 'make mrproper' to fix it";             \
			exit 1;                                         \
		fi;                                                     \
	else                                                            \
		echo '  SYMLINK $@ -> include/arch-$(SRCARCH)';          \
		if [ ! -d include ]; then                               \
			mkdir -p include;                               \
		fi;                                                     \
		ln -fsn arch-$(SRCARCH) $@;                              \
	fi

linux/include/asm: FORCE
	$(Q)set -e; asmlink=`readlink linux/include/asm | cut -d '-' -f 2`;   \
	if [ -L linux/include/asm ]; then                                     \
		if [ "$$asmlink" != "$(SRCARCH)" ]; then                \
			echo "ERROR: the symlink $@ points to asm-$$asmlink but asm-$(SRCARCH) was expected"; \
			echo "       set ARCH or save .config and run 'make mrproper' to fix it";             \
			exit 1;                                         \
		fi;                                                     \
	else                                                            \
		echo '  SYMLINK $@ -> linux/include/asm-$(SRCARCH)';          \
		if [ ! -d linux/include ]; then                               \
			mkdir -p linux/include;                               \
		fi;                                                     \
		ln -fsn asm-$(SRCARCH) $@;                              \
	fi

# 	Split autoconf.h into include/lwk/config/*

include/config/MARKER: scripts/basic/split-include include/lwk/autoconf.h
	@echo '  SPLIT   include/lwk/autoconf.h -> include/config/*'
	@scripts/basic/split-include include/lwk/autoconf.h include/config
	@touch $@

# Generate some files
# ---------------------------------------------------------------------------

# KERNELRELEASE can change from a few different places, meaning version.h
# needs to be updated, so this check is forced on all builds

uts_len := 64

define filechk_version.h
	if [ `echo -n "$(KERNELRELEASE)" | wc -c ` -gt $(uts_len) ]; then \
	  echo '"$(KERNELRELEASE)" exceeds $(uts_len) characters' >&2; \
	  exit 1; \
	fi; \
	(echo \#define UTS_RELEASE \"$(KERNELRELEASE)\"; \
	  echo \#define LWK_VERSION_CODE `expr $(VERSION) \\* 65536 + $(PATCHLEVEL) \\* 256 + $(SUBLEVEL)`; \
	 echo '#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + (c))'; \
	)
endef

include/lwk/version.h: $(srctree)/Makefile .config .kernelrelease FORCE
	$(call filechk,version.h)

# ---------------------------------------------------------------------------

PHONY += depend dep
depend dep:
	@echo '*** Warning: make $@ is unnecessary now.'

# ---------------------------------------------------------------------------
# Kernel headers
INSTALL_HDR_PATH=$(MODLIB)/abi
export INSTALL_HDR_PATH

PHONY += headers_install
headers_install: include/lwk/version.h
	$(Q)unifdef -Ux /dev/null
	$(Q)rm -rf $(INSTALL_HDR_PATH)/include
	$(Q)$(MAKE) -rR -f $(srctree)/scripts/Makefile.headersinst obj=include

PHONY += headers_check
headers_check: headers_install
	$(Q)$(MAKE) -rR -f $(srctree)/scripts/Makefile.headersinst obj=include HDRCHECK=1

###
# Cleaning is done on three levels.
# make clean     Delete most generated files
#                Leave enough to build external modules
# make mrproper  Delete the current configuration, and all generated files
# make distclean Remove editor backup files, patch leftover files and the like

# Directories & files removed with 'make clean'
CLEAN_DIRS  += $(MODVERDIR)
CLEAN_FILES +=	vmlwk System.map vmlwk.bin vmlwk.asm \
                .tmp_kallsyms* .tmp_version .tmp_vmlwk* .tmp_System.map

# Directories & files removed with 'make mrproper'
MRPROPER_DIRS  += include/config include2
MRPROPER_FILES += .config .config.old include/arch linux/include/asm .version .old_version \
                  include/lwk/autoconf.h include/lwk/version.h \
		  .kernelrelease Module.symvers tags TAGS cscope*

# clean - Delete most, but leave enough to build external modules
#
clean: rm-dirs  := $(CLEAN_DIRS)
clean: rm-files := $(CLEAN_FILES)
clean-dirs      := $(addprefix _clean_,$(srctree) $(vmlwk-alldirs))

PHONY += $(clean-dirs) clean archclean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

clean: archclean $(clean-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)
	@find . -path ./user -prune -o $(RCS_FIND_IGNORE) \
	 	\( -name '*.[oas]' -o -name '*.ko' -o -name '.*.cmd' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \) \
		-type f -print | xargs rm -f
	$(Q)$(MAKE) -s -C user clean
	@rm -f init_task

# mrproper - Delete all generated files, including .config
#
mrproper: rm-dirs  := $(wildcard $(MRPROPER_DIRS))
mrproper: rm-files := $(wildcard $(MRPROPER_FILES))
#mrproper-dirs      := $(addprefix _mrproper_,Documentation/DocBook scripts)
mrproper-dirs      := $(addprefix _mrproper_, scripts)

PHONY += $(mrproper-dirs) mrproper archmrproper
$(mrproper-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _mrproper_%,%,$@)

mrproper: clean archmrproper $(mrproper-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)

# distclean
#
PHONY += distclean

distclean: mrproper
	@find $(srctree) $(RCS_FIND_IGNORE) \
	 	\( -name '*.orig' -o -name '*.rej' -o -name '*~' \
		-o -name '*.bak' -o -name '#*#' -o -name '.*.orig' \
	 	-o -name '.*.rej' -o -size 0 \
		-o -name '*%' -o -name '.*.cmd' -o -name 'core' \) \
		-type f -print | xargs rm -f


# Packaging of the kernel to various formats
# ---------------------------------------------------------------------------
# rpm target kept for backward compatibility
package-dir	:= $(srctree)/scripts/package

%pkg: FORCE
	$(Q)$(MAKE) $(build)=$(package-dir) $@
rpm: FORCE
	$(Q)$(MAKE) $(build)=$(package-dir) $@


# Brief documentation of the typical targets used
# ---------------------------------------------------------------------------

boards := $(wildcard $(srctree)/arch/$(SRCARCH)/configs/*_defconfig)
boards := $(notdir $(boards))

help:
	@echo  'Cleaning targets:'
	@echo  '  clean		  - remove most generated files but keep the config'
	@echo  '  mrproper	  - remove all generated files + config + various backup files'
	@echo  ''
	@echo  'Configuration targets:'
	@$(MAKE) -f $(srctree)/scripts/kconfig/Makefile help
	@echo  ''
	@echo  'Other generic targets:'
	@echo  '  all		  - Build all targets marked with [*]'
	@echo  '* vmllwk	  - Build the bare kernel'
	@echo  '  dir/            - Build all files in dir and below'
	@echo  '  dir/file.[ois]  - Build specified target only'
	@echo  '  dir/file.ko     - Build module including final link'
	@echo  '  rpm		  - Build a kernel as an RPM package'
	@echo  '  tags/TAGS	  - Generate tags file for editors'
	@echo  '  cscope	  - Generate cscope index'
	@echo  '  kernelrelease	  - Output the release version string'
	@echo  '  kernelversion	  - Output the version stored in Makefile'
	@echo  '  headers_install - Install sanitised kernel headers to INSTALL_HDR_PATH'
	@echo  '                    (default: /lib/modules/$$VERSION/abi)'
	@echo  ''
	@echo  'Static analysers'
	@echo  '  checkstack      - Generate a list of stack hogs'
	@echo  '  namespacecheck  - Name space analysis on compiled kernel'
	@echo  ''
	@echo  'Kernel packaging:'
	@$(MAKE) $(build)=$(package-dir) help
	@echo  ''
	@echo  'Documentation targets:'
	@$(MAKE) -f $(srctree)/Documentation/DocBook/Makefile dochelp
	@echo  ''
	@echo  'Architecture specific targets ($(SRCARCH)):'
	@$(if $(archhelp),$(archhelp),\
		echo '  No architecture specific help defined for $(SRCARCH)')
	@echo  ''
	@$(if $(boards), \
		$(foreach b, $(boards), \
		printf "  %-24s - Build for %s\\n" $(b) $(subst _defconfig,,$(b));) \
		echo '')

	@echo  '  make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build'
	@echo  '  make O=dir [targets] Locate all output files in "dir", including .config'
	@echo  '  make C=1   [targets] Check all c source with $$CHECK (sparse)'
	@echo  '  make C=2   [targets] Force check of all c source with $$CHECK (sparse)'
	@echo  ''
	@echo  'Execute "make" or "make all" to build all targets marked with [*] '
	@echo  'For further info see the ./README file'


# Documentation targets
# ---------------------------------------------------------------------------
%docs: scripts_basic FORCE
	$(Q)$(MAKE) $(build)=Documentation/DocBook $@

else # KBUILD_EXTMOD

###
# External module support.
# When building external modules the kernel used as basis is considered
# read-only, and no consistency checks are made and the make
# system is not used on the basis kernel. If updates are required
# in the basis kernel ordinary make commands (without M=...) must
# be used.
#
# The following are the only valid targets when building external
# modules.
# make M=dir clean     Delete all automatically generated files
# make M=dir modules   Make all modules in specified dir
# make M=dir	       Same as 'make M=dir modules'
# make M=dir modules_install
#                      Install the modules build in the module directory
#                      Assumes install directory is already created

# We are always building modules
KBUILD_MODULES := 1
PHONY += crmodverdir
crmodverdir:
	$(Q)mkdir -p $(MODVERDIR)
	$(Q)rm -f $(MODVERDIR)/*

module-dirs := $(addprefix _module_,$(KBUILD_EXTMOD))
PHONY += $(module-dirs) modules
$(module-dirs): crmodverdir
	$(Q)$(MAKE) $(build)=$(patsubst _module_%,%,$@)

modules: $(module-dirs)
	@echo '  Building modules, stage 2.';
#	$(Q)$(MAKE) -rR -f $(srctree)/scripts/Makefile.modpost

PHONY += modules_install
modules_install: _emodinst_ _emodinst_post

install-dir := $(if $(INSTALL_MOD_DIR),$(INSTALL_MOD_DIR),extra)
PHONY += _emodinst_
_emodinst_:
	$(Q)mkdir -p $(MODLIB)/$(install-dir)
	$(Q)$(MAKE) -rR -f $(srctree)/scripts/Makefile.modinst

# Run depmod only is we have System.map and depmod is executable
quiet_cmd_depmod = DEPMOD  $(KERNELRELEASE)
      cmd_depmod = if [ -r System.map -a -x $(DEPMOD) ]; then \
                      $(DEPMOD) -ae -F System.map             \
                      $(if $(strip $(INSTALL_MOD_PATH)),      \
		      -b $(INSTALL_MOD_PATH) -r)              \
		      $(KERNELRELEASE);                       \
                   fi

PHONY += _emodinst_post
_emodinst_post: _emodinst_
	$(call cmd,depmod)

clean-dirs := $(addprefix _clean_,$(KBUILD_EXTMOD))

PHONY += $(clean-dirs) clean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

clean:	rm-dirs := $(MODVERDIR)
clean: $(clean-dirs)
	$(call cmd,rmdirs)
	@find $(KBUILD_EXTMOD) $(RCS_FIND_IGNORE) \
	 	\( -name '*.[oas]' -o -name '*.ko' -o -name '.*.cmd' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \) \
		-type f -print | xargs rm -f

help:
	@echo  '  Building external modules.'
	@echo  '  Syntax: make -C path/to/kernel/src M=$$PWD target'
	@echo  ''
	@echo  '  modules         - default target, build the module(s)'
	@echo  '  modules_install - install the module'
	@echo  '  clean           - remove generated files in module directory only'
	@echo  ''

# Dummies...
PHONY += prepare scripts
prepare: ;
scripts: ;
endif # KBUILD_EXTMOD

# Generate tags for editors
# ---------------------------------------------------------------------------

#We want __srctree to totally vanish out when KBUILD_OUTPUT is not set
#(which is the most common case IMHO) to avoid unneeded clutter in the big tags file.
#Adding $(srctree) adds about 20M on i386 to the size of the output file!

ifeq ($(src),$(obj))
__srctree =
else
__srctree = $(srctree)/
endif

ifeq ($(ALLSOURCE_ARCHS),)
ifeq ($(ARCH),um)
ALLINCLUDE_ARCHS := $(ARCH) $(SUBARCH)
else
ALLINCLUDE_ARCHS := $(ARCH)
endif
else
#Allow user to specify only ALLSOURCE_PATHS on the command line, keeping existing behaviour.
ALLINCLUDE_ARCHS := $(ALLSOURCE_ARCHS)
endif

ALLSOURCE_ARCHS := $(ARCH)

define all-sources
	( find $(__srctree) $(RCS_FIND_IGNORE) \
	       \( -name include -o -name arch \) -prune -o \
	       -name '*.[chS]' -print; \
	  for ARCH in $(ALLSOURCE_ARCHS) ; do \
	       find $(__srctree)arch/$${ARCH} $(RCS_FIND_IGNORE) \
	            -name '*.[chS]' -print; \
	  done ; \
	  find $(__srctree)include $(RCS_FIND_IGNORE) \
	       \( -name config -o -name 'arch-*' \) -prune \
	       -o -name '*.[chS]' -print; \
	  for ARCH in $(ALLINCLUDE_ARCHS) ; do \
	       find $(__srctree)include/arch-$${ARCH} $(RCS_FIND_IGNORE) \
	            -name '*.[chS]' -print; \
	  done ; \
	  find $(__srctree)include/arch-generic $(RCS_FIND_IGNORE) \
	       -name '*.[chS]' -print; \
	  find $(__srctree)linux/include $(RCS_FIND_IGNORE) \
	       \( -name config -o -name 'arch-*' \) -prune \
	       -o -name '*.[chS]' -print; \
	  find $(__srctree)ofed $(RCS_FIND_IGNORE) \
	       \( -name config -o -name 'arch-*' \) -prune \
	       -o -name '*.[chS]' -print; \
	  for ARCH in $(ALLINCLUDE_ARCHS) ; do \
	       find $(__srctree)linux/arch/$${ARCH} $(RCS_FIND_IGNORE) \
	            -name '*.[chS]' -print; \
	  done ; )
endef

quiet_cmd_cscope-file = FILELST cscope.files
      cmd_cscope-file = (echo \-k; echo \-q; $(all-sources)) > cscope.files

quiet_cmd_cscope = MAKE    cscope.out
      cmd_cscope = cscope -b

cscope: FORCE
	$(call cmd,cscope-file)
	$(call cmd,cscope)

quiet_cmd_TAGS = MAKE   $@
define cmd_TAGS
	rm -f $@; \
	ETAGSF=`etags --version | grep -i exuberant >/dev/null &&     \
                echo "-I __initdata,__exitdata,__acquires,__releases  \
                      -I EXPORT_SYMBOL,EXPORT_SYMBOL_GPL              \
                      --extra=+f --c-kinds=+px"`;                     \
                $(all-sources) | xargs etags $$ETAGSF -a
endef

TAGS: FORCE
	$(call cmd,TAGS)


quiet_cmd_tags = MAKE   $@
define cmd_tags
	rm -f $@; \
	CTAGSF=`ctags --version | grep -i exuberant >/dev/null &&     \
                echo "-I __initdata,__exitdata,__acquires,__releases  \
                      -I EXPORT_SYMBOL,EXPORT_SYMBOL_GPL              \
                      --extra=+f --c-kinds=+px"`;                     \
                $(all-sources) | xargs ctags $$CTAGSF -a
endef

tags: FORCE
	$(call cmd,tags)


# Scripts to check various things for consistency
# ---------------------------------------------------------------------------

includecheck:
	find * $(RCS_FIND_IGNORE) \
		-name '*.[hcS]' -type f -print | sort \
		| xargs $(PERL) -w scripts/checkincludes.pl

versioncheck:
	find * $(RCS_FIND_IGNORE) \
		-name '*.[hcS]' -type f -print | sort \
		| xargs $(PERL) -w scripts/checkversion.pl

namespacecheck:
	$(PERL) $(srctree)/scripts/namespace.pl

endif #ifeq ($(config-targets),1)
endif #ifeq ($(mixed-targets),1)

PHONY += checkstack
checkstack:
	$(OBJDUMP) -d vmlwk $$(find . -name '*.ko') | \
	$(PERL) $(src)/scripts/checkstack.pl $(SRCARCH)

kernelrelease:
	$(if $(wildcard .kernelrelease), $(Q)echo $(KERNELRELEASE), \
	$(error kernelrelease not valid - run 'make *config' to update it))
kernelversion:
	@echo $(KERNELVERSION)

# Single targets
# ---------------------------------------------------------------------------
# Single targets are compatible with:
# - build whith mixed source and output
# - build with separate output dir 'make O=...'
# - external modules
#
#  target-dir => where to store outputfile
#  build-dir  => directory in kernel source tree to use

ifeq ($(KBUILD_EXTMOD),)
        build-dir  = $(patsubst %/,%,$(dir $@))
        target-dir = $(dir $@)
else
        zap-slash=$(filter-out .,$(patsubst %/,%,$(dir $@)))
        build-dir  = $(KBUILD_EXTMOD)$(if $(zap-slash),/$(zap-slash))
        target-dir = $(if $(KBUILD_EXTMOD),$(dir $<),$(dir $@))
endif

%.s: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.i: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.o: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.lst: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.s: %.S prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.o: %.S prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)

# Modules
/: prepare scripts FORCE
	$(Q)$(MAKE) KBUILD_MODULES=$(if $(CONFIG_MODULES),1) \
	$(build)=$(build-dir)
%/: prepare scripts FORCE
	$(Q)$(MAKE) KBUILD_MODULES=$(if $(CONFIG_MODULES),1) \
	$(build)=$(build-dir)
%.ko: prepare scripts FORCE
	$(Q)$(MAKE) KBUILD_MODULES=$(if $(CONFIG_MODULES),1)   \
	$(build)=$(build-dir) $(@:.ko=.o)
	$(Q)$(MAKE) -rR -f $(srctree)/scripts/Makefile.modpost

# FIXME Should go into a make.lib or something 
# ===========================================================================

quiet_cmd_rmdirs = $(if $(wildcard $(rm-dirs)),CLEAN   $(wildcard $(rm-dirs)))
      cmd_rmdirs = rm -rf $(rm-dirs)

quiet_cmd_rmfiles = $(if $(wildcard $(rm-files)),CLEAN   $(wildcard $(rm-files)))
      cmd_rmfiles = rm -f $(rm-files)


a_flags = -Wp,-MD,$(depfile) $(AFLAGS) $(AFLAGS_KERNEL) \
	  $(NOSTDINC_FLAGS) $(CPPFLAGS) \
	  $(modkern_aflags) $(EXTRA_AFLAGS) $(AFLAGS_$(*F).o)

quiet_cmd_as_o_S = AS      $@
cmd_as_o_S       = $(CC) $(a_flags) -c -o $@ $<

# read all saved command lines

targets := $(wildcard $(sort $(targets)))
cmd_files := $(wildcard .*.cmd $(foreach f,$(targets),$(dir $(f)).$(notdir $(f)).cmd))

ifneq ($(cmd_files),)
  $(cmd_files): ;	# Do not try to update included dependency files
  include $(cmd_files)
endif

# Shorthand for $(Q)$(MAKE) -f scripts/Makefile.clean obj=dir
# Usage:
# $(Q)$(MAKE) $(clean)=dir
clean := -f $(if $(KBUILD_SRC),$(srctree)/)scripts/Makefile.clean obj

endif	# skip-makefile

# Force the O variable for user and init_task (not set by kbuild?)
user init_task: O:=$(if $O,$O,$(objtree))
# Build LWK user-space libraries and example programs
user: FORCE
	@if [ ! -d $O/$@ ]; then mkdir $O/$@; fi
	$(Q)$(MAKE) \
		-j 1 \
		-s \
		-C $(src)/$@ \
		O=$O/$@ \
		src=$(src)/$@ \
		all

# A simple user-space app for the LWK to launch at boot
init_task: user FORCE
	@cp $O/user/hello_world/hello_world $O/init_task

PHONY += FORCE
FORCE:


# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable se we can use it in if_changed and friends.
.PHONY: $(PHONY)
