class PrivateController < ApplicationController
  # This a private trusted API
  skip_before_action :verify_authenticity_token

  # PUT /replace_ds
  def replace_ds
    parent, child, ds = replace_ds_params.values_at(:parent, :child, :ds)
    Domain.replace_ds(parent, child, ds)

    render json: { ok: true }
  end

  private

  def replace_ds_params
    params.require(:parent)
    params.require(:child)
    params.require(:ds)
    params.permit(ds: [])

    params
  end
end
