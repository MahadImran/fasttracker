DemoAccounts.seed_all!

puts "Seeded demo users:"
puts "  #{DemoAccounts::NEWCOMER_EMAIL} / #{DemoAccounts::PASSWORD}  -> empty account"
puts "  #{DemoAccounts::TRACKER_EMAIL} / #{DemoAccounts::PASSWORD}   -> mixed backlog and activity"
puts "  #{DemoAccounts::CAUGHT_UP_EMAIL} / #{DemoAccounts::PASSWORD}  -> fully caught up"
