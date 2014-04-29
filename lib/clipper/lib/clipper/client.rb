require 'faraday'
require 'nokogiri'

module Clipper
  class Client
    USER_AGENT      = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36'
    BASE_URL        = 'https://www.clippercard.com'
    LOGIN_PATH      = '/ClipperCard/loginFrame.jsf'
    DASHBOARD_PATH  = '/ClipperCard/dashboard.jsf'

    attr_accessor :username, :password, :session_id, :logged_in

    def initialize(username, password)
      self.username   = username
      self.password   = password
      self.logged_in  = false

      self
    end

    def balance
      @balance ||= dashboard.css('.cardInfo').children.collect(&:text).join.match(/(\$[0-9\.]+)/)[0].gsub('$', '').to_f
    end

    def logged_in?
      !!logged_in
    end

    def login!
      connection.headers[:user_agent] = USER_AGENT

      response = connection.get(LOGIN_PATH)
      login = Nokogiri::HTML(response.body)

      viewstate = login.xpath('//input').select{|n| n['id'] =~ /viewstate/i}.first['value']
      self.session_id = response.headers['set-cookie'].split(';').select{|c| c =~ /^JSESSIONID/i}[0]

      connection.headers[:cookie] = self.session_id

      login_params = self.class.default_params.merge({
        'j_idt14:username'      => self.username,
        'j_idt14:password'      => self.password,
        'javax.faces.ViewState' => viewstate
      })

      response = connection.post LOGIN_PATH, login_params

      self.logged_in = true
    end

    def self.default_params
      {
        'j_idt14'                     => 'j_idt14',
        'javax.faces.source'          => 'j_idt14:submitLogin',
        'javax.faces.partial.event'   => 'click',
        'javax.faces.partial.execute' => ':submitLogin j_idt14:username j_idt14:password',
        'javax.faces.partial.render'  => 'j_idt14:err',
        'javax.faces.behavior.event'  => 'action',
        'javax.faces.partial.ajax'    => 'true'
      }
    end

    private
    def dashboard
      @dashboard ||= Nokogiri::HTML(request_path(DASHBOARD_PATH).body)
    end

    def connection
      @connection ||= Faraday.new(:url => BASE_URL) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    def request_path(path)
      login! unless logged_in?

      connection.get path
    end

  end
end
