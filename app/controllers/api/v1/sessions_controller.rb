class API::V1::SessionsController < Api::ApiController
  include SessionsHelper
  # Authorize the user and returns a new authorization token. By default returns just a token as a text string, but it could be modified by adding +.xml+ or +.json+ extensions.
  # The token can be stored in the local system, it contains User password encrypted by the key stored on the Tarkin server.
  #
  # <tt>GET|POST /_api/v1/_authorize[.xml|.json]</tt>
  #
  # [parameters:]
  # * User email and password
  # * basic http authentication in header
  #
  # = Examples
  #   resp = conn.get("http://localhost:3000/_api/v1/_authorize", email: "email0@example.com", password="password0")
  #   token = resp.body if resp.status == 200
  #   #=> "vwbtYjEtZl4IY31HBfJbXD31EUdTLv4stnzVQG8AiiZDagQ3s2IIKcRp..."
  #
  # === Shell
  # [via get] <tt>OS_TOKEN=`curl "http://localhost:3000/_api/v1/_authorize?email=email0@example.com&password=password0"`</tt>
  # [via http authentication] <tt>OS_TOKEN=`curl --user email0@example.com:password0 "http://localhost:3000/_api/v1/_authorize"`</tt>
  def create
    respond_to do |format|
      format.json { render json: {token: @token} }
      format.xml  { render xml:  {token: @token} }
      format.text { render text: @token }
    end
  end
end
