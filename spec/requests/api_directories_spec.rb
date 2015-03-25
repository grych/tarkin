require 'rails_helper'

#TODO: review and rewrite all tests
describe "API Passwords" do
  # TODO: DRY with some factory_girl
  before do
    @users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
    @groups = @users.map{|user| user << Group.new(name: "group for #{user.name}")}
    @groups.each_with_index {|group, i| group.authorize(@users[i])}
    @items = @groups.map {|group| group.add Item.new(username: "username for #{group.name}", password: "password for #{group.name}")}

    @root = Directory.create(name: 'root')
    @directories = 3.times.map { |i| Directory.root.mkdir! "dir#{i}", user: @users[i] }

    @subdirectories = @directories.map{ |dir| dir.mkdir!("subdir") }

    @items[0].directory = @directories[0]
    @items[1].directory = @directories[1]
    @items[2].directory = @directories[2]
    @items.each {|i| i.save!}
  end

  it "get a directory listing" do
    post '/_api/v1/_authorize', email: "email0@example.com", password: "password0"
    token = response.body
    e = env.merge({"AUTHORIZATION" => "Token token=#{token}"})
    post "/_api/v1/_dir/dir0", {}, e
    expect(response).to be_success
    expect(response.body).to eq "subdir/\nusername for group for name0"
  end

  private
  # TODO: make it DRY
  def env
    {
      'Accept' => 'text/plain',
      'Content-Type' => 'text/plain'
    }
  end

end
