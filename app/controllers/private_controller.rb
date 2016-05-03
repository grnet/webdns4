class PrivateController < ApplicationController
  # This a private trusted API
  skip_before_action :verify_authenticity_token

  # PUT /replace_ds
  def replace_ds
    parent, child, ds = replace_ds_params.values_at(:parent, :child, :ds)
    Domain.replace_ds(parent, child, ds)

    render json: { ok: true }
  rescue ActiveRecord::RecordNotFound
    render json: { ok: false, msg: 'Domain not found!' }
  end

  # PUT /trigger_event
  def trigger_event
    result = Domain
             .find_by_name(action_params[:domain])
             .fire_state_event(action_params[:event], params[:args])
    render json: { ok: result }
  end

  def zones
    render json: Domain.
            order(:name).
            includes(:group).map(&:to_export)
  end

  private

  def action_params
    params.require(:domain)
    params.require(:event)
    params.permit(:domain, :event, args: [])
  end

  def replace_ds_params
    params.require(:parent)
    params.require(:child)
    params.permit(ds: [])

    params
  end
end
