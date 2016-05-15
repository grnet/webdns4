class HelpController < ApplicationController
  before_action :authenticate_user!

  def api
    render layout: false
  end
end
