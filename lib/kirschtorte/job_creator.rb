require 'bundler/setup'
require 'active_support/core_ext/module/qualified_const'
require 'base64'
require 'json'
require 'resque'

module Kirschtorte
  class JobCreator
    def self.create options
      payload = JSON.parse Base64.strict_decode64(options[:base64])

      # We don't want to list all the available worker
      # classes here, so instead we test for the existence
      # of the requested worker.

      task_name = payload["type"]["name"]
      worker = WorkerDirectory.find task_name

      if worker
        Resque.enqueue worker, options[:base64]
        puts "JobCreator: submitted #{task_name} task"
      else
        puts "JobCreator: no such task available"
      end
    end
  end

  class WorkerDirectory
    def self.find name
      worker_class = [
        'Kirschtorte',
        'Worker',
        self.normalize(name)
      ].join('::')
      if Kernel.qualified_const_defined? worker_class
        Kernel.qualified_const_get(worker_class)
      else
        nil
      end
    end

    def self.normalize name
      name.gsub(/SIP/, "Sip").
           gsub(/AIP/, "Aip").
           gsub(/DIP/, "Dip").
           gsub(/JSON/, "Json").
           gsub(/into/, "Into").
           gsub(/\s+/, "")
    end
  end
end
