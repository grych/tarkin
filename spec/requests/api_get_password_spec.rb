require 'rails_helper'

describe "API Authorization" do
  # TODO: DRY with some factory_girl
  before do
    @users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
    @groups = @users.map{|user| user.add Group.new(name: "group for #{user.name}")}
    @groups.each_with_index {|group, i| group.authorize(@users[i])}
    @items = @groups.map {|group| group.add Item.new(username: "username for #{group.name}", password: "password for #{group.name}")}

    @root = Directory.create(name: 'root')
    @directories = 3.times.map{ |i| Directory.create(name: "dir#{i}", directory: @root) }
    @subdirectories = @directories.map{ |dir| dir.mkdir("subdir") }

    @directories[0].groups << @groups[0]
    @directories[1].groups << @groups[1]
    @directories[2].groups << @groups[2]

    @subdirectories[0].groups << @groups[0]
    @subdirectories[1].groups << @groups[1]  
    @subdirectories[2].groups << @groups[2]

    @items[0].directory = @directories[0]
    @items[1].directory = @directories[1]
    @items[2].directory = @directories[2]
    @items.each {|i| i.save!}
  end
  it "get a password with username and password with GET" do
    #get "/_api/v1/dir0/#{URI::escape("username for group for name0")}?email=email0@example.com&password=password0"
    # or ERB::Util.html_escape
    get "/_api/v1/items/1?email=email0@example.com&password=password0"
    expect(response).to be_success
    password = response.body
  end
end
