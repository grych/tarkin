User.destroy_all
Item.destroy_all
Group.destroy_all
Directory.destroy_all

users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
groups = users.map{|user| user << Group.new(name: "group for #{user.name}")}
groups.each_with_index {|group, i| group.authorize(users[i])}
items = groups.map {|group| group << Item.new(password: "password for #{group.name}")}

root = Directory.create(name: 'root')
directories = 3.times.map{ |i| Directory.create(name: "dir#{i}", directory: root) }
