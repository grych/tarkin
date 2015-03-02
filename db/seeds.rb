# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.destroy_all
Item.destroy_all
Group.destroy_all

users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
groups = users.map{|user| user << Group.new(name: "group for #{user.name}")}
groups.each_with_index {|group, i| group.authorize(users[i])}
items = groups.map {|group| group << Item.new(password: "password for #{group.name}")}
