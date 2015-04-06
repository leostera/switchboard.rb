# Switchboard with your Ruby!
> Necessary alpha quality disclaimer: This is just a hack. Feel free to contribute
though! Feature requests in form of issues are more than welcome :)

## Installation
It's not even a Gem right now. I've never published a Gem before so I'll have to 
take a look at it. Dependencies are quite straightforward.

## Usage
A code snippet speaks for a thousand words

```ruby
# Create a worker
switchboard = Switchboard::Worker.new

# Register a callback
switchboard.on_mail do |message|
  p [:message, message]
end

# Connect an account
switchboard.add_account({
  email: 'your@email.com',
  token: 'yourToken',
  token_type: 'refresh' #or 'access',
  provider: 'google' #or others
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
