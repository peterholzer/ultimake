
all : graph
graph  : $(foreach target,$(TARGETS), $(OUT_DIR)/$(target).png)
# graph  : $(foreach target,$(TARGETS), $(OUT_DIR)/$(target).svg)

define dependency_graph

$(OUT_DIR)/$1.dot : $($1.SOURCES)
	$(make_dir)
	@printf "Creating dependency graph for '$1'\n"
	$(AT)(cd $$<; \
          find . -iname "*.hpp" -o -name "*.h" -o -iname "*.cpp" -o -iname "*.c"  \
          | xargs $(ULTIMAKE.PATH)/src2dot.pl )  >  $$@

endef

%.png : %.dot
	@printf "Rendering '$^' to '$@'\n"
	$(AT)dot $^ -Tpng -o $@

%.svg : %.dot
	@printf "Rendering '$^' to '$@'\n"
	$(AT)dot $^ -Tsvg -o $@

.PHONY : clean-graph
clean  : clean-graph
clean-graph :
	$(AT)-$(RM) $(foreach target,$(TARGETS), $(OUT_DIR)/$(target).dot \
                                             $(OUT_DIR)/$(target).png \
                                             $(OUT_DIR)/$(target).svg)


$(eval $(foreach t,$(TARGETS),$(call dependency_graph,$t)))

# debug output
$(shell mkdir -p $(OUT_DIR))
$(file > $(OUT_DIR)/ultimaky-fancy-debug.mk,$(foreach target,$(TARGETS),$(call dependency_graph,$(target))))


