class VotesController < ApplicationController
  before_action :set_poll

  def create
    # voter_hashの生成
    voter_hash = generate_voter_hash
    
    # 既に投票済みかチェック
    if voter_hash.present? && @poll.votes.exists?(voter_hash: voter_hash)
      redirect_to @poll, alert: "このアンケートには既に投票済みです。"
      return
    end

    # 投票を作成
    @vote = @poll.votes.build(vote_params)
    @vote.voter_hash = voter_hash

    if @vote.save
      set_voter_cookie
      redirect_to @poll, notice: "投票ありがとうございました！"
    else
      redirect_to @poll, alert: @vote.errors.full_messages.join(", ")
    end
  end

  private

  def set_poll
    @poll = Poll.find_by!(slug: params[:poll_slug])
  end

  def vote_params
    params.permit(:choice_id)
  end

  def generate_voter_hash
    # Cookieが存在しない環境でも動作するようにする
    return nil unless cookies[:voter_id].present? || request.remote_ip.present?
    
    # voter_idをCookieから取得、なければ生成
    voter_id = cookies.signed[:voter_id] || SecureRandom.uuid
    
    # IPアドレス、User-Agent、秘密鍵を組み合わせてハッシュ化
    data = [
      request.remote_ip,
      request.user_agent,
      voter_id,
      Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    ].join("-")
    
    Digest::SHA256.hexdigest(data)
  end

  def set_voter_cookie
    # 署名付きCookieでvoter_idを保存（1年間有効）
    cookies.signed[:voter_id] = {
      value: cookies.signed[:voter_id] || SecureRandom.uuid,
      expires: 1.year.from_now,
      httponly: true,
      secure: Rails.env.production?
    }
  end
end