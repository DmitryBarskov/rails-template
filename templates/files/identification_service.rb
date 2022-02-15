# frozen_string_literal: true

class IdentificationSerivce
  def initialize(auth_header)
    @auth_header = auth_header
  end

  def find_user
    return unless token && payload && active_refresh_token?

    User.find_by(id: payload["sub"])
  end

  private

  def active_refresh_token?
    RefreshToken.active.exists?(jti: jti)
  end

  def jti
    payload["jti"]
  end

  def payload
    @payload ||= JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
  rescue JWT::DecodeError
    {}
  end

  def token
    @token ||= @auth_header.split.last
  end

  def jwt_secret
    @jwt_secret ||= ENV.fetch("JWT_SECRET")
  end
end
