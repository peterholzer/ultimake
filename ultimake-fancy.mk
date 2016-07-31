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
    ifndef NOPROGRESS
        NUM_OF_SOURCES := $(words $(foreach target,$(TARGETS), $($(target).SOURCE_FILES)))
        PROGRESS := 0
        PROGRESS_FILE := $(OUT_DIR)/ultimake-rebuild-count
        load_progress = $(shell cat $(PROGRESS_FILE) 2> /dev/null || echo "1")
        inc_progress  = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc))

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50%
#         percentage = $(shell echo $(1)00/$(2) | bc)%
        percentage = $(1)/$(2)

        define ULTIMAKE.PREDEPENDENCY =
            $(inc_progress)
            @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)Scanning dependencies...$(COLOR_NONE) [$(PROGRESS)/$(NUM_OF_SOURCES)]\n';
            @echo -n $(PROGRESS) > $(PROGRESS_FILE);
        endef
        ULTIMAKE.POSTDEPENDENCY =

        define ULTIMAKE.PRECOMPILE =
             @printf '[%3s] $(COLOR_BUILD)$1$(COLOR_NONE)\n' '$(call percentage,$(PROGRESS),$(load_progress))'
        endef
#         ULTIMAKE.POSTCOMPILE = || $(RM) $(@:%.o=%.dep)$(inc_progress) # doesn't work as intended
        ULTIMAKE.POSTCOMPILE = $(inc_progress)

        ULTIMAKE.PRELINK  = @printf '$(COLOR_LINK)$1$(COLOR_NONE)\n'
        ULTIMAKE.POSTLINK = && printf '[%3s] Built target $@\n' '$(call percentage,$(PROGRESS),$(load_progress))'

    endif
