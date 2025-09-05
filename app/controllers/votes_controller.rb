require "digest"

class VotesController < ApplicationController
  before_action :set_poll

  def create
    choice = @poll.choices.find_by(id: params[:choice_id])
    unless choice
      redirect_to @poll, alert: "選択肢を選んでください。"
      return
    end

    vhash = build_voter_hash

    @vote = Vote.new(poll: @poll, choice: choice, voter_hash: vhash)

    if @vote.save
      cookies.signed[voted_cookie_key] = { value: "1", expires: 1.year.from_now, httponly: true }
      redirect_to @poll, notice: "投票ありがとうございました。"
    else
      redirect_to @poll, alert: @vote.errors.full_messages.first || "投票に失敗しました。"
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to @poll, alert: "同一環境からは重複投票できません。"
  end

  private

  def set_poll
    @poll = Poll.find_by!(slug: params[:poll_slug])
  end

  def build_voter_hash
    # PII は保存しない。不可逆ハッシュのみ DB に保存。
    raw = [request.remote_ip, request.user_agent, Rails.application.credentials.secret_key_base].join("|")
    Digest::SHA256.hexdigest(raw)
  end

  def voted_cookie_key
    "voted_#{@poll.slug}"
  end
end
