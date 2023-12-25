DOMAIN			= open-console.eu
TEST_WEBSITE	= $(OWNER_WEBSITE)/

.check-env-vars::
	@test $${SKRODON_PUBLISH?Please set environment variable SKRODON_PUBLISH}

webpages:: .check-env-vars
	bin/produce_webpages

publish:: webpages
	@ if [ -z "$(MARKOV_DEVEL)" ]; \
	  then echo "Upload currently only by MarkOv" >&2; exit 1; \
	  fi
	psync open-console-owner
