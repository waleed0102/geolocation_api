class ApplicationController < ActionController::API
  before_action :authenticate!

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def authenticate!
    token = bearer_token
    return unauthorized_error unless token.present? && ApiKey.active.exists?(token: token)
  end

  def bearer_token
    request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
  end

  def not_found(exception = nil)
    render_error(404, "Not Found", exception&.message || "Resource not found")
  end

  def bad_request(exception)
    render_error(400, "Bad Request", exception.message)
  end

  def unauthorized_error
    render_error(401, "Unauthorized", "Valid API key required. Provide it as: Authorization: Bearer <token>")
  end

  def render_error(status, title, detail)
    render json: {
      errors: [{ status: status.to_s, title: title, detail: detail }]
    }, status: status
  end
end
