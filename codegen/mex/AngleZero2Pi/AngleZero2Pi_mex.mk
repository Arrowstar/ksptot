START_DIR = C:\Users\Adam\Dropbox\DOCUME~1\homework\PERSON~1\KSPTRA~1

MATLAB_ROOT = C:\PROGRA~2\MATLAB\R2013a
MAKEFILE = AngleZero2Pi_mex.mk

include AngleZero2Pi_mex.mki


SRC_FILES =  \
	AngleZero2Pi_data.c \
	AngleZero2Pi_initialize.c \
	AngleZero2Pi_terminate.c \
	AngleZero2Pi.c \
	AngleZero2Pi_api.c \
	AngleZero2Pi_mex.c

MEX_FILE_NAME_WO_EXT = AngleZero2Pi_mex
MEX_FILE_NAME = $(MEX_FILE_NAME_WO_EXT).mexw32
TARGET = $(MEX_FILE_NAME)

SYS_LIBS = 


#
#====================================================================
# gmake makefile fragment for building MEX functions using LCC
# Copyright 2007-2012 The MathWorks, Inc.
#====================================================================
#
SHELL = cmd
OBJEXT = obj
CC = $(COMPILER)
LD = $(LINKER)
.SUFFIXES: .$(OBJEXT)

OBJLIST += $(SRC_FILES:.c=.$(OBJEXT))
MEXSTUB = $(MEX_FILE_NAME_WO_EXT)2.$(OBJEXT)
LCCSTUB = $(MEX_FILE_NAME_WO_EXT)_lccstub.$(OBJEXT)

target: $(TARGET)

ML_INCLUDES = -I"$(MATLAB_ROOT)\simulink\include"
ML_INCLUDES+= -I"$(MATLAB_ROOT)\toolbox\shared\simtargets"
SYS_INCLUDE = $(ML_INCLUDES)

# Additional includes

SYS_INCLUDE += -I"$(START_DIR)"
SYS_INCLUDE += -I"$(START_DIR)\codegen\mex\AngleZero2Pi"
SYS_INCLUDE += -I"$(MATLAB_ROOT)\extern\include"

EML_LIBS = libemlrt.lib libut.lib libmwblas.lib libmwmathutil.lib
SYS_LIBS += $(EML_LIBS)

DIRECTIVES = $(MEX_FILE_NAME_WO_EXT)_mex.def

COMP_FLAGS = $(COMPFLAGS) -DMX_COMPAT_32
LINK_FLAGS0= $(subst $(MEXSTUB),$(LCCSTUB),$(LINKFLAGS))
LINK_FLAGS = $(filter-out "%mexFunction.def", $(LINK_FLAGS0))

ifeq ($(EMC_CONFIG),optim)
  COMP_FLAGS += $(OPTIMFLAGS)
  LINK_FLAGS += $(LINKOPTIMFLAGS)
else
  COMP_FLAGS += $(DEBUGFLAGS)
  LINK_FLAGS += $(LINKDEBUGFLAGS)
endif
LINK_FLAGS += -o $(TARGET)
LINK_FLAGS += 

CFLAGS =  $(COMP_FLAGS) $(USER_INCLUDE) $(SYS_INCLUDE)

%.$(OBJEXT) : %.c
	$(CC) $(CFLAGS) "$<"

# Additional sources

%.$(OBJEXT) : $(START_DIR)/%.c
	$(CC) -Fo"$@" $(CFLAGS) "$<"

%.$(OBJEXT) : $(START_DIR)\codegen\mex\AngleZero2Pi/%.c
	$(CC) -Fo"$@" $(CFLAGS) "$<"



$(LCCSTUB) : $(MATLAB_ROOT)\sys\lcc\mex\lccstub.c
	$(CC) -Fo$(LCCSTUB) $(CFLAGS) "$<"

$(TARGET): $(OBJLIST) $(LCCSTUB) $(MAKEFILE) $(DIRECTIVES)
	$(LD) $(LINK_FLAGS) $(OBJLIST) $(LINKFLAGSPOST) $(SYS_LIBS) $(DIRECTIVES)
	@cmd /C "echo Build completed using compiler $(EMC_COMPILER)"

#====================================================================

