class ApiController < ApplicationController
  # This a private trusted API
  skip_before_action :verify_authenticity_token

  before_action :authenticate_token

  # GET /ping
  def ping
    render json: { ok: true, response: :pong }
  end

  # GET /whoami
  def  whoami
    render json: { ok: true, response: current_user.to_api }
  end

  private

  def authenticate_token
    if user = User.find_by_token(params.require(:token))
      warden.set_user(user, store: false)
    else
      head(403)
    end
  end

end
