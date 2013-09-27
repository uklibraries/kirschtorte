require 'bundler/setup'
require 'base64'
require 'json'

module Kirschtorte
  class JobCreator
    def self.create options
      payload = JSON.parse Base64.strict_decode64(options[:base64])

      # We don't want to list all the available worker
      # classes here, so instead we test for the existence
      # of the requested worker.

      worker = WorkerDirectory.find payload["type"]["name"]

      if worker
        Resque.enqueue worker, payload
        puts "JobCreator: submitted #{worker_class} task"
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
      ]
      if Kernel.const_defined? worker_class
        Kernel.const_get(worker_class)
      else
        nil
      end
    end

    def self.normalize name
      name.gsub(/SIP/, "Sip").
           gsub(/AIP/, "Aip").
           gsub(/DIP/, "Dip").
           gsub(/JSON/, "Json").
           gsub(/\s+/, "")
    end
  end
end
