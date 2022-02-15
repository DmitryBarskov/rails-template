# frozen_string_literal: true

class AuthenticationSerivce
  ACCESS_TOKEN_TTL = 1.hour
  REFRESH_TOKEN_TTL = 30.days

  def initialize(email:, password:)
    @email = email
    @passrord = password
  end

  def authenticate
    return unless user

    create_refresh_token!

    {
      access_token: access_token,
      refresh_token: refresh_token
    }
  end

  private

  def user
    @user = User.find_by(email: @email)&.authenticate(@password)
  end

  def create_refresh_token!
    RefreshToken.create!(
      user_id: user.id,
      expires_at: REFRESH_TOKEN_TTL.from_now,
      token: refresh_token,
      jti: jti
    )
  end

  def access_token
    JWT.encode(
      {
        sub: user.id,
        exp: ACCESS_TOKEN_TTL.from_now.to_i,
        jti: jti,
        type: "access"
      },
      jwt_secret, "HS256"
    )
  end

  def refresh_token
    @refresh_token ||= JWT.encode(
      {
        sub: user.id,
        exp: REFRESH_TOKEN_TTL.from_now.to_i,
        jti: jti,
        type: "refresh"
      },
      jwt_secret, "HS256"
    )
  end

  def jwt_secret
    @jwt_secret ||= ENV.fetch("JWT_SECRET")
  end
end
