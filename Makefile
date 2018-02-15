RUBY_IMAGE:=$(shell grep FROM Dockerfile | cut -f 2 -d ' ')
TEST_FILES:=$(shell find test -type f -iname '*_test.rb')
ENVIRONMENT:=tmp/environment

.DEFAULT_GOAL:=test

.PHONY: check
check:
	docker --version > /dev/null
	docker-compose --version > /dev/null

Gemfile.lock: Gemfile
	docker run --rm -v $(CURDIR):/data -w /data -u $$(id -u) $(RUBY_IMAGE) \
		bundle package --all

$(ENVIRONMENT): Gemfile.lock docker-compose.yml
	docker-compose build
	docker-compose up -d app
	mkdir -p $(@D)
	touch $@

.PHONY: test
test: $(ENVIRONMENT)
	@docker-compose run --rm tests \
		ruby $(addprefix -r./,$(TEST_FILES)) -e exit

.PHONY: test-image
test-image: $(ENVIRONMENT)
	@docker-compose run --rm app \
		ruby $(addprefix -r./,$(TEST_FILES)) -e exit
	# @docker-compose run --rm app \
	# 	bundle exec rubocop

.PHONY: test-smoke
test-smoke: $(ENVIRONMENT)
	@docker-compose run --rm smoke

.PHONY: playground
playground: $(ENVIRONMENT)
	@docker-compose run --rm tests test/play.rb

.PHONY: test-ci
test-ci: test-smoke test-image

.PHONY: clean
clean:
	docker-compose down
	rm -rf $(ENVIRONMENT)
