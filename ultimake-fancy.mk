
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

    #-----------------------------------------------------------------------
    # Show progress percentage
    ifndef NOPROGRESS
        TERM_CURSOR_UP := $(shell tput cuu1)
        NUM_OBJ := $(words $(foreach target,$(TARGETS), $($(target)_SOURCE_FILES)))
        PROGRESS := 0
        PROGRESS_FILE := $(OUT_DIR)/ultimake-rebuild-count
        inc_progress  = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc))
        save_progress = @echo -n $(PROGRESS) > $(PROGRESS_FILE);

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50 (%)
        percentage = $(shell echo $(1)00/$(2) | bc)
#         percentage = $(1)/$(2)

        define print_dep =
            $(inc_progress)
            @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)Scanning dependencies...$(COLOR_NONE) [$(PROGRESS)/$(NUM_OBJ)]\n';
            $(save_progress)
        endef

        define print_obj =
            $(inc_progress)
            @printf '[%3s%%] $(COLOR_BUILD)$1$(COLOR_NONE)\n' '$(call percentage,$(PROGRESS),$(NUM_OBJ))'
        endef
        print_build = printf '[%3s%%] Built target $@\n'                            '$(call percentage,$(PROGRESS),$(NUM_OBJ))'
    endif

endif
