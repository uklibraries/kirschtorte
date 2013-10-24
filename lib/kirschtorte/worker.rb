# Abby Normal support
require 'kirschtorte/client'
require 'kirschtorte/model'

# Worker support
require 'kirschtorte/worker/generic'

# Individual task handlers
require 'kirschtorte/worker/create_aip'
require 'kirschtorte/worker/create_dip'
require 'kirschtorte/worker/get_identifiers'
require 'kirschtorte/worker/pull_sip'
require 'kirschtorte/worker/store_test_dip'
require 'kirschtorte/worker/store_test_oral_history_files'
require 'kirschtorte/worker/create_solr_json'
require 'kirschtorte/worker/index_into_test_solr'
require 'kirschtorte/worker/store_dip'
require 'kirschtorte/worker/store_oral_history_files'
require 'kirschtorte/worker/store_solr_json'
require 'kirschtorte/worker/index_into_solr'
require 'kirschtorte/worker/store_aip'
require 'kirschtorte/worker/store_logs'
require 'kirschtorte/worker/delete_sip_cache'
require 'kirschtorte/worker/delete_dip_cache'
require 'kirschtorte/worker/delete_solr_json_cache'
require 'kirschtorte/worker/delete_log_cache'
