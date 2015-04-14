require 'faye/websocket'
require 'mail'
require 'json'

module Switchboard

  class Worker
    def initialize params={}
      if params[:uri]
        @uri = params[:uri]
      else
        params[:host] ||= "192.168.50.2:8080"
        @uri = "ws://#{params[:host]}/workers"
      end
      
      @ws = Faye::WebSocket::Client.new(@uri)
      @callbacks = []
      listen
    end

    def open
      p [:ws, :connected, @uri] 
    end

    def close
      p [:ws, :disconnected, @uri] 
      @ws.close if @ws
      @ws = nil
    end

    def on_mail &block
      @callbacks << block
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

    def _add_account account
      send_cmd "connect", {
        host: "imap.gmail.com",
        port: 993,
        auth: account
      }
    end

    def listen
      @ws.on :open do |event| open end
      #@todo: retry connection
      @ws.on :close do |event| close end
      @ws.on :message do |event| dispatch JSON.parse(event.data).flatten! end
    end

    def dispatch payload
      type = payload[0]
      body = payload[1]
      p [:dispatch, type, body]

      case type 
      when 'newMessage'
        send_cmd "getMessages", {
          account: body["account"],
          ids: [body["messageId"]],
          properties: ["raw"]
        } if not @callbacks.empty?
      when 'messages'
        state = body["state"] 
        #@todo: send all messages to all the callbacks
        #@todo: map messages raw content with Mail objects
        if state == "TODO"
          raw = body["list"][0]["raw"]
          email = Mail.new(raw)
          to = if email[:delivered_to].is_a? Array
                 email[:delivered_to][0]
               else
                 email[:delivered_to]
               end.value

           message = {
             to: to,
             message: email.subject[0...200]
           }

           @callbacks.each do |cb| cb.call(message) end
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
