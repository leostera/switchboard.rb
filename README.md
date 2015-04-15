# Switchboard with your Ruby!
> Necessary alpha quality disclaimer: This is just a hack. Feel free to contribute
though! Feature requests in form of issues are more than welcome :)

## Installation
Add `gem 'switchboard', github: 'ostera/switchboard.rb'` to your `Gemfile`.

## Usage
A code snippet speaks for a thousand words

```ruby
# Create a worker
switchboard = Switchboard::Worker.new

# Register an open callback
switchboard.on_open do
  p [:open, "Connection opened"]
end

# Register a message callback
switchboard.on_mail do |message|
  p [:message, message]
end

# Connect an oauth account
switchboard.add_account(:oauth2, {
  email: 'your@email.com',
  token: 'yourToken',
  token_type: 'refresh' #or 'access',
  provider: 'google' #or others
})

# Connect a plain account
switchboard.add_account(:simple, {
  email: 'email@your.com',
  password: 'yourpassword'
})

# Watch a single account
switchboard.watch_mailboxes 'your@email.com', ["INBOX", "SENT"]

# or if it's only INBOX, just pass an email
switchboard.watch_mailboxes 'your@email.com'

# Watch all accounts! Yays!
switchboard.watch_all

# Close the connection if you're done with it
switchboard.close
```

## Credits and License
Inspired by [jtmoulia/switchboard-python](https://github.com/jtmoulia/switchboard-python), 
developed by [@ostera](https://github.com/ostera): use at your own risk!
