# SPDX-License-Identifier: LGPL-2.1

# Utils

 PWD		:= $(shell /bin/pwd)
 GOBJ		= $(notdir $(strip $@))
 BASE1		= $(notdir $(strip $1))
 BASE2		= $(notdir $(strip $2))
 BASEPWD	= $(notdir $(strip $(PWD)))


ifeq ($(VERBOSE),1)
  Q =
  S =
else
  Q = @
  S = -s
endif

# Use empty print_* macros if either SILENT or VERBOSE.
ifeq ($(findstring 1,$(SILENT)$(VERBOSE)),1)
  print_compile =
  print_app_build =
  print_fpic_compile =
  print_shared_lib_compile =
  print_plugin_obj_compile =
  print_plugin_build =
  print_install =
  print_uninstall =
  print_update =
  print_descend =
  print_clean =
else
  print_compile =		echo '  COMPILE            '$(GOBJ);
  print_app_build =		echo '  BUILD              '$(GOBJ);
  print_fpic_compile =		echo '  COMPILE FPIC       '$(GOBJ);
  print_shared_lib_compile =	echo '  COMPILE SHARED LIB '$(GOBJ);
  print_plugin_obj_compile =	echo '  COMPILE PLUGIN OBJ '$(GOBJ);
  print_plugin_build =		echo '  BUILD PLUGIN       '$(GOBJ);
  print_static_lib_build =	echo '  BUILD STATIC LIB   '$(GOBJ);
  print_install =		echo '  INSTALL     '$1'	to	$(DESTDIR_SQ)$2';
  print_uninstall =		echo '  UNINSTALL     $(DESTDIR_SQ)$1';
  print_update =		echo '  UPDATE             '$(GOBJ);
  print_descend =		echo '  DESCEND            '$(BASE1) $(BASE2);
  print_clean =			echo '  CLEAN              '$(BASEPWD);
endif

do_fpic_compile =					\
	($(print_fpic_compile)				\
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $(EXT) -fPIC $< -o $@)

do_compile =							\
	($(if $(GENERATE_PIC), $(do_fpic_compile),		\
	 $(print_compile)					\
	 $(CC) -c $(CPPFLAGS) $(CFLAGS) $(EXT) $< -o $@))

do_app_build =						\
	($(print_app_build)				\
	$(CC) $^ -rdynamic -o $@ $(LDFLAGS) $(CONFIG_LIBS) $(LIBS))

do_build_static_lib =				\
	($(print_static_lib_build)		\
	if [ -f $@ ]; then			\
	    mv $@ $@.rm; $(RM) $@.rm;		\
	fi;					\
	$(AR) rcs $@ $^)

do_compile_shared_library =			\
	($(print_shared_lib_compile)		\
	$(CC) --shared $^ '-Wl,-soname,$(1),-rpath=$$ORIGIN' -o $@ $(LDFLAGS) $(LIBS))

do_compile_plugin_obj =				\
	($(print_plugin_obj_compile)		\
	$(CC) -c $(CPPFLAGS) $(CFLAGS) -fPIC -o $@ $<)

do_plugin_build =				\
	($(print_plugin_build)			\
	$(CC) $(CFLAGS) $(LDFLAGS) -shared -nostartfiles -o $@ $<)

do_compile_python_plugin_obj =			\
	($(print_plugin_obj_compile)		\
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $(PYTHON_DIR_SQ) $(PYTHON_INCLUDES) -fPIC -o $@ $<)

do_python_plugin_build =			\
	($(print_plugin_build)			\
	$(CC) $< -shared $(LDFLAGS) $(PYTHON_LDFLAGS) -o $@)

do_clean =					\
	($(print_clean)				\
	$(RM) $1)

ifneq ($(findstring $(MAKEFLAGS), w),w)
PRINT_DIR = --no-print-directory
else
NO_SUBDIR = :
endif

#
# Define a callable command for descending to a new directory
#
# Call by doing: $(call descend,directory[,target])
#
descend = \
	($(print_descend)		\
	$(MAKE) $(PRINT_DIR) -C $(1) $(2))


define make_version.h
	(echo '/* This file is automatically generated. Do not modify. */';		\
	echo \#define VERSION_CODE $(shell						\
	expr $(VERSION) \* 256 + $(PATCHLEVEL));					\
	echo '#define EXTRAVERSION ' $(EXTRAVERSION);					\
	echo '#define VERSION_STRING "'$(VERSION).$(PATCHLEVEL).$(EXTRAVERSION)'"';	\
	echo '#define FILE_VERSION '$(FILE_VERSION);					\
	if [ -d $(src)/.git ]; then							\
	  d=`git diff`;									\
	  x="";										\
	  if [ ! -z "$$d" ]; then x="+"; fi;						\
	  echo '#define VERSION_GIT "'$(shell 						\
		git log -1 --pretty=format:"%H" 2>/dev/null)$$x'"';			\
	else										\
	  echo '#define VERSION_GIT "not-a-git-repo"';					\
	fi										\
	) > $1
endef

define update_version.h
	($(call make_version.h, $@.tmp);				\
	if [ -r $@ ] && cmp -s $@ $@.tmp; then				\
		rm -f $@.tmp;						\
	else								\
		$(print_update)						\
		mv -f $@.tmp $@;					\
	fi);
endef

define update_dir
	(echo $1 > $@.tmp;	\
	if [ -r $@ ] && cmp -s $@ $@.tmp; then				\
		rm -f $@.tmp;						\
	else								\
		$(print_update)						\
		mv -f $@.tmp $@;					\
	fi);
endef

define build_prefix
	(echo $1 > $@.tmp;	\
	if [ -r $@ ] && cmp -s $@ $@.tmp; then				\
		rm -f $@.tmp;						\
	else								\
		$(print_update)						\
		mv -f $@.tmp $@;					\
	fi);
endef

define do_install_mkdir
	if [ ! -d '$(DESTDIR_SQ)$1' ]; then		\
		$(INSTALL) -d -m 755 '$(DESTDIR_SQ)$1';	\
	fi
endef

define do_install
	$(print_install)				\
	$(call do_install_mkdir,$2);			\
	$(INSTALL) $(if $3,-m $3,) $1 '$(DESTDIR_SQ)$2'
endef

define do_install_pkgconfig_file
	if [ -n "${pkgconfig_dir}" ]; then 					\
		$(call do_install,$(PKG_CONFIG_FILE),$(pkgconfig_dir),644); 	\
	else 									\
		(echo Failed to locate pkg-config directory) 1>&2;		\
	fi
endef
