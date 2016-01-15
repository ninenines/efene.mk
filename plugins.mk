# Copyright (c) 2016, Loïc Hoguin <essen@ninenines.eu>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Verbosity.

efene_verbose_0 = @echo " FN    " $(filter %.fn,$(?F));
efene_verbose = $(efene_verbose_$(V))

# Core targets.

FN_FILES = $(sort $(call core_find,src/,*.fn))

ifneq ($(FN_FILES),)

BEAM_FILES += $(addprefix ebin/,$(patsubst %.fn,%.beam,$(notdir $(FN_FILES))))

# Rebuild Efene modules when the Makefile changes.
$(FN_FILES): $(MAKEFILE_LIST)
	@touch $@

define efene_compile.erl
	[begin
		case efene:compile(F, "ebin/", $2) of
			E = {error, _} ->
				efene:print_errors([E], "errors");
			{error, Errors, Warnings} ->
				efene:print_errors(Errors, "errors"),
				efene:print_errors(Warnings, "warnings");
			{ok, CompileInfo} ->
				efene:print_errors(proplists:get_value(warnings, CompileInfo, []), "warnings")
		end
	end || F <- string:tokens("$1", " ")],
	halt().
endef

ebin/$(PROJECT).app:: $(FN_FILES) | ebin/
	$(if $(strip $?),$(efene_verbose) $(call erlang,\
		$(call efene_compile.erl,$?,$(call compat_erlc_opts_to_list,$(ERLC_OPTS))),\
		-pa $(DEPS_DIR)/efene/ebin))

efene-shell: deps
    $(verbose) erl -run efene main shell -noshell -noinput -pa ebin/

endif
