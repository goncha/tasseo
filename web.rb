require 'sinatra'
require 'rack-ssl-enforcer'
require 'haml'
require 'json'

module Tasseo
  class Web < Sinatra::Base

    configure do
      enable :logging
      enable :sessions
      mime_type :js, 'text/javascript'
      use Rack::SslEnforcer if ENV['FORCE_HTTPS']
      use Rack::Static, :urls => ['/dashboards/']
    end

    before do
      find_dashboards
    end

    helpers do
      def dashboards
        @dashboards
      end

      def dashboards_dir
        File.expand_path('../dashboards', __FILE__)
      end

      def find_dashboards
        @dashboards = []
        Dir.foreach(dashboards_dir).grep(/\.js/).sort.each do |f|
          @dashboards.push(f.split(".").first)
        end
      end
    end

    get '/' do
      # AcceptEntry -> String
      accept = request.accept.map { |x| x.to_str }
      if !dashboards.empty?
        if accept.include?('application/json')
          content_type 'application/json'
          status 200
          { :dashboards => dashboards }.to_json
        else
          haml :index, :locals => {
            :dashboard => nil,
            :list => dashboards,
            :error => nil
          }
        end
      else
        if accept.include?('application/json')
          content_type 'application/json'
          status 204
        else
          haml :index, :locals => {
            :dashboard => nil,
            :list => nil,
            :error => 'No dashboard files found.'
          }
        end
      end
    end

    get '/health' do
      content_type :json
      {'status' => 'ok'}.to_json
    end

    get %r{/([\S]+)} do
      path = params[:captures].first
      if dashboards.include?(path)
        haml :index, :locals => { :dashboard => path }
      else
        body = haml :index, :locals => {
          :dashboard => nil,
          :list => dashboards,
          :error => 'That dashboard does not exist.'
        }
        [404, body]
      end
    end
  end
end

