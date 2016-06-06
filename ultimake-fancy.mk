
    ifdef TERM
    #-----------------------------------------------------------------------
    # Colorization for Make and GCC output
    ifndef NOCOLOR
        COLOR_BUILD := $(shell tput setaf 2)
        COLOR_LINK  := $(shell tput setaf 1)$(shell tput bold)
        COLOR_DEP   := $(shell tput setaf 5)$(shell tput bold)
        COLOR_GEN   := $(shell tput setaf 4)$(shell tput bold)
        COLOR_WARN  := $(shell tput setaf 1)
        COLOR_NOTE  := $(shell tput setaf 3)
        COLOR_ERR   := $(shell tput setaf 7)$(shell tput setab 1)$(shell tput bold)
        COLOR_NONE  := $(shell tput sgr0)

        # colorize gcc output and set exit code 1 if "error:" is found
        define GCC_COLOR :=
            2>&1 1>/dev/null | awk '  \
              {                       \
                if(sub("^.*error:.*", "$(COLOR_ERR)&$(COLOR_NONE)")) {err=1} \
                sub("^.*warning:.*", "$(COLOR_WARN)&$(COLOR_NONE)");         \
                sub("^.*note:.*",    "$(COLOR_NOTE)&$(COLOR_NONE)");         \
                print                 \
              }                       \
              END{exit err}'  >&2
        endef
    endif


    #-----------------------------------------------------------------------
    # Show progress percentage
    ifndef NOPROGRESS
        TERM_CURSOR_UP := $(shell tput cuu1)
        NUM_OBJ := $(words $(foreach target,$(TARGETS), $($(target)_SOURCE_FILES)))
        $(info $(NUM_OBJ))
        PROGRESS := 0
        PROGRESS_FILE := $(OUT_DIR)/ultimake-rebuild-count
        PROGRESS_MAX = $(shell cat $(PROGRESS_FILE))
        inc_progress  = $(eval PROGRESS := $(shell echo $(PROGRESS)+1 | bc))
        save_progress = @echo -n $(PROGRESS) > $(PROGRESS_FILE);
        print_dep = @printf '$(TERM_CURSOR_UP)$(COLOR_DEP)Scanning dependencies... [$(PROGRESS)/$(NUM_OBJ)]\n';
    #     print_dep = @printf '\r$(COLOR_DEP)Scanning dependencies of target $(TARGET)$(COLOR_NONE) [$(PROGRESS)/$(words $(OBJ))]';

    # calculate the percentage of $1 relative to $2, $(call percentage,1,2) -> 50 (%)
        percentage = $(shell echo $(1)00/$(2) | bc)
    #     percentage = $(shell echo $(1)00/$(2) | bc) | $(shell echo $(1)/$(2))
        print_obj   = @printf '[%3s%%] $(COLOR_BUILD)$1$(COLOR_NONE)\n' '$(call percentage,$(PROGRESS),$(PROGRESS_MAX))'
        print_build = printf '[%3s%%] $1\n'                            '$(call percentage,$(PROGRESS),$(PROGRESS_MAX))'
    # else
    endif

endif
