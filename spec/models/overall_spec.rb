require 'rails_helper'

describe "overall" do
  before do
    @users = 3.times.map{|i| User.create(name: "name#{i}", email: "email#{i}@example.com", password: "password#{i}")}
    @groups = @users.map{|user| user << Group.new(name: "group for #{user.name}") }
    # @groups.each {|group| group.save! }
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
  it { expect(Directory.root.directories.count).to eq 3 }
  it { expect(Directory.root.directories).to eq @directories }
  3.times.each {|i| it { expect(@directories[i].directories.first).to eq @subdirectories[i] }}
  3.times.each {|i| it { expect(@directories[i].items.first).to eq @items[i] }}
  3.times.each {|i| it { expect(@users[i].ls.count).to eq 1 }}
  3.times.each do |i|
    it {expect(@users[i].ls(@directories[i]).count).to eq 2}
    it {expect(@users[i].ls(@directories[i]).to_a).to eq [@subdirectories[i], @items[i]]}
  end
  describe "user0 should see all groups" do
    before do
      @directories[1].groups << @groups[0]
      @directories[2].groups << @groups[0]
    end
    it { expect(@users[0].ls.count).to eq 3 }
    it { expect(@users[1].ls.count).to eq 1 }
    it { expect(@users[2].ls.count).to eq 1 }
    it { expect(@users[0].ls(@directories[1]).to_a).to eq [@items[1]]}
    it { expect(@users[0].ls(@directories[2]).to_a).to eq [@items[2]]}
  end
end
