class AuthController < ApplicationController
  # PUT /saml
  def saml
    warden.authenticate!(:saml)

    redirect_to root_path
  end
end
