class ApiController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  # This a private trusted API
  skip_before_action :verify_authenticity_token

  before_action :authenticate_token, except: :ping
  before_action :domain, only: [:list, :bulk]

  # GET /ping
  def ping
    render json: { ok: true, response: :pong }
  end

  # GET /whoami
  def  whoami
    render json: { ok: true, response: current_user.to_api }
  end

  # GET domain/<name>/list
  def list
    records = Record.smart_order(@domain.records).map(&:to_api)
    render json: { ok: true, response: records }
  end

  # POST domain/<name>/list
  def bulk
    api_params = params.require(:api).permit!
    ops, err, bulk_ops = domain.api_bulk(api_params)

    if err.empty?
      notify_record_bulk(domain, bulk_ops)

      render json: { ok: true,
                     response: {
                       operations: ops
                     }
                   }
    else
      render json: { ok: false,
                     errors: err,
                     response: {
                       operations: ops
                     }
                   }
    end
  end

  private

  def authenticate_token
    if user = User.find_by_token(params.require(:token))
      warden.set_user(user, store: false)
    else
      head(403)
    end
  end

  def domain
    if params[:domain] =~ /^[0-9]+$/
      params[:domain_id] = params[:domain]
    else
      params[:domain_id] = Domain.find_by_name!(params[:domain]).id
    end

    super
  end

  def record_not_found
    render json: { ok: false, error: :record_not_found }
  end

  def parameter_missing
    render json: { ok: false, error: :parameter_missing }
  end

  def notify_record_bulk(*args)
    notification.notify_record_bulk(current_user, *args) if WebDNS.settings[:notifications]
  end

end
