ENV_FILE := .env
include ${ENV_FILE}
export $(shell sed 's/=.*//' ${ENV_FILE})
export PIPENV_DOTENV_LOCATION=${ENV_FILE}

oc_get_token:
	oc sa get-token "prometheus" -n "${NAMESPACE}"

oc_create_build:
	oc process --filename=openshift/prometheus-flatliner-image-build-template.yaml \
		--param NAMESPACE=${NAMESPACE} \
		| oc apply -f -

oc_build_head:
	$(eval ARCHIVE=$(shell mktemp))
	git archive --format=tar.gz HEAD > ${ARCHIVE}
	oc start-build prometheus-flatliner --from-archive ${ARCHIVE} --follow

oc_trigger_build:
	oc start-build prometheus-flatliner -F

oc_historic_job:
	oc process --filename=openshift/prometheus-flatliner-job-template.yaml \
		--param NAMESPACE=${NAMESPACE} \
		--param FLT_PROM_URL=${FLT_PROM_URL} \
		--param FLT_PROM_ACCESS_TOKEN="${FLT_PROM_ACCESS_TOKEN}" \
		--param FLT_METRICS_LIST="${FLT_METRICS_LIST}" \
		--param FLT_METRIC_START_DATETIME="${FLT_METRIC_START_DATETIME}" \
		--param FLT_METRIC_END_DATETIME="${FLT_METRIC_END_DATETIME}" \
		--param FLT_METRIC_CHUNK_SIZE="${FLT_METRIC_CHUNK_SIZE}" \
		| oc apply -f -

historic_job:
	pipenv run python app.py