class PollsController < ApplicationController
  before_action :set_poll, only: [:show, :edit, :update, :open, :close]

  def index
    @polls = Poll.order(created_at: :desc)
  end

  def show
  end

  def new
    @poll = Poll.new
  end

  def create
    @poll = Poll.new(poll_params)
    if @poll.save
      redirect_to @poll, notice: "アンケートを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @poll.update(poll_params)
      redirect_to @poll, notice: "アンケートを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def open
    @poll.open!
    redirect_to @poll, notice: "アンケートを公開しました。"
  end

  def close
    @poll.closed!
    redirect_to @poll, notice: "アンケートを終了しました。"
  end

  private

  def set_poll
    @poll = Poll.find_by!(slug: params[:slug])
  end

  def poll_params
    params.require(:poll).permit(:title, :description, :ends_at)
  end
end

