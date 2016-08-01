ifdef TERM
    #-----------------------------------------------------------------------
    # Colorization for Make and GCC output
    ifndef NOCOLOR
        COLOR_BUILD := $(shell tput setaf 2)
        COLOR_LINK  := $(shell tput setaf 1)$(shell tput bold)
        COLOR_DEP   := $(shell tput setaf 5)$(shell tput bold)
        COLOR_GEN   := $(shell tput setaf 4)$(shell tput bold)
        COLOR_NONE  := $(shell tput sgr0)
    endif
    TERM_CURSOR_UP := $(shell tput cuu1)
endif

    #-----------------------------------------------------------------------
    # Show progress percentage
    # This progress feature works by counting the number of dependency files generated.
    # This number is saved to a tempfile. When make is being reinvoked, the number of
    # object files gets counted and divided by the saved number of dependency files.

    ifndef NOPROGRESS
        NUM_OF_SOURCES := $(words $(foreach target,$(TARGETS), $($(target).SOURCE_FILES)))
        COUNTER :=
        PROGRESS = $(words $(COUNTER))
#         PROGRESS := 0
        PROGRESS_FILE := $(OUT_DIR)/ultimake-rebuild-count
        load_progress = $(shell cat $(PROGRESS_FILE) 2> /dev/null || echo "1")
#         inc_progress  = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc))
        inc_progress  = $(eval COUNTER := x $(COUNTER))

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50%
        percentage = $(shell echo $(1)00/$(2) | bc)%
#         percentage = $(1)/$(2)

        define ULTIMAKE.PREDEPENDENCY =
            $(inc_progress)
            @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)Scanning dependencies...$(COLOR_NONE) [$(PROGRESS)/$(NUM_OF_SOURCES)]\n';
            @echo -n $(PROGRESS) > $(PROGRESS_FILE);
        endef
#         define ULTIMAKE.PREDEPENDENCY =
#             $(inc_progress)
#             @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)[%3s|%3s|%3s] Scanning dependencies...$(COLOR_NONE)\n' '0' '$(PROGRESS)' '$(NUM_OF_SOURCES)'
#             @echo -n $(PROGRESS) > $(PROGRESS_FILE);
#         endef
        ULTIMAKE.POSTDEPENDENCY =

        define ULTIMAKE.PRECOMPILE =
             @printf '[%4s] $(COLOR_BUILD)$1$(COLOR_NONE)\n' '$(call percentage,$(PROGRESS),$(load_progress))'
        endef
#         define ULTIMAKE.PRECOMPILE =
#              @printf '$(COLOR_BUILD)[%3s|%3s|%3s] $1$(COLOR_NONE)\n' '$(PROGRESS)' '$(load_progress)' '$(NUM_OF_SOURCES)'
#         endef
#         ULTIMAKE.POSTCOMPILE = || $(RM) $(@:%.o=%.dep)$(inc_progress) # doesn't work as intended
        ULTIMAKE.POSTCOMPILE = $(inc_progress)

        ULTIMAKE.PRELINK  = @printf '$(COLOR_LINK)$1$(COLOR_NONE)\n'
        ULTIMAKE.POSTLINK = && printf '[%4s] Built target $@\n' '$(call percentage,$(PROGRESS),$(load_progress))'

    endif
