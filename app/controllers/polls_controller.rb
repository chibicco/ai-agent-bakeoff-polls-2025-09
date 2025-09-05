class PollsController < ApplicationController
  before_action :set_poll, only: [:show, :edit, :update, :open, :close]

  def index
    @polls = Poll.all.order(created_at: :desc)
  end

  def show
    @choices = @poll.choices.includes(:votes)
  end

  def new
    @poll = Poll.new
  end

  def create
    @poll = Poll.new(poll_params)
    
    if @poll.save
      redirect_to @poll, notice: 'アンケートが作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @poll.update(poll_params)
      redirect_to @poll, notice: 'アンケートが更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def open
    @poll.update!(status: :open)
    redirect_to @poll, notice: 'アンケートを公開しました。'
  end

  def close
    @poll.update!(status: :closed)
    redirect_to @poll, notice: 'アンケートを終了しました。'
  end

  private

  def set_poll
    @poll = Poll.find_by!(slug: params[:slug])
  end

  def poll_params
    params.require(:poll).permit(:title, :description, :ends_at, :status)
  end
end