require 'rails_helper'

RSpec.describe Directory, type: :model do
  describe "with invalid name" do
    before do
      @r = Directory.create(name: "root")
      @d = [Directory.new(name: 'invalid/'), Directory.new(name: '*invalid'), Directory.new(name: "dir\nname")]
    end
    it "should not be valid" do
      @d.each do |dir|
        expect(dir).to_not be_valid
      end
    end
  end
  describe "with valid name" do
    before do
      @d = Directory.new(name: "  A valid directory name?   ")
    end
    it { expect(@d).not_to be_valid }
    it { expect(@d.name).to eq "A valid directory name?"}
  end
  describe "root" do
    before do
      @user = User.create(name: 'name', email: 'email@email.com', password: 'password')
      @group = @user.add Group.new(name: 'group')
      @group.save!
      @r = Directory.create(name: "root")
      @r.groups << @group
    end
    it { expect(Directory.root).to eq @r}
    describe "with duplicated root" do
      before do
        @new_r =  Directory.new(name: "the second root")
      end
      it { expect(@new_r).not_to be_valid }
    end
    describe "structure" do
      before do
        @d = [Directory.new(name: 'dir1'), Directory.new(name: 'dir2'), Directory.new(name: 'dir3')]
        @d.each do |dir| 
          @r.directories << dir 
          dir.groups << @group
          dir.save
        end
        @deeper = @d[0].mkdir! 'deep1', description: 'description'
        @d[1].mkdir_p! 'deep2/deeper2', description: 'description2'
        Directory.mkdir_p! '/dir3/deep3/deeper3'
        @cd = Directory.cd('/dir3/deep3')
        @cd2 = @cd.cd('deeper3')
      end
      it { expect(@r.directories.count).to eq 3 }
      it { expect(@d[0].directories.count).to eq 1 }
      it { expect(@deeper.description).to eq 'description'}
      it { expect(@d[1].directories.count).to eq 1 }
      it { expect(@d[1].directories.first.description).to eq 'description2' }
      it { expect(@d[1].directories.first.directories.first.name).to eq 'deeper2' }
      it { expect(@d[2].directories.count).to eq 1 }
      it { expect(@cd.name).to eq 'deep3' }
      it { expect(@cd2.name).to eq 'deeper3'}
      it { expect{@d[0].cd('nonexistent')}.to     raise_error Tarkin::DirectoryNotFound }
      it { expect{@d[0].cd('/nonexistent')}.to    raise_error Tarkin::DirectoryNotFound }
      it { expect{Directory.cd('nonexistent')}.to raise_error Tarkin::DirectoryNotFound }
      describe "with duplicated name in the same directory" do
        before do
          @dup = Directory.new(name: 'dir1', directory: Directory.root)
        end
        it { expect(@dup).not_to be_valid }
      end
      describe "with items" do
        before do
          #@i = Item.create
        end
      end
    end
  end
end
