require 'chef/config'
require 'chef/rest'
require 'chef/api_client'

module Vagrant
  module Butcher
    module Action
      class Cleanup
        def initialize(app, env)
          @app = app
          @env = env
        end

        def vm_config; @vm_config ||= @env[:machine].config.vm;                                          end
        def chef_api ; @chef_api  ||= ::Chef::REST.new(chef_provisioner.chef_server_url);                end
        def victim   ; @victim    ||= chef_provisioner.node_name || vm_config.hostname || vm_config.box; end

        def chef_provisioner
          @chef_provisioner ||= vm_config.provisioners.find do |p|
            p.config.is_a? VagrantPlugins::Chef::Config::ChefClient
          end.config
        end

        def delete_resource(resource)
          @env[:ui].info "Removing Chef #{resource} \"#{victim}\"..."
          begin
            chef_api.delete_rest("#{resource}s/#{victim}")
          rescue Exception => e
            @env[:ui].warn "Could not remove #{resource} #{victim}: #{e.message}"
          end
        end

        def call(env)
          ::Chef::Config.from_file(Config.knife_config)
          %w(node client).each { |resource| delete_resource(resource) }

          @app.call(env)
        end
      end
    end
  end
end
