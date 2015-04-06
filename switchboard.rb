require 'faye/websocket'
require 'mail'
require 'json'

module Switchboard

  class Worker
    def initialize params={}
      params[:url] ||= "192.168.50.2:8080"
      @url = "ws://#{params[:url]}/workers"
      @ws = Faye::WebSocket::Client.new(@url)
      @callbacks = []
      listen
    end

    def open
      p [:ws, :connected, @url] 
    end

    def close
      p [:ws, :disconnected, @url] 
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

    def add_account account
      send_cmd "connect", {
        host: "imap.gmail.com",
        port: 993,
        auth: {
          type: "xoauth2",
          username: account[:email],
          token: {
            type: account[:token_type],
            token: account[:token], 
            provider: account[:provider] 
          }
        }}
    end

    private

    def listen
      @ws.on :open do |event| open end
      @ws.on :close do |event| close end
      @ws.on :message do |event| dispatch JSON.parse(event.data).flatten! end
    end

    def dispatch payload
      type = payload[0]
      body = payload[1]
      p [:dispatch, type, body]

      case type 
      when 'newMessage'
        # if a new message arrives, request it's details
        send_cmd "getMessages", {
          account: body["account"],
          ids: [body["messageId"]],
          properties: ["raw"]
        } if not @callbacks.empty?
      when 'messages'
        # if message details arrive, push to device
        state = body["state"] 
        if state == "TODO"
          # messages will always return an array
          # but we're asking for just one id, so we care
          # about the first one only
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
      @ws.send make_cmd cmd, params
    end

    def make_cmd cmd, params
      [[cmd, params]].to_json
    end
  end

end
