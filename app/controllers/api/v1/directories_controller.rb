class API::V1::DirectoriesController < Api::ApiController
  def index
    if params[:path]
      d = Directory.cd(params[:path])
    else
      d = Directory.root
    end
    respond_to do |format|
      format.json { render json: directory_children(d)}
      format.xml  { render xml:  directory_children(d)}
      format.text { render text: directory_children_text(d)}
    end
  end

  private
  def directory_children_text(d)
    current_user.ls_dirs(d).map{|dir| "#{dir.name}/"}.join("\n") + "\n" + current_user.ls_items(d).map{|item| item.username}.join("\n")
  end

  def directory_children(d)    
    {directories: current_user.ls_dirs(d).map {|dir| {name: dir.name, id: dir.id}}, items: current_user.ls_items(d).map {|item| {username: item.username}}}
  end
end