require 'faye/websocket'
require 'mail'
require 'json'

module Switchboard

  class Worker
    def initialize params={}
      if params[:uri]
        @uri = params[:uri]
      else
        params[:host] ||= "192.168.50.2"
        params[:port] ||= "8080"
        @uri = "ws://#{params[:host]}:#{params[:port]}/workers"
      end
      
      @retry = params[:retry] || 1
      @callbacks = {
        on_mail: [],
        on_open: [],
        on_close: []
      }
      @ws = nil
      connect
    end

    def open
      p [:ws, :connected, @uri] 
      @callbacks[:on_open].each do |cb| cb.call(self) end
    end

    def close event
      p [:ws, :disconnected, @uri, event.code, event.reason]
      @ws.close if @ws
      @ws = nil
    end

    def on_mail &block
      @callbacks[:on_mail] << block
    end

    def on_open &block
      @callbacks[:on_open] << block
    end

    def watch_all
      send_cmd "watchAll"
    end

    def watch_mailboxes email, mailboxes=["INBOX"]
      send_cmd "watchMailboxes", {
        account: email,
        list: mailboxes
      }
    end

    def add_account type, account
      case type
      when :plain
        _add_account(
          type: "plain",
          username: account[:email],
          password: account[:password]
        )
      when :oauth2
        _add_account(
          type: "xoauth2",
          username: account[:email],
          token: {
            type: account[:token_type],
            token: account[:token], 
            provider: account[:provider] 
          }
        )
      else
        throw "Type must be :plain or :oauth2"
      end
    end

    private

    def connect
      @ws = Faye::WebSocket::Client.new(@uri)
      listen
    end

    def reconnect
      if @retry > 0
        sleep @retry
        connect
      end
    end

    def _add_account account
      send_cmd "connect", {
        host: "imap.gmail.com",
        port: 993,
        auth: account
      }
    end

    def listen
      @ws.on :open do |event|
        open
      end

      @ws.on :close do |event|
        close event
        reconnect
      end

      @ws.on :message do |event|
        if event and event.data
          dispatch JSON.parse(event.data).flatten!
        end
      end
    end

    def dispatch payload
      type = payload[0]
      body = payload[1]

      preview = body.map do |k, v|
        if k == "list"
          v.map do |m|
            m["raw"] = "OMITTED" if m["raw"]
            m
          end
        else
          v
        end
      end
      p [:dispatch, type, preview]

      case type 
      when 'newMessage'
        send_cmd "getMessages", {
          account: body["account"],
          ids: [body["messageId"]],
          properties: ["raw"]
        } if not @callbacks[:on_mail].empty?
      when 'messages'
        state = body["state"] 
        if state == "TODO"
          messages = body["list"].map do |message|
            Mail.new(message['raw'])
          end
          @callbacks[:on_mail].each do |cb| cb.call(messages) end
        end
      end
    end

    def send_cmd cmd, params={}
      p [:send, cmd, params]  
      @ws.send(make_cmd cmd, params) if @ws
    end

    def make_cmd cmd, params
      [[cmd, params]].to_json
    end
  end

end
