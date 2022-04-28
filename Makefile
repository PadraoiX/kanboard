default: docker_build_debian

DOCKER_IMAGE ?= padraoix/kanboard
GIT_BRANCH ?= `git rev-parse --abbrev-ref HEAD`

ifeq ($(GIT_BRANCH), master)
	DOCKER_TAG = latest
	DOCKER_TAG = $(GIT_BRANCH)
else
	DOCKER_TAG = $(GIT_BRANCH)
endif

.PHONY: archive test-sqlite test-mysql test-postgres sql \
	build-image build-images docker-push docker-run docker-sh

archive:
	@ echo "Build archive: version=$(DOCKER_TAG)"
	@ git archive --format=zip --prefix=kanboard/ $(DOCKER_TAG) -o kanboard-$(DOCKER_TAG).zip

test-sqlite:
	@ ./vendor/bin/phpunit -c tests/units.sqlite.xml

test-mysql:
	@ ./vendor/bin/phpunit -c tests/units.mysql.xml

test-postgres:
	@ ./vendor/bin/phpunit -c tests/units.postgres.xml

sql:
	@ pg_dump --schema-only --no-owner --no-privileges --quote-all-identifiers -n public --file app/Schema/Sql/postgres.sql kanboard
	@ pg_dump -d kanboard --column-inserts --data-only --table settings >> app/Schema/Sql/postgres.sql
	@ pg_dump -d kanboard --column-inserts --data-only --table links >> app/Schema/Sql/postgres.sql

	@ mysqldump -uroot --quote-names --no-create-db --skip-comments --no-data --single-transaction kanboard | sed 's/ AUTO_INCREMENT=[0-9]*//g' > app/Schema/Sql/mysql.sql
	@ mysqldump -uroot --quote-names --no-create-info --skip-comments --no-set-names kanboard settings >> app/Schema/Sql/mysql.sql
	@ mysqldump -uroot --quote-names --no-create-info --skip-comments --no-set-names kanboard links >> app/Schema/Sql/mysql.sql

	@ let password_hash=`php -r "echo password_hash('admin', PASSWORD_DEFAULT);"` ;\
	echo "INSERT INTO users (username, password, role) VALUES ('admin', '$$password_hash', 'app-admin');" >> app/Schema/Sql/mysql.sql ;\
	echo "INSERT INTO public.users (username, password, role) VALUES ('admin', '$$password_hash', 'app-admin');" >> app/Schema/Sql/postgres.sql

	@ let mysql_version=`echo 'select version from schema_version;' | mysql -N -uroot kanboard` ;\
	echo "INSERT INTO schema_version VALUES ('$$mysql_version');" >> app/Schema/Sql/mysql.sql

	@ let pg_version=`psql -U postgres -A -c 'copy(select version from schema_version) to stdout;' kanboard` ;\
	echo "INSERT INTO public.schema_version VALUES ('$$pg_version');" >> app/Schema/Sql/postgres.sql

	@ grep -v "SET idle_in_transaction_session_timeout = 0;" app/Schema/Sql/postgres.sql > temp && mv temp app/Schema/Sql/postgres.sql

build-image:
	docker build --build-arg VERSION=$(DOCKER_TAG) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

build-images:
	docker build \
		--platform linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6 \
		--file Dockerfile \
		--build-arg VERSION=master.$(DOCKER_TAG) \
		--tag $(DOCKER_IMAGE):$(DOCKER_TAG) \
		.

docker-push:
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

docker-run:
	@ docker run --rm --name=kanboard -p 80:80 -p 443:443 $(DOCKER_IMAGE):$(DOCKER_TAG)

docker-sh:
	@ docker exec -ti kanboard bash
