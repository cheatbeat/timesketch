#!/bin/bash
#
# Script to set up Travis-CI test VM.
#
# This file is generated by l2tdevtools update-dependencies.py any dependency
# related changes should be made in dependencies.ini.

DPKG_PYTHON3_DEPENDENCIES="python3-alembic python3-altair python3-amqp python3-aniso8601 python3-asn1crypto python3-attr python3-bcrypt python3-billiard python3-blinker python3-bs4 python3-celery python3-certifi python3-cffi python3-chardet python3-ciso8601 python3-click python3-cryptography python3-datasketch python3-dateutil python3-editor python3-elasticsearch python3-entrypoints python3-flask python3-flask-bcrypt python3-flask-login python3-flask-migrate python3-flask-restful python3-flask-script python3-flask-sqlalchemy python3-flaskext.wtf python3-google-auth python3-google-auth-oauthlib python3-gunicorn python3-idna python3-itsdangerous python3-jinja2 python3-jsonschema python3-jwt python3-kombu python3-mako python3-mans-to-es python3-markdown python3-markupsafe python3-neo4jrestclient python3-numpy python3-oauthlib python3-pandas python3-parameterized python3-pycparser python3-pyrsistent python3-redis python3-requests python3-requests-oauthlib python3-sigmatools python3-six python3-sqlalchemy python3-tabulate python3-toolz python3-tz python3-urllib3 python3-vine python3-werkzeug python3-wtforms python3-xlrd python3-xmltodict python3-yaml python3-zipp python3-networkx";

DPKG_PYTHON3_TEST_DEPENDENCIES="python3-coverage python3-distutils python3-flask-testing python3-mock python3-nose python3-pbr python3-setuptools";

# Exit on error.
set -e;

if test -n "${UBUNTU_VERSION}";
then
	CONTAINER_NAME="ubuntu${UBUNTU_VERSION}";

	docker pull ubuntu:${UBUNTU_VERSION};

	docker run --name=${CONTAINER_NAME} --detach -i ubuntu:${UBUNTU_VERSION};

	# Install add-apt-repository and locale-gen.
	docker exec ${CONTAINER_NAME} apt-get update -q;
	docker exec -e "DEBIAN_FRONTEND=noninteractive" ${CONTAINER_NAME} sh -c "apt-get install -y locales software-properties-common";

	# Add additional apt repositories.
	if test -n "${TOXENV}";
	then
		docker exec ${CONTAINER_NAME} add-apt-repository universe;
		docker exec ${CONTAINER_NAME} add-apt-repository ppa:deadsnakes/ppa -y;

	elif "${UBUNTU_VERSION}" = "18.04";
	then
		# Note that run_tests.py currently requires pylint.
		docker exec ${CONTAINER_NAME} add-apt-repository ppa:gift/pylint3 -y;
	fi
	docker exec ${CONTAINER_NAME} add-apt-repository ppa:gift/dev -y;

	docker exec ${CONTAINER_NAME} apt-get update -q;

	# Set locale to US English and UTF-8.
	docker exec ${CONTAINER_NAME} locale-gen en_US.UTF-8;

	# Install packages.
	if test -n "${TOXENV}";
	then
		DPKG_PACKAGES="build-essential python${TRAVIS_PYTHON_VERSION} python${TRAVIS_PYTHON_VERSION}-dev tox";
	else
		DPKG_PACKAGES="";

		if test "${TARGET}" = "coverage";
		then
			DPKG_PACKAGES="${DPKG_PACKAGES} curl git";

		elif test "${TARGET}" = "jenkins3";
		then
			DPKG_PACKAGES="${DPKG_PACKAGES} sudo";

		elif test ${TARGET} = "pylint";
		then
			DPKG_PACKAGES="${DPKG_PACKAGES} python3-distutils pylint";
		fi
		if test ${TARGET} = "pypi";
		then
			DPKG_PACKAGES="${DPKG_PACKAGES} python3 python3-pip";

		elif test "${TARGET}" != "jenkins3";
		then
			DPKG_PACKAGES="${DPKG_PACKAGES} python3 ${DPKG_PYTHON3_DEPENDENCIES} ${DPKG_PYTHON3_TEST_DEPENDENCIES}";

			# Note that run_tests.py currently requires pylint.
			DPKG_PACKAGES="${DPKG_PACKAGES} python3-distutils pylint";
		fi
	fi
	docker exec -e "DEBIAN_FRONTEND=noninteractive" ${CONTAINER_NAME} sh -c "apt-get install -y ${DPKG_PACKAGES}";

	docker cp ../timesketch ${CONTAINER_NAME}:/

	if test "${TARGET}" = "pypi";
	then
		docker exec ${CONTAINER_NAME} sh -c "cd timesketch && pip3 install -r requirements.txt";
		docker exec ${CONTAINER_NAME} sh -c "cd timesketch && pip3 install -r test_requirements.txt";
		# The tests do not appear to require on these installs, hence they have been disabled and are kept for referrence.
		# docker exec ${CONTAINER_NAME} sh -c "(cd timesketch/api_client/python && python3 setup.py build && python3 setup.py install)";
		# docker exec ${CONTAINER_NAME} sh -c "(cd timesketch/importer_client/python && python3 setup.py build && python3 setup.py install)";
	else
		docker exec ${CONTAINER_NAME} sh -c "ln -s /usr/bin/nosetests3 /usr/bin/nosetests";
	fi
fi
