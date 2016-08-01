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
        PROGRESS_FILE := $(OUT_DIR)/ultimake-rebuild-count
        load_progress = $(shell cat $(PROGRESS_FILE) 2> /dev/null || echo "1")
        inc_progress  = $(eval COUNTER := x $(COUNTER))

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50%
        percentage = $(shell echo $(1)00/$(2) | bc)%
#         percentage = $(1)/$(2)

        define ULTIMAKE.PREDEPENDENCY =
            $(inc_progress)
            @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)Scanning dependencies...$(COLOR_NONE) [$(PROGRESS)/$(NUM_OF_SOURCES)]\n';
            @echo -n $(PROGRESS) > $(PROGRESS_FILE);
        endef
        ULTIMAKE.POSTDEPENDENCY =

        define ULTIMAKE.PRECOMPILE =
             @printf '[%4s] $(COLOR_BUILD)$1$(COLOR_NONE)\n' '$(call percentage,$(PROGRESS),$(load_progress))'
        endef
        ULTIMAKE.POSTCOMPILE = $(inc_progress)

        ULTIMAKE.PRELINK  = @printf '$(COLOR_LINK)$1$(COLOR_NONE)\n'
        ULTIMAKE.POSTLINK = && printf '[%4s] Built target $@\n' '$(call percentage,$(PROGRESS),$(load_progress))'

    endif
