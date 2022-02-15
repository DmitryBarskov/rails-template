# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdentificationService do
  subject(:service) { described_class.new("Bearer eyJhb.e30.oWXWlOmeb3Gh") }

  describe "#find_user" do
    subject(:found_user) { service.find_user }

    let(:target_user) do
      User.create(email: "user@example.org", password: "123456")
    end

    context "with active refresh token" do
      before do
        RefreshToken.create(
          user: target_user, token: jwt,
          expires_at: 1.hour.from_now
        )
      end

      context "with a vaild token" do
        before do
          allow(JWT).to receive(:decode).and_return(
            [{ "sub" => target_user.id }]
          )
        end

        it { is_expected.to eq(target_user) }
      end

      context "with an invaild token" do
        before do
          allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)
        end

        it { is_expected.to be_nil }
      end
    end

    context "with inactive refresh token" do
      before do
        RefreshToken.create(
          user: target_user, token: jwt,
          expires_at: 1.hour.ago, jti: 42
        )
      end

      context "with a vaild token" do
        before do
          allow(JWT).to receive(:decode).and_return(
            [{ "sub" => target_user.id, jti: 42 }]
          )
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
