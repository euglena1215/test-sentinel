# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all

    @users = @users.where(status: params[:status]) if params[:status].present?

    return unless params[:premium].present?

    @users = @users.where(subscription_type: 'premium')
  end

  def show
    return if current_user.admin? || current_user == @user

    redirect_to root_path, alert: 'Access denied'
    nil
  end

  def create
    @user = User.new(user_params)

    if @user.save
      UserMailer.welcome(@user).deliver_now if params[:send_welcome_email]
      redirect_to @user, notice: 'User created successfully'
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      log_suspension_action if user_params[:status] == 'suspended'
      redirect_to @user, notice: 'User updated successfully'
    else
      render :edit
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :status, :role, :subscription_type)
  end

  def log_suspension_action
    Rails.logger.info "User #{@user.id} was suspended by #{current_user.id}"
  end

  def current_user
    # Stub for authentication
    @current_user ||= User.first
  end
end
